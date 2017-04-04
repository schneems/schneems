---
title: "Double Ruby Rainbow Bug"
layout: post
published: true
date: 2017-04-04
permalink: /2017/04/04/double-ruby-rainbow-bug/
categories:
    - ruby
---

What happens when "don't do that" turns into "it worked before"? This is exactly the scenario I was faced with recently. We had a string of tickets, maybe 4 or so in under two days with the same weird error message. This frequency normally indicates that something changed, but the error was in a weird place, didn't seem to be related to any new code. Here's the error people were reporting on Heroku:

```
remote: -----> Ruby app detected
remote: /tmp/tmp.y7163/bin/ruby: symbol lookup error: /tmp/build_c85cc440028913e25caa54b9ff2142/vendor/bundle/ruby/2.3.0/gems/json-1.8.6/lib/json/ext/generator.so: undefined symbol: rb_data_typed_object_zalloc
remote:  !     Push rejected, failed to compile Ruby app.
```

Pretty cryptic, right? After looking at a few, I figured out a common thread. They all were accidentally invoking the Ruby buildpack twice. Terence Lee dubbed this the "double rainbow" bug. But how is it possible to run the same buildpack twice? When you first deploy, we detect your language by executing `bin/detect` of each buildpack. The first one that returns a good exit code is chosen to compile the app. This buildpack is also "pinned". So if you deploy an app with a `Gemfile` after you deploy, you'll get this asset as your buildpack:

```
$ heroku buildpacks
=== floating-falls-58476 Buildpack URL
heroku/ruby
```

So the buildpack for the app is `heroku/ruby`. Now if you wanted to add another buildpack. Let's say you're using [heroku-buildpack-pgbouncer/](https://github.com/heroku/heroku-buildpack-pgbouncer). If you were following along with the directions It will tell you to first add the pgbouncer buildpack

```
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-pgbouncer
```

But then it also had an example of using the master branch of the `heroku/ruby` buildpack:

```
# Don't do this
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-ruby
```

> Note: Master of the ruby buildpack may be slightly ahead of `heroku/ruby`, don't specify it unless you want to live on the edge.

After running these commands you would get something like this in your app:

```
$ heroku buildpacks
=== floating-falls-58476 Buildpack URLs
1. heroku/ruby
2. https://github.com/heroku/heroku-buildpack-pgbouncer
3. https://github.com/heroku/heroku-buildpack-ruby
```

So the issue was that people were mistakenly installing ruby __twice__. I told all the customers who hit the bug to remove the last entry, and sure enough, the bug went away. Case closed, right?

One of the customers mentioned, that while my fix worked, it shouldn't be needed. They had deployed with those buildpacks for __months__. I verified this through some build logs, so something did indeed change. But what?

## Repro

The first step was to try to reproduce the bug. I slapped together an "app" with an empty `Gemfile` and tried specifying two Ruby buildpacks. No dice. What changed in the [latest Ruby buildpack deploy](https://github.com/heroku/heroku-buildpack-ruby/compare/v154...v155#diff-3fc66e13e389ff4d15c7ca3ddb86464eR333)? We added yarn for Rails 5.1 support. I tried adding `execjs` and `webpacker` to my Gemfile to see if the failure was related, still no luck. I set the problem aside for a bit until a co-worker opened up the [same error message happening on Heroku CI](https://github.com/heroku/heroku-buildpack-ruby/issues/551). With some probing, two very important details were added. The apps that failed all used the `json` gem and were different versions of Ruby than what the Buildpack ran on.

With that extra info I was able to reproduce the bug with a super simple Gemfile:

```ruby
# Gemfile
source "https://rubygems.org"

ruby "2.3.3"
gem "json", "1.8.6" # version doesn't matter?
```

Once you've got a repro of a bug in your hands, nothing can stop you.

## The weirdest bug

So now we know the exact failure conditions - it only happens with the `json` gem and only when a version of Ruby is specified differently than the one specified for the Ruby buildpack. I verified that it doesn't happen when using `v154` of the buildpack (you can specify a tag or branch by using a hashtag `heroku buildpacks:add https://github.com/heroku/heroku-buildpack-ruby#v154`). So now we know the issue is isolated to the [code we previously looked at](https://github.com/heroku/heroku-buildpack-ruby/compare/v154...v155#diff-3fc66e13e389ff4d15c7ca3ddb86464eR333).

I started adding debug statements, and even found a minor bug that wasn't related, but it wasn't until I focused on the original error message that I made progress. Remember this is what was seen in the failure:


```
remote: -----> Ruby app detected
remote: /tmp/tmp.Se0nOtPeri/bin/ruby: symbol lookup error: /tmp/build_c85cc44940028913e25caa54b9ff2142/vendor/bundle/ruby/2.3.0/gems/json-1.8.6/lib/json/ext/generator.so: undefined symbol: rb_data_typed_object_zalloc
remote:  !     Push rejected, failed to compile Ruby app.
```

This error is happening extremely early. Before much code is getting run, we should see this very early on:

```
remote: -----> Ruby app detected
remote: -----> Compiling Ruby
```

This was indicating that the bug was happening not in any of the new code that was added, but somewhere at load time.

For all the effort and digging this ended up being the problem line:

```ruby
require 'json'
```

It was so innocuous that it didn't even register as a potential source of problems. All we're doing is loading in a system `json` library, right? Well...

What was happening is that the first buildpack would execute. We've set up the buildpacks so not only do they install libraries, they make them available for the next buildpack. This means that the Ruby buildpack will set up the `PATH` and `GEM_PATH` for the next run. This is intended so you can use the `heroku/nodejs` buildpack to put `node` on the path if another buildpack needs it. Unfortunately what was happening is that when `require 'json'` gets called it's checking to see if the `json` gem is installed, and loading that if it is. So it found the gem, loaded it and failed because it was compiled for a different version of Ruby.

How did we fix the issue? First we removed the `require`. We still had to parse JSON input, so I vendored in the [okjson library](https://github.com/kr/okjson). Before we merged that we realized we could [fix the issue by using `unset` on `GEM_PATH` before invoking the rest of the buildpack](https://github.com/heroku/heroku-buildpack-ruby/pull/553). The fix is merged into master branch of the buildpack but not yet deployed.


## Double Debugging

Even when faced with "why on earth would you do that" type bug reports, it always pays to ask "was this working before". In our case even though running two Ruby buildpacks was accidental, it turns out the same failure mode also showed up in [Heroku CI](https://devcenter.heroku.com/articles/heroku-ci). Which is a very real and very valid use case.

There are many cases where the fix for a bug isn't that interesting. It's how the bug came to be, why it was allowed to live on to production without being caught, and how it was eventually found out and tamed that's fascinating. In this case, we had not considered the scenario of running the buildpack twice and how a customer's system libraries might interfere with our own code. The reassuring part is that no matter how bad of a bug you find yourself stuck with, once you isolate the behavior and can reliably reproduce it, it's usually a simple matter of time, sweat, and tears.

When it comes to debugging, it always pays to ask "What does this mean?"

<iframe width="560" height="315" src="https://www.youtube.com/embed/MX0D4oZwCsA" frameborder="0" allowfullscreen></iframe>

