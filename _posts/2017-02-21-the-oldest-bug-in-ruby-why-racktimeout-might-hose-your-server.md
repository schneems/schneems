---
title: "The Oldest Bug In Ruby - Why Rack::Timeout Might Hose your Server"
layout: post
published: true
date: 2017-02-21
permalink: /2017/02/21/the-oldest-bug-in-ruby-why-racktimeout-might-hose-your-server/
categories:
    - ruby
---

The "bug" comes up in a few contexts. The problem comes when an error is raised from within an `ensure` block from another source. If you don't know how that's possible keep reading, otherwise skip the next section.

## WTF huh? How is that possible

We are mostly familiar with exceptions

```ruby
raise "something bad happened"
```

If we absolutely need to clean up something in our code we can do it in an ensure block:

```ruby
begin
  file_1 = make_file("file1.csv")
  file_2 = make_file("file2.csv")

  # do work ...

  raise "something bad happened" if work.bad?

  return work
ensure
  clean_up file_1

  clean_up file_2
end
```

In this case, we could be writing to files that need to be deleted after every call to this method. It is guaranteed to be called when the method exits and any time an exception happens in the block.

If you don't follow check out [exceptional ruby](http://exceptionalruby.com/) by Avdi.

Unfortunately things can raise exception other than your own code. For example when you're running a program and want to close it, Ruby will receive a signal by the operating system, to let it know to clean up. In the case of a `SIGKILL` it will raise a `SignalException` exception where-ever the code is in execution. This means it could happen here

```ruby
# ...
ensure
  clean_up file_1
  # Exception could be raised between the two calls right here <================================
  clean_up file_2
end
```

If that happens Ruby will never execute `clean_up file_2`. Granted this is a contrived example and you can do things like use tmp files in a block syntax but that's not the point. The point is that exeptions can come from __outside__ of your code and it can happen inside of an ensure block. This means that we are never actually __guaranteed__ to full execute an ensure block even if all of our code is "correct".

For more information on Ruby's signal behavior check out my post [License to SIGKILL](https://www.sitepoint.com/license-to-sigkill/).

The other case is raising an exception from another thread, you can do this with `Thread#raise`. Here's a contrived example:

```ruby
require 'thread'

threads = []

threads << Thread.new do
  begin
    # ...
  ensure
    clean_up file_1

    clean_up file_2
  end
end

sleep rand(0..2)

threads.each {|thread| thread.raise "no one expects another thread to raise an exception!" }
```

Okay, so __you__ may never do this, that looks like an awful idea. But you do use it and just don't know abut it. It turns out that's almost exactly what's happening with `Timeout` in Ruby. [Why Ruby's Timeout is dangerous](https://jvns.ca/blog/2015/11/27/why-rubys-timeout-is-dangerous-and-thread-dot-raise-is-terrifying/)

It spawns up a new thread, sleeps the amount you want and when it wakes up it raises a `Timeout::Error`. If you've ever used [rack timeout](https://github.com/heroku/rack-timeout), (and recently I learned about [slowpoke](https://github.com/ankane/slowpoke) which also adds postgresql timeouts) it uses `Thread#raise` to kill an entire web request running in another thread.

Most of the time this isn't too awful. However when it goes bad it goes really bad. For example network connections such as Database connections might not be released properly. This could cause issues in your app or in your database. The exception may have happend in a place that puts the thread in an un-recoverable state. It's not dead so the webserver you're using thinks it can handle web requests, but maybe it's stuck and can't actually process those requests.

I work at Heroku and see this. When an app is getting millions of requests and some of them timeout, if something bad can go wrong it eventually will. Traditionally rubyists avoided this problem by throwing away a process and starting a new one. Killing a process is much safer than raising an exception in a thread. Unfortunately this is expensive to throw away an entire process every time there is a small timeout in your web request.

So right now people have to actively choose between not timing out requests which may cause a domino effect of web request backups, or between killing long running requests which may cause threads to be un-usable.

That's the state of the Ruby timeout and thread raising. Basically it's really scary but people do it anyway.

## So now what?

The behavior can't be removed, it's useful to some. The behavior can't be changed dramatically. However, what if we added new behavior to Ruby? I'm proposing a way to tell Ruby that we want to wait until an ensure block has finished before an exception is raised. Maybe something like

```
thread.safe_raise(exception: "no one expects another thread to raise an exception")
```

So if your code is in the middle of an ensure block

```ruby
ensure
  clean_up file_1
  # You are here <========================
  clean_up file_2
end
```

Ruby waits until it is finished before raising the new error:

```ruby
ensure
  clean_up file_1

  clean_up file_2
end

# Ensure is done, raise "no one expects another thread to raise an exception"  now <========================
```

The nice thing about this is that it guarantees our ensure blocks execute. The previous non-deterministic behavior is gone. What about the down sides? We could be deeply nested in ensure blocks, you would have to go all the way up the stack to see if you're fully out of an ensure block. This seems complicated and maybe that process isn't deterministic (thinking halting problem), but I don't know.

The other problem is that you can do slow things in the ensure block and if you're trying to raise a time critical exception such as shutting down a program you may actually want things to stop abruptly and not finish.

For that case, maybe add a timeout behavior to `safe_raise`

```ruby
thread.safe_raise(timeout: 3, exception: "no one expects another thread to raise an exception")
```

So we wait 3 seconds for the timeout to propagate, otherwise we raise where-ever in the code we are. So now we're back to square one in terms of non-deterministic error raising.

So if we have the same problem why do I think this would be better? Right now we have no choice but to raise an exception and pray for the best. If we had new APIs we would allow the developer more control over the behavior they desire.

Another option could be to allow a timeout handler to be registered, maybe if we know we're in a bad state, we want to term the whole process.

```
thread.safe_raise(timeout: 3, timeout_handler: -> { Process.kill('SIGKILL', Process.pid) }, exception: "#...")
```

The point is that we need more control over this behavior.

## Next Steps

So what do you think? Do you like it, hate it? Would you use an API like that? If I get some good responses I'll kick the can around and submit a feature request to Ruby.
