---
layout: post
title: "Design Driven Tests: This is how I roll"
date: '2014-06-05 08:00:00'
published: true
tags: tdd, testing, ruby
---

The only way to be heard in programming these days is to start fires, and kill sacred cows. To which I'll say: Fuck. That. Here's how I write tests, and write design-driven code. I call it T&DD. It's not a prescription, it's how I work.


## Design Driven Programming

Programming is inherently a creative process. Like writing, painting, and sufficiently advanced mathematics. There's not one right approach to designing anything creative. You must start somewhere. For me, that's usually a ping pong of code and README. I start writing code as soon as possible, and throw it away often. When I'm stuck I go back to writing in my README.

While designing code: Some people write tests, others write BDD style "specs", others daydream for days-and hours until they put digits-to-keyboard. The important thing here is that, there is __A__ design, not how that design was created. When [I remodeled my house](http://helloschneeman.tumblr.com/) I made a design in Sketchup instead of AutoCAD. The result was good, the end users (my wife and I) were happy. Though, I still stand by my statement: [We Should (Absolutely Never) Build Software Like We Build Houses](http://www.schneems.com/2014/03/14/why-we-should-never-build-software-like.html)

The important thing for me: is that I understand my user's wants and needs.

## Tests

I write tests, I write lots of tests. I'm on the Rails issue team and will not :+1: a PR unless it has tests. I don't consider an open source project "shipped" until it has tests. I don't care how or when they got there, I care that they exist. Ideally, they're not overly brittle, and they fail before they break a user's app. If you write your tests after a project is done, how do you know what to test?

I test two things: experiences and interfaces.

## Experience Testing

Call it what you will, Test the things that hurt when they break. Find out how your user's utilize your code and make sure your tests cover that.

For my, somewhat popular, [Wicked gem](rubygems.org/gems/wicked) that implements step-by-step wizards in your controllers, this meant I made a bunch of step-by-step wizard controllers and drove them with Capybara. I wrote a library that uses Puma, so, to test it: [I ran Puma](https://github.com/schneems/puma_auto_tune/blob/master/test/test_helper.rb#L55). If I can test the [Heroku Ruby Buildpack](https://github.com/heroku/heroku-buildpack-ruby/tree/master/spec), then, surely, you can find a way to [Test the Untestable](https://www.youtube.com/watch?v=QHMKIHkY1nM).

To me this just makes sense. When I worked for [Gowalla](http://en.wikipedia.org/wiki/Gowalla), we once had signups broken for 3 days. For a social network: This. Hurt. Afterwards, we added tests around the failure, I made sure to manually test signups and watch metrics after all my major deploys. We never felt that pain again.

Again: test what hurts when it breaks, before it breaks.


## Interface Testing

If you're writing a library, you need to test the interface. Or, how other code will interact with your code. If you're doing experience testing, guess what? You're done. You're already using your library by virtue of running through the developer experience.

I do write "unit" tests, but, mostly for refactoring. My unit tests tell me how all of my code fits together and helps to convey a public interface. People will use your code in unexpected ways, by testing at the unit level, you can reach more cases in less time.

Don't be afraid to throw away these tests, though, when your interfaces change, it may be a good time to rev a [version if you're using sem-ver](http://semver.org/).

## My dirty secret

I do write tests before writing code, sometimes, when it makes sense to me. This is usually when I'm troubleshooting a bug. First, I must reproduce the behavior, then I can isolate the cause and implement a fix. Sometimes, these tests are [written in Ruby code](https://github.com/rails/rails/pull/14373/files#diff-9e1f52d3449a7a0cfdbd3a7afb5d905bR20). Sometimes, they're [bash scripts](https://github.com/sstephenson/sprockets/issues/534) that show the problem. Often it's a manual process. Consider that, even in 2014, you have to physically crash cars to get them certified as street legal. Testing doesn't always fit in a tidy, isolated box.

Whether I start with the test or end with it, anything worth not breaking will be shipped with tests.

## I am not a God Object

Don't take my words as gospel, or anyone else's, for that matter. God objects are bad, in code and in real life. I really enjoyed DHH's keynote, and I find that many of his ideas have been weighed down by the zeal which they've been delivered.

I must frequently make bold claims to get people's attention. They [get eyeballs](http://www.reddit.com/r/programming/comments/20enqe/why_we_should_absolutely_never_build_software/) but, often at the expense of my message. For me, that's okay. One of the biggest points lost from the whole keynote is that, there is no "one way" to write software.

Let's not be ashamed to tell one another how we work. Let's keep striving to get better, and let's be accepting of other's differences. Engage in discourse, but don't fight to win, fight to be better. I'm [@schneems](twitter.com/schneems), and this is how I roll.