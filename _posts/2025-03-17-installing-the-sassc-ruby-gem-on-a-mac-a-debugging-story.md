---
title: "Installing the sassc Ruby gem on a Mac. A debugging story"
layout: post
published: true
date: 2025-03-17
permalink: /2025/03/17/installing-the-sassc-ruby-gem-on-a-mac-a-debugging-story/
image_url: https://www.dropbox.com/scl/fi/w9zc274inj5749kn5df2v/Screenshot-2025-03-14-at-3.12.03-PM.png?rlkey=de2mlqabswywckz0o9a0apos8&raw=1
categories:
    - ruby
    - debugging
---

I'm not exactly sure about the timeline, but at some point, `gem install sassc` stopped working for me on my Mac (ARM). Initially, I thought this was because that gem was no longer maintained, and the last release was in 2020, but I was wrong. It's 100% installable today. Read the rest to find out the real culprit and how to fix it.

> FWIW some folks on [lobste.rs](https://lobste.rs/s/d69ogy/installing_sassc_ruby_gem_on_mac) suggested switching to [sass-embedded](https://rubygems.org/gems/sass-embedded) for sass needs. This post still, works but into the future it might not.

In this post I'll explain some things about native extensions libraries in Ruby and in the process tell you how to fix this error below if you're getting it on your Mac:


```
Gem::Ext::BuildError: ERROR: Failed to build gem native extension.

    current directory: /Users/rschneeman/.gem/ruby/3.4.1/gems/sassc-2.4.0/ext
/Users/rschneeman/.rubies/ruby-3.4.1/bin/ruby extconf.rb
creating Makefile

current directory: /Users/rschneeman/.gem/ruby/3.4.1/gems/sassc-2.4.0/ext
make DESTDIR\= sitearchdir\=./.gem.20250314-33410-os7ibg sitelibdir\=./.gem.20250314-33410-os7ibg clean

current directory: /Users/rschneeman/.gem/ruby/3.4.1/gems/sassc-2.4.0/ext
make DESTDIR\= sitearchdir\=./.gem.20250314-33410-os7ibg sitelibdir\=./.gem.20250314-33410-os7ibg
compiling ./libsass/src/ast.cpp
compiling ./libsass/src/ast2c.cpp
make: *** [ast.o] Error 1
make: *** Waiting for unfinished jobs....
compiling ./libsass/src/ast_fwd_decl.cpp
make: *** [ast2c.o] Error 1
compiling ./libsass/src/ast_sel_super.cpp
make: *** [ast_fwd_decl.o] Error 1
compiling ./libsass/src/ast_sel_cmp.cpp
make: *** [ast_sel_super.o] Error 1
compiling ./libsass/src/ast_supports.cpp
make: *** [ast_sel_cmp.o] Error 1
compiling ./libsass/src/ast_sel_weave.cpp
make: *** [ast_supports.o] Error 1
compiling ./libsass/src/ast_values.cpp
compiling ./libsass/src/backtrace.cpp
make: *** [ast_sel_weave.o] Error 1
compiling ./libsass/src/ast_selectors.cpp
make: *** [ast_values.o] Error 1
compiling ./libsass/src/ast_sel_unify.cpp
make: *** [backtrace.o] Error 1
make: *** [ast_selectors.o] Error 1
make: *** [ast_sel_unify.o] Error 1

make failed, exit code 2
```

## Last things first: How to fix the problem

You can install the `sassc` on your Mac by:

- Uninstall(ing) your ruby version(s)
- Delete your gems (or at least `sassc`)
- Update to a recent Xcode release (`$ xcode-select --version` for me reports `xcode-select version 2409`)
- Re-compile Ruby version(s)
- Now `gem install sassc` should work

If you want to know more about native compilation or my debugging process, read on!

> There might be a simpler way to solve the problem (such as directly editing the rbconfig file), but I'm comfortable sharing the above steps because that's what I've done. If you fixed this differently, post the solution on your own site or in the comments somewhere.

## Debugging: Collecting info

When I get an error, it makes sense to search for it and ask an LLM (if that's your thing). I did both. GitHub copilot suggested that I make sure command-line tools are installed and that `cmake` is installed via homebrew. This was unhelpful, but it's worth double-checking.

Searching `libsass make: *** [ast2c.o] Error 1` brought me to [https://github.com/sass/sassc-ruby/issues/248](https://github.com/sass/sassc-ruby/issues/248). This brought me to [https://github.com/sass/sassc-ruby/issues/225#issuecomment-2391129846](https://github.com/sass/sassc-ruby/issues/225#issuecomment-2391129846). Suggesting that the problem is related to RbConfig and native extensions. These have the fix in there, but don't go into detail on the **why** the fix works. This post attempts to dig deeper using a debugging mindset.

> Meta narrative: This article skips between explaining things I know to be true and debugging via doing. Skip any explanations you feel are tedious.

## Explaining: Native extensions

> Skip if: You know what a native extension is

Most Ruby libraries are plain Ruby code. For an example look at [https://github.com/zombocom/mini_histogram](https://github.com/zombocom/mini_histogram). When you `gem install mini_histogram`, it downloads the source code, and that's all that's needed to run it (well, that and a Ruby version installed on the machine). The term "native extensions" refers to libraries that use Ruby's C API or FFI in some way. There are a few reasons why someone would want to do this:

- Performance: A really expensive algorithm might run faster if it's written in a different language and then invoked by Ruby.
- Interface: A library doesn't want to reinvent the wheel, so it leans on already existing software installed at the system level. For example, if a program needs to handle SSL connections, it can use OpenSSL on the system instead of rewriting all of that logic in Ruby. For example, the `psych` gem uses `libyaml`, and the `nokogiri` gem uses `libxml`.

For developers who haven't used much C or C++, it's useful to know that system-installed packages are how they (mostly) share code. There's no rubygems.org for C packages. Things like `apt` for Ubuntu might be conflated as a "C package manager," but it's really like `brew` (for Mac), where it installs things globally. Then, when you compile a program in C, it can dynamically or statically link to other libraries to use them.

Back to native extensions: When a gem with a native extension is installed the source code is downloaded but then a secondary compilation process is invoked. Here's [a tutorial on creating a native extension](https://dev.to/vinistock/creating-ruby-native-extensions-kg1). It utilizes a tool called [rake-compiler](https://github.com/rake-compiler/rake-compiler). But under the hood it effectively boils down to when you `gem install <native-extension>` it will run compilation code such as `$ make install` on the system. This process generates compiled binaries, these binaries are compiled against a specific CPU architecture that is native to the machine you're on, hence why they're called native extensions. You're using native (binary) code to extend Ruby's capabilities.

## Explaining: Vendoring in native extensions

> Skip if: You understand why `libsass` CPP files would be found in the `sassc` gem

Compiling code is hard. Or rather, dependency management is hard, and compiling code requires that the platform have certain dependencies installed; therefore, compiling code is hard. To make life easier, one common pattern that Ruby developers do is to vendor in dependencies into their native extension gem. Rather than assuming `libsass` is installed on the system in a location that is easy to find, it can instead bring that code along with it.

Here you can see that sassc from `gem install sassc` brings C++ source code from libsass:

```term
$ ls /Users/rschneeman/.gem/ruby/3.4.2/gems/sassc-2.4.0/ext/libsass/src | head -n 3
MurmurHash2.hpp
ast.cpp
ast.hpp
```

In this case `libsass` may have dependencies that it hasn't vendored and it expects to find on the system, but the key here is that when you `gem install sassc` it needs to `make install` not just its own bridge code (using Ruby's C API), but it also needs to compile `libsass` as well. That is where the errors are coming from, it's not able to compile these C++ files:

```term
compiling ./libsass/src/ast2c.cpp
make: *** [ast.o] Error 1
make: *** Waiting for unfinished jobs....
```

For completeness: There's another type of vendoring that native-extension gems can do. They can statically compile and vendor in a binary. This bypasses the need to `make install` and is much faster, but moves the burden to the gem maintainer. Here's an example where [Nokogiri 1.18.4 is precompiled to run on my ARM Mac](https://rubygems.org/gems/nokogiri/versions/1.18.4-arm64-darwin). You don't need to know this for debugging the `sassc` install problem, since that process isn't being used here.

## Debugging: Remove ruby from the loop

When debugging, I like to remove layers of abstraction when possible to boil the problem down to its core essence. You might think "I cannot run `gem install sass` " is the problem, but really that's the context; the **real** problem is that within that process, the `make` command fails. The output of the command isn't terribly well structured, but there are hints that this is the core problem:

```term
current directory: /Users/rschneeman/.gem/ruby/3.4.1/gems/sassc-2.4.0/ext
make DESTDIR\= sitearchdir\=./.gem.20250314-65761-9llhhv sitelibdir\=./.gem.20250314-65761-9llhhv
compiling ./libsass/src/ast.cpp
compiling ./libsass/src/ast2c.cpp
```

This is saying, "When I am in this directory" and "I run this command `make <arguments>`" then I get this output.

When someone is experiencing an exception on their Rails app, I encourage them to try copying that code into a `rails console` session to reproduce the problem without the overhead of the request/response cycle. This helps reduce the scope and removes a layer of abstraction.

Here removing abstraction will be manually go into that directory and run `make`. Doing this gave me the same error:

```term
$ make clean && make
compiling ./libsass/src/ast.cpp
compiling ./libsass/src/ast2c.cpp
compiling ./libsass/src/ast_fwd_decl.cpp
make: *** [ast.o] Error 1
make: *** Waiting for unfinished jobs....
```

I was curious about how to get more information out of `make` and found a SO post suggesting that `make -n` will list out the commands. From `man make` or `make --help` I see this description:

```
  -n, --just-print, --dry-run, --recon
                              Don't actually run any commands; just print them.
```

Running that gave me some output:

```term
$ make -n
echo compiling ./libsass/src/ast.cpp
false -I. -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/arm64-darwin24 -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/ruby/backward -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0 -I. -I./libsass/include -I/opt/homebrew/opt/readline/include -I/opt/homebrew/opt/libyaml/include -I/opt/homebrew/opt/gdbm/include -I/opt/X11/include -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE -D_DARWIN_UNLIMITED_SELECT -D_REENTRANT   -fno-common -fdeclspec -std=c++11 -DLIBSASS_VERSION='"3.6.4"' -arch arm64 -o ast.o -c ./libsass/src/ast.cpp
echo compiling ./libsass/src/ast2c.cpp
false -I. -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/arm64-darwin24 -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/ruby/backward -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0 -I. -I./libsass/include -I/opt/homebrew/opt/readline/include -I/opt/homebrew/opt/libyaml/include -I/opt/homebrew/opt/gdbm/include -I/opt/X11/include -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE -D_DARWIN_UNLIMITED_SELECT -D_REENTRANT   -fno-common -fdeclspec -std=c++11 -DLIBSASS_VERSION='"3.6.4"' -arch arm64 -o ast2c.o -c ./libsass/src/ast2c.cpp
```

If you're familiar with the output above you probably spotted the problem. If not, let's detour and explain what this make tool even is.

## Explaining: What is a make?

> Skip this if you know what make is and how to write a `Makefile`

GNU make describes itself as:

> _GNU Make_ is a tool which controls the generation of executables and other non-source files of a program from the program's source files.

The library Rake is a similar concept implemented in Ruby. The name "Rake" is short for "Ruby (M)ake."

In Rake, you can define a task and its prerequisites. The Rake tool will resolve those to ensure they're run in the correct order without having to run them multiple times. This is commonly used for database migrations and generating assets for a web app, such as CSS and JS.

Technically, that's all Make does as well, it allows you to define tasks in a reusable way, and it handles some of the logic of execution. In practice, make has become the go-to composition tool for compiling C programs. In that world there are projects that don't even tell you how to build the binaries because they expect you to `./configure && make && make install` in the same way some Ruby developers might forget instructions on adding a gem to the Gemfile in the README of their rubygem.

You can see a makefile in action following [Ruby's instructions on compilation](https://docs.ruby-lang.org/en/master/contributing/building_ruby_md.html#label-Quick+start+guide)

```term
$ git clone https://github.com/ruby/ruby
$ cd ruby
$ ./autogen.sh
$ mkdir build && cd build
$ ../configure --prefix="${HOME}/.rubies/ruby-master"
$ cat Makefile | head -n 10
RUBY_RELEASE_YEAR = 2024
RUBY_RELEASE_MONTH = 06
RUBY_RELEASE_DAY = 06
# -*- mode: makefile-gmake; indent-tabs-mode: t -*-

SHELL = /bin/sh
NULLCMD = :
silence = no # yes/no
yes_silence = $(silence:no=)
no_silence = $(silence:yes=)
```

At the end of the day, `make` does very little. It's almost more like its own language that happens to be useful for compiling code rather than a "compiling code" tool. The result is that the bulk of the logic comes from the contents of the Makefile and what the developer put in there rather than the Make tool itself. The output ends up being indistinguishable from a bunch of shell scripts in a trenchcoat.

## Debugging: Weird make output

Now we know that `make` does very little and we have its output we see two lines (I added a space for clarity):

```term
$ make -n
echo compiling ./libsass/src/ast.cpp

false -I. -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/arm64-darwin24 -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0/ruby/backward -I/Users/rschneeman/.rubies/ruby-3.4.1/include/ruby-3.4.0 -I. -I./libsass/include -I/opt/homebrew/opt/readline/include -I/opt/homebrew/opt/libyaml/include -I/opt/homebrew/opt/gdbm/include -I/opt/X11/include -D_XOPEN_SOURCE -D_DARWIN_C_SOURCE -D_DARWIN_UNLIMITED_SELECT -D_REENTRANT   -fno-common -fdeclspec -std=c++11 -DLIBSASS_VERSION='"3.6.4"' -arch arm64 -o ast.o -c ./libsass/src/ast.cpp
```

We could remove `make` from the equation by running them directly:

```term
$ echo compiling ./libsass/src/ast.cpp
compiling ./libsass/src/ast.cpp
```

That worked as expected, what about the next line? It starts with `false` which, from the manual page

```term
$ man false
...
DESCRIPTION
     The false utility always returns with a non-zero exit code.
```

So no matter what comes after this command, it will simply exit non-zero. This command can never work. This seems odd, definetly not what the author of this makefile intended. If this is the bug, and I think it is, where is that `false` coming from? Is it dynamic from something in the environment (environment variables) or is it coming from shelling out to some other utility on disk or is it coming from some config file? Or is it static? Is it baked in already.

Re-running `make -n` with env vars (mentioned in the GitHub comments) such as `CC="clang" CXX="clang++"` has no effect. It's the same output. This leads me to believe it's something static.

Looking at the contents of the Makefile:

```term
$ cat Makefile | grep false
CXX = false
```

Huh, that's weird. Where is that used?

```term
$ cat Makefile | grep CXX
CXX = false
CXXFLAGS = $(CCDLFLAGS) -fdeclspec -std=c++11 -DLIBSASS_VERSION='"3.6.4"' $(ARCH_FLAG)
LDSHAREDXX = $(CXX) -dynamic -bundle
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<
```

That last line comes from this code in the Makefile:

```term
.cc.o:
	$(ECHO) compiling $(<)
	$(Q) $(CXX) $(INCFLAGS) $(CPPFLAGS) $(CXXFLAGS) $(COUTFLAG)$@ -c $(CSRCFLAG)$<
```

## Explain: What is in a Makefile

> Skip this if you know make syntax

To understand what this is doing, we can write a tiny make program:

```term
$ cat Makefile
lol:
	echo "hahaha"
```

> The indentation under the `lol:` should be a tab, but your editor or my blogging process might have converted it into a space.

Now when we run that:

```term
$ make
echo "hahaha"
hahaha
```

It printed the command and then the output of that command. We're not limited to static commands though. Modify the file:

```term
$ cat Makefile
CMD=echo

lol:
	$(CMD) "hahaha"
```

Here, we've extracted the command `echo` into a variable and are using that to produce the same effective command.

## Explaining: What CXX=false means in the Makefile

What that means is `CXX=false` tells make to replace `$(CXX)` with `false` which is not what we want. But where did `CXX=false` come from? I'm glad you asked. If you search the source code for that line, you won't find it. That's because this Makefile is generated.

When we looked at native extensions before, notice that I talked about `rake-compiler` and not about hand-rolling a `Makefile`. Even when we looked at `ruby/ruby`-s Makefile, it wasn't hardcoded; it came to be after calling `./autogen.sh` and `../configure`. This Makefile is generated at install time.

## Debugging: Where did the `false` come from?

When you compile Ruby `./configure && make && make install` it needs to gather information about the system in order to know how to compile itself. Things like "what compiler are you using" (it could be gcc or clang, for example). Ruby isn't the only program that needs to know this stuff; native extension code that compiles needs to know it, too.

When you compile Ruby it generates a `rbconfig.rb` file that contains information that Ruby users can access via [RbConfig](https://docs.ruby-lang.org/en/3.4/RbConfig.html).  From the docs:

> The module storing Ruby interpreter configurations on building.
>
>This file was created by mkconfig.rb when ruby was built. It contains build information for ruby which is used e.g. by mkmf to build compatible native extensions. Any changes made to this file will be lost the next time ruby is built.

So that info is what Ruby used at compile time. Where is it?

```term
$ find /Users/rschneeman/.rubies -name rbconfig.rb
...
/Users/rschneeman/.rubies/ruby-3.4.1/lib/ruby/3.4.0/arm64-darwin24/rbconfig.rb
```

When I looked at that file I saw something alarming:

```term
$ cat ../arm64-darwin24/rbconfig.rb | grep false
# frozen-string-literal: false
  CONFIG["CXX"] = "false"
	config[v] = false
```

When Ruby was compiled it came to the conclusion that it should use `clang` to compile C code:

```ruby
  CONFIG["CC"] = "clang"
```

But it mistakenly concluded that it should use the `false` command to compile C++ code (the meaning of these environment variables). It SHOULD be `clang++` or something like `clang++—std=gnu++11`, but it's not.

When the Makefile for the `sassc` gem is generated it hardcodes `CXX=false` into it by mistake because it is pulling that information from the `RbConfig` module generated by Ruby at compile time.

Why did it record `false`? Well, I don't know. I assume it has something to do with the interplay between Ruby's configuration script and Xcode developer tools. I didn't debug down that pathway. Since we can fix the problem by re-installing the same version of Ruby with a newer version of the Xcode developer tools, it seems that the problem is in Xcode, but there might be a more complicated interaction involved (perhaps Ruby is doing something Xcode didn't expect, for example).

## The fix: Uninstall, and reinstall

Thankfully others came before me and came to the conclusion about where the problem was coming from and how to fix it. They suggested what I did above:

- Delete/uninstall Ruby
- Delete/uninstall gems (adding this to avoid any cached or stale generated Makefiles)
- Upgrade Xcode developer tools. (Version `2409` worked for me)
- Reinstall Ruby
- Install `sassc` to your heart's content

After doing this you can inspect the `RbConfig` file:

```term
$ cat /Users/rschneeman/.rubies/ruby-3.4.1/lib/ruby/3.4.0/arm64-darwin24/rbconfig.rb | grep CXX
  CONFIG["LDSHAREDXX"] = "$(CXX) -dynamic -bundle"
  CONFIG["CXXFLAGS"] = "-fdeclspec"
  CONFIG["CXX"] = "clang++ -std=gnu++11"
```

Lookin good. It no longer reports `false`.

## Wrapup

I mentioned above that it might be possible to manually edit these files to fix the problem. That would save the time and energy for re-compiling your Rubies. But you definitely want to upgrade your Xcode developer tools and ensure that future ruby installs have the right information. Going through the motions of this full process for at least one Ruby version (assuming you're using a version switcher like [chruby](https://github.com/postmodern/chruby) or [asdf](https://asdf-vm.com/)) is recommended. Personally, I uninstalled everything to decrease the chances that I have to re-learn about this problem and find this blog post X months/years in the future because I missed something in my process.

For those of you without this problem: Hopefully, this was educational. You might be wondering why I decided to blog about **this** specific topic (of all things). Well, I've got to do something while I'm recompiling all those rubies, and learning-via-teaching is a core pedagogy of mine.

If you enjoyed this post consider:

- Reading more of my writing by:
	- Trying the [evergreen Cloud Native Buildpack tutorial for Ruby](https://github.com/heroku/buildpacks/blob/main/docs/ruby/README.md) that covers building OCI images with CNBs instead of Dockerfiles.
- Buying my book  ["How to Open Source"](https://howtoopensource.dev/) with your corporate card.
- Following me on socials:
	- [Mastodon](https://ruby.social/@Schneems)
	- [Bsky](https://ruby.social/@Schneems)
- Taking some time this fine afternoon to write a blog post about whatever random debugging topic you're currently battling.
- Finding a doggo and petting them
