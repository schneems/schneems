---
title: "Puma 4: New I/O 4 Your Server"
layout: post
published: true
date: 2019-06-26
permalink: /2019/06/26/puma-4-new-io-4-your-server/
categories:
    - ruby
    - puma
---

Here’s the setup: You are a web server named Puma. You need to accept incoming connections and give them to your thread pool, but before we can get that far, you’ll have to make sure all of the request's packets have been received so that it’s ready to be passed to a Rack app. This sounds like the job for a Reactor!

Puma 4 was just released and the internals of the Reactor were changed. While it's not a breaking change, it was such a departure from how Puma previously worked, that we decided it was worthy of a major version bump, to be extra safe. In this post we'll look what a reactor is, how the old reactor worked, and how the new reactor now works.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">By the coders who brought you Llamas in Pajamas. A new cinematic Ruby server experience. Directed by <a href="https://twitter.com/evanphx?ref_src=twsrc%5Etfw">@evanphx</a>, cinematography by <a href="https://twitter.com/nateberkopec?ref_src=twsrc%5Etfw">@nateberkopec</a>, produced by <a href="https://ruby.social/@Schneems?ref_src=twsrc%5Etfw">@schneems</a>.<br><br>Introducing - Puma: 4 Fast 4 Furious<a href="https://t.co/06PG0lzubk">https://t.co/06PG0lzubk</a> <a href="https://t.co/O1dLfwnctJ">pic.twitter.com/O1dLfwnctJ</a></p>&mdash; Richard Schneeman 🤠 (@schneems) <a href="https://ruby.social/@Schneems/status/1143577608791220224?ref_src=twsrc%5Etfw">June 25, 2019</a></blockquote> <script async src="https://platform.twitter.com/widgets.js" charset="utf-8"></script>

To understand the role a Reactor plays in Puma, let's start with an analogy. Imagine you're working in a mailroom. You have a dedicated set of celebrities that read and respond to fan mail. When a celeb is done responding to a letter, they check their mailbox to see if they have another one. When they get a new letter the first thing they do is see if there's any missing pages. Maybe the letter says "to be continued" and there's no other pages. This celeb could sit around all day and wait to see if other letters by the same sender came in before responding, but they are very busy. They want to respond to other fan mail.

The celeb gives you the incomplete letter and tells you to wait for ALL of the pages from that sender. You stick it in your filing system. When another page comes in for a letter it magically shows up in the same envelope (yes, I know it's not a perfect analogy) then you look through your files, see which letter had a new page. Then you check to see if all the pages for that specific letter are present. If you have all the pages then you give the complete letter to the celebrity to respond to, otherwise you put it back in the file.

In this case the celebrity is a Puma thread, and you are the Reactor. The letters are requests, and letters without all pages represent slow or large requests that require additional packets before they can be responded to. The main role of a reactor is to prevent against [slow clients](https://en.wikipedia.org/wiki/Slowloris_(computer_security)) by fully buffering the request before attempting to do work on it.

Here’s how the Puma 3.x (previous current version) implements a Reactor. First it receives an incoming client connection:

A request comes into a `Puma::Server` instance [[code](https://github.com/puma/puma/blob/c24c0c883496f581d9092bbe7f7431129eeb7190/lib/puma/server.rb#L336-L337)]. It is then passed to a `Puma::Reactor` instance [[code](https://github.com/puma/puma/blob/88e51fb08e0735a98a519db46649f01bcc88d03c/lib/puma/reactor.rb#L314-L326)].

The reactor stores the request in an array and calls `IO.select` on the array in a loop [[code](https://github.com/puma/puma/blob/88e51fb08e0735a98a519db46649f01bcc88d03c/lib/puma/reactor.rb#L128-L148)].

When the request is written to by the client, then an `IO.select` will “wake up” and return the references to any objects that caused it to “wake”. The reactor then loops through each of these request objects and sees if they’re complete. If they have a full header and body, then the reactor passes the request to a thread pool.

Once the request is in a thread pool, a “worker thread” can run the application’s Ruby code against the request.

If the request is not complete (not fully buffered, waiting on extra packets), then it stays in the array, and the next time any data is written to that socket reference, then the loop is woken up, and it is rechecked for completeness.

A [detailed example is given in the docs](https://github.com/puma/puma/blob/88e51fb08e0735a98a519db46649f01bcc88d03c/lib/puma/reactor.rb#L66-L122) for `run_internal` which is where the bulk of this logic lives.

This flow is an okay setup, but it depends on `IO.select` which has limitations. With this approach, Puma can only have 1024 active clients, which sounds like a lot, but if you’re using WebSockets, then you might hit that number. Another downside of the `select()` API that puma is using here is that it has to iterate over each connection on the socket to see if any have new bytes written. If you have a lot of connections, it’s not terribly efficient (it's O(n)).

What are the alternatives? In addition to the `select()` from the OS there’s also `epoll` and `kqueue`. And as luck would have it [Julia Evans wrote a fantastic blog post about them](https://jvns.ca/blog/2017/06/03/async-io-on-linux--select--poll--and-epoll/) which sums up the problem and eventual solution pretty well:

> Instead of spending all CPU time to ask “are there updates now? How about now? How about now? How about now? “, Instead, we’d rather ask the Linux kernel “hey, here are 100 file descriptors. Tell me when one of them is updated! “.

That’s what `epoll` does for Linux, and `kqueue` does for FreeBSD (mac). Now when your reactor is ready to perform work, then you can call `epoll_wait` and instead of the OS having to loop through every connection, it instead gets a notification when one of those connections receive data, then it unblocks and gives the list of updated connections to the reactor. The reactor then needs to check to see if the full request has been written and if so, hand it off to a worker or thread.

In addition to the benefit of the ability to maintain more than 1024 connections, using epoll/kqueue reduces request buffering overhead for any app that serves moderate-to-high-load. Sounds great, let’s use it! But how?

It turns out there’s a Ruby library that wraps these two system calls (depending on which system you’re running on) called [nio4r](https://github.com/socketry/nio4r). One of the authors, [https://rubygems.org/profiles/ioquatix](https://rubygems.org/profiles/ioquatix), is prolific in the async/event-driven space in Ruby. They also maintain [rack-freeze](https://github.com/ioquatix/rack-freeze) which is a great way to guard you rack middleware against threading bugs.

The library nio4r stands for “New I/O for ruby” and supports different backends. For example “libev” provides epoll/kqueue, while Java has their own backend, and finally, if a system doesn’t have any of those things it falls back to `Kernel.select`, which still has the limitations we talked about previously, but at least it will work. Currently, windows does not support epoll/kqueue, and it would fall back to `Kernel.select`.

Now that you’ve got a base understanding of the problem, and we’ve got a library that does the thing we want (replace select with epoll), we’re ready to look at a [PR to Puma by its creator, Evan Phoenix](https://github.com/puma/puma/pull/1728).

The bulk of the code is in `lib/puma/reactor.rb` and you might notice if you look at the source someone (me) wrote a ton of docs explaining the intricacies of how the old reactor works.

> Note: The code has been updated to [reference the new system calls](https://github.com/puma/puma/commit/c242e76f4d14dd7582ce27062c6b0d26ff4abaf5)

In the PR, an instance of nio4r is created and called a selector:

```ruby
@selector = NIO::Selector.new
```

Now where previously we were blocking on a call to `IO.select` we now call:

```ruby
ready = selector.select @sleep_for
```

That’s pretty much all there is to the change. There’s another difference in terms of the API, the result of the read from the socket will be accessible via a method called `value`.

For more information here, you can check out nio4r’s documentation, which conveniently has a [getting started guide that covers how to build a simple reactor loop](https://github.com/socketry/nio4r/wiki/Getting-Started).

In the PR, you can also see a good bit of changes in this case statement:

```ruby
case @ready.read(1)
when "*"
  #... lots of code here
```

What exactly is happening, and why would our server be receiving a `*`? The reactor watches a set of connections via `selector.select @sleep_for` but for us to be notified about a write to one of those connections, we’ve got to be tracking it. To do this, we need a way to add a new incoming connection to our connection list.

From the old docs:

> If there was a trigger event, then one byte of `@ready` is read into memory. In the case of the first request,
the reactor sees that it’s a `“*” ` value and the reactor adds the contents of `@input` into the `sockets` array.
The while then loop continues to iterate again, but now the `sockets` array contains a `Puma::Client` instance in addition
to the `@ready` IO object. For example: `[#<IO:fd 10>, #<Puma::Client:0x3fdc1103bee8 @ready=false>]`.

This core behavior still exists, but the end methods are different since we’re now using nio4r rather than a raw array of clients (which wrap individual connections). Instead, we need to register the client:

```
selector.register(c, :r)
```

In the end, you’re still the same good-ole Puma, but you’re faster and can handle UNLIMITED ~~POWER~~ web requests.
