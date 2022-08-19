---
title: "Stopping the Death Spiral of Indecision"
layout: post
published: true
date: 2017-05-08
permalink: /2017/05/08/stopping-the-death-spiral-of-indecision/
categories:
    - ruby
---

Break things and move fast. Which things? How fast? What if we're stuck? A death spiral of indecision is when there's a problem everyone agrees that must be solved - But there's not one clear obvious winning answer. Today, I want to share an extremely effective technique I've used to make progress in these hairy situations.

I start out writing a clear problem statement. When I write, I imagine a new employee starting and having to get up to speed on the issue. Spending some time clearly identifying the exact problem (or problems) gets everyone on the same page. Don't skip this step.

After a problem statement, we'll need solutions. So many solutions. The goal here is to wrangle an impossible problem back to the land of possibility. List out every solution, no matter how good or bad. Remember, "not solving the problem" is always an option even if it's not the best.

Be clear in writing out your solutions. Depending on the level of the problem, you can put in implementation details. There should be very little ambiguity when reading a solution. Take a paragraph or two to explain it if you have to.

Now comes the most important part. List out the pros and the cons of each solution. Work hard here. There should be at least one pro and con per solution. The more leg work you put in here, the easier it will be later.

If you've got multiple related problems, start over at the beginning: write down problem statements and solutions. Label them with names and numbers so that you can reference one problem or solution from the other.

Here's an example for an issue that buildpacks currently face:

```
## Problem 1): Buildpack Ordering

When an app is deployed on Heroku using multiple buildpacks, each of those buildpacks can put executables on the disk, and they can also set the `PATH` via a `profile.d` script. Typically when setting a path you want to prepend to the PATH so that your values take precedence:

    export PATH="/my/values/here:$PATH"

The sourcing of the `profile.d` scripts is not consistent with the order that buildpacks get executed. Currently it is in **glob** order. This can cause issues if a later buildpack expects a former one to have set a value before it's `profile.d` script gets executed.

## 1) Solutions: Buildpack Ordering

### 1.a) Prepend a number before the scripts

Prepend a number before the scripts so `ruby.sh` would become `02_ruby.sh` if it’s the second buildpack to be run by codon.

**Pros:**
  - Easy
  - Robust
  - Requires no intervention from buildpack owners

**Cons:**
  - We can’t use kenneth's solution (listed below as 2.d) to problem 2 if we choose this solution
```

Granted there's more. There is another problem I'm trying to address (problem 2). I've labeled it informally "Kenneth's solution" as well as given it a specific number so someone less familiar can look it up.

> Don't be too concerned about this issue with script file ordering. It's not as big of a problem as it may seem, however, it's related to other problems I'm working on.

This document can now serve as a blueprint for future discussion. Instead of "how about we try X", new ideas must be written down in one place, and documented with caveats and citations. As often happens on many teams, different members or stakeholders may be less or more involved at different times. Having everything in one place allows someone to catch up after they've been gone for a vacation, or because they were out on sick leave. Even if the whole conversation is tabled for a week or a month, you don't have to re-build everything from scratch.

I know what you're thinking, "Schneems this is a lot of work, are you sure I need to do this?". Yes, it is a lot of work. You should probably avoid having to do this at all costs, but when you're left with no other options, writing down all your options in one space can help give you clarity. There are plenty of cases where not making progress is not an option. Later on if you have to answer the question "well did you consider <x>" and "well did you realize that this would impact <y>" you can point to a doc that says "yes, I did and it's still the best answer even if it's not perfect".

A real world example is when I worked on a huge Rails feature in 2014. I had to constantly re-justify decisions and logic, but it was pretty easy since I already had it written down [here's a link to the conversation and my problem statements](https://github.com/rails/rails/pull/13463#issuecomment-31480799).

Once you've got a doc template set up, try to get as many eyes on it as possible. Maybe someone generates a solution you didn't think of (extremely likely). Or maybe they spot new problems with a solution you've proposed (also likely). The idea here is that many heads are better than one. The purpose of the doc is to synchronize. If you put 20 people in a round raft and have them paddle, they will likely go in circles without any kind of collaboration. The document acts as a guide. It gets people pointed in the right direction and gives you a way to measure progress of different solutions.

Once you've got (what seems like) everything in one place, it's up to you to decide how to use the info. You could assign scores to different solutions. Don't just count pros and cons, some will certainly have greater importance than others. You may get lucky and by following the process, find a solution with all the pros and none of the major cons. You may have to cut your losses and choose a less than ideal solution, but hopefully this technique can help you pick the best-non-perfect solution.

A ProCon doc might not solve all your problems, but hopefully it will be enough to loosen your problem solving engine when it's seized up. It's a lightweight process that has worked wonders for me over the years. When your email threads start to drag on, or your issues go stale for weeks, it's a convenient tool to have in your back pocket.

- Pros: A ProCon doc helps unblock development discussions.
- Cons: It's not a magic bullet, also requires typing.

> 2022 update: I still use this technique to this day, however instead of listing pros and cons I now try to list consequences. This subtle change forces me to consider what would change divorced from my judgment of the change. I can still use language to indicate my views but one persons pro might be another's con. Here's a [real world example of using this type of decision document in an open source issue](https://github.com/buildpacks/lifecycle/issues/884#issuecomment-1191800955). I find this change impacts even interactions at work with product managers. Iused to say "we can't do this" which is absolutist and hadds no value. I've found it's much more helpful to instead say "here are the consequences if we did that."
