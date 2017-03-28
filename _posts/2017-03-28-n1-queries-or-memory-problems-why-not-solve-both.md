---
title: "N+1 Queries or Memory Problems: Why not Solve Both?"
layout: post
published: true
date: 2017-03-28
permalink: /2017/03/28/n1-queries-or-memory-problems-why-not-solve-both/
categories:
    - ruby
---


This post is going to help save you money if you're running a Rails server. It starts like this: you write an app. Let's say you're building the next hyper-targeted blogging platform for medium length posts. When you login, you see a paginated list of all of the articles you've written. You have a `Post` model and maybe for to do tags, you have a `Tag` model`, and for comments, you have a `Comment` model. You write your view so that it renders the posts:

```erb

<% @posts.each do |post| %>

<%= link_to(post, post.title) %>

<%= teaser_for(post) %>

<%= "#{post.comments.count} comments"

<% end %>

<%= pagination(@posts) %>

```

[This post originally published on the Heroku blog](https://blog.heroku.com/solving-n-plus-one-queries)

See any problems with this?  We have to make a single query to return all the posts - that's where the `@posts` comes from.  Say that there are N posts returned.  In the code above, as the view iterates over each post, it has to calculate `post.comments.count` - but *that* in turn needs another database query.  This is the N+1 query problem - our initial single query (the 1 in N+1) returns something (of size N) that we iterate over and perform yet another database query on (N of them).

## Introducing Includes

If you've been around the Rails track long enough you've probably run into the above scenario before. If you run a Google search, the answer is very simple -- "use includes". The code looks like this:

```ruby

# before

@posts = current_user.posts.per_page(20).page(params[:page])

```

and after

```ruby

@posts = current_user.posts.per_page(20).page(params[:page])

@posts = @posts.includes(:comments)

```

This is still textbook, but let's look at what's going on. Active Record uses lazy querying so this won't actually get executed until we call `@posts.first` or `@posts.all` or `@posts.each`. When we do that two queries get executed, the first one for posts makes sense:

```ruby

select * from posts where user_id=? limit ? offset ?

```

Active Record will pass in user_id and limit and offset into the bind params and you'll get your array of posts.

> Note: we almost always want all queries to be scoped with a limit in production apps.

The next query you'll see may look something like this:

```ruby

select * from comments where post_id in?

```

Notice anything wrong? Bonus points if you found it, and yes, it has something to do with memory.

There is no limit clause. If each of those 20 blog posts has 100 comments, then this query will return 2,000 rows from your database. Active Record doesn't know what data you need from each post comment, it'll just know it was told you'll eventually need them. So what does it do? It creates 2,000 Active Record objects in memory because that's what you told it to do. That's the problem, you don't need 2,000 objects in memory. You don't even need the objects, you only need the count.

The good: You got rid of your N+1 problem.

The bad: You're stuffing 2,000 (or more) objects from the database into memory when you aren't going to use them at all. This will slow down this action and balloon the memory use requirements of your app.

It's even worse if the data in the comments is large. For instance, maybe there is no max size for a comment field and people write thousand word essays, meaning we'll have to load those really large strings into memory and keep them there until the end of the request even though we're not using them.

## N+1 Is Bad, Unneeded Memory Allocation Is Worse

Now we've got a problem. We could "fix" it by re-introducing our N+1 bug. That's a valid fix, however, you can easily benchmark it. Use `rack-mini-profiler` in development on a page with a large amount of simulated data. Sometimes it's faster to not "fix" your N+1 bugs.

That's not good enough for us, though -- we want no massive memory allocation spikes and no N+1 queries.

## Counter Cache

What's the point of having Cache if you can't count it? Instead of having to call `post.comments.count` each time, which costs us a SQL query, we can store that data directly inside of the `Post` model. This way when we load a `Post` object we automatically have this info. From [the docs for the counter cache](http://edgeguides.rubyonrails.org/association_basics.html#options-for-belongs-to-counter-cache) you'll see we need to change our model to something like this:

```ruby

class Comment < ApplicationRecord

  belongs_to :post , counter_cache: count_of_comments

#…

end

```

Now in our view, we can call:

```erb

<%= "#{post.count_of_comments} comments"

```

Boom! Now we have no N+1 query and no memory problems. But...

## Counter Cache Edge Cases

You cannot use a counter cache with a condition. Let's change our example for a minute. Let's say each comment could either be "approved", meaning you moderated it and allow it to show on your page, or "pending". Perhaps this is a vital piece of information and you MUST show it on your page.  Previously we would have done this:

```erb

<%= "#{ post.comments.approved.count } approved comments"

<%= "#{ post.comments.pending.count } pending comments"

```

In this case the `Comment` model has a `status` field and calling `comments.pending` is equivalent to adding `where(status: "pending")`. It would be great if we could have a `post.count_of_pending_comments` cache and a `post.count_of_approved_comments` cache, but we can't. There are some ways to hack it, but there are edge cases, and not all apps can safely accommodate for all edge cases. Let's say ours is one of those.

Now what? We could get around this with some view caching because if we cache your entire page, we only have to render it and pay that N+1 cost once. Maybe fewer times if we are re-using view components and are using "Russian doll" style view caches .

If view caching is out of the question due to \<reasons\>, what are we left with? We have to use our database the way the original settlers of the Wild West did, manually and with great effort.

## Manually Building Count Data in Hashes

In our controller where we previously had this:

```ruby

@posts = current_user.posts.per_page(20).page(params[:page])

@posts = @posts.includes(:comments)

```

We can remove that `includes` and instead build two hashes. Active Record returns hashes when we use `group()`. In this case we know we want to associate comment count with each post, so we group by `:post_id`.

```ruby

@posts = current_user.posts.per_page(20).page(params[:page])

post_ids = @posts.map(&:id)

@pending_count_hash  = Comment.pending.where(post_id: post_ids).group(:post_id).count

@approved_count_hash = Comment.approved.where(post_id: post_ids).group(:post_id).count

```

Now we can stash and use this value in our view instead:

```erb

<%= "#{ @approved_count_hash[post.id] || 0  } approved comments"

<%= "#{ @pending_count_hash[post.id] || 0 } pending comments"

```

Now we have 3 queries, one to find our posts and one for each comment type we care about. This generates 2 extra hashes that hold the minimum of information that we need.

I've found this strategy to be super effective in mitigating memory issues while not sacrificing on the N+1 front.

But what if you're using that data inside of methods.

## Fat Models Low Memory

Rails encourage you to stick logic inside of models. If you're doing that, then perhaps this code wasn't a raw SQL query inside of the view but was instead nested in a method.

```

def approved_comment_count

self.comments.approved.count

end

```

Or maybe you need to do the math, maybe there is a critical threshold where pending comments overtake approved:

```ruby

def comments_critical_threshold?

self.comments.pending.count < self.comments.approved.count

end

```

This is trivial, but you could imagine a more complex case where logic is happening based on business rules. In this case, you don't want to have to duplicate the logic in your view (where we are using a hash) and in your model (where we are querying the database). Instead, you can use dependency injection. Which is the hyper-nerd way of saying we'll pass in values. We can change the method signature to something like this:

```ruby

def comments_critical_threshold?(pending_count: comments.pending.count, approved_count: comments.approved.count)

pending_count < approved_count

end

```

Now I can call it and pass in values:

```ruby

post.comments_critical_threshold?(pending_count: @pending_count_hash[post.id] || 0 , approved_count: @approved_count_hash[post.id] || 0 )

```

Or, if you're using it somewhere else, you can use it without passing in values since we specified our default values for the keyword arguments.

> BTW, aren't keyword arguments great?

```ruby

post.comments_critical_threshold? # default values are used here

```

There are other ways to write the same code:

```ruby

def comments_critical_threshold?(pending_count , approved_count )

pending_count ||= comments.pending.count

approved_count ||= comments.approved.count

pending_count < approved_count

end

```

You get the gist though -- pass values into your methods if you need to.

## More than Count

What if you're doing more than just counting? Well, you can pull that data and group it in the same way by using `select` and specifying multiple fields. To keep going with our same example, maybe we want to show a truncated list of all commenter names and their avatar URLs:

```

@comment_names_hash = Comment.where(post_id: post_ids).select("names, avatar_url").group_by(&:post_ids)

```

The results look like this:

```ruby

1337: [

{ name: "schneems", avatar_url: "https://http.cat/404.jpg" },

{ name: "illegitimate45", avatar_url: "https://http.cat/451.jpg" }

]

```

The `1337` is the post id, and then we get an entry with a name and an avatar_url for each comment. Be careful here, though, as we're returning more data-- you still might not need all of it and making 2,000 hashes isn't much better than making 2,000 unused Active Record objects. You may want to better constrain your query with limits or by querying for more specific information.

## Are We There Yet

At this point, we have gotten rid of our N+1 queries and we're hardly using any memory compared to before. Yay! Self-five. :partyparrot:. 🎉

Here's where I give rapid-fire suggestions.

- Use the `bullet` gem -- it will help identify N+1 query locations and unused `includes` -- it's good.

- Use `rack-mini-profiler` in development. This will help you compare relative speeds of your performance work. I usually do all my perf work on a branch and then I can easily go back and forth between that and master to compare speeds.

- Use production-like data in development. This performance "bug" won't show until we've got plenty of posts or plenty of comments. If your prod data isn't sensitive you can clone it using something like `$ heroku pg:pull` to test against, but make sure you're not sending out emails or spending real money or anything first.

- You can see memory allocations by using `rack-mini-profiler` with `memory-profiler` and adding `pp=profile-memory` to the end of your URL. This will show you things like total bytes allocated, which you can use for comparison purposes.

- Narrow down your search by focusing on slow endpoints. All performance trackers list out slow endpoints, this is a good place to start. [Scout](https://scoutapp.com) will show you memory breakdown per request and makes finding these types of bugs much easier to hunt down. They also have [an add-on](https://elements.heroku.com/addons/scout) for Heroku. You can get started for free `$ heroku addons:create scout:chair`

If you want to dig deeper into what's going on with Ruby's use of memory check out the [Memory Quota Exceeded in Ruby (MRI) Dev Center article

](https://devcenter.heroku.com/articles/ruby-memory-use), my [How Ruby Uses Memory](http://www.schneems.com/2015/05/11/how-ruby-uses-memory.html), and also Nate Berkopec's [Halve your memory use with these 12 Weird Tricks](https://www.youtube.com/watch?v=kZcqyuPeDao).
