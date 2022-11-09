---
title: "Pairing on Open Source"
layout: post
published: true
date: 2022-11-09
permalink: /2022/11/09/pairing-on-open-source/
image_url: https://www.dropbox.com/s/dl943esjx0dsvb6/ben-pairing-interview.png?raw=1
categories:
    - ruby
---

I came to love pairing after I hurt my hands and couldn't type. I had to finish up the last 2 months of a graduate CS course without the ability to use a keyboard. I had never paired before but enlisted several other developers to type for me. After I got the hang of the workflow, I was surprised that even when coding in a language my pair had never written in (C or C++), they could spot bugs and problems as we went. Toward the end, I finished the assignments faster when I wasn't touching the keyboard, than I was by myself. Talking aloud forced me to refine my thoughts before typing anything. It might be intimidating to try pairing for the first time, but as Ben puts "it's just a way of working together."

This Hacktoberfest, I started a Slack group for the ~350 early purchasers of my book [How to Open Source](https://howtoopensource.dev). In the intake survey, they told me they wanted to learn more about pairing. When I think pairing, I think of Ben Orenstein, CEO of the pairing app [tuple.app](https://tuple.app). I jumped on Twitter and asked if I could interview him for the group, and he agreed!

Listen in as we discuss the intersection of pairing and open source contribution. We'll talk about how it's different from regular pairing (or not), how to find people to pair with, and the best way to ask for help from a potential mentor.

<iframe width="560" height="315" src="https://www.youtube.com/embed/Tml2uXn65Co" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

In addition to talking about pairing in the group, we had developers who organized together to pair for Hacktoberfest. One made their first-ever contribution after their first pairing session. Then she wrote her [first ever English blog post about the experience](https://neko314.hatenablog.com/entry/2022/10/19/164953).

## Topics

- Is pairing on open source different?
- How do you find people to pair with?
- Can you match people in a group to pair?
- [FocusMate.com](https://www.focusmate.com/)
- Can developers of the same level pair?
- What research has been done on pairing?
- [LearnToPair.com](https://learntopair.com/)
- How would you introduce pairing into a team?
- [tuple.app/oss](https://tuple.app/oss) - Free license for open source maintainers
- Can you pair on non-technical tasks?
- How do you initiate pairing sessions?

## Transcript

(If you find a glaring problem with the transcript you can send me a PR to https://github.com/schneems/schneems.)

**Ben:** Yeah, let's rock.

**Schneems:** Well, welcome everyone. My name is Richard Schneeman, author of [How to Open Source](https://howtoopensource.dev). Today I have Ben, the ceo. CEO or CTO?

**Ben:** Ceo.

**Schneems:** Ceo. All right. Yeah, the big guns of [tuple.app](https://tuple.app). So tuple is an application for pairing. It's my favorite application for pairing coincidentally. So you wanna say Hi Ben?

**Ben:** Yeah, I'm stoked to be here. Pairing was a huge game changer in my career and so I'm stoked to talk about this topic that made a big difference for me professionally.

**Schneems:** Awesome, Awesome. Well I am very happy to have you. I recently launched a book and in doing so, asked as some of the people who bought it, what they're interested in. A lot of 'em indicated that they are really interested in pairing, so hence inviting Ben. And so yeah, wanted to ask you a couple of questions. One of 'em that came up is just kind of high level, hey, are there differences pairing on open source software versus proprietary software?

**Ben:** Probably not in the actual act of pairing, I would assume. I can't think of any differences that would be there. I think it's probably, you might see some differences in what it takes to get people to pair with you. I'm not quite sure the willingness of open source maintainers to pair with other contributors. <affirmative>, you would sort of hope it was high, or maybe once you had earned a little bit of trust or shown a bit of promise, that could be a thing. That would be an easier pitch to make. If I were an open source maintainer and I sort had all the responsibility of my project, I would want to train other people on that project. So it's to help share some of the burden, I think. <Right>. And I haven't found a better thing than pairing for transmitting that sort of knowledge yet. So I would think, whereas if you're at a company and you're all are in the same team and you're all working on the same app, it's probably pretty easy to just DM somebody and say, Hey, can we pair on this thing?

**Schneems:** Totally, totally. Yeah. I think and you kind of alluded to a little bit of as a maintainer, needing to balance your like, yes, you wanna train people up, but you also need to balance that with, well hey, am I ever gonna see this person again? So in order to pair you to be able to find people, it's a little bit different in working in the open, working in open source have you ever seen any sort of pairing groups or have you seen any sort of patterns with either a people who say like, Hey, I have a thing I wanna share, or other people come to the table and say, Oh, I have a problem, or I need help with this. Just, or tips really in general for people looking for someone to pair with, but maybe they don't necessarily have a pre-built pool.

**Ben:** It's kind of a bigger question. I think the question of how do you find someone to pair with is a little bit like the question of how do you find colleagues or mentors? Perry is just a way of working together. It's not a magical practice. It's effective and it's a big fan of it, but it's not different than working with other people really. It's just a type of working together. And so I think it really transposes to the question of how do I find great people to work with? And I think maybe a short answer to that is be worth working with. Be a friendly person, a productive person. Show some indications that you are going to be good to pair with, is probably a good way to start <affirmative>. I think if you email someone and say, Hey, I'm looking for a mentor, will you be my mentor?
No one wants to say yes to that. That's not a compelling pitch. But if you say, Hey, I've been a fan of your work. I loved this project and this project, you inspired me to do this thing and I ran into this problem, could you offer me, do you have any advice on how I might tackle this? Now you're starting a relationship with somebody. You've shown that you have done work, you've, you've done some homework already and you're showing that you are possibly worth mentoring. And I think that approach is probably likely to pay better dividends than saying just how do I find someone to pair with who wants to pair with me? Well, in the open source context, try to get a couple prs under your belt maybe or ask if the maintainers have considered a organizing a pairing day where maybe they connect a few people that are interested in becoming contributors or new contributors, something like that.

**Schneems:** <affirmative>, have you seen anything like that in the wild? And I ask because I, it's like, hey, I'm trying to run this community and it's like I've got people who want pair, I have people who wanna work on project. It seemed,

**Ben:** It's a weird thing. I've seen a lot of failed efforts here. I think it's a pretty common programmer impulse to be like, I should build a site that matches pair people together that wanna pair programming. Cuz you could sort envision how the Apple work. And so a lot of programmers write it and I think it's not a matching problem really <affirmative> just because these two people wanna pair in the same time zone and in the same language doesn't mean they're really gonna actually pair together. I think there's more social complex social dynamics at play than an app is going to solve. I think the closest thing I've seen to a direct effort to cause more pairing that has worked well has been inside a company. So one of the customers of Tuol is Shopify. They have thousands of developers using our product and they ran a internal pairing contest. They ran a contest and it was like whoever pairs the most this week or with the most people or the most time becomes eligible for these prizes. And I think the prizes were honestly just t-shirts and badges and things like that. I think they were fairly simple things, <affirmative> But I think you, I remain continually surprised by how much developers will do for a <affirmative>. So <laugh>, that might be a possible approach

**Schneems:** There. A hundred percent. Yeah. I mean we're definitely seeing that there's actually a lot of engagement within the group with within Oktoberfest is just something to focus on, I feel like is a big thing. When you said that, I was like, Oh yeah, it's like a contest. It's like, yeah, who can pair the best? It's who can be the most friendly <laugh>. Ah, I'm gonna crush it at being friendly.

**Ben:** Totally.

**Schneems:** That's interesting. Yeah. Pairing contest. Yeah. And even one of the people in the group specifically called out and mentioned Focusmate. Have you ever heard of Focus Mate?

**Ben:** Yeah. That's the thing where you go and you work with somebody kind of simultaneously, but separately,

**Schneems:** Right? Yeah. So for just everybody else, you log into the site and you just say, Hey, I need to focus. I need basically somebody to keep me accountable. It pairs you up with someone, I mean not pairs. It matches you with someone. There we go. And then you basically just sit there for a block of time. Well you both do work. And the idea is if you start playing on your phone or something, the other person would see. So it's, it's working in a cafe. So yeah. Good. You're familiar with it. Somebody specifically was asking like, Hey, have you ever considered integrating with topple? And it, it's back with the matching issue. Not super keen on that, like you said, as being a technology issue.

**Ben:** Yeah, I don't believe that you're gonna pair random strangers together and have it worked that well. You might occasionally have success there if you get people with similar values and goals, you have higher success rate I'm sure. I think you probably want to pair strangers. I think you need to have a human in the loop <affirmative> and very motivated people. Otherwise it's kind of pairing up workout buddies where if any either person flakes, then the other person is also can't work out. It's now we're just tied together. In this particular foot race, we have considered building some things within teams. I think woodwork is saying Richard joined the team a week ago and hasn't paired with anyone. Maybe someone should pair with him or here's a leaderboard. Richard actually pairs with the most people in a given month. I wonder if anyone could catch him. Here's the second and third and fourth place kind of thing. And sort of take a thing that is already mostly working or is already an established social group and kind of give it nudges. I think that would possibly work. But this we should add matching into twofold to have people find other people to pair with broadly throughout the internet and among strangers. I'm pretty skeptical of, I might be wrong, maybe it would be amazing feature, but I have suspicions,

**Schneems:** <affirmative>. Okay. Yeah, I makes sense.

**Ben:** Your group might be a good different, might be an exception. So we did do some. So when I was running Upcase for Thought bot, which is a educational developer training service I think we did do some matching of pairs and there was some success. I wouldn't say it was resounding success, but there was pairing happening. People reported that it actually occurred. So I think it is possible within a group that has kind of self-selected and identified, I wanna learn this thing, I'm willing to invest this effort to do this

**Schneems:** <affirmative> for that. Within matching people. Of the times that you have mentioned pairing, it kind of sounds like you're mostly envisioning a different level. Senior, junior, I mean

**Ben:** No

**Schneems:** Actually no labels and whatnot or same level or I don't know. Are there any other than values and character traits and just connection, are there any other things to look for that might make a good pair, a good pairing setup or a good pairing pair?

**Ben:** Pair programming is a more social endeavor than almost most programming activities. It's live real time code review a little bit. And so just in a code coder view, you have to be a little careful about how you say things and you have to maybe use more emoji like positive emoji and more air on the side of politeness and friendliness and happiness than you might otherwise. <affirmative>. I think pairing has a little bit of that as well. I think a good pair is someone that has empathy and friendliness and a decent amount of easygoingness. And so I would seek to pair with people that you enjoy spending time with <affirmative>. If they're nice humans and pleasant and enjoy collaborating on things, then you'll probably have a good time pairing with them if they are the type to nerds snip you or while actually you all the time or be condescending. If you don't know something then you will not have a good time pairing with that person. And it's not parenting's fault, it just exposes a thing that was there.

**Schneems:** Right. Yeah. There's just already a relationship. It's not gonna be literally a different person when they show up to the

**Ben:** Yeah. Session.

**Schneems:** Yeah, that makes sense to me. So on the site you do have why pairing and there there's sort a five second, five minute and maybe that's not the delineation. One of the people in my group was asking if you know of any research in the world of pairing. So they were trying to bring pairing to their company and they're basically just looking for more ammo, fire power like hey, we say pairing has done X, Y, and Z. Do you, you know of either a existing research or I don't know, maybe ongoing research?

**Ben:** Yeah, if you Google scientific research into pair programming, our article is the top result I wrote. There's not much is the short answer. So I wrote up what I found and it's about six or so plausible studies that you could maybe say make a decent case for pairing <affirmative>. I think. So hopefully that will help. This is a site that we made learn to pair.com and that's one of the articles. There's lots of stuff there. Most of what I know about pairing, I tried to put in that site, learn

**Schneems:** To pair.com. Got

**Ben:** It. You try to justify this scientific, it feels like coming up with scientific research into programming productivity measures seems very hard to me. <affirmative> I think coming up with a measure of how productive programmers are is tantalizing and so far I think has been fairly intractable. I'm not sure you could get something that would convince a lot of expert practitioners that you have a good metric that actually demonstrates whether a programmer is productive. It might be almost impossible. And so to say here is some scientific research into the effectiveness of pair programming sort of requires some measurement <affirmative> otherwise you're just doing surveys. Did you feel more productive? Did you enjoy this experience more? And the surveys there, people have done this research with surveys and the surveys do show very strong positive results. People enjoyed pairing, they felt more productive, they felt more connected.
I wouldn't probably take this track if I were trying to introduce pairing or try to justify pairing as an activity <affirmative>. I think I would try to no big deal my way into it. Meaning I think sometimes people think I need to convince my team, I should convince my team, my company, my management, that we should do pair programming. And so let me make the case. And it would be great if there were a study that showed that this is clearly a great idea. And I think what you probably should do instead is go to a coworker that you have a great relationship with and who is warm and friendly and empathetic and say, Hey, will you gimme a second set of eyes on this real quick and fire up something like Tuol or some other screen sharing tool or whatever. Or have them pull up a chair next to you.
If you are working in person, plug in an extra keyboard and just write some code together. And don't even call it pairing. Don't make a big deal of it. Just be like, call it a second set of eyes. Cuz that's fundamentally what pairing is at the end of the day. It's two people looking at the same code at the same time. And all the rules or strategies or tactics about who types when and who has a mouse and who has a keyboard and where's the monitor And all this really is of implementation details, but the fundamental activity is two programmers looking at the same code. And so you could do that in person, you could do that remote and I would just casually start this practice and see how it goes. And if you like it and it works well try to do it some more and maybe do it with some other people.
And maybe when someone at a standup says, Oh, I'm still stuck on that, whatever. And say, Oh, do you want me to come take a look at that with you at some point? And then lo and behold you're pairing with them or hey maybe, and Mary should pair on that thing or should work on that thing together. I would go at it grassroots and subtly and not make a big deal about it. And pairing is not for every team, so it might not work <affirmative> but I think that's probably gives you a pretty good chance of success. Top down, we will all pair can work occasionally. There are some organizations that have that and have done that and have become pairing organizations so it can work <affirmative> that's not how I would introduce pairing at an existing organization that is not already pairing or doesn't have extreme buy-in from the top who are willing to say, Yes, we're gonna make this. The priority of the quarter is everyone's gonna pair and we'll see how it goes

**Schneems:** <affirmative>. So I think the reason behind maybe why they were asking, it's like, Oh hey, how can I get this top down buy in? It's maybe they were looking for a credit card, they're looking for the sign in, they're looking for like, Oh hey, I it's specifically, it's like, oh, I heard there's this great app that I would like to get access to. Yeah. I don't know. It's like

**Ben:** What are their options?

**Schneems:** Yeah, yeah. Well it's, You have a free trial period, right?

**Ben:** Yes, we do have a free trial. It doesn't require a credit card card. So we see lots of our customers sign up as entry level developers or developers without a credit card. And then they try it and they like it and they ask someone high up the chain for permission to buy it and then become paid customers. But also and relevant to this group, I suspect, is that we give away the app for open source teams. So you can get a permanently free team if you are open source maintainers or working on open source and it's just two.app/oss and fill out that form with what you're working on. And we grant this to probably almost everyone that fills it out. So we leverage, we use a lot of open source software in our tool and our company is built on top of it. So we were very happy to give back to the OSS community in this way.

**Schneems:** And full disclosure, I am a recipient of this, a happy recipient of this program. And I think only so one, both people don't need to have paid for, is that correct? Yeah. Okay. So it's if you wanna pair with somebody who's never done it, it's they don't have to make this big investment. If one person has a license, you can invite somebody else to pair with you.

**Ben:** Right? Exactly. Yep.

**Schneems:** Okay, cool. I think that helps ease that transition and gets to the heart of the, it's like research maybe not, but it's really, it's how can we hit that ground running? How can we do more pairing? And I think to makes total sense to me. Have you ever heard of, I guess, pairing on non non-technical tasks or just almost like

**Ben:** Yeah,

**Schneems:** Writing an RFC or research or I guess you can speak to that.

**Ben:** I pair on non-technical tasks all the time every week. And this actually happens a lot at our company. A lot of non programming things happen on two sessions as a part of a pair. A lot of the benefit of pairing, there's a lot of benefits of pairing that you get, even if there's no code on the screen. So it's often less boring to work on something or if something is boring, it's less boring it's less likely to be boring <affirmative> it's more engaging. If someone is there with you, it's harder to slack off if you're sharing your screen. So you tend to stay more focused and get the thing done faster with fewer Twitter accidental long Twitter breaks or email breaks or slack breaks or things like that. <affirmative> it spreads knowledge around the team. If I watch someone do a process or writing a doc or something, I'm learning that thing at the same time.
So we are having all this rich communication happening. You can see how someone else works, how someone else thinks, which is really useful for just becoming more awesome yourself. You might see they have a wonderful Macs tool that you wanna steal or Oh hey, I didn't know you could do that in our app with this shortcut, or how did you make that thing happen through while programming, but also through while just using your computer. So there's all these benefits that are available to you. And I think it shines particularly well on coding because programming is so hard and it's just so easy to write bugs that having a second set of eyes is, and it's so hard to make a great design, a good coding design <affirmative> that it feels extra worth having another person there because bugs in production can be very costly. They're not fun to fix. They slow you down a lot. Bad design decisions probably that even worse. True for all those things, but even stronger probably <affirmative>. And so it shines a lot there. But we have found quite a lot of value in just pairing on running payroll or figuring out what's the policy on this thing or what are our goals for next quarter, all those sorts of

**Schneems:** Things. Okay, cool. How do you initiate those conversations? Or do you just say, Hey, I'm working on this, somebody wanted somebody wanna do it with me?

**Ben:** Yeah yeah. Same sort of casual way. I have standing pairing meetings, kinda like you my calendar with people that I work with a lot. True. That's probably true for a number of our employees as well. But yeah, I think there's also just a lot of, there's a fair amount of ad hoc pairing happening where someone just call somebody else, I'm like, Oh, this is tricky. Let me just call this person. And just they get a notification that I'm calling and there's my screen and we start talking and it happens just kind of fairly fluidly and we've built a cult. Our culture is sort of steeped in this as you'd imagine making a pairing app for a living. Great. There's a lot of pairing happening. Everyone's expecting it. No one is shocked when you wanna do it with them. So that does a lot of work there.

**Schneems:** Cool. Very cool. Well yeah, I really appreciate you coming on board and answering some of the open source communities questions. So yeah, thank you Ben from couple.app.

**Ben:** Yeah, my pleasure. For.


