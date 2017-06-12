---
layout: post
title: Optimist's Guide to Pessimistic Library Versioning
subtitle:
date: 2016-04-18
published: true
author_name: Richard Schneeman
author_url: https://www.schneems.com
permalink: blogs/optimists-guide-pessimistic-library-versioning
---

Upgrading software is much harder than it could be. Modern versioning schemes and package managers have the
ability to help us upgrade much more than they do today.

Take for example my post on Upgrading to [Rails 5 Beta — The Hard Way](https://blog.heroku.com/archives/2016/1/22/rails-5-beta-upgrade). Most of the time was spent trying to find all the different libraries my app was using that weren’t compatible yet with Rails 5 and upgrade them.

What if somehow `bundle update rails` could have known they didn’t work and instead find a version that did work? It turns out that it can, but it requires some pain on the maintainer’s part.
In this post, we’ll look at different strategies for declaring dependencies in libraries, why one is dominant right now, and how we might be able to make major version bumps easier into the future.

## [Keep Reading on Codeship](https://blog.codeship.com/optimists-guide-pessimistic-library-versioning/)
