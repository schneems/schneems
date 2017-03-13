---
title: "Puma, Ports, and Polish"
layout: post
published: true
date: 2017-03-13
permalink: /2017/03/13/puma-ports-and-polish/
categories:
    - ruby
---

Polish is what distinguishes good software from great software. When you use an app or code that clearly cares about the edge cases and how all the pieces work together, it __feels__ right. Unfortunately, this is the part of the software that most often gets overlooked, in favor of more features or more time on another project. Recently, I had the opportunity to work on an integration between Rails and Puma and I wanted to share that experience in the context of polish and what it takes to make open source work.

## The problem

Puma has been the default web server in Rails for about a year now and most things just work™. I talked about [some of my previous problems and efforts to get this to work here](https://blog.heroku.com/container_ready_rails_5). When you run `rails server` with Rails 5+, it uses Puma through an interface called a Rack Handler. Lots of different web servers such as `thin` also implement a Rack handler allowing Rails to boot the server without having to know anything about the web server. For example, Rails pass a default port of `3000` to the server.

Part of my previous work for getting Puma to play nice with Rails out of the box involved getting Puma's Rack handler to auto read in config files by default (i.e. `config/puma.rb`). This way, we can generate a config file that works with Rails and Puma and doesn't need any special knowledge of what framework it is running. One of the biggest points was the number of threads in Puma cannot exceed the number of connections in the Active Record connection pool. This works great, but we did run into another slight issue with the config and port. If you remember, I said Rails defaults to port `3000` but we can change this value inside our `config/puma.rb` using the `port` DSL:

```
port ENV.fetch("PORT") { 4000 }
```

So if you boot your app using `rails server` and you don't specify a `PORT` environment variable you would expect this to connect to port `4000` but instead it connects to `3000`. That's the problem.

While this is a bug, it's a pretty inconsequential bug. If you boot with `rails server -p 4000` it works or if you boot with `PORT=4000 rails server` it also works, or if you use `puma -C config/puma.rb`, it works. Just in that one specific case does it fails. That's what I mean by polish. The software has a bug, but it's not mission critical. In fact, it functions very well without that bug being fixed and many people will never hit it. However, when you do hit this bug it's very confusing.

## Frustration

User frustration comes when things do not behave as you expect them to. You pull out your car key, stick it in the ignition, turn it...and nothing happens. While you might be upset that your car is dead (again), you're also frustrated that what you predicted would happen didn't. As humans we build up stories to simplify our lives, we don't need to know the complex set of steps in a car's ignition system so instead, "the key starts the car" is what we've come to expect. Software is no different. People develop mental models, for instance, "the port configuration in the file should win" and when it doesn't happen or worse happens inconsistently it's painful.

I've previously called these types of moments papercuts. They're not life threatening and may not even be mission critical but they are much more painful than they should be. Often these issues force you to stop what you're doing and either investigate the root cause of the rogue behavior or at bare minimum abandon your thought process and try something new.

When we say something is "polished" it means that it is free from sharp edges, even the small ones. I view polished software to be ones that are mostly free from frustration. They do what you expect them to and are consistent.

We like to think that most software we write is free from bugs, but it really just means it's free from bugs we care about. Each bug that gets fixed has a cost both the time spent fixing the bug and the opportunity cost of other features we could be implementing. When it comes down to it, most programmers and organizations don't, can't or won't invest in polishing their product.

## Puma Port Problems Put Right

Let's go back to Puma. This bug has been known for almost a year. Between the [time it was reported](https://github.com/rails/rails/issues/24435) and [fixed](https://github.com/rails/rails/pull/28137), nearly 4,000 tickets had been filed against Rails.

While the bug was easy to reason about, the fix was not. It involved coordination with Rails and Puma and a fairly aggressive refactoring inside of the Puma codebase of how the configuration is stored and loaded. All in all, it took me maybe about 12 hours of dev time to get everything working.

On the Puma side, there are 3 different ways configuration can be applied either directly from a user like `puma -p 4000` or via a config file like we saw earlier, or via its own internal defaults. When booting a server through the Puma CLI, you always want the explicitly user-configured options to "win" over any static config in a file. But you want a configuration specified in the file to "win" over any defaults.

The root of the issue is that the Rack handler has no way of communicating what values are specified as a default i.e. Rails specifies `3000` as a port, versus an explicit value such as `rails server -p 4000`. So when Puma got the value of `3000` it had to assume that it was being explicitly defined by the user, so even if the `config/puma.rb` specified a different port I had to ignore it.

The fix was to record when we are receiving an explicitly user set value and record this in an array `user_supplied_options = [:Port]`. Then in Puma, we can apply the configuration values differently depending on if they've been explicitly set via a user or merely passed in as a default. While this sounds straightforward, it required a major re-tooling of how config is set and stored internally in Puma.

I wanted to write about this fix not because it's big and important, but because it's small. I get asked semi-regularly about the big "show stopper" features coming in \<language\> or \<framework\> and while these kinds of things can be exciting, they're not the bulk of work that goes into polished software. Even for those big features are made up of dozens or hundreds of tiny bug fixes.

In many ways I want my software to be boring. I want it to harbor few suprises. I want to feel like I understand and connect with it at a deep level and that I'm not constantly being caught off guard by frustrating, time stealing, papercuts.

