---
title: "The Fastest Way to Generate a Heap Dump on Heroku"
layout: post
published: true
date: 2017-05-01
permalink: /2017/05/01/the-fastest-way-to-generate-a-heap-dump-on-heroku/
categories:
    - ruby
---

You've got an app with runaway memory use, what do you do hotshot? What do you do? If you've [exausted the usual suspects](https://devcenter.heroku.com/articles/ruby-memory-use) it might be time to take drastic steps. It might be time to take a production heap dump. I [previously wrote about doing this on Heroku](https://blog.codeship.com/the-definitive-guide-to-ruby-heap-dumps-part-ii/), but since then we've launched [Heroku exec](https://devcenter.heroku.com/articles/heroku-exec), a way to SSH into a live running Dyno to allow you to debug. Now that you can do that, you don't need an AWS account or any fancy gems to generate a heap dump, just activate this feature and add the `rbtrace` gem to your app. Let's do this to an app together.

First we need to set up the app with Heroku Exec. Check the [Heroku Exec docs](https://devcenter.heroku.com/articles/heroku-exec) as these steps may change in the future. We're going to start by installing the plugin:

```sh
$ heroku plugins:install heroku-cli-exec
```

Next execute:

```
$  heroku ps:exec
Creating heroku-exec:test on issuetriage... free
Adding the Heroku Exec buildpack to issuetriage

Run the following commands to redeploy your app, then Heroku Exec will be ready to use:
  git commit -m "Heroku Exec initialization" --allow-empty
  git push heroku master
```

This will add a free addon to your app to allow you connect to your Dynos. But to be able to use it, you have to deploy. You can do this by running

```
$ git commit -m "Heroku Exec" --allow-empty
$ git push heroku master
```

Once your app is done deploying you can SSH into a running Dyno by executing

```
$ heroku ps:exec
Establishing credentials... done
Connecting to web.1 on ⬢ issuetriage...
~ $
```

Before we can take a heap dump, we'll need to tell your app to start tracing object allocations. Get out of your `ps:exec` session if you haven't already.

Add the `rbtrace` gem to your `Gemfile`:

```ruby
# Gemfile

gem "rbtrace"
```

Then run `bundle install` locally. Next, you'll want to tell your app to start tracing allocations. If you're using a forked webserver like Unicorn or Puma, you can enable this in an `on_worker_boot` block or similar.

If you're using Puma, add this code to your `config/puma.rb` file:

```ruby
on_worker_boot do
  if ENV['DYNO'] == 'web.1'
    # Trace objects on 1 Dyno to generate heap dump in production
    require 'objspace'
    ObjectSpace.trace_object_allocations_start
  end
end
```

Here we're telling any worker processes to trace where objects were created at. This is not "free" and will cause the Dyno to run slightly slower, because of this we want to limit to running this code in just one Dyno `web.1`.

You'll want to commit this and deploy it. Once you've done that you can now ssh into your Dyno and generate the Heap dump.

```sh
$ heroku ps:exec
Establishing credentials... done
Connecting to web.1 on ⬢ issuetriage...
~ $
```

First we'll need to figure out the PID of your worker processes.

```sh
~ $ ps -eo pid,comm,ppid | grep ruby
   29 ruby                3
   51 ruby               29
```

We're looking at two Ruby processes in our Dyno. The first has a PID of 29 and a parent PID of 3. The second has a PID of 51 and a parent PID of 29. This means that 51's parent is also a Ruby process. Puma uses a master process to hand off requests to child or "worker" processes. We want to run our heap dump against our "child process" which is `51`.
> Note your PID will be different, use the same technique to determine your child Ruby processes.


We can generate the heap dump using `rbtrace` with this command:

```
$ bundle exec rbtrace -p 51 -e 'Thread.new{GC.start;require "objspace";io=File.open("/tmp/ruby-heap.dump", "w"); ObjectSpace.dump_all(output: io); io.close}'
```

This will generate a heap dump in the file `/tmp/ruby-heap.dump`.

We can now download this file to our local machines. Exit the `ps:exec` sessions. The file continues to live on the Dyno because the Dyno has not restarted yet. You can now run this command:

```sh
$ heroku ps:copy /tmp/ruby-heap.dump
```

This will download the file and put it in your local directory with the name `ruby-heap.dump`.

We can now use debugging tools on this dump file. Such as the `heapy` gem that I wrote and maintain.

```sh
$ heapy read ruby-heap.dump

Analyzing Heap
==============
Generation: nil object count: 302087, mem: 0.0 kb
Generation:   4 object count: 171, mem: 6174.9 kb
Generation:   5 object count: 4769, mem: 1614.3 kb
Generation:   6 object count: 1, mem: 0.2 kb
Generation:   8 object count: 199, mem: 8.6 kb
Generation:   9 object count: 1, mem: 0.0 kb
Generation:  12 object count: 44, mem: 198.3 kb
Generation:  13 object count: 6, mem: 0.5 kb
Generation:  14 object count: 645, mem: 1079.0 kb
Generation:  15 object count: 74, mem: 5.1 kb

Heap total
==============
Generations (active): 10
Count: 307997
Memory: 9080.9 kb
```

You can dig into a generation using

```sh
$ heapy read ruby-heap.dump 5

Analyzing Heap (Generation: 5)
-------------------------------

allocated by memory (1653008) (in bytes)
==============================
  1049992  /app/vendor/bundle/ruby/2.4.0/gems/rack-timeout-0.4.2/lib/rack/timeout/support/scheduler.rb:67
   170671  /app/vendor/bundle/ruby/2.4.0/gems/json-2.0.3/lib/json/common.rb:224
    88623  /app/vendor/bundle/ruby/2.4.0/gems/multi_json-1.12.1/lib/multi_json/adapters/oj.rb:15
# ...
```

Here we can see the three locations that allocated the most memory.

I'll admit that I've never successfully found an application level memory problem from a heap dump, but I know some have. If you're out of other options, it's another thing you can try. The exciting thing about `ps:exec` is that you're not limited to heap dumps, you now have access to all system level debugging tools for live running processes. For instance you could install `lsof` via the [Heroku APT buildpack](https://elements.heroku.com/buildpacks/heroku/heroku-buildpack-apt) to debug in a way you never could before. Keep in mind that if you're running on a regular Dyno it's in a container and on a shared system with other applications so thing like `ps` to get memory use won't be entirely accurate. If you need more accuracy from system level commands, consider our [performance-m and performance-l Dynos](https://devcenter.heroku.com/articles/dyno-types) which take up an entire VPS.

Also some tools like `gdb` cannot be used do to security restrictions. You might get an error like `Permission denied.`.

I'm excited for the power and flexibility that `ps:exec` brings to Heroku.
