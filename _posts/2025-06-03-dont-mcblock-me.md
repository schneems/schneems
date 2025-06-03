---
title: "Don't McBlock me"
layout: post
published: true
date: 2025-06-03
permalink: /2025/06/03/dont-mcblock-me/
image_url: https://www.dropbox.com/scl/fi/onnglh20a6qles2b47iqa/Screenshot-2025-06-03-at-10.00.10-AM.png?rlkey=v1v6pcfhz81pqn6mz6bgfbv43&raw=1
categories:
    - culture
---

"That cannot be done." Is rarely true, but it's a phrase I've heard more and more from technical people without offering any rationale or further explanation. This tendency to use absolute language when making blocking statements reminded me of a useful "McDonald's rule" that I was introduced to many years ago when deciding where to eat with friends. It goes something like this:

If I say to a friend, "I'm hungry, let's go to McDonald's" (or wherever), they're not allowed to block me without making a counter-suggestion. They can't just say "No," they have to say something like "How about Arby's" instead. This simple rule changes the dynamic of the suggester/blocker to one of the proposer/counter-proposer. If someone is simply refusing to be involved, they McBlocked me.

In practice, though, it's hard to always have a suggestion you're willing to run with, so a relaxed version of the rule is that the other person has to AT LEAST specify why not. Instead of "no" it must be "no, because". For example, it could be "I had a burger for lunch" or "I'm banned for life after jumping on a table and demanding Szechuan dipping sauce." This helps show that you're not just blocking things, you understand the goal and want to move the conversation forward. It gives the other person something to work with. Easy for eats, but what about tech?

I work for Heroku, and recently, there was a [stack EOL](https://devcenter.heroku.com/changelog-items/3231) where customers were asked to migrate off of Ubuntu 20.04 (heroku-20). In this (many-month-long) deprecation process, I saw a lot of people make a lot of absolute statements. One of them was:

> "You cannot run Rails 4 on heroku-22."

Which, as you'll guess, is only half the story. What they meant was:

> "Rails 4.2 saw its [last release in 2020](https://rubygems.org/gems/rails/versions/4.2.11.3) and is quite thoroughly EOL. That version cannot run on any Ruby version 3.1. x- 3.4. x, which are present on heroku-22 or above, due to library errors. Therefore, to run Rails 4 on heroku-22, you would have to fork it and patch the security vulnerabilities yourself and update it to run on a modern Ruby version."

Which, to be fair, sounds a lot like "cannot be done," but with more words. But, as you'll also have likely guessed, once you know about the possible path forwards, however impractical, it might give you other ideas.

You might start asking questions like "if we have to fork and maintain it, anyone else would have to also, I wonder if someone else already did." This could send you down a quick search where you might discover that [Rails LTS](https://railslts.com/en) is a thing and basically provides a managed fork of Rails 4.2 for a fee that runs with the latest Ruby versions.

I wrote about the existence of this service previously:

- [Heroku blog: Migrating Your Ruby Apps to the Latest Stack](https://www.heroku.com/blog/migrating-ruby-apps-latest-stack/)
- [Reddit thread: On using an old Ruby version on a newer stack](https://www.reddit.com/r/Heroku/comments/1ij7b89/upgrading_ruby_versions_to_run_on_heroku24/)

Now, that new thing could still be a bad idea, and you might still not end up doing it, but the key here is that you're not saying "no," you're saying "here are the barriers I know about." A good way to test if you're just using more words to say "no" or not is if your statement is falsifiable or satisfiable in some way.

A "no, because" statement instead of a plain "no" moves the problem from a blocker into an opportunity. You can see this in a really good open source conversation. Instead of "this can't be done," someone can send a PR. Instead of "I won't merge your PR" they can comment: "I agree/disagree with the problem/opportunity you've raised, I'm uncomfortable merging this because of `<specific reason>`."

A quick story, and you can go. Before writing this post, I pitched the word-smithing of "McBlocker" to my wife at the dinner table (where you can tell we are very cool and fun people). My kids, age 7 and 9, were there. My 9 y/o asked me to take him to the library after dinner (did I mention how cool we are?), where I was talking to him about types of non-fiction that he might like. I was talking about biographies when he blurted out, "I don't like biographies." To which I responded, "Hey, don't McBlock me," and when I got a laugh of recognition in return, I figured the phrase was worth a blog post.

----
If you enjoyed this, you might enjoy my [service for helping people contribute to open source](https://www.codetriage.com/) (free) or my book [How to Open Source](https://howtoopensource.dev/) (paid). Now, go McRepost this to your favorite federated social network!
