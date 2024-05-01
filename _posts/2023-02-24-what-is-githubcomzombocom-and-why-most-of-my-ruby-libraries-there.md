---
title: "What is github.com/zombocom and why most of my Ruby libraries there?"
layout: post
published: true
date: 2023-02-24
permalink: /2023/02/24/what-is-githubcomzombocom-and-why-most-of-my-ruby-libraries-there/
categories:
    - ruby
---

The other day I got another question about the `zombocom` org on GitHub that prompted me to write this post. This org, [github.com/zombocom](https://github.com/zombocom), holds most all of my popular libraries). Why put them in a custom GitHub org, and why name it zombocom? Let's find out.

## Why a custom org?

If you're maintaining one or two libraries, keeping them in your GitHub user's namespace is easy enough. For me, this is [https://github.com/schneems](https://github.com). The zombocom org has 18 libraries, 16 of which I created.

I want to encourage people to contribute to my libraries, so I've taken to giving commit access to developers who land a successful PR. I still control releasing, so this permissive default is intended to allow developers with ambition to express themselves while giving me an opportunity to QA and chime in on changes.

I wanted to take this a step further and give them access to ALL my libraries to make it even easier to contribute. This strategy is time-consuming if my libraries are all under [github.com/schneems](https://github.com/schneems), so I moved them into a custom org name and called it a day.

## Why name it zombocom?

Making a custom org name is familiar for top-rated gems/libraries. For example, [github.com/puma](https://github.com/puma) or [github.com/CodeTriage](https://github.com/codetriage). My most popular library on zombocom is `get_process_mem` with 52 million downloads. But an org with that same name would be overly restrictive.

Custom orgs are usually named around a common theme. But my libraries don't have a shared theme aside from being a thing I wrote that hopefully makes your life easier.

I didn't want 16 namespaces for 16 libraries. I wanted a place where anything was possible. So I named it after [Zombo.com](https://zombo.com):

> Anything is possible at Zombocom. The infinite is possible at Zombocom. The unobtainable is unknown at Zombocom. Welcome to Zombocom

Another org inspired this move [github.com/sparklemotion](https://github.com/sparklemotion). This org was initially used for Nokogiri (the most popular XML/HTML parsing library for Ruby), and other libraries were added over time. The name is a joke from the movie Donnie Darko:

> Sometimes I Doubt Your Commitment To Sparkle Motion.

The Nokogiri library and the sparklemotion org were created by [Aaron Patterson, aka tenderlove](https://github.com/sparklemotion/nokogiri/commit/e7f98b6cb8e4b49da26aa3bd70f415fac2af5ac3). I asked him about it at a conference once, and he said he made it for similar reasons.

Some ask if I also made [Zombo.com](https://zombo.com), but the answer is no. I have nothing to do with that site and don't know who originally wrote it. The name is a tribute to a meme before memes. If the author ever wants to share my org name to put their website source, that would be fun. After all, anything is possible.

---

If you want to get started in open source, but need a helping hand, check out my (paid) book [How to Open Source](https://howtoopensource.dev) or (free) service [CodeTriage](https://www.codetriage.com)
