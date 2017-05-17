---
title: "Ruby Backend Performance Getting Started Guide"
layout: post
published: true
date: 2017-05-17
permalink: /2017/05/17/ruby-backend-performance-getting-started-guide/
categories:
    - ruby
---

You want a faster app - where should you start?  At RailsConf 2017 I was in a panel "Performance: performance" moderated by Sam Saffron and joined by Eileen Uchitelle, Rafael Franca, and Nate Berkopec. While we talked about many things, I realized I've never written explicitly about how to go from "zero" to "working on application performance". Here's the video from the panel if you're interested:

<iframe width="560" height="315" src="https://www.youtube.com/embed/SMxlblLe_Io" frameborder="0" allowfullscreen></iframe>

> BTW, watching conf talks at 1.5x speed is the only way to watch conf videos.

Enough talk about the panel though, let's get started making things faster!

Start by looking at outliers - either start with your slowest endpoints or your endpoints that generate the most memory.

You can get your slowest endpoints from your logs, especially if you're getting any [H12 request timeout](https://devcenter.heroku.com/articles/error-codes#h12-request-timeout) errors. You can use a logging add-on like Papertrail to search for these errors and find an endpoint they're happening on. I prefer to start with memory, because I find that allocating lots of un-needed objects is typically the biggest perf problem in most web applications. Starting with memory also gives us the benefit that if you're not spending time allocating un-needed objects then you're also not needing to allocate memory. With this, you might eventually be able to add another web worker to your server and get even more performance, or perhaps drop down to a smaller server size and save some money.

For memory, I like starting with [Scout](https://elements.heroku.com/addons/scout) as it will show you your most expensive endpoints and the memory they're allocating. I start with the biggest offender.

Now we've got an endpoint that we want to work on, what's the next step? Scout will point you to some common problems, for example, if you're allocating thousands of Active Record objects by accident, it will point out the line where the majority of your allocations are happening. Usually memory problems come from Active Record. Or to be more precise, your use of Active Record. The biggest issues are that the same code may allocate different amounts of objects depending on what's in your database. If you're loading a user and all their "comments" it's not a big deal if they've got 1 or 2 comments. It's a lot bigger deal if they've got 10,000 or 20,000.

There are some common patterns. Make sure all queries to the database are using a `limit` (except perhaps for count queries). This will prevent unexpected object creation. Use `find_each` when you need to loop around a large number of objects. Make sure that if you're [eliminating N+1 queries, that you're not accidentally blowing up your memory](http://schneems.com/2017/03/28/n1-queries-or-memory-problems-why-not-solve-both/).


You can try making changes to your codebase to get rid of the object allocations, but I wouldn't recommend it without first trying to reproduce the behavior locally. Performance problems are a bug, and as such, you can squash them the same way. Reproduce them, isolate the problem, make a patch and verify the issue is gone.

You already know the endpoint where the slow issue is happening, so you just need to be able to reproduce the behavior. You will want to replicate your production environment as closely as possible. This means running with `RAILS_ENV=production` locally and also simulating your production data. One option if you've got a relatively small production database is to pull your production data locally.

```
$ heroku pg:pull DATABASE_URL myapp_db_production
```

If your endpoint uses other data-stores like Memcached or Redis, you may want to populate them locally as well.

If you're not able to pull your production database because it's too large or too sensitive, then I recommend trying to approximate your worst case. For example, find the user with the largest number of comments in your production database, then find what the largest comment record of theirs looks like. Next, write a script to generate a user and a similar (or greater) number of comments and the more "production like" the data, the better you'll be able to reproduce the performance issue. Your code will dicatate the what needs to be created. You can also use a gem like `faker` (or similar).

Now you've got an endpoint and a production-like environment complete with production-ish data. Now might be a good time to make sure that you can't accidentally send out emails, or charge credit cards locally. If you can I recommend my post [Config: Behavior versus Credentials](http://schneems.com/2017/03/21/config-behavior-versus-credentials/).

The next thing we need is a way to measure performance. I highly recommend [rack mini profiler](https://github.com/MiniProfiler/rack-mini-profiler). It will show you page load time as well as call out things like N+1 queries from your database. I use these pieces as an indicator of how the performance patches are going. The time to load the page should go down, and depending on what you're working on, you should likely look at other metrics such as the number of queries being made. If you're working on memory you can add `?pp=profile-memory` to the URL you're profiling and get a count of total objects allocated. Over time, as you work this number should go down.


I recommend using the `bullet` gem as well. Here's how I configure it:

```ruby
if defined?(Bullet)
  Bullet.enable       = true
  Bullet.add_footer   = true
  Bullet.rails_logger = true
end
```

It will show a footer if it detects an easy-ish problem in Active Record to fix. However, I would always verify with `rack-mini-profiler` that your page time is actually going down after making changes. Sometimes the "right" thing to do actually make performance worse.

Always

Be

Benchmarking

Never make a change without first having a baseline. This may be milliseconds to load the page from `rack-mini-profiler`, or number of objects or something else. Don't cheat here. If you're doing page load time, don't just refresh until you get an outlier that is especially slow and then after you make your change just take the best time you see. Ideally, you would record multiple numbers and report the average and variance before and after. That's a bit much for most patches, so I try to take a number that "seems" like it is representative. Write the baseline number down somewhere, like Evernote. When you make improvements, write your new number down.

I haven't found a great way to test performance of API endpoints. You could use something like `time curl` and set up the headers needed to auth as your problem user. It would be really cool if someone wrote a gem that added an API test front end to `rack-mini-profiler` where you could specify headers, params, HTTP method, etc. Then click "go" and it would show you the reponse as well as the same details from `rack-mini-profiler` (like where N+1 queries are happening and how much memory is allocated). If you've had some good methods of testing your API via performance tools let me know.

I would like to eventually add a small memory metric to the default `rack-mini-profiler`. For example, you could grap the `GC.stat(:total_allocated_objects)` before and after the request and display the number by default (instead of having to use a special page via a query param). If someone beats me to this patch, great ;)

I will mention that while I wrote [derailed](https://github.com/schneems/derailed_benchmarks) I find it easier to approximate a customer's experience via `rack-mini-profiler` for many cases, this gives the ability to iterate faster and do better performance work. The `bundle exec derailed bundle:mem` command is still useful, but it's likely not going to give your app huge performance gains at runtime.

Now we've got a slow endpoint, a production-like app set up, some performance tools, and some recommendations for how to fix a few common Active Record related performance issues. It's up to you to connect the dots and figure out where to go from here.

If you want to dig deeper, I recommend the [Complete Guide to Rails Performance](https://www.railsspeed.com/), which covers front end issues you may be experiencing. Once you've made one endpoint faster or more memory-efficient go to the next. One good goal is to reduce response variance, so that your "perc-95" numbers are closer to your "average" response times. You might want to set a specific goal like "speeding up 3 endpoints" or "reducing memory use by 5%" and work until you hit that goal. You might also want to explicitly get performance work budgeted in to your sprints (or however you plan your work). If you don't make a plan and the support of your team/company then you're setting yourself up for failure. Performance debugging isn't really all that different from regular debugging, but it's a new set of tools and competencies. Make a goal and stick to it. The most important piece to focus on to improve application performance is your persistence.
