---
layout: post
title: "Debugging a Memory Leak on Heroku"
date: 2015-10-13
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---


This is one of the most frequent questions I’m asked by Heroku Ruby customers: “How do I debug a memory leak?” Memory is important. If you don’t have enough of it, you’ll end up using swap memory and really slowing down your site. So what do you do when you think you’ve got a memory leak? What you’re most likely seeing is the normal memory behavior of a Ruby app. You probably don’t have a memory leak. We’ll work on fixing your memory problems in a minute, but we have to cover some basics first.

### [Keep Reading on Codeship Blog](https://blog.codeship.com/debugging-a-memory-leak-on-heroku/)
