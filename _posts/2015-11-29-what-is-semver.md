---
layout: post
title: "SemVer for Library Maintainers"
date: 2015-11-29
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

SemVer is simple. Well...until you start publishing libraries, and accidentally break a metric ton of apps on accident. I've never caused any mass scale melt downs, however I've made my fair share of screw-ups. I [maintain gems](https://rubygems.org/profiles/schneems) with over 200 million downloads. I wish I had this guide available to me when I first got in the library authorship game. Let's take a look at what SemVer is and how to use it as a maintainer.

## SemVer is...

SemVer is a way to communicate the stability of your project that computers can understand. It is communicated by numbers like Rails `4.1.7`. This means

```
Major: 4
Minor: 1
Teeny: 7
Patch: nil
```

This version is greater than `3.2.1` and less than `4.1.8`. If SemVer is done properly, computers can resolve your application's dependencies in ways that don't break when you upgrade versions. The short version is that teeny patches are always backwards compatible, minor patches are for new features (that are still backwards compatible) and major versions are for breaking changes.

Note: I'm adding an extra version (teeny) not in the [semver.org 2.0 spec](https://semver.org/). Ruby uses this in Rubygems so that `2.0.0-rc1` would become `2.0.0.rc1` for example [Rails 4.2.0.rc1](https://rubygems.org/gems/rails/versions/4.2.0.rc1).

## Humans are squishy, machines are not

The numbering of SemVer is meant to communicate to computers the backwards compatibility of code. The biggest problem is that this number is generated via a human. Maybe the author didn't realize you were using that interface, removed it, then only bumped the teeny version.

Bug and Security fixes can also mess up SemVer. Sometimes people will rely on incorrect behavior. For example [Ruby recently removed SSLv3 support](https://www.ruby-lang.org/en/news/2014/10/27/changing-default-settings-of-ext-openssl/) from the NetHTTP library. While this development will protect users of the code, it will also break the code. Just because you fixed a bug doesn't mean you get to call it a teeny version bump.

## When to Rev

If you're maintaining code, it helps to understand when to increment which version and when. I write Ruby primarily but most of the examples should apply to all languages.

### Rev Patch

Patch levels are used for betas and release candidates:

```
$ gem install rack --pre
Successfully installed rack-1.6.0.beta2
```

This way the maintainers of Rack can try new things out without saying "this is compatible". The biggest caveat here is that when they release a patch version, no one will try it by default, they have to manually specify.

Really popular projects do this to get feedback. It really helps for you to add `ruby-head` to your Travis CI matrix and to manually try out Rails betas and other library pre versions. If no one tries it, no one gets feedback and a potentially broken version may be released.

Rails has used the convention that a `beta` means unstable. This means that the interface of `beta2` is not guaranteed to be the same as `beta1`. A [release candidate](https://rubygems.org/gems/rails/versions/4.2.0.rc2) or an "rc" is slightly more stable but may have bugs. A release candidate is the maintainers saying "we think this is a totally fine version but we still want cautious people to test it out". Interfaces should be stable at this point and only bugfixes applied to later release candidates.

Note: This is the same behavior as semver.org's patch with a non integer field (i.e. 1.0.1-beta) if your language doesn't have a "teeny".

### Rev Teeny

The teeny version gets revved any time a bugfix or [security release comes out](https://weblog.rubyonrails.org/2013/12/3/Rails_3_2_16_and_4_0_2_have_been_released/). If you added a feature that didn't break anything, should you rev the teeny version? Nope. You should rev the minor version. The key to a correct teeny SemVer is **backwards-compatible**. If a user upgrades their teeny version and something breaks, welp you didn't use SemVer correctly.

### Rev Minor

When you add features, bump the minor version. If your change broke any existing tests or require that you modify existing documentation, it likely should be a major bump instead.

It took me a while to realize why, if our change is still backwards compatible, we shouldn't be able to simply rev a teeny version. There are two reasons for this. First is the ability to downgrade. If there are two versions, SemVer says that `0.0.9` and `0.0.8` are equivalent but the higher version may have bug fixes. If you start developing with `0.0.9` and it has an extra method (a different API), now you can no longer downgrade your app to use the `0.8` version because it will break. This might not happen that often, but when it does, it will be painful.

The second reason is a bit more pragmatic. Even though you think your new API is backwards compatible it may require a future change or bug fix that makes it incompatible. Instead of waiting until that happens to rev a minor version, it is safer to rev it when you introduce the new API.

For me this is one of the harder pills to swallow. I know I should rev minor version more, however what is a new feature? If I add compatibility for my gem to work with a newer dependency, is that a feature or a bug fix? A good rule of thumb could be backwards compatibility test. Would code written in this version work in the previous version? If the answer is yes go for a teeny bump; otherwise it's time to bump a minor version.

### Rev Major

Breaking changes is the major version rallying cry. If you modify an interface, remove a public method, or break any existing tests via your change, then it's most certainly a major version bump. The hardest thing about breaking backwards compatibility isn't revving the version number though, it's about communicating those changes. Before you break, communicate.

The best breaking change communication we've got is deprecations. Add a deprecation and cut a teeny release. A deprecation should emit a warning, letting users know what is breaking and why. Deprecations can be simple:

```ruby
def foo
  puts "DEPRECATION WARNING: Method `foo` will be removed in version 2+. Please use method `bar` instead: #{caller_locations.first}"
end
```

Or they can be sophisticated using built in logging. From the [semver.org docs](https://semver.org/):

> there should be at least one [...] release that contains the deprecation so that users can smoothly transition to the new API.

In a deprecation, say what is going away, the replacement (if there is one), and point to the location in code where the deprecated code was called. Don't forget to update your documentation. While SemVer is for computers it helps to [keep a changelog](https://keepachangelog.com/) for humans.

## There is no going back

In Rubygems any versions are released for good, you can't update them later. If you mess up a release, you can [yank](https://help.rubygems.org/kb/gemcutter/removing-a-published-rubygem) a gem which removes the gem permanently. This should be avoided at all costs, only in cases where the gem would actively do irreversible harm (such as accidentally deleting critical files). Even when your version has a security bug, you shouldn't yank. Instead of yanking, you can release a newer gem with the fixes included. While this leaves little room for mistakes, computers need consistency. Version 1.1.0 of your gem should always behave the same way in 30 seconds or 30 years.

## What about Security?

This is important enough to spell out. When a security fix is backwards compatible you should port it to every supported version and bump the TEENY version. If it's not backwards compatible, release a new TEENY version with a deprecation, it should state that the current version is insecure and also state what feature is changing behavior:

```ruby
puts "Versions 3.5.7 and before of <library name> have a backwards incompatible security vulnerability <link>."
```

State what versions are affected and what versions are safe. This way you won't accidentally break a user's application and if they need to run the insecure code until they can upgrade then they'll be aware of the issue.

If the security vulnerability is bad, you should [look into issuing a CVE](https://seclists.org/oss-sec/2013/q4/43), and notify users if you can.

## Maintaining Multiple Releases

If your library is popular enough for you to need to actively maintain multiple releases, then you can't really use SemVer due to the backwards incompatible security release problem. That being said, if your two maintained releases are under Major versions (i.e. 4 and 5) instead of minor versions (i.e. 4.1 and 4.2) you can use the minor version for backwards incompatible security updates, and deprecate in the teeny versions. While it's not technically SemVer, it's pretty close and it prevents you from releasing backwards incompatible changes into the teeny version number.

## Versioning is Hard

This all may look simple or even border-line on "common sense", but based on the number of breaking changes in teeny versions I've seen: it's much harder in practice. When in doubt of any versioning, ask around. Ask your friends and co-workers. Get people to help [triage your github issues with CodeTriage](https://www.codetriage.com/) and open up an issue stating your intentions. The golden rule is to not break anything in a teeny release. The silver rule is to deprecate and communicate before you break anything.

If you see a library breaking SemVer, be nice, provide them with resources (like a link to this post), and volunteer to help with versioning in the future. In the end versioning is supposed to make your life easier instead of harder. Don't let versioning scare you. Try your best and you'll get it over time. Happy versioning friends.

---
If you like writing code, or versioning arbitrary things [follow @schneems on twitter](https://twitter.com/schneems).
