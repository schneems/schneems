---
title: "Jumping Off The Ruby Memory Cliff"
layout: post
published: true
date: 2017-04-12
permalink: /2017/04/12/jumping-off-the-memory-cliff/
categories:
    - ruby
---

The memory use of a healthy app is like the heartbeat of a patient - regular and predictable. You should see a slow steady climb that eventually plateaus, hopefully before you hit the RAM limit on your server:

![](https://www.dropbox.com/s/i8onv4cb9qsm9qa/Screenshot%202017-03-21%2010.21.52.png?raw=1)

Like a patient suffering from a heart ailment, the shape of our metrics can help us determine what dire problem our app is having. Here's one example of a problem:

![](https://www.dropbox.com/s/jt9a4damzccvmag/Screenshot%202017-03-21%2010.21.06.png?raw=1)

Memory spikes way up. The dark purple at the bottom indicates that we are now swapping significantly. The dotted line is our memory limit, which you can see we go well over. This sharp spike would indicate a problem, however, it's curious how the memory simply drops off and goes back down after a bit. What's going on?

If you're running on Heroku, you'll likely see a cluster of [H12 - Request timeout errors](https://devcenter.heroku.com/articles/error-codes#h12-request-timeout) at the same time. What is going on?

If you're using a web server that has multiple processes (called forks or workers), one explanation is that some request or series of requests, came in that were so expensive they locked up the child process. Maybe you accidentally coded in an infinite loop, or perhaps you're trying to load a million records from the database at once, whatever the reason, that request needs a LOT of resources. When this happens things grind to a halt. The process starts aggressively swapping to disk and can't run any code.

Lucky for us, when this happens, web servers like Puma have a failsafe in place. Every so often, the child process sends a "heartbeat" notification to the parent to let it know that it's still alive and doing well. If the parent process does not get this notification for a period of time, it will reap the process (by sending it a SIGTERM) telling it to shut down, and starting a new replacement process.

That's what's going on here. The child process was hung and using a lot of resources. Eventually, it hits the "worker timeout", the default of which is 60 seconds and the process then gets killed. There are a few reasons why the problem persists longer than 1 minute - there may be multiple problem processes, the child process might not shut down right away, or the server may use so many resources that the parent process is having a hard time getting CPU resources to even check for a timeout.

Another memory signature you might see looks like this:

![](https://www.dropbox.com/s/lujfdn6ts8nsgd5/Screenshot%202017-03-22%2008.52.27.png?raw=1)

It's kinda like a saw tooth, or a group of sharks. In this case the memory isn't suddenly spiking as badly as before and something is making it go back down. It still has a drop off cliff at the end. This is likely due to an app using something like [Puma Worker Killer](https://github.com/schneems/puma_worker_killer) with rolling restarts. Recent versions of Ruby will `free` memory back to the operating system, but very conservatively. It doesn't want to give memory back to the OS just to turn around and have to ask for more a second later. So essentially that cliff indicates that something is dying, either intentionally or otherwise.

Now you know why your app is "jumping off the memory cliff", what can you do? You need to find the endpoint that is taking up all your resources and fix it. This is extremely tricky because any performance tools such as Scout, won't have the resources to report back analytics while the process it is running in is stuck. This means you're more or less flying blind. My best advice would be to start with your H12 errors and use a logging add-on that you can search through. Find what endpoints are causing H12 errors then try to reproduce the problem locally using [rack-mini-profiler](https://github.com/MiniProfiler/rack-mini-profiler) or [derailed benchmarks](https://github.com/schneems/derailed_benchmarks). I would look at the first H12 error in the series first.

If you can't reproduce, add more logging around that endpoint - maybe it only happens with a specific user, or at a certain time of day, etc. The idea is to get your local app as close to the conditions causing the problem as possible.

The bad news is that you're still jumping off a cliff. The good news is that at least you know why and the approximate location of the cliff. It might take awhile to narrow down the problem and make it go away, but after that, you can hit the ground running.

