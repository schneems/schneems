---
layout: post
title: "Benchmarking Rack Middleware"
date: '2014-10-31 08:00:00'
published: true
tags: performance, benchmarking, ruby
---

Performance is important, and if we can't measure something, we can't make it fast. Recently, I've had my eye on the `ActionDispatch::Static` middleware in Rails. This middleware gets put at the front of your stack when you set `config.serve_static_assets = true` in your Rails app. This middleware has to compare **every** request that comes in to see if it should render a file from the disk or return the request further up the stack. To do that it hits the disk, basically doing this on every request:

```ruby
Dir["#{full_path}#{ext}"].detect { |m| File.file?(m) }
```

My gut said there had to be a better way, but how do we measure a singular rack middleware's performance? I couldn't find any really good posts on it, so I improvised using `benchmark/ips` and `Rack::MockRequest` to simulate traffic.

## Bootstrap your Middleware

First you need to load the file where your middleware is defined:

```ruby
require 'rack/file'
require 'action_controller'
load '/Users/schneems/Documents/projects/rails/actionpack/lib/action_dispatch/middleware/static.rb'
```

Now we need to load our test capabilities:

```ruby
require 'rack/test'
```

Now we can instantiate a new object that we can call in isolation:

```ruby
noop       = Proc.new {[200, {}, ["hello"]]}
middleware = ActionDispatch::Static.new(noop, "/my_rails_app/public")`
```

Then we wrap it up in a mock request:

```ruby
request = Rack::MockRequest.new(middleware)
```

I wanted to compare the speed of the middleware with the speed of the proc that it hits, so I made a no-op mock request as well:


```ruby
noop_request = Rack::MockRequest.new(noop)
```

Now, if we want to exercise a request against our singular middleware we can call

```ruby
request.get("/path_i_want_to_hit")
```

## Run your Benchmarks

To do the comparison you'll need the [benchmark ips](https://github.com/evanphx/benchmark-ips) gem installed

```
$ gem install benchmark-ips
```

The gem works by running different blocks of code for variable amounts of time to record how many iterations per second they can achieve. The higher the number, the faster the code.

We set up our benchmark:

```ruby
require 'benchmark/ips'

Benchmark.ips do |x|
  x.config(time: 5, warmup: 5)
  x.report("With ActionDispatch::Static") { request.get("/")  }
  x.report("With noop")                   { noop_request.get("/") }
  x.compare!
end
```

You should get an output similar to this:

```
Calculating -------------------------------------
With ActionDispatch::Static
                          1525 i/100ms
           With noop      2667 i/100ms
-------------------------------------------------
With ActionDispatch::Static
                        15891.2 (±11.6%) i/s -      79300 in   5.056266s
           With noop    28660.9 (±11.7%) i/s -     141351 in   5.009789s
```

Higher iterations are better, so the blank no-op middleware was `(28660.9 - 15891.2)/15891.2 * 100 #=> 80` roughly 80% faster or ran 80% more operations than with the default `ActionDispatch::Static`. This is expected, but only gives us a baseline. So, we still need to test our new code.

## Comparing Benchmarks

I ran the tests a few times to ensure I wasn't getting any flukes. Then, I set it up so that the middleware had some optimizations to not hit the disk were incorporated:


```
Calculating -------------------------------------
Modified ActionDispatch::Static
                          2330 i/100ms
           With noop      2422 i/100ms
-------------------------------------------------
Modified ActionDispatch::Static
                        24490.9 (±7.9%) i/s -     123490 in   5.081158s
           With noop    26870.1 (±8.7%) i/s -     135632 in   5.093423s
```

Here you can see that our no-op code ran `(26870.1 - 24490.9)/24490.9 * 100 # => 9.71` roughly 10% faster than the default `ActionDispatch::Static`. Here the closer the better as the `nooop` is the fastest possible case.

When we graph the results

![](https://www.dropbox.com/s/dcsrhrfh7gb44dc/Screenshot%202014-08-08%2014.05.21.png?dl=1)

You can see that my slight optimizations got us pretty close to the optimal state. The tick marks on each bar show the standard deviation (the ±) to make sure that the numbers are somewhat sane.

If we do the math, we can see that my new middleware is `(24490.9 - 15891.2)/15891.2 * 100 # => 54.11` or roughly 54% faster than the original `ActionDispatch::Static` in the case when we're making a request that is not requesting a file.

## Keep it in Context

Make sure not to get tunnel vision when you're benchmarking, in this case my optimizations made all non-asset requests faster, but since that required more logic, it actually makes asset requests (i.e. `request.get("assets/application-a71b3024f80aea3181c09774ca17e712.js")`) slightly slower. Luckily, I did some benchmarking there and found the difference to not really be measurable. Either way, don't just benchmark your happy path, make sure to benchmark all common conditions.

Right now you might also be thinking "Holy cow 54% speed improvement in Rails, zOMG!" but you have to remember that this is a middleware tested in isolation. The performance improvement isn't as much when we compare it to the whole Rails application stack, which I had to benchmark as well (and is a whole different blog post). The end result came to a ~2.6% overall speedup with the new middleware. Not bad.

Go forth and benchmark your Rack middleware! If you have any feedback or know of a different/better way to do this, find me on the internet [@schneems](https://twitter.com/schneems).
