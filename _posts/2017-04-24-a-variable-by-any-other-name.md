---
title: "A Variable By any Other Name"
layout: post
published: true
date: 2017-04-24
permalink: /2017/04/24/a-variable-by-any-other-name/
categories:
    - ruby
---

Sometimes when you do everything right, things still go wrong. I previously [talked about how bad I am at spelling and grammar in "The Four Year Typo"](https://www.schneems.com/2017/04/19/the-four-year-typo/), which reminded me of my first major production failure at Heroku.

Here's the setup. We have a service that builds apps. You don't need to know this, but it's called "codon". This is the service that runs the buildpacks such as the one I currently maintain, the [Heroku Ruby Buildpack](github.com/heroku/heroku-buildpack-ruby). Believe it or not, when I started we had no production monitoring of build failures. If we so much as hiccup, Twitter tends to catch on fire and our support tickets come in like a tsunami, so there wasn't a huge need. However, the faster we can find out about failures the faster we can fix them and the fewer people who are impacted. Also, when you're deploying as many apps as we are, a one-in-a-million bug occurs a non-trivial number of times. So, we really have to be on top of things. One day I made a change to a buildpack that caused one of those one-in-a-million bugs to be exposed in Bundler, but because it wasn't a major system meltdown, we didn't really hear anything about it. While that is a bug, it's not the one I'm writing about.

The bug I introduced came later, as a remediation for this bug. We decided we should set up error alerting and monitoring for language specific build failures (where before, they were system wide). To do this we already had a script that was aggregating failures, I just needed to modify it to log language failures. The reporting system worked like this, you created a hash and assigned values from a database to it:

```ruby
guages = {}
guages["my.key"] = value_from_database
```

Later this got serialized and sent to a collection service. I refactored a bit of the logging and alerting code to DRY it up. I introduced a block that we could call with different metrics:

```ruby
POST_GAUGES.call(gauges)
```

Then later I added my metrics

```ruby
gauges = {}
gauges["my.new.key"] = value_from_database
```

If you've got a keen eye, you might notice what I didn't. The original code was misspelled `guages` instead of `gauges`. This code worked for ages because it was consistently misspelled all over the method. No, I didn't write the original code.

Using a different variable name would normally have raised an error, but due to the way the code was structured, we were creating the same variable multiple times to send multiple batches of metrics, or at least it used to be setting the same variable. Instead it was accidentally sending the same variable multiple times `gauges` instead of `guages`. Devoid of any other context it kinda looked like this:

```ruby
gauges = {}
gauges["my.new.key"] = value_from_database
POST_GAUGES.call(gauges)

# ...

guages = {}
guages["my.key"] = value_from_database
POST_GAUGES.call(gauges)
```

When we deployed the code, my metrics reporting was working, but all of our build fleet started reporting zero builds. In the words of a former governor and Dancing with the Stars contestant, who somehow "runs" the Department of Energy:

> "Oops"

We found the issue and fixed it up, but for awhile it was a head scratcher. This went through a code review and no one caught it. I was technically "right" when I spelled the variable correctly, but simultaneously "wrong" because it wasn't consistent.

This just goes to show that consistency can be a powerful tool. In the face of a major mistake, misspelling the variable, consistency saved the day with the original code and provided smooth operation until someone came along and broke the consistency. With such a powerful tool we can use it for good or evil.

Could consistency have saved this bug from going into production too? Had I consistently broken each of the metric generation pieces into its own method, that would have prevented a `gauges` variable from being in scope when the original code was expecting `guages`. This would have raised an error and lead to detection in development instead of production. While often we might look at "best practices" as somewhat arcane rules, having a baseline of consistency can help write code that is easier to read and more bug free.

If you liked this bug journey, you might also enjoy my talk about the process of testing the Heroku Ruby Buildpack and lessons learned from testing non-deterministic systems, watch [Testing the Untestable](https://www.youtube.com/watch?v=QHMKIHkY1nM).
