---
layout: post
title: "Debugging Super Methods in Ruby 2.2"
date: '2015-01-14'
published: true
tags: debugging, ruby, super, method,
---

Debugging a large codebase is hard. Ruby makes debugging easier by exposing [method metadata](https://www.ruby-doc.org/core-2.2.0/Method.html) and [caller stack](https://www.ruby-doc.org/core-2.2.0/Kernel.html#method-i-caller) inside Ruby's own process. Recently in Ruby 2.2.0 this meta inspection got another useful feature by exposing [super method metadata](https://bugs.ruby-lang.org/issues/9781). In this post we will look at how this information can be used to debug and why it needed to be added.


<h3><a href="https://engineering.heroku.com/blogs/2014-01-14-debugging-super-methods-ruby22">Keep reading on the Heroku engineering blog</a></h3>.

One of the first talks I ever wrote was "Dissecting Ruby With Ruby" all about inspecting and debugging Ruby processes using nothing but Ruby code. If you've never heard of the [Method  method](https://ruby-doc.org/core-2.2.0/Method.html) it's worth a watch.

<iframe width="560" height="315" src="//www.youtube.com/embed/UYVUSoNrM-c" frameborder="0" allowfullscreen></iframe>

In short, Ruby knows how to execute your code, as well as where your code was defined. For example, with this small class:

```ruby
class Dog
  def bark
    puts "woof"
  end
end
```

We can see exactly where `Dog#bark` is defined:

```ruby
puts Dog.new.bark
# => "woof"
puts Dog.new.method(:bark).source_location.inspect
# => ["/tmp/dog.rb", 2]
```

Even if someone did some crazy metaprogramming or you accidentally over-wrote the method, Ruby will always tell you the location of the method it will call.

## Super problems

If you've [seen the "Dissecting Ruby" talk](https://www.youtube.com/watch?v=UYVUSoNrM-c), you'll know that there is a big problem with the super method. It's almost impossible to tell where the final method location being called is written.

```ruby
class SchneemsDog < Dog
  def bark
    super
  end
end
```

I ended up using some metaprogramming to figure this out:

```ruby
cinco = SchneemsDog.new
cinco.class.superclass.instance_method(:bark)
# => ["/tmp/dog.rb", 6]
```

This works, but it wouldn't if we did certain types of metaprogramming. For example, we would get the wrong answer if we did this:

```ruby
module DoubleBark
  def bark
    super
    super
  end
end
cinco = SchneemsDog.new
cinco.extend(Doublebark)
```

In this case, `cinco.bark` will call the method defined in the `Doublebark` module:

```ruby
cinco.bark
# => bark
# => bark

puts cinco.method(:bark)
#<Method: SchneemsDog(DoubleBark)#bark>
```

The actual "super" being referred to is defined in the `SchneemsDog` class. However, the code tells us that the method is in the `Dog` class, which is incorrect.

```ruby
puts cinco.class.superclass.instance_method(:bark)
# => #<UnboundMethod: Dog#bark>
```

This is because our `Doublebark` module isn't an ancestor of the `cinco.class`. How can we solve this issue?

## Super solutions

In feature request [#9781](https://bugs.ruby-lang.org/issues/9781), I proposed adding a method to allow Ruby to give you this information directly. Shortly after, one of my co-workers, [Nobuyoshi Nakada](https://bugs.ruby-lang.org/users/4), A.K.A. "The Patch Monster", attached a working patch, and it was accepted into the Ruby trunk (soon to become 2.2.0) around July.

If you are debugging in Ruby 2.2.0 you can now use [Method#super_method](https://ruby-doc.org/core-2.2.0/Method.html#method-i-super_method). Using the same code we mentioned previously:

```ruby
cinco = SchneemsDog.new
cinco.method(:bark).super_method
# => #<Method: Dog#bark>
```

You can see this returns the method on the `Dog` class rather than the `SchneemsDog` class. If we call `source_location` in the output, we will get the correct value:

```ruby
module DoubleBark
  def bark
    super
    super
  end
end
cinco = SchneemsDog.new
cinco.extend(Doublebark)

puts cinco.method(:bark)
# => #<Method: SchneemsDog(DoubleBark)#bark>
puts cinco.method(:bark).super_method
# => #<Method: SchneemsDog#bark>
```

Not only is this simpler, it's now correct. The return of `super_method` will be the same method that Ruby will call when `super` is invoked, regardless of whatever craziness is done with metaprogramming. Even though this is a simple example, I hope you'll find this useful in the wild.


---
Follow [@schneems](https://twitter.com/schneems) for Ruby articles and pictures of his dogs. Note that Cinco was not harmed in the making of this blog post


![](https://www.dropbox.com/s/xl1idg4ulbtid0p/Screenshot%202015-01-12%2011.15.27.png?raw=1)
