---
title: "Why does My Memory Usage Grow Asymptotically Over Time?"
layout: post
published: true
date: 2019-11-06
redirect_from:
  - /2019/11/06/how-ruby-really-uses-memory-on-the-web-and-beyond/
permalink: /2019/11/07/why-does-my-apps-memory-usage-grow-asymptotically-over-time/
image_url: https://www.dropbox.com/s/ik7ixj8qqo8m4jq/Screenshot%202019-10-28%2012.27.11.png?raw=1
hnurl: https://news.ycombinator.com/item?id=21466921
twurl: https://twitter.com/schneems/status/1192178141088890880
loburl: https://lobste.rs/s/nuaw9q/how_ruby_really_uses_memory_on_web_beyond
categories:
    - ruby
    - memory
    - performance
---

Why on earth does my memory consumption chart look like that? It's a question I hear every week. To help answer that question, I wrote a [Web server request simulator](https://github.com/schneems/simulate_ruby_web_memory_use) to model how Ruby uses memory over time. We will use the output of that project to dissect why a Ruby on Rails web app's memory would be expected to look like this:

![](https://www.dropbox.com/s/58w258qszoo9h9c/Screenshot%202019-10-28%2012.48.28.png?raw=1)

> [Logistic](https://en.wikipedia.org/wiki/Logistic_function) function generated via Wolfram Alpha `Plot[100 / (1 +  e^-(x/100) )], {x, 0, 1000}]`. Shape is asymptotic.

In this post, we'll talk a little about what causes this shape of memory use over time. Then we will dig into what that memory behavior means in terms of optimizing your application.

> Originally, this post was titled "How Ruby REALLY Uses Memory: On the Web and Beyond," which was less precise. I've re-generated the graphs to be more visible and, based on feedback, made the explanations more concise.

## Simulating one Request

Here is the output of simulating one thread handling one request:

![](https://www.dropbox.com/s/73e4k8zw0p9aqty/Screenshot%202019-11-07%2010.28.22.png?raw=1)

Time is the bottom axis — memory on the horizontal. As time progresses, our thread will process the request and allocate objects which require more memory. This behavior produces a diagonal line going up and to the right.

Once the request is over, their slots can be recycled, so the amount of objects memory required goes back down to zero. This behavior causes the graph to drop to zero and produces a "tooth" shape.

## Ruby Tracks Max Memory: Multiple Requests with One thread

Now that you understand the output format, let's look at a few requests and add in another piece of data, the "Max total" memory:

![](https://www.dropbox.com/s/jebpa2cblj05s2h/Screenshot%202019-11-07%2010.31.35.png?raw=1)

This "max total" line at the top of the graph traces the total maximum amount of memory needed to run the application.

In this example, the first request needs a large amount of memory.

Ruby will allocate enough space to handle whatever task needs to be done. Then it will assume (correctly in this case) that in the future, you'll need to use that memory again, so it holds onto it. While looking at these graphs, the top line roughly represents the memory requirements of your program that you would see in Heroku's memory metrics dashboard, or from activity monitor locally (if you're on a Mac).

The other important thing about this graph is that different requests allocate different quantities of objects. You can see this visually as some of the spikes are different shapes and sizes. These shapes might represent serving different endpoints or parameters such as `/users?per_page=2` versus `/users?per_page=42_000`.

## Simulation with two threads - one request each

Your application is rarely serving only one request at a time. What does a server handling two concurrent workloads look like in terms of memory use?

When we simulate multiple requests, the high-water mark of the "max" memory needed to run the application is now the sum of all threads.

![](https://www.dropbox.com/s/sh42ajt9be9yue0/Screenshot%202019-11-07%2012.58.42.png?raw=1)

In this example, the first request needed a lot of memory, and while it was being prepared, the next request came in. You can see that when both threads are processing a request, the "Max Total" goes up proportional to the sum of all threads.

Thread two maxes out at 222 memory units. At this time, thread one is about 74 memory units. The "Max Total" for the whole system ends up being around 296 memory units.

## Simulation with two threads - ten requests each

Here's another example with ten requests per thread:

![](https://www.dropbox.com/s/qozqz4ua1klxdzv/Screenshot%202019-11-07%2013.00.08.png?raw=1)

Notice where the green "Max Total" line seems to jump above the other spikes, this is where the system is processing multiple requests at a time.

## 1,000 Requests Simulation with two threads

Here's another example with 1000 requests:

![](https://www.dropbox.com/s/ik7ixj8qqo8m4jq/Screenshot%202019-10-28%2012.27.11.png?raw=1)

It takes a while, but over time, memory use doubles. The height of thread one and two roughly max out at about 390 memory units. Overall memory use is 780 (390 * 2) memory units. This doubling happens because eventually, two requests end up being served at the same time with the maximum amount of memory requirements.

So what happens if we add a third thread? Do we expect it to use 1,170 memory units total?

![](https://www.dropbox.com/s/kluh761tzo2ser9/Screenshot%202019-10-28%2013.33.48.png?raw=1)

Huh, it didn't even come close to 1,170 memory units. In fact, it's less memory than the two-thread example. Why? The total memory use depends not just on the number of threads, but also the distribution of requests we are getting.

What is the likelihood that the largest request will come in and hit all threads at the same time? In this case, it didn't happen, but it doesn't mean it won't ever.

## Simulating ten threads instead of just two

What happens if we move from two threads to ten? Would you expect our memory usage to be 10x? Let's find out:

![](https://www.dropbox.com/s/dlj7pdia962s61e/Screenshot%202019-10-28%2013.42.32.png?raw=1)

If we were going to 10x our memory, I would expect to see 3,900 (10 * 390) memory units being used.

This graph doesn't show anywhere near that number, though. Why not? Our system still has the same theoretical maximum, but getting there means we would have to have several seemingly random events align perfectly. All ten threads would have to be serving the "largest" endpoint all at the same time.

## What does it all Mean?

Here are some conclusions that you can draw from these simulations:

- Total memory use goes up as the number of threads are increased
- Memory use for an individual thread is a factor of the **largest possible request** it will ever serve
- Memory use across all threads are based on a distribution of how likely that maximum request is to be hit **simultaneously** by all existing threads
- As your application executes over time, it is expected and natural that your memory requirements will increase until they hit a steady-state.

## Tune your application

If you want your application to use less memory, you need to move one of the factors we mentioned: number of threads, largest possible request, or the distribution of incoming requests.

You can decrease thread count to reduce your memory needs, but that might also lower your throughput.

You can add capacity via scaling out, such as adding additional dynos/servers. Adding capacity works because more servers/dynos in operation spread out the requests more, and the event that all threads on an individual machine are processing the largest request at the same time is reduced. This tactic might work from one to two servers, but over time returns are diminishing. i.e., the benefit of going from 99 servers to 100 won't have a significant impact on the overall distribution of requests for individual machines.

In my experience, neither of these are viable long term solutions. Reducing object allocation is the **best path to reducing your overall memory needs**.

The good news is that reducing object allocation in your largest requests also means your application runs faster. The bad news is that moving this allocation number requires active effort and an intermediate-to-advanced understanding of performance behavior.

If you want to start improving your application's memory consumption here are additional resources;

- [Complete Guide to Rails Performance (Book)](https://www.railsspeed.com) - This book is by Nate Berkopec and is excellent. I recommend it to someone at least once a week.
- [How Ruby uses memory](https://www.sitepoint.com/ruby-uses-memory/) - This is a lower level look at precisely what "retained" and "allocated" memory means. It uses small scripts to demonstrate Ruby memory behavior. It also explains why the "total max" memory of our system rarely goes down.
- [How Ruby uses memory (Video)](https://www.schneems.com/2015/05/11/how-ruby-uses-memory.html) - If you're new to the concepts of object allocation this might be an excellent place to start (you can skip the first story in the video, the rest are about memory).
- [Jumping off the Ruby Memory Cliff](https://www.schneems.com/2017/04/12/jumping-off-the-memory-cliff/) - Sometimes you might see a "cliff" in your memory metrics or a saw-tooth pattern. This article explores why that behavior exists and what it means.
- [Ruby Memory Use (Heroku Devcenter article I maintain)](https://devcenter.heroku.com/articles/ruby-memory-use) - This article focuses on alleviating the symptoms of high memory use.
- [Debugging a memory leak on Heroku](https://blog.codeship.com/debugging-a-memory-leak-on-heroku/) - TLDR; It's probably not a leak. Still worth reading to see how you can come to the same conclusions yourself. Content is valid for other environments that Heroku. Lots of examples of using the tool `derailed_benchmarks` (that I wrote).

When working on reducing your application's memory footprint, focus on the largest endpoint. If you can reduce your largest request by a factor of two in the simulation, from 390 memory units to 195, then your maximum theoretical usage at ten threads becomes 1,950 units. Neat!

In my experience, there is usually one or two endpoints that allocate an obscene amount of memory, maybe two to five times the amount of other endpoints. If I were to tune your memory use, I would start with the largest requests.

## Caveats and Fine Print

The models I described above closely mimic the behavior and performance I've seen from real-world production applications over my last decade-plus working with Ruby. However, since these examples are based on simulation: it is useful to be explicit about what is simulated and what is excluded.

**Ruby behavior** This behavior is a very rough approximation of how Ruby (2.6 is the latest release at the time of writing) allocates memory. In reality, the garbage collector (responsible for allocating memory) is more nuanced than this simulation. There is a range of topics you need for the full picture: object slots, slot versus heap allocation, generational GC, incremental GC, compacting memory, fragmentation due to malloc implementation, etc. But for now, this simplification is good enough.

**Thread behavior** Ruby can only execute one thread at a time due to the GVL, but "IO" calls such as database queries, or a network requests can release the GVL. Ruby's threads also use time-slicing, so if you have two requests trying to execute at the same time and neither are doing IO, then imagine that Ruby is bouncing back and forth between the two working on each a little at a time. In reality, there are more considerations, and we can model those interactions, but they're not necessary for now.

**Threads versus processes** While I said "threads," concurrency via processes will see the same memory behavior for processing requests. I specifically chose "threads" for this example because people generally don't associate them with memory use, or understand why memory goes up over time.

One difference in memory use between threads and processes is that a process will require a higher base-line amount of memory use than a thread. To understand more of the differences between the two concurrency constructs, you might want to check out my video and post [WTF is a Thread](https://www.schneems.com/2017/10/23/wtf-is-a-thread/).

**Active versus "base" memory** When you boot up your application but have not served any requests, there is a memory footprint. Think of this as the "base" size of the application. As a request comes in, imagine that your application pulls a user from the database, which requires allocating objects, renders a template that needs objects, and does a whole lot of internal object creation to deliver the request back. These objects are what I refer to as "Active" memory.  Active memory is not retained for long but is needed for the duration of the request. For this simulation, I only included "active" memory generated from requests.

**Zero Retained objects** This simulation also assumes that at the end of the request that all allocated objects can be garbage collected. In reality, this is not true. For example, in Ruby on Rails, there is a "prepared statement cache" that will grow in size as your application prepares and saves those statements. When people think of "a memory leak," that's what they typically are thinking of, first memory is allocated, then retained, and never allowed to be reclaimed by the garbage collector. The primary purpose of these simulations are to show how memory needs can increase over time when there is no "leak," and no objects are retained after a request.

**What about background jobs** These examples are framed in terms of "web" requests. Still, they apply to any system that is running concurrent processes or threads, such as processing background libraries, like Sidekiq.

## Play

If you want to play around with the code that generated these simulations, you can by using [my simulation and charting code on GitHub](https://github.com/schneems/simulate_ruby_web_memory_use).
