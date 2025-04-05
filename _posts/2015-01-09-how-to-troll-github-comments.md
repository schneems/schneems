---
layout: post
title: "How (Not) to Troll GitHub Comments"
date: '2015-01-09 08:00:00'
published: true
tags: github, comments, community, open source, oss, discussion, troll
---
Trolling is horrible and counter-productive; however, we can learn what NOT to do, by asking what a troll would write. Who am I to talk about trolling github comments? I wrote an app, which helps thousands of people get more visibility into open source discussions, so they can make better comments and help out. The service is called CodeTriage and [it sends community issues right to your inbox.](https://www.codetriage.com/rails/rails). Essentially, I read a lot of Github issues and comments. Time to pay the troll toll.

## Feelings, not Facts

> **Troll:** Why bother stating easy to understand facts? You can save a ton of time by not providing any numbers, references, or other factual information when writing a troll comment. Instead, use phrases like "I think", "I believe" and "I bet". This way you never have to actually back up your statements. Use vague terms like "lots" and "huge" without specific comparisons. ![:trollface:](https://www.dropbox.com/s/kx9d3in03mfux74/Screenshot%202014-12-31%2010.49.16.png?raw=1)

**Instead:** Give numbers and references when all possible 5 lines of code might not be a "huge" PR to Rails, but if your library is only 10 lines, it would be adding 50% more code. Quantify your feelings.

"You said that this is adding technical debt. I disagree, you can see that the number of methods is being cut in half (71.0 / 176 #=> 0.40 ), and we're removing a dependency."

It's important to explain how you got the numbers. List out bench-marking methods or code snippets. If no one else can get the same results, maybe you made a mistake. Treat this like a peer review in a scientific journal. Whether you're numbers are right or wrong, you'll learn something by posting them and having others investigate.

## Assume everyone already knows everything.

> **Troll:** If you see "bad" code, the only way you can make sure you'll rid the world of the vermin who wrote it is to make fun of them as brutally as possible. Your comments better be snarky and sarcastic. Explain nothing, just tell everyone that what they're doing is wrong. Bonus points if you can make your opponent softly cry into their crappy non-mechanical keyboard ![:trollface:](https://www.dropbox.com/s/kx9d3in03mfux74/Screenshot%202014-12-31%2010.49.16.png?raw=1)

**Instead:** Treat everyone as though they're new, or at least new to the info you're bringing to the table. Not everyone knows how the law of demeter applies to a doubly-linked-red-black-big-O-notation-dynamically-interpreted-state-machines like you do. Use logic and information to show someone why something may be a bad idea, instead of simply stating so-called "facts".  Try to direct people to resources whenever possible.

The first time I ever got on IRC, I asked a question about <Software A> in a room devoted to <Software B> that I had mistakenly thought were related. The response was quick and snarky - "You might as well be asking questions about beach volleyball, what a <stupid | bad | horrible | idiotic> question". After that, I never went back on IRC. It wouldn't have taken much to say "this isn't the best place to ask that question, try in the #<Software A>-room". Remember that something is new to everyone. You were even a newb once. Before you hit submit, ask yourself if your <number> years younger self would have found your comment helpful or degrading. Save the snark for your YouTube comments.

## Make it an argument, not a conversation

> **Troll:** Comments aren't meant to be productive, they're all about proving you're right and everyone else is wrong. The internet will laugh at everyone else and throw you up on their shoulders after you humiliate and demean your opponents...erm, I mean 'collaborators'. Everyone knows not to read the comments on blogs, so why read the prior comments on an issue? You'll just waste time. No one will mind re-arguing a dead point. Promise. ![:trollface:](https://www.dropbox.com/s/kx9d3in03mfux74/Screenshot%202014-12-31%2010.49.16.png?raw=1)

**Instead:** Make it a conversation. It's not about being right, but rather moving the community and code forwards. If someone points out why your statement was invalid, thank them. You just learned something, and the world got collectively smarter. If you didn't understand their critique of your statement(s), ask for more information. Not listening, or repeating the same argument over and over, or throwing a 'hissy fit' isn't going to solve anything. If you believe they misunderstood you or your point, tell them what you agree with and what you need to clarify. Again, stay away from emotional arguments or attacks. Use facts and supporting evidence when possible.

Did I mention that not all commenters are native English speakers? If the statements are very curt, consider that they don't understand how to wrap it up in a nice package for you. Don't take short statements defensively. If you were hurt by a comment you considered below the belt, let the commenter know via a private email or message; don't go in attacking. Tell them what they did that might be seen as harmful, offensive, or otherwise bad. Tell them how it made you feel and provide an alternative. If someone is a repeat offender and is obviously trying to troll you, call them out in public, but again, please be respectful. The only way to win the troll game is to take the high road.

## Attack the people, ignore the code

> **Troll:** Can't think of a good reason why your code example is better, but you're TOTALLY sure. Attack the person writing that code, "What kind of idiotic numbskull writes code like that?" or "I see the person making the changes focused on one [trade off]". People may agree with the other person's code, however once you annihilate their personal character, everyone will have to agree with you. ![:trollface:](https://www.dropbox.com/s/kx9d3in03mfux74/Screenshot%202014-12-31%2010.49.16.png?raw=1)


**Instead:** Stick to the facts. Name calling is only appropriate in politics and second grade (both arguably at similar levels of intellect). Adults work on open source and even if the person you're talking to can't legally drink or is 10 years your junior, they deserve respect. I've been beating this drum pretty hard so far, and hopefully you'll hear that rhythm next time you're typing out a comment.

The hardest part here for me is unintentionally making someone feel bad. Quite a few pull requests (PRs) come in that must be closed, and for many people it's their first attempt to reach out and communicate via code. I'm always thankful of any PR that comes in regardless of merge status. It takes a bit more time, but I always try to [write a thoughtful response and always be appreciative](https://github.com/schneems/wicked/pull/145#issuecomment-67085880).

## In all seriousness

Open source is funded on a currency of <3's. It's done mostly by people for free, and in their free time. Even if you're commenting on a private project at your company, it doesn't give you license to be a jerk because the other person is getting paid. The point of being a troll is to get a reaction from people. Trolls want to be heard and not listen. When people behave this way in open source, they don't win. Instead they make the whole community worse for everyone. Besides wasting precious cycles responding and acknowledging troll behavior, it increases burnout in maintainers. Many people don't even realize when they slip into these patterns. You might be trolling by accident without even knowing it. All I'm asking is that you take two seconds before you hit submit and re-read your comments. Only you can prevent comment trolling.

---
Friends don't let friends Troll, send this article to a friend and receive imaginary internet karma [@schneems](https://ruby.social/@Schneems).
