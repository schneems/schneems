---
layout: post
title: "Hashie Considered Harmful - An Ode to Hash and OpenStruct"
date: '2014-12-15 08:00:00'
published: true
tags: performance, benchmarking, ruby, hash, memory
---

**Update:** I made a [PR to mitigate most of the performance penalty in Omniauth](https://github.com/intridea/omniauth/pull/774). Deprecating and removing Hashie has resisted several attempts at refactoring. There's also a really good set of discussions [in the Reddit comments](https://www.reddit.com/r/ruby/comments/2pkzec/hashie_considered_harmful_an_ode_to_hash_and/).

-----------

New Ruby programmers mistakenly believe that hashes should be used everywhere for everything. They grow attached to hashes and use them in many places they shouldn't; creating and passing hashes when a proper [Plain Old Ruby Object](https://blog.steveklabnik.com/posts/2011-09-06-the-secret-to-rails-oo-design) would be much better. Eventually, they begin to wish hashes behaved more like objects and this is a horrible idea, as we will see in a short while.

I love hashes and I love objects. You can store values in hashes and store logic in your objects. To understand why we need to do some digging. Hashes in Ruby are dumb data structures. If you mistype a key, there are no warnings or errors. There’s no easy way to do custom setters or getters on a hash. Hashes are fast, and they're flexible. Hashes work fine for passing data, but work poorly for storing it in a controlled and structured manner. For the uninitiated, here’s what I’m talking about:

```ruby
hash = {}
hash[:spellning] = "richard"
```

This raises no errors, even if we misspell a key, unlike a class:

```ruby
class Foo
  attr_accessor :spelling
end
Foo.new.spellning = "richard"
# => NoMethodError: undefined method `spellning=' for #<Foo:0x007fbf2388bb40>
```

This error is extremely valuable, it gives us feedback about our mistake early. With the hash, we wouldn't get an error until we try to access the value of `hash[:spelling]` later, only to find it returning `nil`. Then, we have to hunt down the line to what caused the error, and when I'm tired and hungry, it's frustrating. Using a Ruby object, we get this feedback at the cause of the error rather than somewhere later down the line.

At some point and time, you’ve likely said: “Hmm…hashes, look like objects, wouldn’t it be great if I could access and set values on one like an object?”. Hopefully when this happened you found [OpenStruct](https://www.ruby-doc.org/stdlib-2.1.3/libdoc/ostruct/rdoc/OpenStruct.html) which lets you do basically the same things as a hash, but with the accessors of a user-defined object:

```ruby
require 'ostruct'
foo = OpenStruct.new
foo.spellning = "richard"
```

Okay so we get no errors, but it "feels" like an object. Open struct can be a convenient way to pass around data, but it has similar limitations to a Hash. Even better, OpenStruct has hash-like operators, we can use it __almost__ like a hash. The key word here is "almost".


```ruby
require 'ostruct'
foo = OpenStruct.new
foo["spelling"] = "richard"
puts foo["spelling"] # => "richard"
puts foo.spelling # => "richard"
```

That looks pretty darn close to a hash. What can't an open struct do? Well, let's compare:

```ruby
open_struct_methods = OpenStruct.new.methods
hash_methods        = {}.methods
missing_methods     = hash_methods - open_struct_methods
puts missing_methods
# => [:rehash, :to_hash, :to_a, :fetch, :store, :default, :default=, :default_proc, :default_proc=, :key, :index, :size, :length, :empty?, :each_value, :each_key, :each, :keys, :values, :values_at, :shift, :delete, :delete_if, :keep_if, :select, :select!, :reject, :reject!, :clear, :invert, :update, :replace, :merge!, :merge, :assoc, :rassoc, :flatten, :include?, :member?, :has_key?, :has_value?, :key?, :value?, :compare_by_identity, :compare_by_identity?, :entries, :sort, :sort_by, :grep, :count, :find, :detect, :find_index, :find_all, :collect, :map, :flat_map, :collect_concat, :inject, :reduce, :partition, :group_by, :first, :all?, :any?, :one?, :none?, :min, :max, :minmax, :min_by, :max_by, :minmax_by, :each_with_index, :reverse_each, :each_entry, :each_slice, :each_cons, :each_with_object, :zip, :take, :take_while, :drop, :drop_while, :cycle, :chunk, :slice_before, :lazy]
```

Wow, okay, that's a lot of differences. An open struct behaves more like an object than a data store. It is missing manipulation methods like `merge!` and meta information methods like `empty?`. This makes sense, when was the last time you merged a user object?

```ruby
User.new.merge(user)
# => NoMethodError: undefined method `merge' for #<User:0x007fa26b9170e8>
User.new.empty?
or: undefined method `empty?' for #<User:0x007fa26b9170e8>
```

## Value Objects

I lump both `Hash` and `OpenStruct` as value objects, because they're good for transporting values, but they don't act as a typical user-defined object. They're not good for persisting data and encapsulating complex logic. For example, a user's name should always start with a capital letter, this is easy for objects:

```ruby
class User
  attr_reader :name

  def name=(name)
    @name = name.capitalize
  end
end
user = User.new
user.name = "schneems"
puts user.name
# => "Schneems"
```

But this behavior is hard for a hash, and even for an Open Struct.

## Using Hashes

Likely, you're already familiar with using hashes to transport data:

```ruby
def link_to(name, path, options = {})
  # ...
```

Here, `options` is a hash, it makes sense to pass in a variety of different configuration options without having to specify them all in ordered arguments. However, since a hash is so flexible, we need to do additional error checking, such as ensuring that a critical key is present, or that its value isn't unexpected (i.e. someone passed in a number when you expected a string).

## Using OpenStructs

Using an Open Struct is less obvious. If you are interacting with a library and they expect an object input, you can fake it by using an Open Struct.

```ruby
my_values = {foo: "bar"}
objectish = OpenStruct.new(my_values)
OtherLibraray.new(objectish)
```

I find open structs useful when in the console and experimenting with new code, sometimes I use them to test interfaces in code I write. Honestly though, I generally don't use them much. Usually, when I think I want to use an open struct, what I really want is a [plain old ruby object](https://blog.steveklabnik.com/posts/2011-09-06-the-secret-to-rails-oo-design). It is much easier to manipulate the data in a hash than an Open Struct because they have all those meta methods, and they're more lightweight (Open Struct creates and stores a hash under the hood).

It's worth noting that `OpenStruct` is pretty slow compared to a regular hash:

```ruby
require 'benchmark/ips'
require 'ostruct'

hash        = {foo: "bar"}
open_struct = OpenStruct.new(hash)

Benchmark.ips do |x|
  x.report("openstruct") { open_struct[:foo] }
  x.report("hash")       { hash[:foo] }
end
```

results:

```
Calculating -------------------------------------
          openstruct   128.619k i/100ms
                hash   149.182k i/100ms
-------------------------------------------------
          openstruct      5.329M (± 7.4%) i/s -     26.496M
                hash      8.451M (± 3.9%) i/s -     42.219M
```

Because of this speed disparity and the confusion of interface, I recommend staying away from using OpenStruct in production code. Check out the [OpenStruct source code (it is in Ruby)](https://github.com/ruby/ruby/blob/trunk/lib/ostruct.rb) to see how it's implemented. Bonus points if you can guess why it's so much slower.

## What about Hashie?

It seems that, at this point, it would make sense to create an OpenStructHash object that behaved like an open struct and a hash at the same time. This is exactly what [Hashie](https://github.com/intridea/hashie) does (specifically Hashie::Mash). Unfortunately, it's a really bad idea. I've tried to use Hashie on several projects and always walked away frustrated and angry. I've used other people's code with Hashie deeply embedded, and it's always been a sore spot. But why?

Hashie tries to be two things at the same time. It has all the manipulation methods of a `Hash` and all accessor methods of a `OpenStruct`. This means your object now has a massive method surface area and an identity crisis.

```ruby
hashie = Hashie::Mash.new(name: "schneems")
hashie[:name]   # => "schneems"
hashie["name"]  # => "schneems"
hashie.name     # => "schneems"
```

This isn't so bad if you're using it as a simple hash, but then you don't need the extra methods...just use a hash. Having this advanced pseudo-object creates problems. For example how does it behave when it interacts with other objects. Let's say I want the values in my hashie object to take precedence in a merge, so I pass it into the `Hash#merge` method:

```ruby
hashie = Hashie::Mash.new(name: "schneems")
hash   = { job: "programmer" }
result = hash.merge(hashie)
result.name
# => NoMethodError: undefined method `name' for {"name" => "schneems", job: "programmer"}
```

Well, that stinks. Did you notice anything else? Hashie::Mash lets you access the hash with a string or a symbol for convenience. This produced a weird result here, where some of the keys in `result` are strings and some are symbols.

```ruby
puts result.inspect # => {:job=>"programmer", "name"=>"schneems"}
```

This is really weird, if we `merge!` a hash twice, we expect to get the same result:

```ruby
hash1  = {name: "schneems"}
hash2  = {job: "programmer"}
result = hash1.merge!(hash2)
puts result.inspect # => {:job=>"programmer", :name=>"schneems"}
result = hash2.merge!(hash1)
puts result.inspect # => {:job=>"programmer", :name=>"schneems"}
```
However, with hashie:

```ruby
hashie = Hashie::Mash.new(name: "schneems")
hash   = {job: "programmer"}
result = hashie.merge!(hash)
puts result.to_hash.inspect # => {"name"=>"schneems", "job"=>"programmer"}
result = hash.merge!(hashie)
puts result.to_hash.inspect # => {:job=>"programmer", "name"=>"schneems", "job"=>"programmer"}
```

WAIT, Now we've got the same value with two different keys (`:job` and `"job"`). This isn't really a "bug" so to speak, hashie does its best to do the right thing, but in this case it can't, it doesn't have enough information. There are more issues than just merge, but they're not as easy to show in a few lines of code.

## Hashie - Bad goes to Worse

Having multiple access modes to a hash (string and symbol) is really convenient, so some may use hashie for this task. In Rails, `HashWithIndifferentAccess` does this chore, and it's really helpful. The "oh crap I used a string and I meant a symbol" is a common and painful error with hashes. However, it rarely stops there with Hashie.

Most people use hashie for either configuration objects, where they can't be bothered to define the config attributes properly or as a way to "cheaply" build objects from the JSON response of an API. If you poke around, maybe some of your favorite API wrapper libraries use Hashie.

Both of these are horrible choices. For the config case, you now open up your users to a multitude of misconfiguration options (misspelling, no input validation, etc.) You can build these into a hashie::mash object, but it's not simple:

```ruby
class MyConfigOptions < Hashie::Mash
  def name=(value)
    raise "not a string #{value}" unless value.is_a?(String)
    self["name"] = value
  end
end

config = MyConfigOptions.new
config["name"] = 99
puts config.name.inspect # => 99
puts config.name.class   # => Fixnum
```

Ughhhh. You can also overwrite `def []=(key, value)`, but then, what if someone passes in a hash at initialization, well, you have to overwrite that too. Hashie has some internal helper methods for these cases, but...why not just use a class? Help your consumers with meaningful error messages and behavior. If you want them to interact with an object, return an object. If you want to return a hash, give them a hash. Giving them a pseudo object that behaves as both opens up weird edge cases and confusion for your consumers. Much easier to write

```ruby
class MyConfigOptions
  attr_accessor :name

  def name=(value)
    raise "not a string #{value}" unless value.is_a?(String)
    @name = value
  end
end
```

Now, you also magically have a documented interface!

## It gets worse (again) - Memory Overload

Let's say, for some reason, you love this weird edge-casey nature and undecided pseudo-object behavior. You choose to use Hashie for a really popular project, let's hypothetically call it [omniauth](https://github.com/intridea/omniauth). The insanely open behavior that you crave so much come at a very high cost of large numbers of short-lived objects used internally by hashie.

I profiled a Rails app [CodeTriage.com](https://www.codetriage.com/) using Omniauth. I used [memory_profiler with my derailed_benchmarks](https://github.com/schneems/derailed_benchmarks) to benchmark memory usage. On one single request to the Rails app, Hashie created more objects than `activesupport` and it came in at number 3 total in the list:


```
allocated memory by gem
-----------------------------------
rack-1.5.2 x 6491
actionpack-4.1.2 x 4888
hashie-2.1.1 x 4615        <========= Using Hashie
activesupport-4.1.2 x 4523
omniauth-1.2.1 x 1387
actionview-4.1.2 x 1107
ruby-2.1.2/lib x 1097
railties-4.1.2 x 925
activerecord-4.1.2 x 440
warden-1.2.3 x 200
```

That's a lot of objects for little benefit. Does this have an impact on performance? Oh, yeah.

I spent a few hours forking and removing Hashie from Omniauth, the memory savings were readily apparent:

```
allocated memory by gem
-----------------------------------
rack-1.5.2 x 6491
actionpack-4.1.2 x 4888
activesupport-4.1.2 x 3292
ruby-2.1.2/lib x 1337      <========= Replace Hashie with Open Struct
omniauth/lib x 1267
actionview-4.1.2 x 1107
railties-4.1.2 x 925
activerecord-4.1.2 x 440
warden-1.2.3 x 200
codetriage-ko1-test-app/app x 40
other x 40
```

My replacement uses a custom object that inherits from `OpenStruct` from the standard lib and we can see it creates fewer objects `1337` (super l33t) versus `4615`. The change also had a measurable impact on speed. I'm still tweaking, but initial benchmarks indicate a 5% increase in speed in the total request. This is a 5% increase on __TOTAL__ request time, i.e. the app got 5% faster...not just omniauth.

Unfortunately, this was a proof of concept as this would be a breaking change (the API wasn't 100% compatible). Here's the [PR for removing hashie from omniauth](https://github.com/intridea/omniauth/pull/774) and discussion.

## Alternatives

The easiest way to quit smoking is to never start. If you've inherited a hashie addicted project, what can you do? In Omniauth, I removed hashie, let all the tests fail, then worked on one test at a time till they were all green. In this case, Omniauth is really popular, so we can't just change the interface without proper deprecation warning. Ideally, in the future, we can isolate how the code is used, and replace it with some stricter (and therefore easier reason about) interfaces that are even faster.

If you really __need__ to take arbitrary values, consider a plain ole' Ruby Hash. If you really need the method access using the dot syntax, use a `Struct`, an `OpenStruct`, or even write a custom PORO. If you're using hashie in an object that also wraps up logic, get rid of hashie, and keep the logic. Subclassing `Hash` is pretty much evil. It's a proven fact(TM) that [subclassing hashes causes pain and performance problems](https://tenderlovemaking.com/2014/06/02/yagni-methods-are-killing-me.html) so don't do it.

While I've ripped on Hashie a good amount: it's a good, fun library to play with, and you can learn quite a bit about metaprogramming through the code. I recommend you check it out, but whatever you do...don't ever put it in production.

---
If you like performance, or not using Hashie follow [@schneems on twitter](https://ruby.social/@Schneems)
