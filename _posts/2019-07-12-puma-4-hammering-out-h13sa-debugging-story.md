---
title: "Puma 4: Hammering Out H13s—A Debugging Story"
layout: post
published: true
date: 2019-07-12
permalink: /2019/07/12/puma-4-hammering-out-h13sa-debugging-story/
categories:
    - ruby
    - puma
---
For quite some time we've received reports from our larger customers about a mysterious [H13 - Connection closed error](https://devcenter.heroku.com/articles/error-codes#h13-connection-closed-without-response) showing up for Ruby applications. Curiously it only ever happened around the time they were deploying or scaling their dynos. Even more peculiar, it only happened to relatively high scale applications. We couldn't reproduce the behavior on an example app. This is a story about distributed coordination, the TCP API, and how we debugged and fixed a bug in Puma that only shows up at scale.

![Screenshot showing H13 errors](https://heroku-blog-files.s3.amazonaws.com/posts/1562883126-Screenshot%202019-06-23%2015.04.50.png)

> This article was originaly published on the [Heroku Blog](https://blog.heroku.com/puma-4-hammering-out-h13s-a-debugging-story)

## Connection closed

First of all, what even is an H13 error? From our error page documentation:

> This error is thrown when a process in your web dyno accepts a connection, but then closes the socket without writing anything to it.
> One example where this might happen is when a Unicorn web server is configured with a timeout shorter than 30s and a request has not been processed by a worker before the timeout happens. In this case, Unicorn closes the connection before any data is written, resulting in an H13.

Fun fact: Our error codes start with the letter of the component where they came from. Our Routing code is all written in Erlang and is named "Hermes" so any error codes from Heroku that start with an "H" indicate an error from the router.

The documentation gives an example of an H13 error code with the unicorn webserver, but it can happen any time a connection is closed via a server, but there has been no response written. Here’s an example showing how to [reproduce a H13 explicitly with a node app](https://github.com/hunterloftis/heroku-node-errcodes/blob/master/h13).

What does it mean for an application to get an H13? Essentially every one of these errors correlates to a customer who got an error page. Serving a handful of errors every time the app restarts or deploys or auto-scales is an awful user experience, so it's worth it to find and fix.

## Debugging

I have maintained the Ruby buildpack for several years, and part of that job is to handle support escalations for Ruby tickets. In addition to the normal deployment issues, I've been developing an interest in performance, scalability, and web servers (I recently started helping to maintain the Puma webserver). Because of these interests, when a tricky issue comes in from one of our larger customers, especially if it only happens at scale, I take particular interest.

To understand the problem, you need to know a little about the nature of sending distributed messages. Webservers are inherently distributed systems, and to make things more complicated, we often use distributed systems to manage our distributed systems.

In the case of this error, it didn't seem to come from a customer's application code i.e. they didn't seem to have anything misconfigured. It also only seemed to happen when a dyno was being shut down.

To shut down a dyno two things have to happen, we need to send a `SIGTERM` to the processes on the dyno which [tells the webserver to safely shutdown](https://devcenter.heroku.com/articles/what-happens-to-ruby-apps-when-they-are-restarted). We also need to tell our router to stop sending requests to that dyno since it will be shut down soon.

These two operations happen on two different systems. The dyno runs on one server, the router which serves our requests is a separate system. It's itself a distributed system. It turns out that while both systems get the message at about the same time, the router might still let a few requests trickle into the dyno that is being shut down after it receives the `SIGTERM`.

That explains the problem then, right? The reason this only happens on apps with a large amount of traffic is they get so many requests there is more chance that there will be a race condition between when the router stops sending requests and the dyno receives the `SIGTERM`.

That sounds like a bug with the router then right? Before we get too deep into the difficulties of distributed coordination, I noticed that other apps with just as much load weren't getting H13 errors. What did that tell me? It told me that the distributed behavior of our system wasn't to blame. If other webservers can handle this just fine, then we need to update our webserver, Puma in this case.

## Reproduction

When you're dealing with a distributed system bug that's reliant on a race condition, reproducing the issue can be a tricky affair. While pairing on the issue with another Heroku engineer, [Chap Ambrose](https://twitter.com/chapambrose?lang=en), we hit an idea. First, we would reproduce the H13 behavior in any app to figure out what [curl exit code](https://curl.haxx.se/libcurl/c/libcurl-errors.html) we would get, and then we could try to reproduce the exact failure conditions with a more complicated example.

A simple reproduction rack app looks like this:

```ruby
app = Proc.new do |env|
  current_pid = Process.pid
  signal      = "SIGKILL"
  Process.kill(signal, current_pid)
  ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
end

run app
```

When you run this `config.ru` with Puma and hit it with a request, you'll get a connection that is closed without a request getting written. That was pretty easy.

The curl code when a connection is closed like this is `52` so now we can detect when it happens.

```term
$ curl localhost:9292
  % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                 Dload  Upload   Total   Spent    Left  Speed
  0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0
curl: (52) Empty reply from server
```

A more complicated reproduction happens when SIGTERM is called but requests keep coming in. To facilitate that we ended up with a reproduction that looks like this:

```ruby
app = Proc.new do |env|
  puma_pid = File.read('puma.pid').to_i
  Process.kill("SIGTERM", puma_pid)
  Process.kill("SIGTERM", Process.pid)

  ['200', {'Content-Type' => 'text/html'}, ['A barebones rack app.']]
end

run app
```

This `config.ru` rack app sends a `SIGTERM` to itself and it's parent process on the first request. So other future requests will be coming in when the server is shutting down.

Then we can write a script that boots this server and hits it with a bunch of requests in parallel:

```ruby
threads = []

threads << Thread.new do
  puts `puma > puma.log` unless ENV["NO_PUMA_BOOT"]
end

sleep(3)
require 'fileutils'
FileUtils.mkdir_p("tmp/requests")

20.times do |i|
  threads << Thread.new do
    request = `curl localhost:9292/?request_thread=#{i} &> tmp/requests/requests#{i}.log`
    puts $?
  end
end

threads.map {|t| t.join }
```

When we run this reproduction, we see that it gives us the exact behavior we're looking to reproduce. Even better, when this code is deployed on Heroku we can see an H13 error is triggered:

```language-text
2019-05-10T18:41:06.859330+00:00 heroku[router]: at=error code=H13 desc="Connection closed without response" method=GET path="/?request_thread=6" host=ruby-h13.herokuapp.com request_id=05696319-a6ff-4fad-b219-6dd043536314 fwd="<ip>" dyno=web.1 connect=0ms service=5ms status=503 bytes=0 protocol=https
```

You can get all this code and some more details on the [reproduciton script repo](https://github.com/schneems/puma_connection_closed_reproduction). And here's the [Puma Issue I was using to track the behavior](https://github.com/puma/puma/issues/1802)

## Closing the Connection Closed Bug

With a reproduction script in hand, it was possible for us to add debugging statements to Puma internals to see how it behaved while experiencing this issue.

With a little investigation, it turned out that Puma never explicitly closed the socket of the connection. Instead, it relied on the process stopping to close it.

What exactly does that mean? Every time you type a URL into a browser, the request gets routed to a server. On Heroku, the request goes to our router. The router then attempts to connect to a dyno (server) and pass it the request. The underlying mechanism that allows this is the webserver (Puma) on the dyno opening up a TCP socket on a $PORT. The request is accepted onto the socket, and it will sit there until the webserver (Puma) is ready to read it in and respond to it.

What behavior do we want to happen to avoid this H13 error? In the error case, the router tries to connect to the dyno, it's successful, and since the request is accepted by the dyno, the router expects the dyno to handle writing the request. If instead, the socket is closed when the router tries to pass on the request it will know that Puma cannot respond. The router will then retry passing the connection to another dyno. There are times when a webserver might reject a connection, for example, if the socket is full (default is only to allow 1024 connections on the socket backlog), or if the entire server has crashed.

In our case, closing the socket is what we want. It correctly communicates to the router to do the right thing (try passing the connection to another dyno or hold onto it in the case all dynos are restarting).

So then, the solution to the problem was to close the socket before attempting to shut down explicitly. Here's the [PR](https://github.com/puma/puma/pull/1808). The main magic is just one line:

```ruby
@launcher.close_binder_listeners
```

If you're a worrier (I know I am) you might be afraid that closing the socket prevents any in-flight requests from being completed successfully. Lucky for us closing a socket prevents incoming requests but still allows us to respond to existing requests. If you don't believe me, think about how you could test it with one of my above example repos.

## Testing distributed behavior

I don't know if this behavior in Puma broke, or maybe it never worked. To try to make sure that it continues to work in the future, I wanted to write a test for it. I reached out to [dannyfallon](https://twitter.com/touchingvirus?lang=en) who has helped out on some other Puma issues, and we remote paired on the tests using [Pair With Tuple](https://tuple.app/).

The tests ended up being [not terribly different than our example reproduction above](https://github.com/puma/puma/pull/1808/files#diff-ad8d9f1e0cf07519c2372ca5f60ca4d2), but it was pretty tricky to get it to have consistent behavior.

With an issue that doesn't regularly show up unless it's on an app at scale, it's essential to test, as [Charity Majors](https://twitter.com/mipsytipsy) would say "in production". We had several Heroku customers who were seeing this error try out my patch. They reported some other issues, which we were able to resolve, after fixing those issues, it looked like the errors were fixed.

![Screenshot showing no more H13 errors](https://heroku-blog-files.s3.amazonaws.com/posts/1562883272-59190728-7bf56a80-8b4b-11e9-8e01-84238fecf24c.png)

## Rolling out the fix

Puma 4, which came with this fix, [was recently released](https://github.com/puma/puma/releases/tag/v4.0.0). We reached out to a customer who was using Puma and seeing a large number of H13s, and this release stopped them in their tracks.

Learn more about Puma 4 below.

<blockquote class="twitter-tweet" data-lang="en" data-align="center" data-conversation="none" data-dnt="true" data-id="1143577608791220224 "><p lang="en" dir="ltr">By the coders who brought you Llamas in Pajamas. A new cinematic Ruby server experience. Directed by <a href="https://twitter.com/evanphx?ref_src=twsrc%5Etfw">@evanphx</a>, cinematography by <a href="https://twitter.com/nateberkopec?ref_src=twsrc%5Etfw">@nateberkopec</a>, produced by <a href="https://ruby.social/@Schneems?ref_src=twsrc%5Etfw">@schneems</a>.<br><br>Introducing - Puma: 4 Fast 4 Furious<a href="https://t.co/06PG0lzubk">https://t.co/06PG0lzubk</a> <a href="https://t.co/O1dLfwnctJ">pic.twitter.com/O1dLfwnctJ</a></p>&mdash; Richard Schneeman 🤠 (@schneems) <a href="https://ruby.social/@Schneems/status/1143577608791220224?ref_src=twsrc%5Etfw">June 25, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>
