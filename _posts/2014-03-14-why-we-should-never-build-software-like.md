---
layout: post
title: "Why We Should (Absolutely Never) Build Software Like We Build Houses"
date: '2014-03-14'
published: true
tags: design, architecture, software, home building
---

I'm [building a house](http://helloschneeman.tumblr.com/) and I [write software](http://github.com/schneems) for a living. So when someone showed me the article [Why We Should Build Software Like We Build Houses](http://www.wired.com/opinion/2013/01/code-bugs-programming-why-we-need-specs/) I had to disagree.

## Building a House

I'm [renovating a 1905 house](http://helloschneeman.tumblr.com/), and true to the Author's word, it hasn't fallen down. But it did require foundation repairs, major systems upgrades, and updates. Houses aren't static, they move, they breath and if you simply build one and never touch it again, it won't make it past the 100-year mark.

In the software world, we build, test, and iterate quickly. Crafting a house, on the other hand, is a giant [waterfall](http://en.wikipedia.org/wiki/Waterfall_model) on a waterfall. Before you know where to put your walls, you have to know what kind of couch you want. It sounds like hyperbole, but there's little room to decide "as you go". If you find out you want a few inches of toe room for your toilet, it's hard to tear down your walls and re-route your plumbing, so you better get it right the first time. When it's finally time to pick light fixtures to give your house the finishing touch and you fall in love with a wall-mounted lights, too bad - all your receptacles are off the ceiling, installed way before drywall, texture, and paint.

The house building process leaves very little room for iteration. Feedback cycles are measured in weeks, sometimes months. Planning everything out and accounting for every use case right from the start is simply impossible. Now, this is true for both building software applications and building houses. But while being stuck with early, poorly informed decisions is a fact of life in house building, it fortunately doesn't have to be in software.

## The Better Way

Encouraging developers to write paragraphs before each method and "figuring out exactly what a method should do...its spec may be a paragraph or even a couple of pages"[[1]()] does not sound like the quickest nor the best way to get feedback. It's not even the best way to spec out a project.

While "Architects don’t make their blueprints out of bricks", developers can and do make blueprints with code. Coders have been known to leverage [Test driven development](http://en.wikipedia.org/wiki/Test-driven_development), [business driven development](http://en.wikipedia.org/wiki/Business-driven_development), and my personal favorite, [README driven development](http://tom.preston-werner.com/2010/08/23/readme-driven-development.html). These are all approaches to plan with code.

Code blueprints should be free from implementation details (as much as possible) and give high level feedback on the concept. In my [UT on Rails](http://www.schneems.com/ut-rails/) course, I have students write user stories to explain high level concepts behind what a visitor will see and do as they interact with your project. This type of a "blueprint" is a common and  easy way to introduce new developers to the design process. It's not a commitment to implementation or architecture. User stories guide a project, not dictate it. User stories are not waterfall.

I also encourage writing "specifications" which are somewhat different from "blueprints". Specs in Ruby are tests that can be run against your code to verify it does what you say it will. These are tied to the implementation, which means you should be willing to throw them away when your project scope changes, or if your implementation takes a different direction.

## Say "No" to Building Software Like We Build Houses

Every day as I work on my house, I wish it was more like writing software, not the other way around. On one end of the spectrum is coding with no design at all, on the other end we get waterfall. Both extremes are considered harmful. So what should you do?

Don't bury yourself beneath a mountain of metaphorical bricks before you start a project. Yes, put thought into your work. Yes, make mistakes fail early and often. Yes, change your blueprints to suit new understandings of the problem definition. But please, under no circumstances ever build a piece of software like you would build a house.