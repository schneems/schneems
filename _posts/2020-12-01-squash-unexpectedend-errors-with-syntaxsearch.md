---
title: "Squash Unexpected-End errors with syntax_search"
layout: post
published: true
date: 2020-12-01
permalink: /2020/12/01/squash-unexpectedend-errors-with-syntaxsearch/
image_url: https://www.dropbox.com/s/uutrcg27flp9ky0/dead_end.jpg?raw=1
categories:
    - ruby
    - syntax
---

Have you ever hit an error that you just plain hate? Back in 2006, I was learning to program Ruby and following an example from a book. I typed in what I saw, hit enter, and ran into a supremely frustrating error message:

```ruby
Array(values).map |x|
  x.upcase
end

# =>  syntax error, unexpected `end', expecting end-of-input
```

I was beyond confused about this `unexpected end` error. `end` is a keyword. Right? How could Ruby not expect `end`? After staring at the code for a while, I realized my mistake. My `map |x|` line should be `map do |x|` (missing the `do`). That moment was the start of a 14-year long hatred of that error message and a search for something better. This post is about how I wrote a gem that you can use to improve this error message. Keep reading!

<blockquote class="imgur-embed-pub" lang="en" data-id="a/vlWfwS4"  ><a href="//imgur.com/a/vlWfwS4">Syntax Search: Extra end</a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>

> Update: I changed the name of the lib from "syntax_search" to "dead_end". All the explanations about how the code work still hold up.

## TLDR;

To get improved "unexpected end" syntax errors in your project, add this to your Gemfile:

```ruby
gem "dead_end"
```

Then make sure it's required in your code:

```ruby
Bundle.require # If you're using Rails, this is the default.

require 'dead_end'
```

If you're using rspec, add this line to your `.rspec` file:

```
--require dead_end
```

> This is needed because `bundle exec rspec path/to/file.rb` will throw a syntax error before the gem gets loaded

Now when you run your code, you get a helpful error:

```
SyntaxSearch: Unmatched `end` detected

This code has an unmatched `end`. Ensure that all `end` lines
in your code have a matching syntax keyword  (`def`,  `do`, etc.),
and that you don't have any extra `end` lines.

file: ~/spec/unit/env_proxy_spec.rb
simplified:

        1  # frozen_string_literal: true
        2
        3  require_relative "../spec_helper.rb"
        4
        5  module HerokuBuildpackRuby
        6    RSpec.describe "env proxy" do
    ❯   7      before(:all)
    ❯  10      end
       11
       # ...
      246    end
      247  end
```

## Back Story

After that initial experience with this error, I mostly trained my brain that "unexpected end" (for me) means that I'm missing a "do" somewhere. That's where most programmers stop. The error becomes background noise in their programming life.  I've seen developers develop defense mechanisms for syntax errors like this. For example: making sure to run their code frequently, or making sure to have small commits so they can revert to working code quickly, or they scan the git diff. Either way, you slice it, the error message ultimately is not that helpful. Programmers adopt these practices as a work-around for this message. It's like if there was a hole in your house, and instead of covering it up, you just spent time walking around it.

I remember vividly around 2013 I was working for Heroku, and we had Matz, Nobu, and Koichi from the Ruby core team fly into the office. We recorded an audio interview with them, and on the way out, I told Koichi and Nobu about this pain point. They listened, and we ultimately concluded that it was a difficult, if not impossible, problem to solve. I shelved the idea.

## The impossible goal

Why is it so difficult to improve this error message? Here's an example of code with a missing `do`:

```ruby
it "touches a file" do
  Dir.chdir("/tmp")
    FileUtils.touch("myfile")
  end
end
```

This code has a syntax error, the `Dir.chdir("/tmp")` is missing a `do`. BUT that's not what triggers the error. The parser tries to match each `end` to a corresponding syntax keyword (begin/def/do/if/while/etc.).

When Ruby tries to parse this code. It mistakenly thinks that the first `end` belongs to the first do:

```ruby
it "touches a file" do # <== Here
  # Dir.chdir("/tmp")
  #   FileUtils.touch("myfile")
  end # <== Here
end
```

It then keeps parsing, and it tries to match the last `end`, but it can't. The parser hits the end of the file which is unexpected. Then an error is raised.

In this example, it might be obvious to a human where the missing syntax was, but a computer cannot know the programmer's intent. In this case, `Dir.chdir()` by itself without a block is VALID ruby code and will change the directory. Imagine if you found this code:

```ruby
it "touches a file" do
  Dir.chdir("/tmp")
  Dir.chdir("foo")
    FileUtils.touch("myfile")
  end
end
```

One of these is expected to be a `chdir` with a block, but not the other. Without more information, a computer can't KNOW which line is supposed to have the `do`. But you, my human friend, likely have a pretty good idea because there is extra information: the indentation.

## Relax constraints and add information: Indentation informed syntax

Since it's impossible to prove which line was intended to have the syntax, I relaxed my goals from "tell the user the problem" to "narrow the search space for the user to likely locations with a problem". Finding the line that caused a syntax error isn't impossible, which is why this blog post didn't just stop above.

Humans use indentation to inform our decisions about what the author of the code intended it to do. Why not cut out some of the middle work and have the program narrow our search for us? Some IDEs will warn you if you have an `end` that does not have a corresponding syntax keyword on the same indentation. For example, my vim setup:

![screenshot of indentation in vim](https://www.dropbox.com/s/ack4j3im9ogmjqf/Screen%20Shot%202020-11-17%20at%2010.56.18%20AM.png?raw=1)

Originally I had the idea I could use that same detection idea, but I wanted to show the offending line, and not just the most likely `end` causing the problem. Beyond that, I wanted it to be robust for when indentation was a little off. By definition, when a syntax error occurs, the programmer has done something wrong. Only giving them a decent error when they've done everything else perfectly is not ideal. Also, I wanted to boost the signal to noise. Was it possible to remove code that I was pretty sure didn't contain the error?

With all this in mind, I began to hunt for a solution.

## Search for syntax

When you're trying to drive from one place to another, you'll find many ways to reach the destination. The way that Google maps works is it searches for a solution and has a heuristic for success. When it finds a solution that provably minimizes the heuristic (such as time to destination), it returns this to the user.

Usually, when you're routing somewhere, you don't want to be routed into a dead end. But what if your plan already had a dead-end in it? If you can remove a part of the plan and end up at your destination, then you know you've removed the dead end.

I view syntax error like a dead end in code. If we can remove a dead end from our route then we have a valid path. Another way to put this: if you remove a syntax error from a document, then the document becomes valid (it can be parsed). I used this concept to "search" for one or more syntax errors in a document.

Here's a video of the process:

<blockquote class="imgur-embed-pub" lang="en" data-id="a/DQLlPRp"  ><a href="//imgur.com/a/DQLlPRp">Syntax Search: Def missing an end</a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>

## Defining the roads

When navigating between two locations in a car, there are natural constraints for how it moves. It's constrained by gas and brake pedals, engaged gear direction, and steering wheel angle at the low level. But google maps does not need to go into that much detail. Instead, it just looks at the intersections.

Code has similar low-level constraints. Programs are made of individual characters but assembled into larger grammars that span multiple lines and eventually make an entire source file on disk. To search for a dead-end in the code, we need to find the right granularity. I chose to have my smallest unit be a line of source code and chunk the code into multiple lines to form "code blocks".

Once we have one or more code lines, we can remove it to see if we've found our solution. We can also independently verify if that block can be parsed or not.

Like how Google maps mimics how a driver would behave, we can mimic how a human would begin to break apart logically and chunk source code. For example:

```ruby
class Cat
  def eat

  def speak      # <==
    puts "meow"  # <==
  end            # <==
end
```

In this case, you might be able to see that the `def speak` "block" is valid. We can run it through a parser to confirm this programmatically. If the code block is valid, it cannot contain the syntax error, so it can effectively be commented out. My algorithm reduces it to:


      1  class Cat
    ❯ 2    def eat
      7  end


Once the `def speak` block was commented out, it then checked the `def eat` line and saw the document was valid without it. The code then returned. We've found the syntax error!

## Turn-by-turn

The bulk of the heavy lifting is done in the code block generation. It starts at the furthest most indentation. I will then expand outwards until it hits a change in indentation. We parse all the internal code with the same indentation before "expanding" a block to a lower indentation level. As it works the program also marks and comments-out code that it's found to be valid. It's easier to visualize with an animation:

<blockquote class="imgur-embed-pub" lang="en" data-id="a/fVYBAT3"  ><a href="//imgur.com/a/fVYBAT3">Syntax Search: Missing do</a></blockquote><script async src="//s.imgur.com/min/embed.js" charset="utf-8"></script>

This process simplifies the code as it runs and has a high likelihood of producing a code block that contains the syntax error(s).

## Complicating scenarios

Since I started this project knowing that the actual goal to "show you what line is missing syntax" is impossible, I'm left knowing that I'll have to live with some unsatisfactory results. They're imperfect because the intent is unclear.

Here's an example:

```ruby
class Cat
  def eat
    puts "nomnom"

  def speak
    puts "meow"
  end
end
```

Without involving a human, there could be two possible errors here. Maybe `def eat` is missing an `end`, but it's also possible that the `def speak` line was supposed to be removed and the contents consolidated into one single block. Without more information, we cannot know. When my program tries simplifying this, it spits out:

      1  class Cat
    ❯ 2    def eat
    ❯ 5    def speak
    ❯ 7    end
      8  end

You can see a little more clearly that we could make this code valid by either removing line two or five or adding an end after line 2. That ambiguity is important and can be left up to the programmer.

## Next steps

Try it out! Seriously. Syntax errors in the wild might look different than in the "lab" here. I need you, and more importantly, I need your syntax errors.

Installation instructions are found at the readme: [install syntax_search in your codebase today!](https://github.com/zombocom/syntax_search)
