---
layout: post
title: "Why is RubyGems Slow?"
date: '2015-04-10'
published: true
tags: debugging, ruby, performance
---

“Why exactly is RubyGems slow?” is the question that more than one developer has asked, but few have bothered to do anything about. Recently @mfazekas took up the task for profiling an especially slow case using dtrace. This resulted in several high profile pull requests to improve performance and drop memory allocations. These in turn lead me to ask the question, just what is Rubygems doing that takes so long? The short answer is, way more than you ever thought; for the long answer, keep reading.

<h2><a href="https://www.sitepoint.com/rubygems-slow/">Keep Reading on Sitepoint.com</a></h2>

Article covers RubyGem basics and a deep dive into internals.

