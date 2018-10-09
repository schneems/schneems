---
title: "Pair With Me: Rubocop Cop that Detects Duplicate Array Allocations"
layout: post
published: true
date: 2018-10-09
permalink: /2018/10/09/pair-with-me-rubocop-cop-that-detects-duplicate-array-allocations/
categories:
    - ruby
    - performance
---

You might know [rubocop](https://github.com/rubocop-hq/rubocop) as the linter that helps enforce your code styles, but did you know you can use it to make your code faster? In this post, we'll look at static performance analysis and then at the end there's a video of me live coding a PR that introduces a new performance cop to rubocop.

## Static Performance Analysis

Most performance improvements are made by "hotspot" analysis. You find some code and a benchmarking tool. Run the code, find the "hotspots" and then either speed up those sections or reduce the number of times that they need to be called. Concerning finding the most significant gains, nothing beats hotspot analysis, but what if you could detect code that is inefficient and re-write it without changing behavior. The code might be critical and the performance gain huge, or it might be tiny. Static performance analysis can tell you where your code can be faster, but it cannot tell you if that performance improvement will be meaningful in any kind of a real way.


## For example

You may have seen Juanito's awesome [fast-ruby](https://github.com/JuanitoFatas/fast-ruby) repo that includes a bunch of "do this, not that" style of performance micro-optimizations. Here's an example, instead of writing this code:

```ruby
[true, false, false].select { |item| item }.first
```

You can use this code:

```ruby
[true, false, false].detect { |item| item }
```

In the second example, Ruby will stop iterating after it hits the first element to return true, so it does less work and is faster.

## Performance analysis with Rubocop

While it's good to know that one of those pieces of code is faster than another, it's tedious to search your whole codebase for these patterns manually. Instead, you can configure rubocop to find some of these issues for you. To detect the above example, you can enable the `Performance/Detect` cop. Here's a [link to the documentation](https://rubocop.readthedocs.io/en/latest/cops_performance/#performancedetect).

There's also another library called [fasterer](https://github.com/DamirSvrtan/fasterer). I'm not sure if they have feature parity, but they're two approaches to the same problem.

## Uses

Since we don't know how useful these performance cops will be to your actual code, it's not a great idea to enable them all, and force all the code in your main Rails app to follow all the conventions. While some of the perf optimizations are as clean as the one above, many more require modifying your code in sometimes less readable ways.

While it might not be a great idea on a project level, I think it's a good idea for library maintainers to add rubocop to their projects and enable performance cops:

```yml
Performance:
  enabled: true
```

It's also a good idea to tell rubocop what version of Ruby you're on. For example, newer rubies have `String#match?` for matching regular expressions which is faster than `String#=~.` Telling rubocop your minimum ruby version lets them maximize your optimizations:

```yml
AllCops:
  DisabledByDefault: true
  TargetRubyVersion: 2.5
```

## Running rubocop

You can run rubocop from the command line:

```
$ rubocop
```

Some of the changes can be applied automatically, to do this run with `--auto-correct`

```
$ rubocop --autocorrect
```

You can also add a rake task and have it autorun before CI to ensure no perf issues creep in.

## Decreasing array allocations

Now that you know all about rubocop and it's performance abilities, I want to tell you about a feature I introduced. In code it's common to see array methods chained like this:

```
array = ["a", "b", "c"]
array.compact.flatten.map { |x| x.downcase }
```

Each of these methods `compact`, `flatten,` and `map` will allocate a new array. However, some of them have mutating "cousins" that can be used instead. We can write this code to be faster:

```ruby
array = ["a", "b", "c"]
array.compact!
array.flatten!
array.map! { |x| x.downcase }
array
```

> Note that the bang methods are not drop-in replacements and cannot be chained directly because sometimes they return `nil`.

Here we can mutate our original array variable because we also created it and know that no one will be trying to use the original. If we were calling this on an array passed into a method, then we would want to make the first call use `compact` instead and rely on the behavior that it will return a new array that we can safely mutate. For example:

```ruby
def my_method(array)
  array = array.compact # don't mutate incoming arguments, duplicate the original
  array.flatten!
  array.map! { |x| x.downcase }
  array
end
```

That's the general idea behind several performance patches that I've made. After finding this pattern manually a few times, I wondered if I could turn it into its cop.

## Video

If you want to watch me live code this feature you can follow along here:

<iframe width="560" height="315" src="https://www.youtube.com/embed/w4Uzy6XFzCY" frameborder="0" allow="autoplay; encrypted-media" allowfullscreen></iframe>


I didn't edit this, so you're getting all my mistakes and "umms." I recommend watching on at least 1.5x speed. As you're watching pretend you're pairing and try to find my mistakes before I do.

## Aftermath

I was eventually able to get all of this working and [submit a PR to rubocop](https://github.com/rubocop-hq/rubocop/pull/6234). I also ran it against rails and found this pattern being used about 100 times. However, as you can see from my [will never be merged PR](https://github.com/rails/rails/pull/33806) that some of the code is pretty gnarly. Usually, this is the part of the post where I tell you I made things a billion times faster, but it looks like while there were one or two spots that were actually hotspots, most of those locations were not. Was all that work in making the cop worthless then? In the case of Rails, I've spent a ton of time doing "hotspot" analysis which had previously pointed out many other changes. Since Rails has already been reasonably well optimized, this blanket optimization didn't show much improvement in my real world app [CodeTriage](https://www.codetriage.com). In other libraries that haven't spent much time optimizing there might be more significant gains. I did have one person report a reasonably huge savings within their actual Rails app where they were chaining methods on a massive array of active record objects. So while it's not a magic performance bullet, it does have its uses.

If you're wondering "What about JIT? Can't it do this for me eventually?" It turns out that yes, JIT can optimize this issue away through a concept called "loop fusion", but unless you're running Truffle ruby (not sure if JRuby does this or not), then you're not going to be able to avoid this perf hotspot. Eventually, maybe MJIT will be able to do this, but until it can then we can see real-world gains by applying more efficient patterns to real-world ruby code
