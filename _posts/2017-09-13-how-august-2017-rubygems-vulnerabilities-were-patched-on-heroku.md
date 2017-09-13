---
title: "How August 2017 RubyGems Vulnerabilities were patched on Heroku"
layout: post
published: true
date: 2017-09-13
image: og/heroku-rubygems.png
twurl: https://twitter.com/schneems/status/908046292466663424
permalink: /2017/09/13/how-august-2017-rubygems-vulnerabilities-were-patched-on-heroku/
categories:
    - ruby
---

This is less a blog post and more of an FYI. This is pretty much verbatim of a snippit I wrote to respond to people asking about the Rubygems vulnerabilities. The TLDR; push to Heroku using any supported Ruby version and you're safe. If you're not using a supported Ruby version upgrade your app. The vulnerabilites were fairly low impact, but you should still take steps to protect yourself.

Recently there were reported a number of security vulnerabilities in Rubygems. All supported versions of Ruby on Heroku-16 and cedar-14 have been patched on Heroku. These include:

- Ruby 2.2.7
- Ruby 2.3.4
- Ruby 2.4.1

To get the patch you must be using one of these versions. If you're using an older version, for example 2.4.0 then you must upgrade to the latest supported version in the series, 2.4.1, to get the patch.

If your app is already on one of these patched Ruby versions, you must trigger a deploy to get the patched Ruby version. You can force a deploy by adding an empty commit:

```
$ git commit --allow-empty -m "Deploy to get latest patched Ruby on Heroku"
$ git push heroku master
```

Once you've deployed you can verify the patched version of Rubygems by running `heroku run bash` and then `gem -v`. Make sure the version matches the rubygems version listed on [the Heroku Ruby version devcenter article](https://devcenter.heroku.com/articles/ruby-support#ruby-versions). For example, if you're running 2.4.1 then you should see this:

```term
$ heroku run bash
~$ gem -v
2.6.13
```

When your `gem -v` matches a patched version listed on the devcenter article then you are completely protected from the vulnerability.


## Timeline

The vulnerability was originally announced over twitter with no CVE attached on August 27th (PST):

- [https://twitter.com/segiddins/status/901989418931822593](https://twitter.com/segiddins/status/901989418931822593 )

When a security vulnerability is announced, Heroku will audit to determine the severity and set a timeline for a patch. Due to the lack of a CVE this was difficult to score, and we manually audited through each commit in 2.6.13.

We patched the Ruby 2.4.1 with the available release of Rubygems 2.6.13. Here is the changelog entry:

- [https://devcenter.heroku.com/changelog-items/1251](https://devcenter.heroku.com/changelog-items/1251 )

Typically when a severe security vulnerability is patched, it should come out with only a fix for the vulnerability. If there are other bugfixes or other behavior changes this may cause regressions that will cause previously functioning apps to no longer work. The 2.6.13 version is a security release. You can see it in the changelog:

```
# coding: UTF-8

=== 2.6.13 / 2017-08-27

Security fixes:

* Fix a DNS request hijacking vulnerability.
  Discovered by Jonathan Claudius, fix by Samuel Giddins.
* Fix an ANSI escape sequence vulnerability.
  Discovered by Yusuke Endoh, fix by Evan Phoenix.
* Fix a DOS vulernerability in the `query` command.
  Discovered by Yusuke Endoh, fix by Samuel Giddins.
* Fix a vulnerability in the gem installer that allowed
  a malicious gem to overwrite arbitrary files.
  Discovered by Yusuke Endoh, fix by Samuel Giddins.
```

Usually when a severe security vulnerability is found all supported minor versions that are still maintained will be issued a security only patch. This allows anyone who needs an older version to be protected without having to adapt to any changes in behavior. At the time this patch was released Ruby 2.2.7 was using Rubygems 2.4.5.2 and Ruby 2.3.4 was using Rubygems 2.5.2. No new minor versions of Rubygems were released for these versions.

The Ruby team at Heroku sought the advice of the Rubygems maintainers and were advised that the vulnerabilities are relatively low impact. At the time we determined that if no patched versions of Rubygems were available for the 2.2 series and 2.3 series then we would defer to Ruby core. The reason for this is that the version of Rubygems that comes on Heroku is the default version packaged by Ruby core.

On the 29th Ruby core took action by releasing several patches

- [https://www.ruby-lang.org/en/news/2017/08/29/multiple-vulnerabilities-in-rubygems/ ](https://www.ruby-lang.org/en/news/2017/08/29/multiple-vulnerabilities-in-rubygems/ )

These were not released as new versions of Rubygems which would have been very easy to apply to our build system, but were instead released as patches. To accommodate these we had to update our binary build system.

Once patched binaries are built, they are uploaded to a staging environment where we test them to make sure that the correct version of rubygems was on the platform and there were no mistakes in the compilation process.

On August 30th (PST) the patched versions of Ruby 2.2.7 and 2.3.4 were uploaded to the platform for the heroku-16 and cedar-14 stacks.

- [https://devcenter.heroku.com/changelog-items/1252](https://devcenter.heroku.com/changelog-items/1252)
- [https://devcenter.heroku.com/changelog-items/1253](https://devcenter.heroku.com/changelog-items/1253)


That’s it. Hope that answers any questions you’ve got about what we did to protect your applications and what exactly happened.

Don’t forget to deploy your app if you haven’t already since August 30th and always try to stay on the latest supported patch version of Ruby when possible.
