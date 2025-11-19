---
title: "Learn How to Lower Heroku Dyno Latency through Persistent Connections (Keep-alive)"
layout: post
published: true
date: 2025-11-04
permalink: /2025/11/04/learn-how-to-lower-heroku-dyno-latency-through-persistent-connections-keepalive/
categories:
    - ruby
    - http
---

Before the latest improvements to the Heroku Router, every connection between the router and your application dyno risked incurring the latency penalty of a TCP slow start. To understand why this is a performance bottleneck for modern web applications, we must look at the fundamentals of the Transmission Control Protocol (TCP) and its history with HTTP.

Keep reading in the [heroku blog post](https://www.heroku.com/blog/learn-how-to-lower-heroku-dyno-latency-keep-alive/).

