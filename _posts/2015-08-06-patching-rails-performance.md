---
layout: post
title: "Patching Rails Performance"
date: 2015-08-06
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
permalink: blogs/2015-08-06-patching-rails-performance
---

In a recent [patch](https://github.com/rails/rails/pull/21057) we improved Rails response time by **>10%**, our largest improvement to date. I'm going to show you how I did it, and introduce you to the tools I used, because.. who doesn’t want fast apps?

> Originally posted on the [Heroku Engineering Blog](https://engineering.heroku.com/blogs/2015-08-06-patching-rails-performance/)

In addition to a speed increase, we see a 29% decrease in allocated objects. If you haven't already, you can [read or watch more about how temporary allocated objects affect total memory use](https://www.schneems.com/2015/05/11/how-ruby-uses-memory.html). Decreasing memory pressure on an app may allow it to be run on a smaller dyno type, or spawn more worker processes to handle more throughput. Let's back up though, how did I find these optimizations in Rails in the first place?

<!--more-->

A year ago Heroku added [metrics](https://devcenter.heroku.com/articles/metrics) to the application dashboard. During the internal beta, one of the employees building the product asked if they could get access to my open source app, codetriage, because it was throwing thousands of [R14-out of memory](https://devcenter.heroku.com/articles/error-codes#r14-memory-quota-exceeded) errors a day. This error occurs when you go over your allotted RAM limit on Heroku (512 mb for a hobby dyno). Before metrics, I had no clue. As the feature was made available to customers,  they became  acutely aware that their apps were slow, used lots of swap memory, and threw errors right and left. What should they do to get their apps back in shape?

Initially we recommended reducing the number of web worker processes. For example if you were running 3 [Unicorn workers](https://devcenter.heroku.com/articles/rails-unicorn) (our recommended webserver at the time) we might suggest you decrease it to 2. This solved the problem for most people. Exposing the RAM usage helped tremendously. Still, customers reported "memory leaks" and overall they weren’t happy with their memory use. When our largest customers started to ask questions, they landed on my desk.

It wasn't long before a customer came forward with an app that performed normally on the surface but started to swap quickly. With the owner's permission I was able to use their Gemfile locally, and started to write a [series of re-useable benchmarks](https://github.com/schneems/derailed_benchmarks) to reproduce the problem. A concept similar to my [benchmarking rack middleware](https://engineering.heroku.com/blogs/2014-11-03-benchmarking-rack-middleware/) article, since Rails is a Rack app. I worked on the original concept with [Koichi](https://github.com/ko1). We were able to isolate that particular issue to [a few problematic gems](https://www.schneems.com/2014/11/07/i-ram-what-i-ram.html) that retained a large amount of memory on boot. Meanwhile [Sam Saffron was writing some amazing posts](https://samsaffron.com/) about debugging memory in [discourse](https://www.discourse.org) which eventually spawned [memory_profiler](https://rubygems.org/gems/memory_profiler). I added the memory_profiler to [derailed benchmarks](https://github.com/schneems/derailed_benchmarks#dissecting-a-memory-leak), this is eventually what I used to find hot spots for this performance patch.

I'm responsible for maximizing Ruby developer happiness on Heroku. This can mean writing documentation, patching the buildpack to stop pain points before they happen, or working upstream with popular open source libraries to resolve problems before they hit production. The longer I look at slow code or code with a large memory footprint, the more I see these things as reproducible and ultimately fixable bugs. As I was seeing issues in customer's reported apps and in some of my own, I went to the source to try to fix the issues.

```
$ derailed exec perf:objects
```

I ran this benchmark against my Rails app, identified a line that was allocating a large amount of memory, and refactored. In some cases we were using arrays only to join them into strings in the same method, other times we were duplicating a hash before it was merged. I slowly whittled down the allocated object count. Allocating objects takes time. If we modify an object in place without creating a duplicate, we can speed up program execution. Alternatively, we can use a pooled object like a frozen string that never needs to be re-allocated. The test app, codetriage.com, uses [github style routes](https://github.com/codetriage/codetriage/blob/630149788431e629e3b8a261c3cb9a8e1e11da5a/config/routes.rb#L34-L45) which requires constraints and a "catch all" [glob route](https://guides.rubyonrails.org/routing.html#route-globbing-and-wildcard-segments). Applying these optimizations resulted in a 31% speed increase in url generation for a route with a constraint:


```ruby
require 'benchmark/ips'
repo = Repo.first

Benchmark.ips do |x|
  x.report("link_to speed") {
    helper.link_to("foo", app.repo_path(repo))
  }
end
```

The routing improvements combined with all the other savings gives us a speed boost of more than 10%. The best part is, we don't have to change the way we write our Rails app, you get these improvements for free by upgrading to the next version of Rails. If you're interested in where the savings came from, look at the [individual commits](https://github.com/rails/rails/pull/21057/commits) which have the methodology and object allocation savings for my test app recorded.

![](https://www.dropbox.com/s/mdjtq0miucbby8f/Screenshot%202015-08-03%2011.38.33.png?raw=1)

Working with Rails has made me a better developer, more capable of debugging library internals, and helped our Ruby experience on the platform. Likewise having a huge number of diverse Rails apps running on the platform helps us be aware of actual pain points developers are hitting in production. It feels good when we can take these insights and contribute back to the community. Be on the lookout for the Rails 5 pre-release to give some of these changes a try. Thanks for reading, enjoy the speed.

---
If you like hording RAM, maximizing iterations per second, or just going plain fast follow [@schneems](https://twitter.com/schneems).


