---
layout: post
title: "Nothing Lasts Forever: Symbol Collection in Ruby 2.2"
date: '2015-01-19'
published: true
tags: ruby, symbols, gc,
---

What is symbol GC and why should you care? Ruby 2.2 was just released and in addition to incremental GC, one of the other big features is [Symbol GC](https://bugs.ruby-lang.org/issues/9634). If you've been around the Ruby block, you've heard the term "symbol DoS". A symbol denial of service attack occurs when a system creates so many symbols that it runs out of memory. This is because, prior to Ruby 2.2, symbols lived forever. For example in Ruby 2.1:

<h2><a href="https://www.sitepoint.com/symbol-gc-ruby-2-2/">Keep Reading on Sitepoint.com</a></h2>

