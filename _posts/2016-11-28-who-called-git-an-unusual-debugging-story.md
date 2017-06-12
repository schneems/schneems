---
title: "Who Called Git? An Unusual Debugging Story"
layout: post
published: true
date: 2016-11-28
permalink: /2016/11/28/who-called-git-an-unusual-debugging-story/
categories:
    - ruby
---

I don't usually talk about support ticket work that I do. Most tickets are so specific it's hard to write generalized articles. When I get a type of ticket that is worth blogging about, I usually find a better place to write about it like devcenter docs, or I look for a way to push a fix to an upstream open source library. Today I got an unusual bug, and I fixed it in a fairly unusual (for me) way. Thought you might be interested.

## The Issue

The customer was complaining that this output was coming out when they would run commands

```
$ heroku run rails console
fatal: Not a git repository (or any parent up to mount point /app)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
```

Originally they thought that the issue may have been coming from our `heroku` CLI since the issue wasn't happening locally.

> BTW, did you know you can open up a shell session to Heroku using `heroku run bash`. I've been telling people this for about 5 years and it's still surprising to them, very useful for debugging.

Anyway, after a little investigation it turns out that they get that output any time you run any app commands on the server

```
$ heroku run bash
~$ rake assets:precompile
fatal: Not a git repository (or any parent up to mount point /app)
Stopping at filesystem boundary (GIT_DISCOVERY_ACROSS_FILESYSTEM not set).
# ...
```

The problem isn't that traumatic, but it's annoying. Also, it's best practice to run with as few warnings as possible. On an unrelated support ticket: a customer of mine was getting a warning that told them exactly how to fix their problem, but they didn't notice it because they were regularly getting 5 or 6 other warnings on deploy so when a new one was added they didn't see it and didn't take action.

## Bug Hunt

The customer gave application access so I was able to reproduce the issue pretty easily. That error output is what you would get if you try to run a `git` command when there isn't a git repo.

```
$ cd /tmp
$ git checkout foo
fatal: Not a git repository (or any of the parent directories): .git
```

If you didn't know where the message came from, a quick google would point `git` as being the source of the error. But why was this only happening on Heroku?

One of the ways that we make scaling so fast is that we package your app in a zipped file and (roughly) all we have to do to get it to run is put it on a dyno and unpack it. One of the limiting factors is how fast we can transfer the zipped file (we call it a slug), so we recommend keeping the size of your repo low. To help with this we strip out the `.git` directory of your app since it only adds extra disk space and makes scaling, restarting, or migrating to other dyno types slower. The error from git is telling us that we're trying to run a git command with no git repository. This makes sense since we strip the `.git` directory.

So we know why the issue is happening (no git repo on the dyno plus we're running a git command). But we don't know where the issue is happening, i.e. what is triggering that git code.

My first instinct was to grep their app for `git` calls:

```
~ $ grep -R git app/* config/* lib/*
```

I got a few hits but they were mostly `di"git"` strings, no smoking guns.

Expanding the search to all directories gave me way too many hits. 5210 references to the string `git` to be exact. It would take too long to go through all of them.

We can get a bit more specific if we assume we are shelling out searching for `"\`git"` however there's still 195 entries, which is still quite a bit.

## The Trick

While this specific problem isn't that common, this general type of problem is. When one program calls another one, we usually want to know where in the first program that the second was being called. In a perfect world we would be able to raise an exception in the second program and get a backtrace from the first, however this doesn't always work. In our case the call to git was erroring and returning a non-zero exit code, however the parent program was ignoring it.

The only option I had was to attempt to get more information. I figured maybe if I could find out what arguments are passed to `git` I could better find the problem.

To do this I wrote an executable to `bin/git` and since `bin/` is first on the path, the OS will pick it over the orignial `git` command.

```
$ heroku run bash
~$ cat <<EOT > bin/git
#!/usr/bin/env ruby

raise ARGV.inspect
EOT
```

> Don't be alarmed, we aren't modifying your production code, a `heroku run` instance spins up a new dyno that isn't connected to your running app. You can do whatever you want to this instance's disk and it won't effect your production website.

You also have to make sure it's executable

```
~$ chmod +x bin/git
```

Now we can see that our command is preferred:

```
~ $ which git
/app/bin/git
```

Now when we run any command against the app we get a new error output

```
/app/bin/git:4:in `<main>': ["rev-parse", "--short", "HEAD"] (RuntimeError)
```

This gives us more information. The output means that git is being called with `git rev-parse --short HEAD`. A quick grep for this gives us one and only one match:

```
~ $ grep -R "git rev-parse --short"
.../gems/raven-ruby/lib/raven/configuration.rb:      self.release = `git rev-parse --short HEAD`.strip rescue nil
```

This was comming from the [raven gem](https://github.com/getsentry/raven-ruby/blob/56761da7df7941f386c85605745df1bbb1a3e149/lib/raven/configuration.rb#L142) which is a sentry client. They are trying to determine the SHA of the latest "release" to report to the sentry server, but they weren't checking to see if a `.git` folder was present first.

So that's where our error message was coming from. It turns out this was already [fixed on a more recent version of raven](https://github.com/getsentry/raven-ruby/blob/37753a4eb34177bbb285d081326bbd16293de222/lib/raven/configuration.rb#L298) where the check was added.

After the customer upgraded to a more recent version of `raven` and the error went away!

## Thoughts

Writing a custom executable to output debugging info isn't a common technique and likely you'll never use it. I wanted to write this because it was an interesting case, maybe there is a better way to find this info, but this one worked just fine.

We don't always go on such deep dives for customer issues, but if we get a ton of similar error reports or find an issue that is intriguing enough, sometimes we can dig in, and sometimes it's fun.
One debugging technique I do use ALL the time that would have potentially solved this issue is to update gems. Most people run with really old dependencies. Usually I recommend this when there is some related culprit. For example if `rake assets:precompile` is failing I suggest upgrading any gem with "sprockets" or "asset" in the name. Often bugs are fixed by the larger community but you won't take advantage of those fixes unless you upgrade to a version with that fix.

If you don't have a smoking gun of where the problem is coming from, you can run `bundle outdated`. This is an example of the command run against the [rubygems.org](https://github.com/rubygems/rubygems.org) repo:

```
$ bundle outdated
Fetching gem metadata from https://rubygems.org/........
Fetching version metadata from https://rubygems.org/..
Fetching dependency metadata from https://rubygems.org/.
Resolving dependencies....

Outdated gems included in the bundle:
  * psych (newest 2.1.0, installed 2.0.17, requested ~> 2.0.12) in group "default"
  * rack (newest 2.0.1, installed 1.6.4) in group "default"
  * rails (newest 5.0.0, installed 4.2.7.1, requested ~> 4.2.7) in group "default"
  * actionmailer (newest 5.0.0, installed 4.2.7.1)
  * actionpack (newest 5.0.0, installed 4.2.7.1)
  * actionview (newest 5.0.0, installed 4.2.7.1)
  * activejob (newest 5.0.0, installed 4.2.7.1)
  * activemodel (newest 5.0.0, installed 4.2.7.1)
  * activerecord (newest 5.0.0, installed 4.2.7.1)
  * activesupport (newest 5.0.0, installed 4.2.7.1)
  * arel (newest 7.0.0, installed 6.0.3)
  * rails-dom-testing (newest 2.0.1, installed 1.0.7)
  * railties (newest 5.0.0, installed 4.2.7.1)
```

Thanks to [Nate](https://www.speedshop.co/) for reminding me about this command at Rubyconf. Also, coincidentally, he happens to be the person who made the fix in the Sentry client.

---
If you liked this consider [following @schneems on twitter](https://twitter.com/schneems) or signing up to get [new articles in your inbox](https://eepurl.com/bbuvuz) (about 1 email a week when I'm on a roll).

