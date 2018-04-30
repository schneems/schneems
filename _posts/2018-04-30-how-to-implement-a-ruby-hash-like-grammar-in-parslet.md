---
title: "How to Implement a Ruby Hash like Grammar in Parslet"
layout: post
published: true
date: 2018-04-30
permalink: /2018/04/30/how-to-implement-a-ruby-hash-like-grammar-in-parslet/
categories:
    - ruby
    - parslet
    - parsing
---

Before you can understand how to build a parser using `parslet`, you need to understand why you might want to. In my case I have a library called [rundoc](https://github.com/schneems/rundoc) it allows anyone to write documentation that can be "run". For example, someone might write docs that had this:

    ```
    :::>> $ rails -v
    ```


Then in your documentation output you would get this result:

    ```
    $ rails -v
    Rails 5.2.0
    ```

> Note: If you want, you can skip to the next section for the tutorial.

While this doesn't seem that impressive on the surface - if you have docs that need to be updated frequently: it can save a lot of time spent copying and pasting of output. Even more importantly, it can catch errors and regressions that you might not catch manually.

I use this library to keep some docs in the Heroku devcenter such as the [getting started with Rails 5](https://devcenter.heroku.com/articles/getting-started-with-rails5) article. When a new version of Rails or Ruby is released I can update the doc, "run it", and then ensure that the output in the documentation matches perfectly with the output someone using the same commands would get. If a command fails, the generation process fails, so the doc acts as a test as well.

The other added benefit of this approach is to the reader. By ensuring consistency of output of commands, the reader can better detect when something has gone wrong. Enough about my project though, this article is about building a parser. Why does `rundoc` need `parslet`?

When I wrote `rundoc` I first implemented it using regexes. They started out simple, but then got more and more gnarly, here's what they look like now:

```
INDENT_BLOCK       = '(?<before_indent>(^\s*$\n|\A)(^(?:[ ]{4}|\t))(?<indent_contents>.*)(?<after_indent>[^\s].*$\n?(?:(?:^\s*$\n?)*^(?:[ ]{4}|\t).*[^\s].*$\n?)*))'
GITHUB_BLOCK       = '^(?<fence>(?<fence_char>~|`){3,})\s*?(?<lang>\w+)?\s*?\n(?<contents>.*?)^\g<fence>\g<fence_char>*\s*?\n'
CODEBLOCK_REGEX    = /(#{GITHUB_BLOCK})/m
COMMAND_REGEX      = ->(keyword) {
                         /^#{keyword}(?<tag>(\s|=|-|>)?(=|-|>)?)\s*(?<command>(\S)+)\s+(?<statement>.*)$/
                        }
```

This allows the registration of a "command" such as `$` which then takes one input, a string. It's pretty flexible, but recently I wanted to allow for a more complex grammar, something that would allow me to use keword arguments like syntax:

    ```
    :::>> background.start(command: "rails server", name: "server")
    ```

While I could maybe have implemented this in a regex, it seemed like I was using the wrong tool for the job, and that I needed a fully featured parser. Enter Parslet.

Rather than trying to write one regex to rule them all, `parslet` allows me to build up my grammar piece by piece. These small pieces then fit together to make more and more complex grammars. The output of this parse step is a deeply nested syntax "tree", which we will see in a bit.

Parslet then has the concept of a "transformer" that can be used to turn complex parsed trees into any kind of Ruby code such as value objects that we want. When you combine parsers and transformers, you can write your own mini-language with whatever syntax rules you want. This is perfect for something like `rundoc`.

While there are other parser libraries in Ruby, I chose parslet largely because of the amount of examples and documentation it had. The [documentation site](http://kschiess.github.io/parslet/documentation.html) is great, and there are [examples directly in the repo](https://github.com/kschiess/parslet/tree/master/example). My only minor-nit is that the [readme isn't rendered in markdown in github](https://github.com/kschiess/parslet/pull/187), but I can get over it.

I also looked at the `treetop` gem, but I couldn't make much progress. I investigated the `racc` library which is great if you're familiar with `yacc` syntax (which I'm not). Yacc is the syntax that [Ruby uses to implement it's own grammar](https://github.com/ruby/ruby/blob/trunk/parse.y). If you want to go down that Rabbit hole, Aaron recommended the O'Reilly book on Yacc which seems good, but requires more reading than I was willing to put into this project.

Now that you know my problem and my toolset, it's time for a tutorial! I'm writing this: not as an expert in parsers (or in `parslet` even), but really to convince myself that I understand what I've already done. When you can explain how you did somethign to someone else, then you actually understand it. Without further ado, here's the tutorial.

## Tutorial Setup

In this parslet tutorial we will build a grammar that can read in a Ruby 1.9 style hash with symbol keys and string values. Something like this:

```ruby
{hello: "world", iam: "Schneems"}
```

That might seem like an easy goal, but as Caral Sagan once said, if you want to create a buttermilk biscuit from scratch, you'll first have to invent the universe.

How does this relate to `rundoc` ? Remember how I wanted syntax that matched keyword args? I'll have to implement that same syntax to get Ruby hash literal syntax to work in Parslet.

I generally don't develop using pure TDD methods (i.e. writing tests first, then getting them to pass), but I've found when implementing a grammar, it's much easier to write a test and then implement it second.

To that end, I've implemented a failing test and my code all in one file:

```ruby
require 'parslet'

class MyParser < Parslet::Parser
end

class MyTransformer < Parslet::Transform
end

require 'minitest/autorun'
require 'parslet/convenience'

class MyParserTest < Minitest::Test
  def test_parses_a_comma
    input = %Q{,}
    parser = MyParser.new.comma
    tree = parser.parse_with_debug(input)
    refute_equal nil, tree
  end
end
```

I can run this file directly using `$ ruby example.rb` and see if my tests pass.

## My First Failing Test

> If you like to see the finished product first, you can jump to the [source code to my example parslet app](https://github.com/schneems/implement_ruby_hash_syntax_with_parslet_example.git).

In the above code, the `comma` method on `MyParser.new` is referring to a "rule" in parslet that I've not implemented yet. This test fails with:

```
NoMethodError: undefined method `comma' for #<MyParser:0x00007ff5dc074d18>
    example.rb:14:in `test_parses_a_comma'
```

In parslet you add a rule by using the `rule` keyword, giving the rule a symbol name, and then defining the rule inside of a block. Here's a rule that matches our comma:

```
class MyParser < Parslet::Parser
  rule(:comma) { str(",") }
end
```

Inside of the block the keyword `str` refers to a literal string match. In this case we're only passing in a single comma, so it matches the comma in our input string. Pretty straight forward. The tests now pass.

When building a grammar, I've found it easiest to start with very small pieces and build out from there. We can re-use those small pieces to help build more complicated grammars.

While this matches a single comma, it won't match if we add a test to have spaces around it:

```ruby
def test_parses_a_comma_with_spaces
  input = %Q{ , }
  parser = MyParser.new.comma
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree
end
```

Now the test fails:

```
Expected ",", but got " " at line 1 char 1.
F

Finished in 0.001192s, 838.9262 runs/s, 838.9262 assertions/s.

  1) Failure:
MyParserTest#test_parses_a_comma_with_spaces [example.rb:19]:
Expected nil to not be equal to nil.
```

How can we update the grammar to allow for spaces? In addition to `str` there is also a `match` keyword that will match via a regex. A space could be matched like this:

```ruby
 rule(:spaces) { match('\s').repeat(1) }
```

Here the regex `\s` will match any whitespace character. The call to `repeat(1) says that it must be repeated at least once, but has no upper bound. This means it will match ` ` (one space) and `      ` (6 spaces) but not `` (no spaces).

While this is a useful rule, we also want to match the case where we don't have spaces in addition to the case where we do. To accomplish that we can add a `spaces?` rule, that uses the `spaces` rule and adds to it:

```ruby
 rule(:spaces?) { spaces.maybe }
```

Inside of the block the call to `spaces` uses our previously defined rule. The `maybe` method is provided by parslet and indicates that if it matches the `spaces` rule, great. Also if it doesn't match that rule, it's fine.

We can put all these things together to get our tests to pass by updating the `comma` rule, here's the full thing:

```ruby
class MyParser < Parslet::Parser
  rule(:spaces)  { match('\s').repeat(1) }
  rule(:spaces?) { spaces.maybe }
  rule(:comma)   { spaces? >> str(',') >> spaces? }
end
```

While we understand `spaces?` and `str(',')`, what is this `>>` operator doing? I don't know the term for it, but I mentally named it "and then". I read this rule as "Match spaces (if there are any), and then explicitly match a string of ',' and then match spaces (if there are any)". Now that we have a rule, let's make sure our tests pass:

```
Finished in 0.001970s, 1015.2284 runs/s, 1015.2284 assertions/s.

2 runs, 2 assertions, 0 failures, 0 errors, 0 skips
```

Great!

Now that we have a comma, what else could our language use? How about a string.

Here's the test:

```ruby
  def test_parses_a_string
    input = %Q{"hello world"}
    parser = MyParser.new.string
    tree = parser.parse_with_debug(input)
    refute_equal nil, tree
  end
```

It fails, how will it pass? Let's look at the structure of our string first. It's got a quote character `"` then it has other characters, those characters can be repeated, and they cannot include another quote. Then finally the string terminates with another quote `"`. How is this represented in parslet syntax?

```ruby
rule(:string) {
  str('"') >> (
    str('"').absent? >> any
  ).repeat.as(:string) >> str('"')
}
```

You've seen everything here before, except for `absent?`, `any`, and `as`. The `absent?` method checks for the lack of that character. The `any` keyword will match, well, anything. The `any` character is shorhand for `match('.')`. The combination of `str("'").absent? >> any` is checking each character that it does not contain a `"` and then it will match any other character.

What does the `as` do? This is our way of telling parslet's that we are dealing with a significant part of our grammar. While I don't necessarily need to know how many spaces are around a comma, I'll likely want to know the contents of a string. That's why I added `as(:string)`.

When you run the tests you'll see that it passes. I want to go one step further though and actually verify the format of the parsed tree (instead of saying "not nil"). To do that I'll change the test:

```
  def test_parses_a_string
    input = %Q{"hello world"}
    parser = MyParser.new.string
    tree = parser.parse_with_debug(input)
    expected = {string: "hello world"}
    assert_equal expected, tree
  end
```

In parslet, each `as` produces a hash (and potentially an Array). As we keep going you'll see that they will be deeply nested. While a parser builds a tree, a "transformer" takes a tree as an input and simplifies it to make it smaller.

To understand, we'll try to add a grammar for Ruby's hash. Eventually we want to parse `{ hello: "world" }`. To start though we can match a subset of this, just the inner part `hello: "world"`. This is also similar to keyword args.

Before we start, lets brainstorm the syntax of this. A key is any character that is not a `:` or a space, followed by a `:` literal. The value is a string, but in the future it could be a number or an array. We can also have multiple keys and multiple values separated by commas.

This is a complicated feature, let's start with the smaller parts and work towards the larger piece. I mentioned that a value can be things other than a string, to allow for this later we can add a `value` rule:

```
rule(:value) { string }
```

If a "number" rule existed then we could use the `|` operator to specify that a value can be a `string | number` (string or number). We won't do that here, but know that's why I pre-emptively made a `value` rule, even if it doesn't look like it's doing anything.

Next up I want a `key` parser. Here's a test:

```ruby
def test_key
  input = %Q{ hello: }
  parser = MyParser.new.key
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree
end
```

The key rule needs to allow for a space at the beginning and the end. You'll remember that a key is a repetition of characters that are not `:` or a space, and that ends in a colon `:`. Here's what I came up with:

```ruby
rule(:key) {
  spaces? >> (
    str(':').absent? >> match('\s').absent? >> any
  ).repeat.as(:key) >> str(':') >> spaces?
}
```

This gets the tests to pass. Notice, that since we'll care about the contents of the `key`, it is named here using the `as` keyword.

A hash can have repeating key value pairs. Before we match an entire series, let's group a key and a value together. Start with a test:

```ruby
def test_parses_a_key_value_pair
  input = %Q{ hello: "world" }
  parser = MyParser.new.key_value
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree
end
```

It fails, let's make it pass with a `key_value` rule:

```
rule(:key_value) {
  (
    key >> value.as(:val)
  ).as(:key_value) >> spaces?
}
```

We are really close to finishing our grammar, but before we do, I want to take a look at the output of the tree for this key/value. It looks like this:

```ruby
{ :key_value => { :key => "hello"@1, :val => { :string => "world"@9 }}}
```

This hash somewhat makes sense to me. We have a top level key `key_value` and that points to another hash. This hash has a `key` key that points to a `"hello"` string and a `val` key that points to yet another hash `{:string=>"world"@9}`. While it's not super complicated, we can make the result of this simpler by using a transformer.

## Transformers - Abstract Syntax Trees in disguise

I mentioned transformers previously, but they're such an abstract concept it helps to look at an example. Think of them as a way to reduce leaf nodes on our tree so that they make more sense. One way to represent our current parse tree is this:

```
- key_value
  - key: "Hello"
  - val:
    - string: "world"
```

You'll notice that the `key` and `val` results are not at the same level. Wouldn't it be great if there was a way for us to tranform `{:string=>"world"@9}` into something more useable? With a transformer we can. We will convert that leaf hash into a simple string. Here's our test.

```ruby
def test_parses_a_key_value_pair
  input = %Q{ hello: "world" }
  parser = MyParser.new.key_value
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree

  actual = MyTransformer.new.apply(tree)
  expected = {key_value: {key: "hello", val: "world"}}
  assert_equal expected, actual
end
```

Transformers match on a tree's hash key and value type, and then modify the result. Here's the transformer that will allow this test to pass:

```ruby
class MyTransformer < Parslet::Transform
  rule(string: simple(:st)) { st.to_s }
end
```

What is going on here? We are telling our transformer to match the key `string` when you see that, and a `simple` value, then make a match, and name that match `st` and call our block. What is a `simple` value? A value such as a string or an integer, and not something complex like a hash or an array.

Given this definition it will match `{:string => "foo"}` but not `{ :string => { :complex => "value"}}`.

Once the transformer matches `{ :string => "foo" }`, the `simple(:st)` is captured. In this case that is a string of `"foo"`. That value is then named `st` and passed to our block. We want to ensure it's a string so we call `to_s` on it and then it is returned. The entire hash of `{ :string => "foo" }` would then become a simple string `"foo"`

Previously a leaf node that looks like this:

```ruby
{string: "world"}
```

Would now look like this:

```ruby
"world"
```

There is one tricky point in this example. Not only was the value of "world" modified (we called `to_s` on it) but the entire hash went away, and was replaced by the value we returned. This is a subtly that is kind of pointed out in the [documentation for transformers](http://kschiess.github.io/parslet/transform.html), but not really that well illustrated.

Here's the example they give, but with more details. If you have a tree like this:

```ruby
{
  dog: 'terrier',
  cat: 'suit'
}
```

You cannot match `dog` by itself. I.e. a rule like this makes no sense:

```
rule(:dog => 'terrier') { 'foo' }
```

Because you're not only modifying the value, you're modifying the entire match (the key and the value). If this was a legal match it would produce something like this:

```ruby
{
  'foo',
  cat: 'suit'
}
```

Which is not a legal Ruby object (the `'foo'` in the example is not a key/value pair, and a hash can only hold key/value pairs). If you wanted to make this modification to a parse tree, you have to match the entire hash and then return a new hash object:

```ruby
class MyTransformer < Parslet::Transform
  rule(dog: 'terrier', cat: simple(:cat_value)) {
    out = {}
    out[:dog] = 'foo'
    out[:cat] = cat_value
    out
  }
end
```

Here we're only matching when a `dog` key has a value of `terrier`, but matching when the cat key can be any simple object (such as a string).

Now a test like this would pass:

```ruby
def test_dog_cat
  tree = { dog: 'terrier', cat: 'suit'}

  actual = MyTransformer.new.apply(tree)
  expected = { dog: 'foo', cat: 'suit' }
  assert_equal expected, actual
end
```

While transformers demonstrated here aren't the most useful, they can save you work down the road when your tree starts to get extremely nested. We'll come back later.

## Repeated rules

At this point we can parse a single key/value pair, but what about multiple pairs? Here's a test:

```ruby
def test_parses_multiple_key_value_pairs
  input = %Q{ hello: "world", hi: "there" }
  parser = MyParser.new.key_value
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree
end
```

In this case we already have a `key_value` rule, and a `comma` rule, we either want to match a single key/value pair, or a key/value pair followed by a comma and another key/value. This latter pattern can repeat indefinitely. Here's how this looks as a parslet rule:

```ruby
rule(:named_args) {
  spaces? >> (
    key_value >> (
      comma >> key_value
    ).repeat
  ).as(:named_args) >> spaces?
}
```

This rule gets the tests to pass, though what kind of tree do you think our test string (`hello: "world", hi: "there"`) returns?

It's a hash, yes. The first layer only has one key, named `:named_args`. One key points to one value. How do you think the two `key_value`'s are stored? If it was only one `key_value`, it could be represented as one hash:

```ruby
{ :named_args =>
  { :key_value =>
     { :key  => "hello",  :val=>{:string=>"world"@9} }
  }
}
```

However we have two elements with the same key `key_value`. The only way to store them both is via an Array. The output of parsing `hello: "world", hi: "there"` would look like this:

```ruby
{
  :named_args =>
    [
      { :key_value =>
        { :key => "hello"@1, :val => {:string=>"world"@9}}
      },
      {
        :key_value =>
        { :key=>"hi"@17, :val => {:string=>"there"@22}}
      }
    ]
}
```

This is a subtle but important point in parslet, depending on how many times an element is matched, the value of a hash might be a hash or an array of hashes.

## Our first true data structure

Now that we have repeated key/value pairs, let's add a little syntactic sugar on them to make a Ruby style hash:

```ruby
def test_parses_hash
  input = '{ hello: "world", hi: "there" }'
  parser = MyParser.new.hash_obj
  tree = parser.parse_with_debug(input)
  refute_equal nil, tree
end
```

How can we match this? Hopefully you've got a reasonable guess. Here's my answer:

```ruby
rule(:hash_obj) {
  spaces? >> (
    str('{') >> named_args >> str('}')
  ) >> spaces?
}
```

We're essentially letting the `named_args` do the heavy lifting. You might also notice that I chose no to match anything with an `as` method. In this case nesting our key/value pair one level deeper in a `hash` key, doesn't really buy anything for us right now.

While this gets the tests to pass, I want to go one step further.

```ruby
actual = MyTransformer.new.apply(tree)
expected = { hello: "world", hi: "there" }
assert_equal expected, actual
```

In this case we're transforming a string representation of a hash into an actual hash. While it might not seem that exciting, considering we could have simply run `eval` to produce the same thing, keep in mind that this ability to implement a grammar and build a transformer to produce the objects we want allows us to implement virtually any language of our choosing, not just replicate Ruby features.

For now this is only a failing test. Here's the tree we can manipulate with our transformer:

```ruby
{ :named_args => [
      {:key_value => { :key => "hello"@3, :val => {:string=>"world"@11}}},
      {:key_value => { :key => "hi"@19, :val => {:string=>"there"@24}}}
    ]
}
```

In our transformer we need to match this entire hash, there is only one key in the top level hash `named_args`, however it's pointing at a pretty complex value, an array holding hashes that point to hashes.

We already have a transformer that will convert the `{:string=>"there"@24}` into simply `"there"`.

Parslet provides the ability to match ANY values with the keyword `subtree`. This is dangerous because you are now responsible for handling any inconsistencies in the input. For example, remember we looked at how this rule could return either a single hash or an array of hashes, when you choose to match via `subtree` you're now responsible for knowing that and doing the right thing.

Let's make sure that we can match this hash, then we'll add logic



```ruby
class MyTransformer < Parslet::Transform
  # ...

  rule(:named_args => subtree(:na)) {
    puts na.inspect
  }
end
```

The output should be an array like this:

```ruby
[
  {:key_value => { :key => "hello"@3, :val => "world" }},
  {:key_value => { :key => "hi"@19, :val => "there" }}
]
```

Notice that our `val` is simply a string here, and not the complex hash object. This is because our prior transformation was already applied.

To transform this into a hash, we need to ensure the input is always consistent, then build a hash by looping through each element in our input and adding the keys and values to that hash. Here's my solution:


```ruby
class MyTransformer < Parslet::Transform
  # ...

  rule(:named_args => subtree(:na)) {
    Array(na).each_with_object({}) { |element, output_hash|
      key = element[:key_value][:key].to_sym
      val = element[:key_value][:val]
      output_hash[key] = val
    }
  }
end
```

The `Array()` ensures we are dealing with an array. The `each_with_object` iterates over each element while yielding it and the input (in this case a hash) to the block, the return will be the input (the hash). We can then extract the key and value from each hash, and add them to our output hash.

This does the trick, and our test now passes!

You can run the [code on GitHub](https://github.com/schneems/implement_ruby_hash_syntax_with_parslet_example/blob/master/example.rb).

## Just the beginning

This article is already really long, but we're just scratching the surface of what you can do with parslet. You'll eventually want to keep adding grammar rules until you're happy with your language. I mentioned, implementing arrays, or integers. Do you think you could do that now? You can also add a `root` node which is where your parser starts parsing by default, rather than calling an explicit parser rule like we've been doing in our tests.

If you followed this tutorial, you're mostly there already! I recommend also walking through the official [parslet tutorial](http://kschiess.github.io/parslet/get-started.html) and looking at some of the other examples. If you get stuck, try going back to the basics, as well as writing more & smaller tests.

When constructing parsers, try to imagine what kind of a "tree" your desired grammar might produce, and try working, starting from the leaves. Once you've got the parser, try working in the same direction with your transformers, building from the leaves inward. While this will feel clunky at first, you'll get the hang of it over time.

When all else fails, write a blog post!

## parslet Cheatsheet

### Parser

#### Parser Syntax

- `str()` matches an exact string.
- `match()` matches a regex.
- `any` matches anything, an alias for `match('.')`.
- `.maybe` is a method on a match object that allows it to be matched 0 times.
- `.repeat` is a method on a match object that allows it to be matched a number of times. If passed arguments, they represent `repeat(<min times>, <max times>)`.
- `.absent?` is a method on a match object, it essentially inverts the match so that `string("f").absent?` will not match an `"f"`.
- `>>` can be used to chain together rules (the "and then" operator).
- `|` can be used to match one of multiple rules in order (the "or" operator).
- `.as` is a method on a match segment that allows you to capture values and name the capture

### Parser Notes

- Parsers are defined using the `rule` keyword.
- Matching with the same `as` value multiple times at the same level will result in an array instead of a hash.

### Transformer Syntax

- `simple` matches only non-nested values. I.e. numbers, strings, etc.
- `subtree` matches EVERYTHING.
- `sequence` is an inbetween that matches nested objects, but not deeply nested objects.

#### Transformer Notes

- Transformers are defined using the `rule` keyword.
- The transformer rule expects a `key => value` input.
- A transformer rule must match an entire hash (i.e. the key and the value, not just the key).
- The result of the transformer replaces the whole hash.
- There must be somewhere for that replacement to live (i.e. the dog/cat example).


## Downloadable Example app.

Here's the [source code to my example parslet app](https://github.com/schneems/implement_ruby_hash_syntax_with_parslet_example.git).
