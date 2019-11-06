---
title: "How Ruby REALLY uses Memory: On the Web and Beyond"
layout: post
published: true
date: 2019-11-06
permalink: /2019/11/06/how-ruby-really-uses-memory-on-the-web-and-beyond/
image_url: https://www.dropbox.com/s/ik7ixj8qqo8m4jq/Screenshot%202019-10-28%2012.27.11.png?raw=1
categories:
    - ruby
    - memory
    - performance
---

I wrote [How Ruby uses Memory](https://www.sitepoint.com/ruby-uses-memory/) over four years ago, but there continue to be many misunderstandings about Ruby's memory behavior. In this post, I will use a [simulated multi-threaded webserver](https://github.com/schneems/simulate_ruby_web_memory_use) to show how different memory allocation patterns work behave. Together we can work through the memory behavior that many developers struggle to understand.

## Understanding the output: Simulation with one thread

Here's an example of a web server with one thread serving a few requests:

![](https://www.dropbox.com/s/h6pz8hat1ra9ojp/Screenshot%202019-10-28%2013.00.21.png?raw=1)

Time is the bottom axis. As time progresses, our thread will process requests and allocate objects. The pointy bits on the graph represent a web server processing a request. As the request is processed, varying amounts of objects are allocated to generate a response. While these objects are being used, they cannot be reclaimed by the garbage collector. Once the request is over, they can be recycled, so the amount of objects retained goes back down to zero. When object retention drops back down to zero, you can see the memory requirements for that thread also drop to zero in the graph.

> The units of memory and time duration is completely arbitrary since this is a simulation; the shape of the graph is the critical part.

The other line at the top of the graph traces the total maximum amount of memory needed to run the application. In this example, the first request needs a large amount of memory, but then the second third and fourth all use less than the first. You can see the total maximum amount of memory increase and then stay stable. This behavior is a very rough approximation of how Ruby (2.6 is the latest release at the time of writing) allocates memory. It will allocate enough space to handle whatever task needs to be done. Then it will assume (correctly in this case) that in the future, you'll need to use that memory again, so it holds onto it. While looking at these graphs, the top line roughly represents the memory requirements of your program that you would see in Heroku's memory metrics dashboard, or from activity monitor locally (if you're on a Mac).

In reality, the garbage collector (responsible for allocating memory) is more nuanced than this simulation. There are a range of topics you need for the full picture: object slots, slot versus heap allocation, generational GC, incremental GC, compacting memory, etc. But for now, this simplification is good enough.

## Simulation with two threads

In Ruby applications, especially web ones, you're rarely serving only one request at a time. What does a server handling two concurrent workloads look like in terms of memory use?

When we simulate multiple requests, the high-water mark of "max" memory needed to run the application is no longer only affected by the memory use of one thread, but of all the threads.

![](https://www.dropbox.com/s/h8y2ou1gc5sy09x/Screenshot%202019-10-28%2012.24.26.png?raw=1)

In this example, thread one needed a lot of memory to process a request, and while it was being prepared, thread two started processing a request, though it was ultimately smaller in size.

The total memory required to start generating both responses isn't the maximum of the two threads, but instead the sum. The "max total" line spikes up faster than when thread two starts to run and looks to nearly double the value of thread one.

This point is important:

> The maximum (theoretical) amount of memory your application will conceivably allocate is the maximum amount of memory an individual request will need to serve multiplied by the total number of concurrent requests your web server can process.

In this example, thread one spikes up to somewhere around 140 memory units, and thread two is about 120. These might represent different requests to different endpoints in an application, perhaps `/users/10` and `/users/42`. What if both requests were made to the same endpoint `/users/10` then the maximum amount of memory needed would go up to 280 (140 + 140) rather than the value of 260 you see here.

Since there's no way, we can predict the arrival rate of requests. With enough load and enough requests, you should assume that multiple requests will hit this maximum value at the same time.

## 1,000 Requests Simulation with two threads

Here's another example with 1000 requests instead of a handful.

![](https://www.dropbox.com/s/ik7ixj8qqo8m4jq/Screenshot%202019-10-28%2012.27.11.png?raw=1)

If you look at the high point of thread one and two, then you'll see they roughly max out at about 390 memory units. While the simulation doesn't immediately double that number, over a long enough duration, the simulation ends up serving two requests at the same time with this maximum amount of memory, which needs a total of 780 memory units to serve.

So what happens if we add a third thread? Do we expect it to use 1,170 memory units total?

![](https://www.dropbox.com/s/kluh761tzo2ser9/Screenshot%202019-10-28%2013.33.48.png?raw=1)

While we're using more memory, and there is a theoretical maximum of 1,170 memory units, getting to that value depends on the distribution of our requests. What is the likelihood that the largest request will come in and hit all threads at the same time? In this case, it didn't happen, but it doesn't mean it won't ever.

This is another crucial point:

> Since the amount of memory your application needs to serve requests is a function of the distribution of memory needs of your endpoints. Since the rate of requests coming in is a distribution, that means your memory usage isn't static. It is a distribution, as well.

## Simulating ten threads instead of just two

When I added a new thread, then our memory requirements were doubled. Granted, it didn't happen right away, and based on our request distribution. We might never see that full theoretical "max" memory. So what happens if we move from two threads to ten. Would you expect our memory usage to be 10x? Take a look at the graph:


![](https://www.dropbox.com/s/dlj7pdia962s61e/Screenshot%202019-10-28%2013.42.32.png?raw=1)

If we were going to 10x our memory, you would expect to see 3,900 (10 * 390) memory units being used. This graph doesn't show anywhere near that number, though? Why not. While our theoretical system still has the same theoretical maximum, remember that for it to happen, we would have to have several seemingly random events align perfectly. Here's what affects our memory requirements:

- Size of the request: Some endpoints in applications require lots of memory and some very little memory. Since, in practice, Ruby does not return memory, the largest request is the dominant factor for how much memory a system will need.
- Distribution of incoming requests: We saw memory use double when two threads are serving the same request, and also when they start being processed at about the same time. The more overlap between parallel requests means the more memory your application will need to use to run your application.

You can think of these two factors as distributions. Often the size of a request can vary wildly in an application, and also, the rate that the requests come in can vary wildly. When that is the case, then the steady-state for required memory use won't be anywhere near our calculated maximum.

If, on the other hand, there's only one endpoint and it always allocates the same amount of memory, and the application is under heavy load: then it would be much more likely that the steady-state for required memory use will come close to your theoretical maximum.

## What does it all Mean?

Here are some things I hope you can agree with based off of these simulations:

- Total memory use goes up as the number of threads are increased
- Memory use for an individual thread is a factor of the largest possible request it will ever serve
- Memory use across all threads are based on a distribution of how likely that maximum request is to be hit simultaneously by all existing threads
- As your application executes over time, it is expected and natural that your memory requirements will increase until they hit a steady-state.

Here's something that I didn't explicitly say already but want to now: **To reduce your application's memory, focus on decreasing allocation amount in your largest request.**

Are there other ways to move the needle? Our simulation is based on the above factors: number of threads, largest possible request, and request distribution. Sure, you can decrease thread count, to move that number, but that decreases your throughput. You can also add capacity via scaling out (which would make it less likely that multiple threads would be processing the large request at the same time). This tactic might work from one to two servers, but over time there are diminishing returns. In my experience, neither of these are viable long term solutions. Reducing object allocation is the best path forward.

The closer your mental model of Ruby memory use is to reality, the more effective you will be when diagnosing or fixing memory-related issues.

- [Complete Guide to Rails Performance (Book)](https://www.railsspeed.com)
- [How Ruby uses Memory](https://www.sitepoint.com/ruby-uses-memory/)
- [Ruby Memory Use (Heroku Devcenter article I maintain)](https://devcenter.heroku.com/articles/ruby-memory-use)
- [Jumping off the Ruby Memory Cliff](https://www.schneems.com/2017/04/12/jumping-off-the-memory-cliff/)
- [How Ruby uses memory (Talk)](https://www.schneems.com/2015/05/11/how-ruby-uses-memory.html) (you can skip the first story in the video, the rest are about memory)
- [Debugging a memory leak on Heroku](https://blog.codeship.com/debugging-a-memory-leak-on-heroku/)

Focus on the largest request. If we can reduce our largest request by a factor of two from 390 memory units to 195, then our maximum theoretical usage at ten threads becomes 1,950 units. In my experience, there is usually one or two endpoints that allocate an obscene amount of memory, maybe two to five times the amount of other endpoints. If I were to tune your memory use, I would start with the largest requests. But there's a funny thing about performance and process improvements. Once your largest request is no longer the largest, then another endpoint will take up that position. If you want to streamline your application's memory use, it's not just enough to do this process once. You must continue to improve this process. If you're new to this space, I highly recommend the book [The Goal](https://amzn.to/2Cm44Eh) (affiliate link). I've also written about this concept for a guest blog post [The “Goal” of Performance Tuning](https://blog.codeship.com/goal-performance-tuning/).

## Caveats and Fine Print

The models I described above closely mimic the behavior and performance I've seen from real-world production applications over my last decade-plus working with Ruby. However, since these examples are based on simulation: it is useful to be explicit about what is simulated, and what is excluded.

**Thread behavior** Ruby can only execute one thread at a time due to the GVL, but "IO" calls such as database queries, or a network requests can release the GVL. Ruby's threads also use time-slicing, so if you have two requests trying to execute at the same time and neither are doing IO, then imagine that Ruby is bouncing back and forth between the two working on each a little at a time. In reality, there are more considerations, and we can model those interactions, but they're not necessary for now.

**Threads versus processes** While I said "threads," concurrency via processes will see the same memory behavior for processing requests. I specifically chose "threads" for this example because people generally don't associate them with memory use, or understand why memory goes up over time. One difference in memory use between threads and processes is that a process will require a higher base-line amount of memory use than a thread. To understand more of the differences between the two concurrency constructs, you might want to check out my talk and post [WTF is a Thread](https://www.schneems.com/2017/10/23/wtf-is-a-thread/).

**Active versus "base" memory** When you boot up your application but have not served any requests, there is a memory footprint. Think of this as the "base" size of the application. As a request comes in, imagine that your application pulls a user from the database, which requires allocating objects, renders a template that needs objects, and does a whole lot of internal object creation to deliver the request back. These objects are what I refer to as "Active" memory.  Active memory is not retained for long but is needed for the duration of the request. For this simulation, I only included "active" memory generated from requests.

**Zero Retained objects** This simulation also assumes that at the end of the request that all allocated objects can be garbage collected. In reality, this is not true. For example, in Ruby on Rails, there is a "prepared statement cache" that will grow in size as your application prepares and saves those statements. When people think of "a memory leak," that's what they typically are thinking of, first memory is allocated, then retained, and never allowed to be reclaimed by the garbage collector. The primary purpose of these simulations are to show how memory needs can increase over time when there is no "leak," and no objects are retained after a request.

**Background jobs** These examples are framed in terms of "web" requests, but they apply to any system that is running concurrent process or threads, such as Sidekiq processing background jobs.

## Play

If you want to play around with the code that generated these simulations, you can by using [my simulation and charting code on GitHub](https://github.com/schneems/simulate_ruby_web_memory_use).