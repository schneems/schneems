---
title: "How to \"Sustain Heroku\""
layout: post
published: true
date: 2026-03-01
permalink: /2026/03/01/how-to-sustain-heroku/
image_url: https://www.dropbox.com/scl/fi/4xz9bl3g1bvrr4kxif2yc/Screenshot-2026-02-28-at-9.17.09-AM.png?rlkey=4uc09udxmopa72xrbngvcijy6&raw=1
categories:
    - ruby
    - heroku
---

This is a personal essay (I speak for me and my views, not for my employer) about what exactly a ["Sustaining Engineering Model"](https://www.heroku.com/blog/an-update-on-heroku/) is, in the context of the recent Heroku announcement, and the book "The Innovator's Dilemma," as seen by someone who has worked at the company for the past 14 years.

I was listening to "The Nvidia Way" recently, as recommended by "Oxide and Friends" [Books in the Box](https://oxide-and-friends.transistor.fm/episodes/books-in-the-box-v) episode. It mentions "The Innovator's Dilemma" a LOT. So I picked up that audiobook too. I was surprised to find out that the forward (of this edition) of The Innovator's Dilemma was written by Marc Benioff, CEO of Salesforce (which has owned and operated Heroku since 2011).

I'm still working through the book, but some of the terminology we're now being thrust into seems to come from the book. A "sustaining" business. [https://online.hbs.edu/blog/post/sustaining-vs-disruptive-innovation](https://online.hbs.edu/blog/post/sustaining-vs-disruptive-innovation). In that context, "sustaining" isn't a bad thing; it's basically short for "predictable." If you're in the business of selling hammers, there are incremental improvements to materials or processes. You can find efficiency through forecasting and prior market knowledge. But it's not a market where new upstarts are coming in with radically different things and taking over.

When I worked for GE as an intern in their Appliance Park (made refrigerators, etc.) there was an organizational strategy for delivering new products to market (such as French door refrigerators, or meeting new energy-star guidelines). It was called NPI (New Product Introduction), where those engineers got good at optimizing for speed of delivery to the market. And another org called PCTO (Product Cost Take Out), where they would take products already delivered and find ways to increase the margins on them (like using a cheaper compressor in exchange for more expensive insulation if that allowed you to still meet regulation and energy-star targets).

Even in such an old field as home appliances, there's still work to be done. There are still competitive edges to be found and optimized. To me, that's an example of a sustaining business.

No GE intern wanted to work in PCTO. It wasn't "cool" or "glamorous." But it's the bulk of the work. It's how the company stays competitive. It would have been "better" to "design it right the first time," but that would lead to longer product introduction cycles, which not only means your competitors deliver before you, but it also means they're learning what works and what doesn't before you. The PCTO org brought value not just by having a cost-competitive product. It is also what enabled NPI to exist at all.

When I hear Heroku say it is moving to a ["sustaining" engineering model](https://www.heroku.com/blog/an-update-on-heroku/), it doesn't mean features stop. Heck, the first commercial fridge was introduced in 1913, and we're still finding ways to add bells and whistles, like the water pitcher in the door and quad-door design of my most recent fridge. But those innovations aren't disruptive; they're iterative and relatively predictable. Those innovations are only possible because [worse is better](https://en.wikipedia.org/wiki/Worse_is_better). i.e., GE figured out what mattered (shipping fast is more important than perfect), but it did it in a way that it didn't stop there, once it's shipped, it's shipped again over and over until the kinks are worked out and the margins are competitive.

## Sustaining is Focus and Predictable Growth

In "The Innovator's Dilemma," a "sustaining" innovation would be increasing the density of iron on a disk platter to achieve incrementally more storage density or going from one spindle to two. A "disruptive" technology would be the digital camera. It originally produced worse images than film and was very expensive. Kodak didn't invest in it because it didn't give their current customers what they needed. By the time digital cameras disrupted the film camera industry, Kodak was too late to make a difference.

In the context of Heroku, a transition to a "sustaining engineering model" means (to me) we've got to examine our [sacred cows](https://en.wikipedia.org/wiki/Sacred_cow_\(idiom\)) and focus on the most important pieces of the company. Some of this is a continuation of what we were already doing. There's already been a push for toil reduction and increased automation. In my personal role, I want to move building Ruby binaries to be a completely automated process (right now it is semi-automated), with a balance between speed and automation, and security via checksum validation. This is an engineering investment in engineering. Spending hours now to save minutes for a thing that is predictable and recurring will not only free me up to work on other automations, but it will also reduce interruptions and toil. Previously, this was on the roadmap, but it's been a lower priority. Other teams have other examples. For example, [Next Generation Postgres](https://www.heroku.com/blog/introducing-the-next-generation-of-heroku-postgres/) is already in pilot and still moving ahead.

To me, "sustaining" means "focus." Focus inward on what we're doing today and what our customers need today. It might mean missing out on disruptive changes, but focusing on what the "next big thing" could be can cause you to miss out on the incremental progress improvements right in front of your nose.

More doesn't always mean better. More processes, more ways to track work, and more inboxes to check all slow us down. Less doesn't always mean worse. Sustaining isn't just keeping lights on. It's keeping your product and your customers nourished, sustained, not frozen in time or starved. When Heroku first came out, it was a mind-blowing, disruptive change from how people spun up servers before it. Sustaining means aligning on what not to do, beyond just what we would like to do. We can't afford to be fat and lazy. We can't afford to aim for 100% in 100% of everything we do. Frankly, that model wasn't serving our customers very well.
