---
title: "Cache Invalidation Complexity: Rails 5.2 and Dalli Cache Store"
layout: post
published: true
date: 2018-10-17
permalink: /2018/10/17/cache-invalidation-complexity-rails-52-and-dalli-cache-store/
categories:
    - ruby
    - performance
    - cache
---

Rails applications that use ActiveRecord objects in their cache may experience an issue where the entries cannot be invalidated if all of these conditions are true:

1. They are using Rails 5.2+
2. They have configured `config.active_record.cache_versioning = true`
3. They are using a cache that is not maintained by Rails, such as `dalli_store`

In this post, we discuss the background to a change in the way that cache keys work with Rails, why this change introduced an API incompatibility with 3rd party cache stores, and finally how you can find out if your app is at risk and how to fix it.

Even if you're not at Rails 5.2 yet, you'll likely get there one day. It's important to read and potentially mitigate this issue before you run into it in production.

> This article was [originally published on the Heroku Engineering blog](https://blog.heroku.com/cache-invalidation-rails-5-2-dalli-store).

## Background: What are Recyclable Cache keys?

One of the [hallmark features of Rails 5.2 was "recyclable" cache keys](https://weblog.rubyonrails.org/2018/1/31/Rails-5-2-RC1-Active-Storage-Redis-Cache-Store-HTTP2-Early-Hints-Credentials/`). What does that mean and why do you want them? If you're caching a view partial that has an Active Record object when the object changes then you want the cache to invalidate and be replaced with the new information.

The old way that Rails accomplished cache invalidation is to put version information directly into the cache key. For an Active Record object this means a formatted string of `:updated_at`. For example:

```language-ruby
# config.active_record.cache_versioning = false
user = User.first
user.name = "richard"
user.save
user.cache_key
# => "users/1-<version-1>"
```

This scheme is quite robust. When the object changes so does the key:

```language-ruby
# config.active_record.cache_versioning = false
user = User.first
user.name = "schneems"
user.save
user.cache_key
# => "users/1-<version-2>"
```

However, this causes unnecessary cache invalidations. For example, let's say that you have three objects and three slots in your cache. Letters A, B, and C differentiate the objects, while a number indicates their versions, these are all version one:

```
[A(1), B(1), C(1)]
```

When object A changes, it doesn't evict the cache for object A, instead, it evicts the last cache entry which is C. Now the cache looks like this:

```
[A(2), A(1), B(1)]
```

The next time that C is requested it won't be found, and it will be re-calculated and get added to the front of the cache. This addition pushes out the copy of B:

```
[C(1), A(2), A(1)]
```

Now the next time that B is requested it won't be found, and it will be re-calculated and get added to the front of the cache:


```
[B(1), C(1), A(2)]
```


While we only made one change to object A, it resulted in clearing and resetting the values for both B(1) and C(1) even though they never changed. This method of cache invalidation adds unnecessary time spent recalculating already valid cache entries. Cache versioning's goal is to fix this unneeded cache invalidation.

### Cache invalidation with cache versioning (recyclable cache keys)

With the new method of cache versioning, the keys stay consistent, but the `cache_version` is stored inside the cache entry and manually checked when pulling an entry from the cache.

```language-ruby
# config.active_record.cache_versioning = true
user = User.first
user.name = "richard"
user.save
user.cache_key
# => "users/1"

user.cache_version
# => "<version-1>"

user.name = "schneems"
user.save
user.cache_key
# => "users/1"

user.cache_version
# => "<version-2>"
```

Here's an example of how the cache works with cache versioning:

```
[A(1), B(1), C(1)]
```

When object A changes, to version two, it will pull the A(1) object from the cache, see that it has a different version, and replace the entry in the same slot using a consistent cache key:

```
[A(2), B(1), C(1)]
```

Now future calls to retrieve the A object will show that the version is correct, and the cached value can be used.

With this new scheme, changing one object does not have a cascade effect on other cached values. In this way, we're able to keep valid items in our cache longer and do less work.

How well does it work? DHH at Basecamp had this to say:

> We went from only being able to keep 18 hours of caching to, I believe, 3 weeks. It was the single biggest performance boost that Basecamp 3 has ever seen.

By enabling recyclable cache key versioning (`config.active_record.cache_versioning = true`), instead of having to recalculate every cache entry every 18 hours effectively, the churn spread out over 3 weeks, which is very impressive.

## What's the issue?

Now that you know what recyclable cache keys are and how Rails implements them you should know that the client that talks to the cache provider needs to be aware of this new scheme. Rails [ships with a few cache stores](https://guides.rubyonrails.org/caching_with_rails.html#activesupport-cache-store)

- `:memory_store`
- `:file_store`
- `:mem_cache_store`
- `:redis_cache_store`

If you're using one of these stores then you get a cache client that supports this feature flag. However, you can also provide a custom cache store and other gems ship with a store. Most notably:

- `:dalli_store` (not maintained by Rails)

If you're using a custom cache store then it's up to that library to implement this new scheme.

If you're using `:dalli_store` right now and have `config.active_record.cache_versioning = true` then you are quietly running in production without the ability to invalidate caches. For example, you can see [CodeTriage, an app that helps people contribute to Open Source](https://www.codetriage.com) not change the view when the underlying database entry is modified:

![dalli_store_rails_codetriage_demo](https://heroku-blog-files.s3.amazonaws.com/posts/1539677220-dalli_store_rails_codetriage_demo.gif)

Why is this happening? Remember how we showed that the cache key is the same no matter if the model changes? The Dalli gem (as of version 2.7.8) only understands the `cache_key`, but does not understand how to insert and use cache versions. When using the `:dalli_store` and you've enabled recyclable cache keys then the `cache_key` doesn't change and it will always grab the same value from the cache.

## How to detect if you're affected

First confirm what cache store you're using, make sure to run this in a production env otherwise you might be using a different cache store for different environments:

```language-ruby
puts Rails.application.config.cache_store.inspect
# => :dalli_store
```

If it's not on the above [list of officially supported Rails cache backends](https://guides.rubyonrails.org/caching_with_rails.html#cache-stores) then you might be affected. Next, inspect your cache versioning:

```language-ruby
puts Rails.application.config.active_record.cache_versioning
# => true # truthy values along with `:dalli_store` cause this issue
```

## How to mitigate

There are several options, each with their own trade-off.

### Switch from dalli to `:mem_cache_store`

You can switch away from the `:dalli_store` and instead use the official `:mem_cache_store` that ships with Rails:


```language-ruby
config.cache_store = :mem_cache_store
```

> Note: This cache store still uses the `dalli` gem for communicating with your memcache server.

If you were previously passing in arguments it looks like you can just change the store name, for instance if you're using the memcachier service it might look like this:

```language-ruby
config.cache_store = [:mem_cache_store, (ENV["MEMCACHIER_SERVERS"] || "").split(","),
                      { :username => ENV["MEMCACHIER_USERNAME"],
                        :password => ENV["MEMCACHIER_PASSWORD"],
                        :failover => true,
                        :socket_timeout => 1.5,
                        :socket_failure_delay => 0.2 }]
```

This was [tested on CodeTriage](https://github.com/codetriage/codetriage/pull/786).

**Pros:** With this store you get cache key recycling, you also get cache compression which helps significantly with time transferring bytes over a network to your memcache service. To achieve these features this cache store does more work than the raw `:dalli_store`, in preliminary benchmarks on [CodeTriage](https://www.codetriage.com) while connecting to an external memcache server the performance is roughly equivalent (within 1% of original performance). With the decreased space from compression and the extra time that cache keys can "live" before being evicted with key recycling, this makes this store a net positive.

**Cons:** The cache keys for `:mem_cache_store` are identical to the ones generated via `:dalli_store`, however it does not have the version information stored in the cache entry yet. When `:mem_cache_store` sees this it falls back to the old behavior of not validating the "freshness" of the entry. This means in order to get the updated behavior where changing an Active Record object actually updates the database you'll need to invalidate old entries. The "easiest" way to do this is to is to flush the whole cache. The problem with this is that will significantly slow your service as your entire application is then functioning with a cold cache.

### Disable recyclable cache keys (cache versioning)

If you don't want to replace your cache store, disabling the cache versioning feature will also fix the issue of changing Active Record objects not invalidating the cache. You can disable this feature like this:

```language-ruby
config.active_record.cache_versioning = false
```

If you're wondering about the config naming as I was it's `cache_versioning` because the version of the object lives in the cache rather than in the key. It's effectively the same thing as enabling or disabling recyclable caching.

**Pros:** You don't have to switch your cache store. Doesn't require a cache flush (but will instead manually invalidate keys automatically due to changing cache key format). You can use this information to slowly roll out the cache key changes if you're able to do blue/green deploys and roll out to a percentage of your fleet. You'll still get some instances operating under a cold cache but by the time 100% of instances are running with the new version then the cache should be fairly "warm".

**Cons:** You won't have to flush your old cache, BUT the cache key format will change which effectively does the same thing. When you change this config then your whole app will not be able to use any cache keys from before and will effectively be working with a cold cache while you're re-building old keys. You do not get recyclable keys. You do not get cache compression. Disabling the cache versioning will also mean that dalli must do more work to build cache keys which actually makes caching go slightly slower.

Overall I would recommend switching to `:mem_cache_store` and then flushing the cache.

## Next steps

At Heroku we've taken efforts to update all of our documentation to suggest using `:mem_cache_store` instead of directly using dalli. That being said there are still a ton of [historical references to using the older store](https://duckduckgo.com/?q=%22%3Adalli_store%22&t=h_&ia=software) if you see one in the wild please make a comment and point at this post.

Since the issue is deeper than the `:dalli_store`, it potentially affects any custom cache we need a way to systematically let people know when they're at risk for running in a bad configuration.

My proposal is to add a predicate method to all maintained and supported Rails cache stores for example `ActiveStorage::Cache::MemCacheStore.supports_in_cache_versioning?` (method name TBD). If the app specifies `config.active_record.cache_versioning = true` without using a cache that responds affirmatively to `supports_in_cache_versioning?` then we can raise a helpful error that explains the issue.

There's also work being done on [dalli](https://github.com/petergoldstein/dalli) both for adding a limited form of support and for adding documentation.

As it is said there are two truly hard problems in computer science: cache invalidation, naming, and off by one errors. While this incompatibility is unfortunate it's hard to make a breaking API change that fully anticipates how all external consumers will work. I've spent a lot of time in the Rails contributor chat talking with [DHH](https://github.com/dhh) and [Rafael](https://github.com/rafaelfranca) and there's a [really good thread of some of the perils of changes that touch cache keys in one of my performance PRs](https://github.com/rails/rails/pull/33835). We realize the sensitive nature of changes anywhere near caching. In addition to bringing more scrutiny and awareness to these types of changes, we're working towards making more concrete policies.
