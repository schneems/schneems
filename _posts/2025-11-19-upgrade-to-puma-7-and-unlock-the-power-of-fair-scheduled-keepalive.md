---
title: "Upgrade to Puma 7 and Unlock the Power of Fair Scheduled Keep-alive"
layout: post
published: true
date: 2025-11-05
permalink: /2025/11/05/upgrade-to-puma-7-and-unlock-the-power-of-fair-scheduled-keepalive/
categories:
    - ruby
---

Puma 7 is here, and that means your Ruby app is now keep-alive ready. This bug, which existed in Puma for years, caused one out of every 10 requests to take 10x longer by unfairly “cutting in line.”  In this post, I’ll cover how web servers work, what caused this bad behavior in Puma, and how it was fixed in Puma 7; specifically an architectural change recommended by MSP-Greg that was needed to address the issue.

Keep reading in the [Heroku blog post](https://www.heroku.com/blog/upgrade-to-puma-7-and-unlock-the-power-of-fair-scheduled-keep-alive/).

