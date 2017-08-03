---
title: "Is WEBrick Webscale?"
layout: post
published: true
date: 2017-08-01
permalink: /2017/08/01/is-webrick-webscale/
hnurl: https://news.ycombinator.com/item?id=14904375
twurl: https://twitter.com/schneems/status/892470634281930752
image: og/webrick.png
categories:
    - ruby
---

[WEBrick](http://ruby-doc.org/stdlib-2.4.1/libdoc/webrick/rdoc/WEBrick.html) is the "slowest" webserver in Ruby, how could it possibly be webscale? To answer this question and explore [Is Ruby Too Slow For Web-Scale?](https://www.speedshop.co/2017/07/11/is-ruby-too-slow-for-web-scale.html), we will compare WEBrick to a real piece of "webscale" tech: [NGINX](https://www.nginx.com/resources/wiki/).

{% img 'og/webrick.png' %}

While there might be some faster webservers on the market, is there a case where WEBrick is fast enough? Before we can dig into that question, let's look at a real world deployment of WEBrick in production.

I somewhat accidentally ran my own blog on WEBrick for a few years. When I first made the move to a self-hosted blog, the easiest thing to do was to use the default buildpacks that ships with Heroku (I maintain the Ruby one). All I had to do was add a `Procfile` and put this in it:

```
web: jekyll server -P $PORT --no-watch --host 0.0.0.0
```

This `Procfile` tells [jekyll](https://rubygems.org/gems/jekyll) (a static blog framework in Ruby) to boot up, bind to the `PORT` environment variable and do not "watch" for file changes, only serve what is on disk at boot. Under the covers, this `jekyll` command uses WEBrick as its webserver to serve my content. I deployed and kinda forgot about it, figuring I would come back to scale everything up later.

Fast forward a few years and I still hadn't updated the way I was serving my site. It was still using WEBrick. One day I opened my Heroku metrics panel and to my surprise, I noticed that my performance was good, like REALLY good. Would you believe that my average response rate was under 100ms? What if I told you it was around 7ms? Because that's what it was:

![](https://www.dropbox.com/s/og3vb3e2i9eocfs/Screenshot%202017-05-30%2014.20.05.png?dl=1)

Even the Perc95 was great, it's under 35ms. As Nate mentioned on his blog, under a certain threshold (100 milliseconds) things appear more or less instantaneous to end-users. For my little blog, humming along using a pure Ruby stack, I was in that "instantaneous" category out of the box.

- WEBrick "webscale" speed: ✅🎉

In the case of my blog, my throughput averages around 25 requests per minute and when I published [my most popular post of 2017](https://schneems.com/2017/07/18/how-i-reduced-my-db-server-load-by-80/) it spiked up to 375 requests per minute.

![](https://www.dropbox.com/s/bqh3trvy0q7nb29/Screenshot%202017-07-25%2009.32.45.png?dl=1)

Since the blog is on Heroku, if it gets swamped, I can scale up by adding more dynos very easily. However, the core concern of "webscale" is our costs. It doesn't matter if you can handle 1 million requests per second if you break the bank. Is Ruby too expensive to be "webscale"? Let's calculate the number of instances we need to serve the largest spike of the year:

According to [Little's law](https://en.wikipedia.org/wiki/Little%27s_law) and [Nate's own math](https://www.speedshop.co/2015/07/29/scaling-ruby-apps-to-1000-rpm.html), we can calculate the number of "instances" we need to serve this content:

```
webrick instances = avg requests (per second) * average response time (seconds)
```

We can use this math to approximate the maximum number of requests per second that could be served by 1 WEBrick instance:

```
avg requests (per seconds) = 1.0 instances / average response time (seconds)
```

When we plug in the numbers:

```
1.0 instances / 0.007 seconds per request
# => 142.85 average requests (per second)
```

This means that 1 dyno with webrick could handle `142.85 (requests per second) * 60 (seconds in a minute) #=> 8571.0` requests per minute. Currently, my max is 375. That means that WEBrick could have handled up to 22 times that maximum load. Granted this is theoretical and assumes that the requests arrive exactly one after the other every 7 milliseconds. If all 8K requests came in at exactly the same time, one would be served in 7ms, the next would take 14 milliseconds (7 milliseconds waiting and 7 milliseconds of actual processing), the next 21 milliseconds, and so on. The last request would experience a latency of 56 seconds.

> If you want to be pedantic about it, the socket by default would only accept 1024 requests in the backlog and the rest would be rejected, also there is a 30 second timeout from the router. But you get the point.

- WEBrick "webscale" cost: 😜😇

I promised we would compare to NGINX (pronounced "engine-x")? The results may surprise you! I eventually switched my blog to generate static content via Ruby and then serve it via NGINX.

While I was fairly happy with the performance of my quick and dirty jekyll setup on Heroku, there was one thing that I was missing: the ability to force SSL.

Heroku added a cool feature called [Automated Certificate Management (ACM)](https://devcenter.heroku.com/articles/automated-certificate-management). Basically, when you turn it on we provision a lets encrypt cert for your app and auto rotate it for you. I added it to my blog because everyone should be using SSL all the time, and also Google considers whether or not [you provide SSL as a signal in determining your page rank](https://webmasters.googleblog.com/2014/08/https-as-ranking-signal.html).

After turning ACM on, one annoyance I had was that there was no way to "force" visitors of my site to use SSL. If they typed in `http` instead of `https` they got unencrypted traffic. To solve this seemingly mundane issue, I switched my entire app to use NGINX. While it might sound drastic, it wasn't really. I used a great buildpack called [the static buildpack](https://github.com/heroku/heroku-buildpack-static). It provides NGINX (and some other bells and whistles). The biggest win for me was that I didn't have to manually write my NGINX configuration. Instead, all I had to do was provide a `static.json` file in the root of my directory:

```json
{
  "root": "_site",
  "https_only": true,
  "clean_urls": true,
  "error_page": "404.html",
  "headers": {
    "/": {
      "Cache-Control": "no-store, no-cache"
    },
    "/assets/**": {
      "Cache-Control": "public, max-age=15552000"
    }
  }
}
```

> Note: I'm using sprockets to generate fingerprinted assets, if you're not, don't set a max-age on your assets.

After adding this file, I had to delete my `Procfile` and add the static buildpack:

```term
$ heroku buildpacks:add https://github.com/heroku/heroku-buildpack-static.git
```

> Make sure that the static buildpack is the last buildpack on your list.

When I deployed what did I see? My response time went down, my average is now around 3ms and perc95 around 10ms. Though it can still peak up to "WEBrick" levels occasionally:

![](https://www.dropbox.com/s/y4cp96i23pnrk27/Screenshot%202017-07-25%2010.04.33.png?dl=1)

- NGINX "webscale" speed: ✅🎉🚀💯

One other thing it did was drop my memory use like a (WEB)brick. Here's screenshot of just after the deploy

![](https://www.dropbox.com/s/gr1t0ili613mybv/Screenshot%202017-05-31%2011.38.40.png?dl=1)

Back to our calculations though, how does NGINX stack up on our cost metric of "webscale"? To know this we first have to know how many concurrent requests it can handle. NGINX uses processes via a directive `worker_processes`. In the static buildpack it's set to [auto](https://github.com/heroku/heroku-buildpack-static/blob/995b07c1df7971c66d1c921f2c55132a2dca57ca/scripts/config/templates/nginx.conf.erb#L2). After some digging I found out that this value is configured based on the number of CPUs on the system. Which is configured by a [system call for POSIX based systems](https://github.com/nginx/nginx/blob/9edd64fcd842870ea004664288cadc344c33f0bd/src/os/unix/ngx_posix_init.c#L57).

What is that value for CPUs on Heroku? I'm sure there's a command line tool to get the same info, but I've been on a C kick, so let's use the exact same system call on a dyno.

First, we can "bash" into our dyno, this gives us a bash shell on a one-off dyno:

```term
$ heroku run bash
```

> Note: If you're on a different dyno type you can pass that value in with the `-s` flag. For example a performance-m dyno would be `-s performance-m`.

Now we have to get our C code on disk. We can use `cat` to do this:

```term
~$ cat > numprocessors.c <<EOL
  #include <unistd.h>
  #include <stdio.h>

  int main() {
    int val = sysconf(_SC_NPROCESSORS_ONLN);
    printf("# => Number of processors from sysconf: %i\n", val);
    return 0;
  }
EOL
```

This C code makes the system call and prints the results. Now we have to compile and call our executable:

```term
~$ gcc numprocessors.c && ./a.out
# => Number of processors from sysconf: 8
```

> Or you can run `getconf _NPROCESSORS_ONLN` on the command line.

There you go. The number of processes in NGINX will be 8. Also since our average response time is down to 3ms we'll get a boost in our calculations there.

```
8 instances / 0.003 seconds per request
# => 2666.666 average requests per second
```

Is NGINX webscale? I think so.

- NGINX "webscale" cost: ✅🎉🚀💯

At the end of the day, NGINX beat our little WEBrick server, but that's expected. NGINX is far more complex with far more development hours in it. What was surprising to me was how long I was able to get by without it. When people say "use the right tool for the job" sometimes they mean don't over engineer things with the 100% fastest tools. One thing that WEBrick is good at doing is being simple and relatively bug-free. For example, if you need to serve some files from a directory, you can do it in a one liner shell script:

```ruby
ruby -rwebrick -e "WEBrick::HTTPServer.new(:Port => ENV['PORT'], :DocumentRoot => ENV['HOME']).start"
```

> Or even simpler [with this one weird trick](https://twitter.com/schneems/status/892414459846832128)

Would I ever encourage you to deploy a top [500 Alexa](http://www.alexa.com/topsites) site with WEBrick? Absolutely not, but that doesn't mean it's worthless. It has served me and my site well.

The other thing to consider in the cost of delivery is that while WEBrick is more than capable for my needs (up to a 22x increase in my max blog readers) when we talk about "webscale" we're usually in a scenario where we must actually, you know, scale. As soon as you start having to add more servers, you can save money by going with a higher throughput technology. If you're only running 2 servers, it's maybe not worth it to drop down to 1. Yet, if you're running 2 million servers, there will be a very real, and very significant financial impact to moving to a higher throughput tech.

> Note: When considering "server" costs also consider human costs. If switching languages __just__ to drop server costs means hiring additional headcount, or delaying new features then it probably won't be worth it. A better metric would be RPM / Total costs (including all of engineering headcount).

While WEBrick fought the good fight and even passed my two "webscale" sniff tests, sadly this post fails the [Betteridge’s Law of Headlines](https://en.wikipedia.org/wiki/Betteridge%27s_law_of_headlines). WEBrick is not "webscale".

You might be shocked to learn (as I was) that WEBrick is multi-threaded. If you've heard about Ruby's GVL (or GIL, depending on how old you are) then you might be surprised to hear that adding threads matter. In short the GVL prevents more than one bit of Ruby code from executing at the same time (similar to Python). However when you do IO such as a disk read, a database call, or an API request the GVL is released, and allows other Ruby threads to run. In WEBrick [EVERY new request is run in a new thread](https://github.com/ruby/ruby/blob/cff3941b817b976a57f42b374c3dfceff1ad459d/lib/webrick/server.rb#L185). One of the reasons WEBrick is so good at running my blog is that it only has to grab static pages from disk and serve them. The longest piece of this is, you guessed it: IO. I did some load testing using `siege` on my blog locally:

```term
$ siege -b -t60s 127.0.0.1:3000
# ...
Lifting the server siege...      done.

Transactions:             21970 hits
Availability:               100.00 %
Elapsed time:                59.37 secs
Data transferred:           535.31 MB
Response time:                0.04 secs
Transaction rate:           370.05 trans/sec
Throughput:                   9.02 MB/sec
Concurrency:                 14.59
Successful transactions:  21970
Failed transactions:          0
Longest transaction:          4.84
Shortest transaction:         0.00
```

In this case I was able to serve nearly 22,000 requests in one minute which is 2.75x more than my calculated maximum. Granted my local machine is a beast compared to what I'm running in production. Locally I've got 8GB of Ram (compared to 512 MB) and 4 physical cores (compared to sharing 8 virtual cores with other apps). You can see it's not all roses & sunshine, the longest transaction took nearly 5 seconds, which is not acceptable for "webscale". The interesting thing is that by giving my program more resources, it's able to effectively use them. Not only is it faster, it's faster with zero configuration. I was curious and during load testing WEBrick got up to 101 spawned threads. Not bad for the "slowest" webserver in Ruby.

Okay, you're probably thinking that this isn't a fair comparison because of the IO heavy workload right? I run such a "real world" app [CodeTriage, the best place to get started in Open Source](https://www.codetriage.com), and I can tell you that a non-trivial amount of time is spent in the database (IO). You can read all about my efforts to speed up that layer and how impactful it was:

- [A Tale of Slow Pagination](https://schneems.com/2017/06/22/a-tale-of-slow-pagination/)
- [Using Heroku's "Expensive Query" Dashboard to Speed up your App](https://blog.heroku.com/expensive-query-speed-up-app)
- [How I Reduced my DB Server Load by 80%](https://schneems.com/2017/07/18/how-i-reduced-my-db-server-load-by-80/)

This brings us back to our original question: Is Ruby webscale? We looked at the best in class of "webscale" technologies (NGINX) and we looked at the simplest webserver in Ruby. While NGINX won hands down, it was more of a fight than I would have expected. If we swapped in a more complex Ruby server such as [Puma](https://rubygems.org/gems/puma) then I would be able to go even faster.

> With siege I got Puma up to 32,623 RPM and a "longest" request of `0.63` seconds. As a side note I actually think this is around the threshold for the max load my machine can generate.

While the Perc95 is better on NGINX (versus Ruby), there's essentially no human discernible difference between a 30ms and 10ms response time.

When it comes to speed, the question is never about pure performance. If that was the case, we would all be writing assembly. The question is about being fast __enough__, while allowing you to ship and iterate quickly. Ruby meets my needs and [each year continues to get about 7-10% faster](http://engineering.appfolio.com/appfolio-engineering/2016/7/19/speed-up-ruby-by-7-or-more). There is also a push for Ruby "3x3" to make Ruby 3 at least 3 times faster than Ruby 2. To that end there are really exciting projects [like MJIT](https://engineers.sg/video/keynote-simple-goal-hard-to-accomplish-reddotrubyconf-2017--1830). There are already alternative implementations with JIT like [JRuby](http://jruby.org/) and [TruffleRuby](https://github.com/graalvm/truffleruby). Ruby is fast enough for my needs, and is only getting faster.

So while WEBrick might not be "webscale", is Ruby? I say yes.
