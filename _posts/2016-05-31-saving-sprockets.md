---
layout: post
title: "Saving Sprockets"
date: 2016-05-31
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

What do you do when a maintainer leaves a project with over 51 million downloads? That is what we had to consider this year when Sprockets lost the developer responsible for more than 70% of the commits. We'll explore this and more through my RailsConf 2016 talk and the transcript below.

I've spoken in 12 countries on 5 continents and this is my favorite talk to date. This talk was difficult. The ideas were in my head, but I couldn't get the words right for the longest time. This was an emotional talk for me . Writing this talk turned into a soul searching journey through open source. What does it mean to be a maintainer? What does it mean to leave a project? What does it mean to respect and help a maintainer? The road was long and perilious but i'm very happy with the talk. Hopefully you'll join me on this archeological expedition.

<iframe width="560" height="315" src="https://www.youtube.com/embed/qxaE8yblHPk" frameborder="0" allowfullscreen></iframe>

> This version has intro music and closed captions. Transcript and slides are below.

Here's what some people had to say about my talk.

- "That was an epic talk on many levels" - [@_tankard](https://twitter.com/_tankard_/status/735500519297277953)

- "Every single Ruby developer should watch @schneems's [Saving Sprockets] talk" - [@samphippen](https://twitter.com/samphippen/status/736647582882103296)

- "good talk man, every conf should have sth like that until people learn how this oss thing works :)" - [@_solnic_](https://twitter.com/_solnic_/status/735507903294103554)

- "Thoroughly enjoyed, would attend again, ⭐️⭐️⭐️⭐️⭐️ / ⭐️⭐️⭐️⭐️⭐️" - [@chrisarcand](https://twitter.com/chrisarcand/status/735503089969438721)

- "I loved it [...] but I am biased in favor of smart ideas full disclosure" - [@searls](https://twitter.com/searls/status/735238530578976768)

- "Go home people, @schneems just had the best slide analogy of #RailsConf" - [@cecycorrea](https://twitter.com/cecycorrea/status/728315278874972164)

- "Don't quote me boy" - [Eazy-E](https://en.wikipedia.org/wiki/Eazy-E)

## Slides

<script async class="speakerdeck-embed" data-id="f271db53c81e492ca550b29b8f166a18" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>



## Transcript(ish)

> This is the text of my talk with some minor adaptation to make sense when reading without slides. It's about 5,000 words or the length of two of my normal blog posts.

We want to start out asking the question, Why does sprockets need saving? For those of you who haven't been around since May of 2011, it is the premiere feature of Rails 3.1, and Sprockets is the Asset Pipeline. Sprockets actually came first, before it was ever wrapped up into Rails. One thing I wanted to mention before we get too carried away, is that you don't need to look like Indiana Jones in order to maintain open source, it just so happens that he is my Sprockets spirit animal. 

So, from 2011 to 2016 sprockets has had 51 million downloads, and I'd like to put that into perspective. Rails has had 65 million downloads, so Sprockets is, pretty close, and, of that entire library, one developer is responsible for 2027 commits, which happens to be about 68% of sprockets. That's one person. Compared, in contrast, to a Ruby hero, Rafael Franca, who has over 5000 commits on Rails. This accounts for only 0.9% of Rails. 51 million downloads, one developer, and one day, Josh is left. "I'm cutting it, I'm out, I'm gone." 

So, when something like this happens, what should we do? Should we, as a community abandon Sprockets? There's a lot of people who said "I don't like Sprockets", and "it's got problems". To them, I ask: what are the problems? Do you know what they are? Because, we can't fix what we can't define, and if we want to attempt a re-write, then a re-write would assume that we know better. We still have the same need to do things with assets, so we don't really know better. 

I think we should stick with Sprockets and make it better. Assets are really the easy part of Sprockets. There's a whole bunch of edge cases. Also, Sprockets has a really well-defined and established API.

Losing maintainers is inevitable, and it's not always expected. Jim Weirich was the creator of a amazing library that we've all used called Rake, and in 2014, Jim passed away very suddenly. It wasn't like anybody saw this coming. He wasn't, working with someone to pass on the software to for a long period of time. And so, whether a maintainer suddenly walks away or they pass away, it hurts. We, as library consumers have to cope with it, and there's a lot of different ways that we do that. We might go through a period of denial and say something like "they're going to come back". We are going to get this person back into our lives. You might be angry and say, "leaving is selfish", or "that was such a jerk thing to do". You might start bargaining and say "Maybe if we hire them, they'll work on it full time and we can get them to come back," and eventually, acceptance. "They're not going to come back, who's going to take this over?" 

The number one rule, is that a maintainer does not owe you anything. 

> A maintainer does not ow you Anything

Not even an explanation. If you're going to leave a project, or someone is leaving a project, it's a very personal decision. I actually reached out to Josh and said, "Hey, man, let's talk about this. I'm giving a talk at RailsConf. I need some content, gotta help me out," and Josh didn't want to talk about it, and I want to respect that wish, and I also want to respect what he's done, which brings me on to the number two rule.

The number two rule, is that you owne a maintainer respect.

Some people will say things like, "Oh, but I really hate this project." It is possible to critique software without demonizing the creator, and, as a matter of fact, I'm going to critique the crap out of Sprockets. Notice, one word choice was intentional here. I'm critiquing and I'm not criticizing. I aim to be productive with the words that I'm using. I want to find what is bad, and then make it better. Originally, when Sprockets fell into my lap, and somebody said, "hey, do you want to be on Sprockets core?" I was like, "Sprockets, why did it have to be Sprockets?". You are not your software. Josh gave years of his life to project. No matter what you think of the project, or what you think of how it was maintained. I want to give a thank you to Josh. 


Rule number three, is that words without actions are empty. 


I want you to be actionable with your critiques and think about this. For example, we have a hacker news comment which says, "unless they this feature to node, I see this as ugly and barely usable" 


![](https://www.dropbox.com/s/r9xn2b839v098tr/Screenshot%202016-05-27%2015.48.17.png?dl=1)

When I read that, that's not going to make me want to go out and help them. Instead, they could've easily said, "Hey, this is great, this is amazing, I love it. It looks like they don't have this thing I need, and, as a matter of fact,  I can't use it and here is my use case" and that's actionable feedback. You can critique without criticizing. So, I want you to ask yourself, "is this comment adding anything?" 

Hyperbole in comments and blog posts is good for laughs and fake internet points but it doesn't help. I want you to be honest with your critiques. I want you to be productive. Here is the babeljs creator tweeted at the screenshot, again, coincidentally, from hacker news, and it reads, "Babel sucks. I never thought I could hate something so strongly." 

![](https://www.dropbox.com/s/kvmo24k9yv0bfv1/Screenshot%202016-05-27%2015.50.36.png?dl=1)

Wow, that's really going to encourage that guy to go out and fix all of your problems. You might disagree and you might have very strong opinions, and those opinions might be very negative. Even if that's the case this software is in your life for a reason, and if you can figure out why those things hurt, why you are having those negative feelings, and you can enumerate that in a productive way then it helps everyone. Complaining by itself accomplishes nothing. When I startted the talk I wanted to touch on "how do we keep a maintainer longer". Or if you're maintaining software, how can you stick around longer. To do that we need to look at what maintainers want. We also need to do our homework and ask ourselves is there any value in a maintainer sticking around? All maintainers will one day leave and we can either have a maintainer that just mic drops and you never see them again, or we can have somebody who's passing the torch and graceful hand-off. 

While I'm working on Sprockets, there's so many times that I say "this is absolutely batshit insane. This makes no sense. I'm going to rip this all out. I'm going to completely redo all of this." And then, six hours later, I say "wow, that was genius," and I didn't have that right context for looking at the code. Maintainers are really historians, and these maintainers, they help bring context. We try to focus on good commit messages and good poll requests. Changelog entries. Please keep a changelog, btw. But none of that compares to having someone who's actually there. A story is worth 1000 commit messages. For example, you can't exactly ask a commit message a question, like, "hey, did you consider trying to uh..." and the commit message is like, "uh, I'm a commit message." It doesn't store the context about the conversations around that. 

So, maintainers are historians and we can keep those maintainers longer by giving them what they want. Maintainers want respect. They want to be appreciated. They also want help, and I know all of you are thinking, "Ugh, this is the part where he's going to be like, asking me to help, and I really don't want to do that." Or, maybe you already are helping. Maybe you're saying, "I don't have enough time", or "ughh just fix all of the things for me it will be faster if you do it". I'm here to say that if you have five minutes to snap-to-face-to-fours-tagram, then you have five minutes to help open source. You can contribute to docs. You can read the guides. You can fix typos. Maybe you found a really surprising behavior. Was that behavior documented? If not then, go ahead and add it to the guide. If you have five minutes to help, then you can submit a bug report. Seriously, the maintainers have no clue that things are broken. You might be thinking, "oh, there's thousands of people using Rails and all of them have reported this thing." No. 

The question of "why is Sprockets bad?" I don't know. Nobody actually gives me actionable bug reports. So, if you have five minutes to help, then please let us know what your problems are in a productive way. 

> Critique over criticism. 

Another thing you can do to help is sign up for a service that I wrote and maintain called [CodeTriage](https://www.codetriage.com). You can go there and sign up for a project you care about and it will send you an issue in your inbox once a day. It's a very actionable way to get started. When you get the issue you can ask common questions like, "what version were you running on?", "Was this working previously?". Let's step back, would you rather the maintainer of that project spent the time fixing bugs or would you rather they spent the time asking for insanely small minutiae on the issues? Anyone can ask those questions. And it might only seem like you're giving a minute or two out of your day, how could that be impactful? If you give a minute, you are actually saving a minute of a maintainer's time. A little bit of help can go a long way. And if you don't help, then who will? It also has the benefit of exposing you to different parts of projects, which helps you grow as a developer. 

If you have 10 minutes to help, include an example app to reproduce the problem. Example apps are amazing. I get all these bug reports that are like, "well, first I run Rails New," and then I go and try the instructions and come back an hour later "sorry, couldn't reproduce," and then they respond, "oh yeah, I forgot to add this other thing," and then I try it, and couldn't reproduce, and I waste hours of my life that I could be spending fixing bugs or writing nef features. As the reporter you waste hours of your life. Nobody's happy. Instead, you can ask and say "here's an application that is going to reproduce my problem.". Make a new project with the bare minimum to get the bug to show. Put it on `github.com/<username>/ExampleApp` if you don't have that yet. You can even choose `ExampleApp1` or `ExampleApp2` as a repo name. I'm not picky. If you give a minute of your time, then you're going to save a minute for a maintainer. 

I personally challenge you, if you haven't already, please try and make it your goal to produce one example app this year. It is so helpful. 

If you have 30 minutes to help, you can try fixing a bug. Anybody's bug or your bug. It's not as hard as it sounds, just timebox it. Even if you don't fix it, then you're guaranteed to learn something. You're guaranteed to read other people's code. You're going to be navigating into debugging other people's code, which happens to be highly marketable skills. With all of this, I know you're like, "Okay, uh, I don't want to do that like, every time," and that brings me back to club soda. 

I drink club soda at home, and I don't like putting the whole thing in my refrigerator. So instead, what I do is I put like three or four in to get cold. Then when I pull one out, I put one back in. However sometimes I run out of club soda. How did this happen? Is somebody stealing my club soda? Is my dog drinking my club soda? The rule is one in, one out. It's pretty simple. But clearly it's not sustainable. Instead what I found, is that if I put two cans instead of just one can that I somehow end up with 3-4 cans in the refrigerator. Now I always have club soda. You got it? It all makes sense. No?

So what I'm saying is, you don't always have to contribute to open source. You don't always have to make an example app, but just, every once in a while please go the extra mile. 

These are all different ways that we can help a maintainer. Ways we can make their job a little bit easier. So how do we transition from one maintainer to another maintainer? Well, what is a maintainer? We've talked about this. A maintainer is somebody who knows the stories. A maintainer is someone who's going to take 5, 10, 30 minutes out of their day to help. If a maintainer is somebody who helps, and the act of helping preserves history. Then maybe the act of helping is the answer to keeping a maintainer. Also, the act of helping is the key to creating maintainers.

If you have people familiar with your code whenever you actually go through that hand-off process, people aren't just starting from zero. 

The next question we have is, how can we foster a culture for helping? How can we get more people to help? If you are a maintainer, you want people in your project. If you're using that project, you want more people helping and contributing because that makes it better. So, how do we foster that culture for helping? We talked about what maintainers want, but we never really talked about what the helpers want. 

Well, helpers want documentation. They want sane code. They want what regular users want: good user experience. Non-magical code, backwards compatibility, good deprecations, reliable tests. These are all things that are interesting to them. So let's look at one and compare it on the Sprockets chart. 

Documentation. Sprockets has 73% documented methods. Seventy-three percent of all methods are documented. That's a lot. That's really up there. On a side-note, I think that method documents are kind of like unit tests. They are very focused on one part, and don't necessarily tell the whole story, so it is possible for those comments to get a little bit out of sync with reality. I also highly recommend keeping a README. A README I see as something more like an integration test. It's going to tell a little bit more of the whole story, and if we look at Sprockets, well, Sprockets has about 2,600+ words. That's a pretty long blog post. That's a pretty substantial README. That's a pretty long story. If I'm here, telling you that helpers love docs, and I'm telling you that Sprockets has docs, why doesn't Sprockets have anybody helping? 



I put on my design research hat. I went to design research school and I learned about user stories. So, we are going to actually consider the people using our product. I want to introduce you to Pedro. Pedro enjoys long walks on the beach. Favorite food is bagel bites, and he's building the next Uber for goldfish. Pedro is a Rails user, and Pedro cares about the Rails interface. This is going to be, how do I get one file to require another one? I want to know what I actually have to type into my project to get it to work. Now, I don't care about all that other stuff. I just want the things I need now. 


Next up is pat Pat. Pat is addicted to ES6. I know. Pat loves to fly fish and Pat is a plugin developer for Sprockets. By the way, did you know that Sprockets has plug-ins? Okay, well, they're not called plugins, they're called processors and transformers and compressors and like 20 other things, but it does have a plugin system. And Pat cares about the processor interface. They maintain one. They want to know that, whenever we pass the hash of things to them, what is going to be in it? And what can I do with it? What should I do with it? Pat wants this documented when Pat is working on their plugin. 

Finally, Diana has a dog named Exception, and hates mustard. Both of these are highly relevant to Diana's job as a Rails developer, i.e. somebody actually developing Rails, somebody actually building an asset pipeline. Diana cares about the low-level interface. What does that mean? Diana cares about what are the classes she can use? What are the methods on those classes? All of them. If she wants to be able to disable gzip. Here you go. 

These are all different people with very different needs who need different documentation. Don't make them hunt down the documentation that they need. When I started working on sprockets. Somebody would be ask, "is this expected?" and I'm would say honestly, "I don't know, you tell me. Was it happening before?" And through doing that research, I put together some guides, and I eventually we could definitivly say what was expected behavior. The only way that I could make those guides make sense is if I split them out, and so, we have a guide for "building an asset processing framework", so if you're building the next Rails asset pipeline, or "end user asset generation", if you are a Rails user, or "extending Sprockets" if you want to make one of those plugins. It 's all right there, it's kind of right at your fingertips, and you only need to look at the documentation that fits your use case, when you need it. 


We made it easier for developers to find what they need. Also, it was super useful exercise for me as well. One thing I love about these guides is that it lives in the source and not in a wiki, because documentation is really only valid from one point in time. Otherwise, you end up in the wiki like, "if you're using this version, do this, if you're using this version, do this," and it's 20 versions and it's no good. Helpers love contributing to docs, so you know what? We can make more docs. We can make our docs better. Those docs are going to be the gateway drug to code contributions. 

The next thing I want to talk about is sane code and realtalk. Sprockets was designed to solve problems, and sometimes, when it's putting out a fire, it kind of feels like it's starting other fires. Maybe making additional problems that you didn't see before, and you don't know why it fails. The reason you don't know, is because Sprockets isn't talking to you. How does code talk? Code can speak to you through errors, and I'm not talking about "something broke", or "no method errror, on nil". I'm talking about. I want my error to say, "this broke." I want my error to say, "ID key is missing,", look here "this is the thing that you're missing,". Good errors are instructive, and Sprockets will have better errors. It doesn't yet. I do care about this. I am the owner of a gem called, wait for it, Sprockets Better Errors. That gem was merged into Sprockets Rails, but yes, I had some good ideas for better errors in Sprockets itself. 

The other way that code can speak to us is through deprecation. Now, deprecating something in a code comment is not enough. Right now, Sprockets is doing this. They have a little code comment, and they're like, "by the way, this method is now deprecated." We will just delete it, and it won't be available, and you never knew that because A) No one is casually reading the method documentation, and B) Who has the time. It's not as though every single time you upgrade every version of Sprockets, are you going to read every method comment in the documentations. Are you going to do that? No. You cannot just sit back and break your API, especially when you have 51 million downloads. That is nacceptable. Since, your code knows when somebody's using a deprecated interface. We can yell at them.

 We have these things called deprecations. I wrote a detailed guide on [using Deprecations in your library](https://blog.codeship.com/the-straight-dope-on-deprecations/). 


 Sprockets 3.X will have deprecations before we go to Sprockets 4.X. We have a branch. We've started working on this. If you've not implemented deprecations in your own project, it's super simple. You say "hey, the thing you're using is deprecated. Use this other thing that's not deprecated, and here's where you were using it." It's kind of like a three-step process. So deprecations are going to nudge people into the right behavior. They're going to help get people to upgrade, and they also help with API design, because, if you can't write a good deprecation, then guess what? The interface probably wasn't the best. 


In the talk I mention an hash key based API, turns out I was wrong. More information can be found [at this PR](https://github.com/rails/sprockets/pull/301). This just further underscores the importance of having a maintainer who knows what is up around to sanity check things for you.

This is my favorite section coming up. I hope you're paying attention. Sprockets suffers from something that I like to call the god object problem. It has this one main class that has all of these concerns mixed in with it. It's one object with 105 methods. It's using a lot of them, and you ask yourself, "where did that method come from?" and you look at this source code, maybe it came from 

    Sprockets::Environment 
    Sprockets::dependencies
    Sprockets::DigestUtils
    Sprockets::HTTPUtils
    Sprockets::Mime
    Sprockets::Server
    Sprockets::Resolve
    Sprockets::Loader
    Sprockets::Bower
    Sprockets::PathUtils
    Sprockets::PathDependencyUtils
    Sprockets::PathDigestUtils
    Sprockets::DigestUtils
    Sprockets::SourceMapUtils
    Sprockets::UriUtils. 


This is my personal favorite, 

    Spjrockets::Utils

Is mixed into 

    Sprockets::Compressing

Which is then mixed into 

    Sprockets::Configuration

Which is then included in 

    Sprockets:Base

Which is inherited by 

    Sprockets::Environment

Which is then wrapped in cache by 

    Sprockets::CachedEnvironment. 

It's impossible to just glance at something and know how things are interacting. You change this one method that you thought was only being used in this one part of the project, and something else breaks.

For more information about how Sprockets work, I highly recommend you go to [Rafael's talk](https://www.youtube.com/watch?v=CzFFYelG7WY)

What is the solution to god objects? We can move logic over to helper classes. For example I introduced the [URITar class](https://github.com/rails/sprockets/blob/697cc28fd224a16ecbca091e4a754fc45ffb79e2/lib/sprockets/uri_tar.rb) while I was adding new functionality. It takes a absolute path and trims it down to a relative path, or it can take a relative path, and make it an absolute path. We need this for storing things in the cache. The beautiful thing about this is it has a couple extra methods that make it a little bit cleaner that are not actually exposed to that god object API. We can expose only the things we need. So, it's going to minimize that god object API and it also, hopefully, produces small, easy-to-read files. 

You can look at that file and say, to yourself "I vaguely understand a tar utility can expand or compress a file maybe it's related to that but for URIs". Ideally, this produces readable code and readable code also attracts helpers who read code, believe it or not. As a side-note, I will say that Ruby is object oriented, if you're not super comfortable with objects and classes, please spend a little bit of time there. It's totally worth checking out. Sandi Metz [has a book](http://www.poodr.com/) that I have totally not read, but she's given a ton of conference talks, which I have seen, and you should watch the talks, and I'm sure the book is amazing as well. As well as Katrina Owen as done a ton of Refacotring talks. If you want to see how can we make this better, how can we make this more readable, as well as [exercism.io](http://exercism.io/) is an actual place where you can go and try out your skills. You actually refactor things there. It's pretty cool. They're also working on a book together which I'll actually read when it comes out.

Helping takes commitment, and we do need to respect that. How are different ways that we can respect that commitment? When somebody gives a pull request, even if it's not the best pull request, we, as maintainers, can say "thanks for submitting this". That person cared enough and you can help them, to help you. You can explain the reasons why you're not merging it, or help them to get to a place where you can merge it. You can also help guide them and say "I don't really care about that thing. How about you look at this other thing which I really care about?" And it's a way to get them on board. If you just close an issue, dismiss it, and then lock it: that is not how you attract people to help you. 

What else do people want? People want recognition. Rails has this great leader board. That's actually the reason why I had my first commit under Rails, I wanted to just be on the board, period. Maybe you don't have a leader board, but you can still give recognition.

Maybe your helpers want pizza.

There's a fun story where, when I introduced a feature, I actually broke windows on a minor release of Sprockets, and I had a developer come to me tell me that I broke the build on windows. I had no idea what to do How do I fix this? He helped explain the problem, we worked through it, we pushed a release. Later I went to him and I said "okay, obviously you care about Sprockets, you care about Windows, you have a Windows machine. Can you help me get the Sprockets tests running on Windows?" He was hesitant to commit that much time to a pretty thankless task. I wanted to show how much I would appreciate it so I offered to buy him a pizza for his efforts. I'm not joking. That's not like, hyperbole. "I will actually order delivery for you for a pizza to your home". Well, a couple weeks later, he did it, and he did not happen to, in those couple of weeks, reach out to me and mention "hey, by the way, I live in Germany". But he did live in Germany. I now know lots about ordering pizzas for delivery in Germany and explaining to credit card companies what open source is, I'm happy to do things for people who help me. The cost of the pizza was trivial compared to the time spent on the feature, but the gesture was worth more. We mentioned acknowledgement. Well, thank you, thank you, [Daniel](https://github.com/daniel-rikowski), for doing this, and Sprockets is now tested on a Windows CI server via appveyor. 

All of these things we've talked about good docs, clean code, those are ideals we can strive for. What happens when you actually have the scenario where you inherited a project? Where the precious maintainer might not have done all of these things? They just mic-dropped? What are you going to do? 

You can start by finding something that needs fixing. I call this bug-driven development. I keep on talking about example apps because the only way to get started is with an example app that allows you to reproduce the problem. If I didn't mention example apps are amazing, and you should probably make it a goal to make one this year. 

Oncew you have an example app, reproduce the problem and then repeat. Every single bug that you fix, you're going to learn a little bit more about the code base, and eventually you're going to start seeing non-bug problems. Eventually you're going to be a lot more comfortable. An example of this for me was Source Maps. Source Maps are a thing in Sprockets 4, and it was half-finished when Josh stepped away, and when I got this project, I had no idea what they were. Somebody would report a bug. I would try and fix that bug and it made the tests break, and I had to step back and ask if the tests are even reliable? I've got no clue. So where do we start? I put on my archaeologist hat, which was totally the inspiration for this talk, and I started research. I looked at the Mozilla RFC. I got out  evernote and I started taking notes, and I learned a whole lot about source maps. I eventually was able to take those notes and actually turn them into guides. I took all of that information and said "I don't know this, so other people probably don't know this. Let's not make them work as hard". I made those notes into a guide and I put it in the Sprockets source tree. If you're interested in reading it, it's totally rough, but it works. I've even used it for my own reference more than a few times. So if you want to know what a source map is, then I can tell you, go [read my Source Maps guide](https://github.com/rails/sprockets/blob/master/guides/source_maps.md). In this process I ended up having to borrow from some other projects, I actually used other projects from the technology which shall not be named (NPM). 

I used `uglifyjs` to verify my encoding and make sure that my encoding tests were valid. I used `source-map` to verify that my decoding was test for correct, and then I got the tests to a place where they could pass. So, is source maps finished? No. I need more bug reports that are actionable. 

We've got to wrap up soon. With all of that being said, where do we go? Because maintainers won't be around forever. I won't be around forever. So, I need help. I need help maintaining the history of Sprockets. I don't need you to know everything. I don't need you to go out there and fix all of the problems. You know what? Sometimes I might just need you to help not say bad things about me on the internet. If somebody's like, hey, trash-talking me ask them to clarify their positions into a critique. 

We can preserve these stories by getting involved, and if you don't get involved, then who will? 

It's open source. 

You can say well maybe somebody else will. Guess what? That somebody else is you, and we all need to step up. 

We can take five minutes. We can just read those guides. We can write some docs. We can open some issues. We can create example apps, which I've totally not mentioned before. 


It's only 

five 

minutes. 

I invite you to join me, and together we can become maintainers, we can become helpers, and together, we can Save Sprockets.

