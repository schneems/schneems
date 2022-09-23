---
layout: post
title: 'Prepare, Do, Test: Make your Technical Writing Shine'
date: '2013-09-05T10:00:46-05:00'
tags:
- writing
permalink: /post/60359275700/prepare-do-test-make-your-technical-writing-shine
---

Don't pump and dump information on your readers: build better community and better view numbers by following the **Prepare**, **Do**, **Test** pattern.

Let's back up. If you're new to my site: I've been teaching [Rails courses for a few years](https://www.schneems.com/ut-rails), and I work with a [ton of open source](https://github.com/schneems?tab=activity), and I generally get a kick out of explaining things to people.

I've written for [Rubysource](https://www.sitepoint.com/author/rschneeman/), my own blog, and a fair bit of Heroku's devcenter documentation. When writing for a technical audience, I cringe when I get a comment that says, "I'm stuck", or "did it work?" and especially "what do I do next?".

To solve these problems and more, I follow this framework:

## Prepare

Introduce the reader to what they will be doing at a high level and what they can expect in the end.

It sounds simple, but many articles just jump into the "how" and completely forget the "why". If you don't know what to write: try giving your article to someone new to that subject and writing down all the questions they ask as they go through the exercise.

See if you can answer those questions in the article before they even need to ask them. I usually do this for the whole document (see my ["what"](https://github.com/centerforstudents/ruby_view_server#what) section in the Ruby View Server Exercise</a>), and I also do this before individual exercise "todo's" (such as in <a href="https://github.com/centerforstudents/ruby_view_server#3-use-a-layout-to-add-content-to-all-pages">"Using a Layout to add content to all Pages"</a>).

Once they know where they're going, send them on their way.

## Do

This one is simple: give the user the directions you want them to follow. Focus on **context, consistency, and completeness**.

Should the student type those words in a text editor or the terminal? A little consistency goes a long way. I always make sure to preface all commands that go in the terminal with a <code>$</code>. I make sure that the user knows this by adding a disclaimer to most <a href="https://github.com/centerforstudents/ruby_view_server#what">tutorials on my site</a>:

>  All code that starts with a $ indicates it is running in the terminal. You should not copy the $.

The **best way to see if your writing worked is to give them to a real live person**.

Ideally, you'll give it to 20 people. Suppose one of them is tripped up by an unstated convention or inconsistent marking or command. In that case, others will likely have the same problem. It's okay not to re-hash Comp-Sci 101 in every tutorial, but know your target audience's skill level and write accordingly. Put any assumptions or prerequisites early in your writing.

## Test

The most important and most commonly missed step in technical writing is the test step**.

Did the command your student just run work? How are they supposed to know?

This section is where you give your student the tools to verify they did everything correctly. Give them the output they should expect. Or have them run an extra command to verify things were done successfully.

Here's an example: I recently attended a <a href="https://railsgirls.com">Rails Girls</a> session in Austin and got fed up of students accidentally running <code>mkdir</code> in the wrong directory.

So instead of just giving them the command they're <a href="https://github.com/railsgirls/railsgirls.github.com/commit/9c4cb24e248ee05a361c6cc78d05301be6a62e0b">now asked to verify using <code>ls</code> or <code>dir</code></a> after they run the command.

Not only does this answer the question, "did it work?" It lets them know something has gone wrong before getting lost in the next step.

## Outcome

Writing tutorials and technical docs with a test at each step give your readers the context you're writing about. It has the nice side effect of sharing your workflow.

As you write using this pattern, you may find that you actually develop in a similar flow. You have a goal, make a change, and then test to see if the change took effect. When you tell your readers how to check their work, you're giving them insight into how they can do the same. With all those benefits, there are a few downsides.

## It takes Longer

Writing this way takes longer, and there doesn't ever seem to be enough time.

Sometimes taking longer is a good thing. Ernest Hemingway famously <a href="https://www.openculture.com/2013/02/seven_tips_from_ernest_hemingway_on_how_to_write_fiction.html">wrote using a pencil</a> instead of a typewriter because it slowed his process and forced him to review his work.

Meditate on your workflow. Sometimes you find a quick hack you want to share, but taking your time to write about a topic in-depth helps solidify it in your mind and can be reflective.

## It Might Be an Overshare

Writing in this lockstep of "do" and "test" can be tiresome for senior developers.

When I wrote about my experience getting mruby running on my machine for Rubysource, some comments were complaining <a href="https://www.sitepoint.com/try-mruby-today/#comment-7032">that I spent too long explaining trivial details</a>.

Indeed, you cannot always please all people, so I choose to be inclusive in my writing.

Senior developers can quickly skim my articles and skip the "test" steps they already know. The opposite cannot be said for newer developers.

You cannot write a terse article without explanation and expect them to just "get it" 100% of the time.

In that same article, I got the comment <a href="https://www.sitepoint.com/try-mruby-today/#comment-7031">"This post is a true work of love! The average layman thanks you."</a>. I find for every comment that says "this article is too verbose" comment, I get a dozen "thanks, I've struggled with this forever" messages.

## Technical Writing

Is a skill that takes time to cultivate. I learn new things every time I write markdown.

If you don't write technical stuff: start practicing now for when you need it later. If you are following an open source guide such as Railsgirls, consider adding checksums or tests that will help catch problems without extra assistance.

The best way to prove any technical writing is to try it out on someone new to that topic. You can find these people in user groups and meetups, or if you're fortunate, you might find you're <a href="https://rubyandrichard.tumblr.com/">married to them</a>.

Thanks for following along and next time you write technical material don't forget **Prepare**, **Do**, and **Test**.

<hr>Thanks for reading, if you liked these tips follow <a href="https://twitter.com/schneems">@schneems</a> on twitter or ~~tumblr~~.
