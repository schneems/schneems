---
title: "Triage with Me - 11 issues & 2 PRs in 1.5 hours"
layout: post
published: true
date: 2020-09-22
permalink: /2020/09/22/triage-with-me-11-issues-2-prs-in-15-hours/
image_url: https://www.dropbox.com/s/pcxmw6vai9endld/Screen%20Shot%202020-09-22%20at%209.41.27%20AM.png?raw=1
categories:
    - ruby
    - open source
    - issue triage
---

Contributing to open-source can be intimidating, especially when you're getting started. In this post and video series, join me as I triage 11 issues on a repo that I didn't create and don't have much experience with.

I didn't edit the videos, so any mistakes and accomplishments are raw and live to see. I re-watched the videos and took notes on the types of problems I encountered and the questions and solutions that I explored along the way. I cleaned up my notes and put them all here along with the videos so you can follow along. Afterward, if you want to come back to a piece of advice or technique, you can skim my notes instead of re-watching the whole video.

While I don't recommend you sit down and try to respond to every open issue in the repository, hopefully, by watching me triage issues, you can help get a sense of how you might be able to dig in and start contributing. As you're watching, try asking yourself how you would respond and what questions you might ask.

The videos are split up into 4 sections with a bonus video at the end of my work on a PR to remove some deprecations. This open-source repo is written in Ruby, but the issues tended to be about higher-level concepts such as stdout/stderr and accessing APIs via HTTP. As a result, they should be accessible to someone from any programming language background. I've never triaged the issues on this repo before, so be prepared for a raw and real-time triaging session.

> Recommended: Increasing your resolution on YouTube to the maximum so you can read the text better.
> Recommended: Increasing the playback speed to 1.5x or higher since I didn't cut out the "umms" and pauses either.

If you like this "with me" series, find me on [twitter @schneems](https://twitter.com/schneems) and pitch me what you would like for me to work on live and record for another session.

## Triage session 1/4

<iframe width="560" height="315" src="https://www.youtube.com/embed/Y8keqeNXizo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Issue 1 [Heroics should use keep-alive connections #16](https://github.com/interagent/heroics/issues/16)

- Use the GitHub UI to identify commentators of note Contributor/Author/Member
- Ask: "Do I understand the issue?"
  - List your assumptions, ask for clarification if needed
- Ask: "Is this still a priority?"
  - If we don't know if it's a priority, how could we find out? Is there a way for us to test our assumptions about prioritization? i.e., how could we write a benchmark to quantify "give some nice speedups."
- View: Code that's mentioned [Link#run](https://github.com/interagent/heroics/blob/3278cc6dbedc64b2d06571f869f249dbce574f18/lib/heroics/link.rb#L25-L102)
  - Grab some example code or write some pseudo-code to validate we understand each other correctly.
  - Read the docs of the mentioned code
- Ask: "Can you point me at another location where this is implemented?"
- Thoughts:
  - As the triager, you do not need to fully understand every aspect of the conversation, but you need to work to drive the issue to completion.
  - When someone talks about performance, ask for benchmarks or other ways we can quantify it. If they give benchmarks, run them, and verify the results.
  - Context building is an important activity. If you don't have enough context from the issue, likely, others don't have enough either.

### Issue 2 [Examples produced by the CLI don't show correctly help options #28](https://github.com/interagent/heroics/issues/28)

- Click: Check linked issues for possible additional context.
- View: If the reporter mentions code you've never seen before, find it.
  - In addition to the code referenced, try to see if there are other references to the code. What is the context around that code?
- Reproduce: On bug reports with reproduction steps, see if you can follow the reproduction steps and verify the bug.
  - In the video, this is where we found the bug "uninitialized constant Moneta."
  - Ask: "Where is this code or constant defined."
    - Search for where Moneta is defined (Is it internal? Is it external?)
  - Moneta is defined as a dependency in the Gemspec
  - Add the missing require to fix the failure
  - The reproduction example runs now that the original reporter gave us without an error
- Document: Deprecation warnings and other problems that come up that might be good for future contributions
- Thought: Many issues straddle the line between feature and bug report. Bug reports are easier to work with than feature proposals. See if you can treat the issue as a bug.
- When I tried to reproduce their example, I couldn't, and it looks like the issue had already been fixed.
- Thought: It takes work to verify a reproduction is valid or not, and the process can yield a lot of context (in this case, a PR to fix the moneta require issue even).
- In writing out a response, state what you've observed and then what you believe to be accurate based on those observations.
  - Explicitly state what you think the next steps should be (i.e., close the issue, more research, asked for clarification, etc.) and support the statement.

- We took the fix for the moneta failure we saw earlier and made it into a PR.
- Tool: I use the open-source GUI [gitx](https://rowanj.github.io/gitx/) to stage commits and write messages. It's not required, though.
- Ask: When making a PR, "Does this need a changelog?" "Does this need tests?", or "do tests need to be updated?"

## Triage session 2/4

<iframe width="560" height="315" src="https://www.youtube.com/embed/Wo69bL0XhpA" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Issue 3 [feature: automatic generated web admin ui #36](https://github.com/interagent/heroics/issues/36)

- For feature requests: What's the context, opportunity, and implementation?
  - Context: Looking for an easier way for non-programmers to interact with an API
  - Opportunity: This could be solved by a web interface
  - Implementation: They're asking for this feature to be baked into this library, but no other details.
- Try to find empathy and understanding. What drove the original creator to ask the issue?
- Ask: For a feature request, is the best place for this feature inside of this library
  - Can the feature be provided externally, via another library, plugin, or extension?
- I say "sorry" not because I'm personally sorry in this case. However, instead, I empathize that the experience of getting no response is not great and that I still value their participation in the open-source community.
- When suggesting issues should be closed, I suggest ways the issue creator can continue even though the issue is being closed. For example: porting the suggested feature to its own library.
- Even closing issues requires empathy when doing it respectfully, and that empathy takes energy. The more people are helping, the more energy to go around.

### Issue 4 [Errors should go to stderr #40](https://github.com/interagent/heroics/issues/40)

- I start off trying to do an ad-hoc demonstration of stdout and stderr
  - Deprecation warnings go to stderr so that captured and piped output can be sent to other sources such as `jq`.
  - To [skip past me explaining what stdout and stderr are: jump to 14:46](https://youtu.be/Wo69bL0XhpA?t=886)
- The issue included a script to run that shows the problem. I try to reproduce the bug.
  - Verify stated behavior is the actual behavior
  - In the process of reproducing this stated bad behavior, I found another issue where the exit code `$?` returns a success status code (i.e. `0`) even when the command failed due to an incorrect flag.
- The report referenced a command `heroics-generate`. Unsure of its use, I looked it up in the project and found documentation on the README.md
  - I see the issue reported is using a suggested pattern from the README
  - While the issue states what they desire "to use stderr instead of stdout," I see another way that could be used to address the issue using CLI arguments
- I opened a new issue with the exit code behavior I saw before
  Issues need to describe the problem and describe what you expected to happen and what actually happened. Also, add relevant details like version numbers, operating system, etc. where relevant.

## Triage session 3/4

<iframe width="560" height="315" src="https://www.youtube.com/embed/6-XthOjomOw" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>


### Issue 5 [Escape identifiers #41](https://github.com/interagent/heroics/issues/41)

- Review linked resources
  - Click "y" on a GitHub page to get a URL with the commit SHA in it. When you post the link back to the issue, it should always stay valid and point to the code at that point in time, even if the file is deleted or modified later.
  - If someone links to a resource that is no longer valid, it's helpful to find what they're talking about and comment back with a link to it.
  - Consider copying relevant information from linked resources (in addition to linking) so people can get context without having to move away from the issue.
- You might notice that I use block quotes to reference things someone else has said and then reply to them. It's unnecessary, but I find this convention can cut the confusion, especially if you find yourself wanting to respond to multiple things.
- Ask: Is it possible that someone is using/abusing this bug as a feature
  - If so, ask how likely that use is, what's the impact to this person of fixing the bug, and if there's any way to safely detect this usage so it can be warned/errored/deprecated.
  - Even if you don't see a "valid" reason why someone might use something non-standard, breaking it is still a breaking change. If you value stability for your project, you need to consider the migration experience. Keyword: Backwards compatibility.
- If the issue contains a bug, ask for a reproduction or try to reproduce it.
  - The reporter might be describing behavior that has been fixed. They might be using an older version. Ask for versions.
- I use Grammarly for help with spelling and grammar. Reading sentences with grammar errors makes it harder to understand the underlying message. Taking time to clean up and clarify your comment means less time for other people reading.
  - This is also true in any distributed communication environment, such as a remote job where you're communicating via slack/email/issues.


### Issue 6 [chunked encoding support #42](https://github.com/interagent/heroics/issues/42)

- I didn't explain it, but a chunked response is when you send parts of your response back at a time, imagine 1/4 of a web-page sent four times, instead of all of the data in a single request.
- When you can treat an issue as a bug report, it becomes easier to work with.
- If the reporter only gives the expected response, ask for the current response/behavior.
- Ask for a way to reproduce the issue.
  - I link to https://www.codetriage.com/example_app to give the poster more context over what I'm asking for. Previously I would say, "can you give me a reproduction" and people would respond with several things from "what does that mean" to "my app is private, I can't give you the source code." This article intends to pre-emptively answer as many of these common questions as possible to guide the poster to give you what you need to drive the issue to completion.

### Issue 7 [Validating request payload client side #51](https://github.com/interagent/heroics/issues/51)

- The more context required to understand an issue that isn't explicitly laid out, the harder it will be to understand the problem, and the less likely progress will be made on the issue.
  - The feature request is vague enough that I felt I had to spend time explaining it in the video. I could have asked for clarification instead.
- Ask: Is the behavior the reporter is describing true?
  - Gonna sound like a broken record: Ask for a reproduction
- Read what other commenters have said, try to understand their comments.
- A commenter left links to files that no longer are valid
  - Find the correct links and get a "y" version (link to a specific commit).
- Ask: If the proposed behavior is implemented, what are the consequences? Both good and bad. What if it's not implemented? Is the bad that bad? Is the good that good?
- Ask: Is there another way to achieve the requested goals?

## Triage session 4/4

<iframe width="560" height="315" src="https://www.youtube.com/embed/H-u46L33oHo" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

### Issue 8 [Add `connect_url` or similar method to generated clients #52
](https://github.com/interagent/heroics/issues/52)

- Read the issue, read the comments. Understand the feature request.
- Consider the age of the feature request and the movement/momentum on the issue. Even if something is a good idea, it might not make sense to prioritize it.
- This was the fastest issue that I closed so far. I mention that it might be I'm running out of emotional energy (i.e., patience). You need to be protective of your energy and time, but also you don't want to do a sub-par job.


### Issue 9 [Exposed ETags #63](https://github.com/interagent/heroics/issues/63)

- I explain heroics (again) and then etags. If I didn't know what etags are, I would have searched for them, likely read Wikipedia and look for some examples. You could ask for how to do what they're asking (make requests to the Heroku API with etags) without Heroics as one possible path forwards.
- I wanted to take the issue and expand on it. Instead, I decided to hold off and validate their request. I did mention my own needs/desires for a more consistent low-level interface.
- I suggest closing the issue since "no one is actively working on it right now."
  - Instead of just closing, I provide an example of what could be useful to move the issue forwards: specific ideas of API design or example code, a PR, etc.
  - Whenever I close an issue, I want to leave guidance for what might prompt me to re-open it (when relevant).
  - Related to my real-life experience of "arguing effectively." When I need to walk away from a situation/argument, it will feel rude and abrupt if you just leave. This could spark further conflict. Instead, I state that I'm leaving and making a plan for when we can revisit and come back to the issue.

### Issue 10 UTF-8 with bom fails generating a client

> Note: I'm purposefully not linking to this one because I got frustrated writing this response. I don't want anyone posting anything negative to the thread. Later on, in the video, I enumerate some common types of seemingly "bad behavior" that might be attributed to other things such as English not being the first language (just an example, I don't know this person at all). At the end of the day, my goal is to help the open-source project. I appreciate they took the time to open an issue. At this point in my marathon triaging session, I'm a little out of patience. I wanted to leave these issues in my videos as I think they represent real feelings and experiences you'll have in the open-source community. Again: I don't want to shame, or diss, or hate on this poster. Please take my comments in the general sense and with a grain of salt. Be nice. Be kind. Build community, not hate.

> Update: I looked it up, and they're from Saint Petersburg, so likely my read of "English not their first language" is likely correct.

- I am frustrated by this issue. They were asked to provide more information and then didn't describe the issue as "it is simple."
  - "99% of triaging issues is asking for reproductions/example-apps and verifying that they behave as described."
  - If you're opening an issue, please be considerate of the maintainer's time and energy. Don't ask them to do things that you can do for them.
  - If you're frustrated with an interaction, try to center yourself on the common goals: In this case, everyone wants the open-source library to be better.
  - If you must write a snarky response, don't send it. Or maybe send it to a friend or something. Be nice. Issue reporters and commenters are contributing too. Empathy generates empathy, snark generates frustration and more snark.


While I'm somewhat accidentally on the topic of behavior that I don't like: I encourage you to try to have empathy and understand if maybe there's another way a comment could be interpreted. At the same time, if you see a pattern of bad behavior or a comment crosses a personal line, be protective of yourself and your community. 99% of the time that I've messaged someone privately saying, "when you said <x> it made me feel <y>, and that's bad," they apologized and fixed the behavior. This experience is where my comment of "maybe English is not their first language" came from. Most of those people I told them their words were hurtful had no idea and genuinely appreciated the opportunity to improve. For actual bad actors, there are mod tools. In general, I recommend the communication technique Non-Violent Communication - NVC. At a high level: state your observation, say how it made you feel, state what you require, explicitly state what you need from the person.

- Stating, "I don't know what this means" is difficult, especially on the internet. It's helpful to state what you didn't understand because if you have a question, it's likely someone else does. By taking that risk, that leap of stating what wasn't clear, you're normalizing the community's behavior.
- Some people who create issues don't know that not having a reproduction attached to an issue is the blocker to moving forwards. Sometimes you, as the issue triager, need to push back a little stronger. If they've already been dragging their feet, then stating, "let's close this until we can get a reproduction" might motivate them to work on providing the needed example.

### Issue 11 I dont have definitions in my json schemas #67

> Note: Also not linking to this one due to my previous "frustration" comments. It's the same person. Here's where I first realize that English might not be their first language.

- Triaging multiple issues in the same repo helps show you patterns and context you wouldn't otherwise get. For example, the fact that one person created multiple issues. Even if they're not explicitly linked via URLs, they might be related.
- It's okay to not understand an issue AT ALL when you read it. When this happens, you need to figure out if you want to invest the time and energy to learn more or cut your losses and move on to another issue. When you're first getting started, you'll be confused more often than you'll know what you're doing. One "hack" is to timebox your involvement with issues. I'm shooting for about 10 minutes here roughly. If, after that time, I still had no clue, I could choose to ask some clarifying questions possibly or to instead invest my energy in another issue.
- When I said, "that's what I would have said as well." I'm referring to the statement by them to ask the poster to provide a PR for additional docs.
- At this point, I mention the grammar of the issue and introduce the idea that maybe English is not their first language.
- If you're opening up an issue, try not to accidentally write in a commanding tone. Instead of "you should point to this problem in your readme," maybe a softer, "the readme should point to this problem." Describe the end goal instead of the action to get to the end goal.
- Closing issues is better when you yell out "CLOSED" in a happy and accomplished voice.
- If you didn't know, you can edit the README or docs without ever needing to leave the web interface of GitHub.
- Triaging issues is exhausting. My patience is wearing thin, and it's showing in my responses. The more people who can help, the better responses and interactions the community will have.

At this point, there were 2 issues left. One of them was about deprecations, and I already wanted to work on it. I had previously commented on it. The last issue was one that we opened in a prior issue triaging session.

## (Bonus) Paring pull-request session 5/4

<iframe width="560" height="315" src="https://www.youtube.com/embed/Ow9H2gvFBjE" frameborder="0" allow="accelerometer; autoplay; encrypted-media; gyroscope; picture-in-picture" allowfullscreen></iframe>

- If you're going to deprecate a method, please provide a suitable replacement suggestion instead of "this method is obsolete."
  - URI.escape and URI.unescape are both deprecated in Ruby
  - The docs recommend CGI.escape
- I use Duck Duck Go as a search engine mostly because I don't like Google AMP and want to use the same engine on my phone and desktop. With DDG, you can "fall back" to a google search by adding "g!" to your query, which sends you to google. I don't use it often but need to here.

- The decision to deprecate URI.escape is 10 years old.
- Docs that come up from APIdoc often show up first but frequently have wrong info. I want ruby-doc.org instead when possible.
- When I got to the CGI page on ruby-doc.org, I searched "escape" in the browser and couldn't find that method. When that happens, sometimes the method comes from an included module, so I click through to the `CGI::Util` module. This module is where the method is defined.
- I started to blindly replace `URI.escape` with `CGI.escape` in the code.
- A tab I previously opened was linked to a PR that got rid of the warning. I used this to investigate how they fixed the issue. They used `URI::DEFAULT_PARSER.escape`.
- When I ran into that constant, I wanted to investigate it because it was unfamiliar. I loaded up IRB to investigate.
- I re-read their PR to see if they left more context or comments.
- At this point, I thought since the docs recommended CGI, I was more comfortable using that.
- I decided to test it in IRB since I already had it open.
- CGI.escape is not a suitable replacement.

```
require 'cgi'
irb(main):003:0> CGI.escape("url here")
=> "url+here"
irb(main):004:0> URI.escape("url here")
(irb):4: warning: URI.escape is obsolete
=> "url%20here"
```

> Note: that the results are different

- I decided to use `URI::DEFAULT_PARSER` instead of `CGI`.
- After making the change, I ran the tests to see if that got rid of all the deprecation warnings in the output.
- I tried updating my gems to get rid of deprecation warnings. Investigating the `turn` I see it's not had a new release since 2014, and the repo is marked as unmaintained.
- Question: Are we using this library that is marked as unmaintained? Removing the gem gives us an error.
- At this point, I don't know what it does and don't know how long it will take to remove it. I decided to clean up the other warnings and save that for last if there's time.
- For the warning "assigned but unused," you can use the character underscore `_` as a variable to tell Ruby that you don't care about using the variable.
- For the duplicate test method, my initial thought is someone copied and pasted the whole method again by accident. On closer investigation, they're similar but not the same. I rename one of the methods.
- You can start a commit message with `[close #<issue number>]`, and when it's merged into the default branch, it auto closes that issue. It's also helpful for bookkeeping later to ensure it's clear the issue and the PR are related.
- When writing a commit message, try to give the maximum amount of context. Imagine if you had amnesia and found yourself in front of the commit message and need to understand why you did what you did. In this case, I wanted to link to external resources. I also realized I didn't read through the history of why `URI.escape` is deprecated and might want to later, so I use the commit as a place to store the link.
- Usually, when I make a PR, I bundle all the changes into one commit via [squashing my commits](https://www.codetriage.com/squash). Conventions vary based on the project. Some people try to "pad" their contribution with extra commits, so it looks like they're more active/helpful than they really are on a repo. Don't do that. Do what's right for the conventions of the community you're working with and what's best for the project. I said "rebase" but meant "squash."
- Since I don't know how deeply integrated `turn` is into the project, I want to timebox removing it.
- I deleted the references to turn, and the tests pass.
- It might seem redundant to re-write a good PR message since there are already links to the commits with individual contexts. It's worth spending the extra time and writing good PR messages and descriptions, so all the appropriate context is available with minimal maintainer effort.
- Notice that I'm re-using my notes from working on the issue while making the PR.
- It's not guaranteed that triaging issues will show you pull request opportunities, but it's an excellent place to start looking and start building context.

## Wrap Up

If you're inspired to go work on some open-source issues and don't know where to get started, I recommend [signing up for CodeTriage](https://www.codetriage.com). If you like this "with me" series, find me on [twitter @schneems](https://twitter.com/schneems) and pitch me what you would like for me to work on live and record for another session. You can also [subscribe to my email newsletter](https://schneems.com/mailinglist) to get more content.

