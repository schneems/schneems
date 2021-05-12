---
title: "The room where it happens: How Rails gets made"
layout: post
published: true
date: 2021-05-12
permalink: /2021/05/12/the-room-where-it-happens-how-rails-gets-made/
image_url: https://www.dropbox.com/s/bkzho8h2jm44h0f/Screen%20Shot%202021-05-12%20at%2011.17.54%20AM.png?raw=1

categories:
    - ruby
    - rails
    - basecamp
---

Today I'm going to share my perspective on how Ruby on Rails is developed and governed and how I feel the Basecamp "incident" impacts the future of Rails. I'm going to start out telling you what I know for sure, dip into some unknowns, and dive into some hypotheticals for fun.

First off, who am I? Find me [@schneems](https://www.twitter.com/schneems) on Twitter and GitHub. I first contributed to Ruby on Rails ten years ago in 2011, and I'm in the top 50 contributors (by commits). I help maintain a few open source projects, including Puma and the Ruby Buildpack for Heroku (my day job). I've got  1,611,289,709 and counting gem [downloads to my name](https://rubygems.org/profiles/schneems).

In the Ruby on Rails ecosystem, I am known as a "contributor". In Rails speak, that means that I also have commit access to the project.

> Note "getting commit" means that the person can merge PRs, close issues, and (depending on configuration) push to the main branch.

## The Basecamp incident

The reason I'm bringing this all up is that the Rails world has been reeling. DHH is not only the creator of Rails but also the Co-Founder of Basecamp. Basecamp has been in the news a lot after having ~1/3 of their employees quit. Many have also asked about Rail's governance. To bring you up to speed on the loose timeline of the Basecamp news:

- [Jason Fried made a highly criticized blog post](https://world.hey.com/jason/changes-at-basecamp-7f32afc5)
- [DHH doubled down](https://world.hey.com/dhh/basecamp-s-new-etiquette-regarding-societal-politics-at-work-b44bef69)
- [Then again](https://world.hey.com/dhh/mosaics-of-positions-ae6d4d9e)
- [Then Casey Newton broke the story of the events that lead to that seemingly-out-of-nowhere series of posts](https://www.platformer.news/p/-what-really-happened-at-basecamp)
- [DHH Responded to the story](https://world.hey.com/dhh/let-it-all-out-78485e8e)
- [The week ended with over 1/3 of Basecamp Employees quitting](https://twitter.com/_breeeeen_/status/1388198260603506693)
- [Then Casey posted again with some more details of an interaction with Ryan Singer the day most employees left](https://www.platformer.news/p/-how-basecamp-blew-up)

It's hard to fully capture the response of the Twitterverse to the original announcements and news. A few voices of opposition were louder on my timeline than others and I wanted to share them for additional context:

- [Kim Crayton](https://twitter.com/KimCrayton1)
  - [Apr 26 Twitter thread](https://twitter.com/KimCrayton1/status/1386837814202052612)
  - [Apr 28 tweet](https://twitter.com/KimCrayton1/status/1387419490560978951)
  - [Apr 30 tweet](https://twitter.com/KimCrayton1/status/1388144198851891200)
  - [May 1 tweet and video link](https://twitter.com/KimCrayton1/status/1388552534713905152)
  - [May 4 thread](https://twitter.com/KimCrayton1/status/1389518660427997185)
- [John Breen](https://twitter.com/_breeeeen_)
  - [Blog post response](https://breen.tech/post/cringe-camp/)
  - [Twitter thread following people leaving Basecamp](https://twitter.com/_breeeeen_/status/1388198260603506693)
- [Emily Pothast](https://twitter.com/emilypothast)
  - ["The Pyramid of Hate that brought down Basecamp"](https://marker.medium.com/the-pyramid-of-hate-that-brought-down-basecamp-838b63ca27e)

## Basecamp concerns hit Rails

To many, DHH is the face of Rails. DHH created Rails, he holds the Rails trademark, and he keynotes at RailsConf every year. When Basecamp news hit Twitter, concern became increasingly apparent with this [Rails forum thread on Discuss](https://discuss.rubyonrails.org/t/effect-of-the-last-week-on-ruby-on-rails/77702) that many people are worried about how the situation unfolding with Basecamp will affect Rails. The new word of the day was "governance".

Basically, to most people, "how rails gets made" is a mystery box. That concern triggered Rails Core drafting and publishing [a Rails Governance blog post](https://weblog.rubyonrails.org/2021/5/2/rails-governance/) which lists out who exactly is on Rails Core (helpful) and states that they operate through "consensus".

Many people responded to the blog post. One that popped up on my timeline was [Steve Klabnick's "My "the project isn't run by one person or company" T-shirt sure is raising a lot of questions answered by my shirt" tweet](https://twitter.com/steveklabnik/status/1388954169936171020).

I interacted with that thread a bit, ultimately leading to this point where I'm now typing up a blog post.

## How does someone get commit access to Rails?

I will start with how I got commit access. I wrote a script that emails me a Rails issue a day. I read the issues as they came in, learned from them, and eventually started commenting. My "issue triage" efforts were noticed, and I was invited to the "issue team". In this process, I was granted commit to the project and given access to the #contributor Basecamp instance where chat happens.

> I eventually turned that script into a service named [CodeTriage](https://www.codetriage.com)

I've been around when others have been added as contributors. Generally, someone in the #contributors channel mentions they've noticed that a particular developer is helping a lot. They then suggest that we invite them to become a "contributor". Usually, by that time, many in the #contributors' room know this developer and agree to the addition. I don't think I've ever seen someone be brought up for commit and get rejected, though I can't guarantee it's never happened. As far as I know, there's not a formal process, and anyone in the #contributors channel could suggest/request someone else to be added.

In short, it comes down to this: A developer gets commit access to Rails after doing a significant amount of work on the project and is independently recognized or asked for commit access.

I don't know if there are more formal criteria for getting access. I've been told that most activity happens in #contributors (as opposed to #core), and I'm inclined to believe there's not much more to the process.

## Rails Contributors vs. Rails Core

In addition to #contributors, developers can also become a member of "Rails Core". While I took ownership of a significant Rails dependency (Sprockets, which frankly needs yet another new owner), I am not in Rails Core.

What does "Rails Core" mean if it doesn't mean "commit"? This point is tricky and perhaps a bit subtle. It's not written down anywhere. I've learned via trial and error and observation. One significant differentiator is that Rails Core members have release access to Rails itself. While I can cut a release of Sprockets, I do not have access to Rails/Railties/ActiveRecord, etc. The other big thing is seniority/authority/ownership.

Different Rails Core members seem to own different parts of the framework. Some more obviously than others. For instance, [Xavier Nora](https://twitter.com/fxn) previously owned the Rails autoloading code and now owns the Zeitwork gem used by rails to replace the old autoloading code. Even though it's not written down who-owns-what (that I know of), you can go into a part of the project and look at the commit history. If there is an owner of a specific file or sub-library, then usually, it's not hard to pick out a recurring name.

In addition to ownership, there's a seniority/authority aspect. I had a case where a Rails core member left me feedback on a documentation PR. They expressed disapproval of some of my decisions. I didn't fully respond to the disapproval and merged the commit in myself. Later I got a private message from a Rails Core member (and Basecamp employee) saying that my behavior was not okay and that I shouldn't go around/over/behind a decision from Rails Core. I apologized and listed actions I could take to help prevent it from happening again.

It makes sense that an official opinion from #core will over-write one from a #contributor, especially when the issue at hand is the contributor's own work. I don't make a habit of ignoring feedback, but also, at the time that I decided to merge my commit (I won't try to justify it), I didn't understand the severity of the action.

This dynamic of not knowing the full repercussions of administrative actions also exists outside Rails and open source. Recently at work, I submitted a PR to an internal project. The person who owns the project "approved" it, but it was a little unclear if they expected me to merge it or if they're waiting for something else. In that case, I have their chat and know their working hours. I got the ambiguity resolved in 5 seconds by messaging them. In the fully async world of open source issues, a comment might take days to get a response (and sometimes never).

## How I GUESS someone gets on Rails Core

While I'm not in "Rails Core," I've seen many go into the ranks. I've also seen a number NOT become Rails core despite their massive involvement with the project. Based on those sets of people and my own experiences, I have some fan theories.

I've already mentioned some prereqs. A developer has to do a lot of work on Rails and already be recognized as a contributor. They've got to be willing to take over a large amount of code to maintain. They need to be active and present in their maintenance. I don't know if this is a strict requirement or merely a coincidence, or a rite-of-passage, but it seems they must be willing to shepherd at least one Rails release.

From the outside-in, the most common cause for a prolific contributor to not be given the #core title seems to be disagreement with another core member. That being said, the only core member I know this has happened with for sure is DHH. I honestly don't know if people are nominated, or they need to ask, or what. I've previously guessed that it would be possible for me to attain this "rank" if I could drop other open source commitments, be able to focus more time on Rails, and bring some "large" feature to the table. For instance, I've questioned/wondered if I could pitch making `derailed_benchmarks` a first-class Rails feature and if that would be a "large" enough project to merit a nomination. I've never asked publicly or privately, though, because I've not felt that I had the time or energy to take on the role fully. Would that work? I don't know. I've not tried. But that's my best guess.

> Also, I want to take a moment to say a huge thanks to Rails Contributors but especially Rails Core...the amount of work they put into the project is enormous. While being on Rails Core is an honor, it's also a significant commitment and a lot of work.

## How do major features happen in Rails?

I view two sides of software - the tactical and strategic:

- Tactical: Made or carried out with only a limited or immediate end in view (i.e., short-term goals)
- Strategic: Of great importance within an integrated whole or to a planned effect (i.e., long-term goals)

All the tactical work of Rails happens out in the open, mainly on GitHub. Some parts of it happen in the #contributor room (but less than you might think). Strategic work is a bit harder to pin down.

My strategy for doing any work in Rails has been to break up any "strategic" initiatives into smaller individually comprehensible "tactical" initiatives. For example, in my blog post [Container Ready Rails 5](https://www.schneems.com/blogs/container_ready_rails_5), I am pitching a larger feature/ability in Rails to manage a "containerized" Rails app better. In reality, this was a series of PRs made individually (which are linked in the post). While I had a strategy and this end goal, I didn't start with a top-down design doc. I made PRs where I saw opportunities. I had conversations on GitHub issues, on Twitter, in Basecamp, and in person at conferences.

I was able to ship this project because I could break it down into smaller components. For more prominent features like Hotwire, Action Text, Action Storage, or DB sharding: the project is too big to squeeze in one-pr-at-a-time. In my view, there are two mainline ways to get a prominent feature that cannot be broken up into Rails.

The first way is to lay out the plans and get buy-in. This process might look like posting a design doc and asking for collaboration. The most recent time I've seen this happen is with a doc on "sharding" in Basecamp. I've never shipped something that large in Rails, but I'm guessing there's also a decent amount of "whipping the votes" and getting buy-in. Even if it's as tiny as mentioning "I wish we had feature X in Rails, don't you?" at a conference.

The second path to getting a prominent feature in Rails is to extract it from Basecamp. There's still a measure of buy-in and communication. There still may be plans posted, design docs, and the rest...but it's a different tone in the conversation. When the Rails feature is coming as an extraction from Basecamp, it's typically a conversation about "how" rather than "if". It might be possible to get #core or #contributors to reject and block one of these extractions, but I've not seen it happen.

In the past, this strategy has served the community well as Rails ends up with features that have usually been semi-battle tested in production. It means that the implementers know the problem space well and are not designing features in a vacuum. Critics have noted that some features might be over-optimized for the Basecamp use case on the flip side. It's a common enough joke that Rails is "Basecamp in a box".

## Explicit and Implicit Governance

Most of what I've laid out here is based on my observations. Not much about how "Rails gets made" is written down or official. This fact makes sense to me. While some Rails Core and Contributors work for companies that allow them to work on open source work hours, I don't believe any of them are "full-time" on Rails. On the #core list, everyone is a programmer and a contributor first. Project management, people management, and coordination happen, but they're emergent properties of the system.

**What I like about this system:** I've benefitted from this system. I'm at the top(ish) of that leaderboard. I have a great relationship with many/most other contributors. I love the Rails community. I think we're a solid group. I've navigated this implicit system very well. I've taken risks to push the boundaries of what I've believed was acceptable action and discourse. I've also patiently built consensus very slowly for divisive changes over the years. The funny thing is that I didn't even realize that's what I was doing. I loved a system driven by programmers because it "made sense to me" about getting changes in. I loved that if I "did the work", then I got the benefits. If there's something in Rails I didn't like, I felt empowered to change it.

**What I don't like about this system:** Every step along the way, I've had to sit back, watch, and guess. This system fits my personality and style well. I'm used to finding ways to "work-steal" from others and find consensus. But there's also plenty of times where I felt stuck. I listed one above. A PR was blocking other work, and I thought merging it wasn't a big deal. I guessed wrong.

I feel confident working in this system, but I also feel afraid of working in this system. It can be exhausting to backchannel and "find buy-in" for every little thing. I don't like that when I read the Basecamp news and had a visceral reaction, my first thought was, "Will my commit access be revoked if I share what's on my mind?" It's incredibly unclear what mechanisms exist to remove commit access from someone against their will, and also unclear what recourse those people can take to get it re-instated.

I also didn't know what would happen to Rails, or what even __could__ happen to Rails? While I've taken it for granted as a given that any Basecamp feature extractions are "guaranteed" (my opinion) to get into Rails, why? What could change that would make that not true anymore? As you've read this post, you've probably seen me mention the word "Basecamp" concerning how Rails works quite a bit. Would we continue to use it? Is it even possible __not__ to use it? While these are specific questions that popped into my mind, the critical question is that I don't even know if I can ask these questions without fear of retribution. Even hypothetically.

## Moving forwards

Writing all this down made it clear to me that Rails is fundamentally built on politics. Every step of the journey involves implicit relationships that developers must navigate. The irony of the "no-politics" controversy is that it doesn't remove the politics. It just removes the ability to talk about politics. It forces those private conversations to be public. Will there be repercussions for me writing this? I don't know, and that's a bit worrying.

What is my relationship with DHH? I've primarily done most of my work by flying under his radar. I've met him in person a few times. He's always been personable, IRL. He's never followed me on Twitter, and other than being involved in asking me to take ownership of Sprockets, I'm not sure he's aware that I exist. I wish they had walked back their statements on Monday instead of doubling and tripling down, instead of going on network news to advocate others should do the same. I wish they came out strongly in favor of diversity and inclusion efforts. I wish they were vocal through their actions in dismantling white supremacy and in being anti-racist. Jason posted "an update", which seems to be perhaps the beginning of some kind of acknowledgment. I think the damage has been done, and this event has highlighted deep, fundamental problems that cannot be so quickly whisked away.

DHH has not been in the Basecamp Rails #contributor chat since "the incident". I don't know what he plans on doing. I don't speak for him. I don't speak for anyone else in Rails Core or Contributors. These are my observations and opinions.

There's a little activity in the contributor room, mostly about everyday getting-stuff-done topics. Some mentions of the forum post and chatter around it, but it's quieter than I would have thought.

I want to use [a framework called Nonviolent Communication (NVC) that has been valuable to my personal and professional life](https://en.wikipedia.org/wiki/Nonviolent_Communication) to try to be as straightforward as possible given the circumstances.

**Observe:** I wrote about the dynamics of how Rails is governed and the events that lead up to this post above. It's not all pure "objective fact," but instead, it's what I'm seeing.

**Emotion:** I'm anxious over the future of Rails and the Rails community. I've got a fear that I should be doing something about that anxiety. I've also feared that if I take the wrong action, there will be some negative retribution. I'm feeling defensiveness in myself and the Ruby community. I've distinctly noticed that this topic hasn't even come up at all on /r/ruby, even while it's basically been the "twitter character of the day" on my feed for over a week and has regularly topped the orange site. I'm frustrated. I wrote this post in a partial attempt to process these feelings. [wheel](https://feelu.vercel.app/)

**Need:**  What I want is to build software as a community. I want to see from my community leaders that they can respect, value, and learn from the community. If a decision is made or action is taken that causes an uproar, I want reassurance that those voices have been heard. The ability to acknowledge a problem or disagreement is foundational to being able to work together.

I want to build software in a collaborative way where I can feel confident that I understand the impacts of my actions. I want to work with those that "Dare Greatly" (Brene Brown) and can let their guards down, be vulnerable, and (as a result) produce the best possible outcomes.

**Request:** This is where I narrow down a specific request to the listener so that my words won't be misinterpreted (as much). It's not a demand. It can be heard and acknowledged without the REQUIREMENT that it be acted upon. I ask you to open up about how you're feeling and what you want to see happen. I see lots of bomb-throwing, I think it's backed by a lot of rage, but I don't know. I appreciate clarity from using NVC and might invite you to try on that framework. I don't have a specific "fix" to recommend for this situation. Some have jumped to solutions. Some of those solutions may help. I'm not asking for a coup or trying to prevent one, for that matter. What I want is to be heard. I want clarity on the situation. I want to talk with more people and not feel entirely so alone in all of this.
