---
layout: post
title: "Ruby Debugging Magic Cheat Sheet"
date: 2016-01-25
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

This document is all about deciphering behavior of Ruby code using nothing but Ruby code. I recommend you get familiar with a debugger like [pry-debugger](https://github.com/nixme/pry-debugger), this doc doesn't go into debuggers [because they're not always available](https://www.reddit.com/r/ruby/comments/42lxrq/ruby_debugging_magic_cheat_sheet/czbef0m).

Many of these techniques are pulled from my first popular talk [Dissecting Ruby with Ruby](https://www.youtube.com/watch?v=UYVUSoNrM-c).

> This page is open source and a living document, send suggestions in PR form to [my blog on GitHub](https://github.com/schneems/schneems/blob/master/_posts/2016-01-25-ruby-debugging-magic-cheat-sheet.md).

Unless otherwise stated, all techniques work for the last major release of Ruby.

## Figure out where a method was defined

```ruby
object = Object.new
puts object.method(:blank?).source_location
=> ["/gems/activesupport-5.0.0.beta1/lib/active_support/core_ext/object/blank.rb", 14]
```

This method was defined on line `14` of the file `active_support/core_ext/object/blank.rb`.

## Opening a dependency from a project

```sh
$ bundle open active_support
```

This will open the version of `active_support` you have in your `Gemfile.lock`. From here you can add debugging statements.

This command will use the value in your `EDITOR` environment variable. The default is vi or something. You can set this in your `.bashrc` file. For example I use Sublime text and have this in my `.bashrc`

```sh
export EDITOR="subl -w"
```

Google for the appropriate invocation for your editor.

If you close the file accidentally you can use `gem pristine` which is discussed below.

## See where an object was created

You can use object space to see where a constant or an object was created.

```ruby
require 'objspace'
ObjectSpace.trace_object_allocations_start

Kernel.send(:define_method, :sup) do |obj|
  puts "#{ ObjectSpace.allocation_sourcefile(obj) }:#{ ObjectSpace.allocation_sourceline(obj) }"
end

world = "hello"

sup world
# => /tmp/scratch.rb:10
```

Since the invocation to get the file and line number is so long, I added a helper method `sup`. Make sure tracing is started early as possible, I usually put this code in the top of my Gemfile. Remove this code when you're not debugging, tracing allocations has a performance impact.

If you find yourself on a remote machine without access to an editor you can [inject this into a Gemfile in a few lines of bash](https://gist.github.com/schneems/003de3b80e6b983c84ebc7273fd60947)

Thanks to [I need to find where this object came from](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html#i-need-to-find-where-this-object-came-from).

## Figuring out how a method was called

To generate a backtrace without raising an exception use the `caller` method like:

```ruby
class Project

  def foo
    puts "====================="
    puts caller
  end
end
```

Now when you generate a request you'll get a backtrace like:

```sh
=====================
/Users/richardschneeman/documents/projects/my_rails_app/app/controllers/projects_controller.rb:18:in `new'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/basic_implicit_render.rb:4:in `send_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/abstract_controller/base.rb:183:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/rendering.rb:30:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/abstract_controller/callbacks.rb:20:in `block in process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:126:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:506:in `block (2 levels) in compile'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:455:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:101:in `__run_callbacks__'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:750:in `_run_process_action_callbacks'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:90:in `run_callbacks'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/abstract_controller/callbacks.rb:19:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/rescue.rb:27:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/instrumentation.rb:31:in `block in process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/notifications.rb:164:in `block in instrument'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/notifications/instrumenter.rb:21:in `instrument'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/notifications.rb:164:in `instrument'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/instrumentation.rb:29:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal/params_wrapper.rb:248:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activerecord-5.0.0.beta1/lib/active_record/railties/controller_runtime.rb:18:in `process_action'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/abstract_controller/base.rb:128:in `process'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionview-5.0.0.beta1/lib/action_view/rendering.rb:30:in `process'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal.rb:192:in `dispatch'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_controller/metal.rb:264:in `dispatch'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/routing/route_set.rb:50:in `dispatch'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/routing/route_set.rb:32:in `serve'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/journey/router.rb:42:in `block in serve'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/journey/router.rb:29:in `each'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/journey/router.rb:29:in `serve'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/routing/route_set.rb:715:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionview-5.0.0.beta1/lib/action_view/digestor.rb:14:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/etag.rb:25:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/conditional_get.rb:25:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/head.rb:12:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/session/abstract/id.rb:220:in `context'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/session/abstract/id.rb:214:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/cookies.rb:608:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activerecord-5.0.0.beta1/lib/active_record/query_cache.rb:36:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activerecord-5.0.0.beta1/lib/active_record/connection_adapters/abstract/connection_pool.rb:963:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activerecord-5.0.0.beta1/lib/active_record/migration.rb:524:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/callbacks.rb:29:in `block in call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:97:in `__run_callbacks__'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:750:in `_run_call_callbacks'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/callbacks.rb:90:in `run_callbacks'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/callbacks.rb:27:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/reloader.rb:71:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/remote_ip.rb:79:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/debug_exceptions.rb:49:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/web-console-3.0.0/lib/web_console/middleware.rb:27:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/show_exceptions.rb:31:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/railties-5.0.0.beta1/lib/rails/rack/logger.rb:42:in `call_app'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/railties-5.0.0.beta1/lib/rails/rack/logger.rb:24:in `block in call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/tagged_logging.rb:70:in `block in tagged'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/tagged_logging.rb:26:in `tagged'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/tagged_logging.rb:70:in `tagged'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/railties-5.0.0.beta1/lib/rails/rack/logger.rb:24:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/request_id.rb:24:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/method_override.rb:22:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/runtime.rb:22:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/activesupport-5.0.0.beta1/lib/active_support/cache/strategy/local_cache_middleware.rb:28:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/load_interlock.rb:13:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/actionpack-5.0.0.beta1/lib/action_dispatch/middleware/static.rb:132:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/rack-2.0.0.alpha/lib/rack/sendfile.rb:111:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/railties-5.0.0.beta1/lib/rails/engine.rb:522:in `call'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/puma-2.15.3/lib/puma/server.rb:541:in `handle_request'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/puma-2.15.3/lib/puma/server.rb:388:in `process_client'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/puma-2.15.3/lib/puma/server.rb:270:in `block in run'
/Users/richardschneeman/.gem/ruby/2.3.0/gems/puma-2.15.3/lib/puma/thread_pool.rb:106:in `block in spawn_thread'
```

Ugh, long ugly backtrace. What does it mean? The top line is the last method that was run before our, `puts caller` was called. In this case

```sh
/Users/richardschneeman/documents/projects/my_rails_app/app/controllers/projects_controller.rb:18:in `new'
```

This was called from the `projects_controller` line 18, in the `new` method in my app. We can trace this back all the way to the beginning of the request by looking at the first line

```sh
/Users/richardschneeman/.gem/ruby/2.3.0/gems/puma-2.15.3/lib/puma/thread_pool.rb:106:in `block in spawn_thread'
```

This is where Puma instantiated the request.

If you work from the bottom of the backtrace and go up, you can see exactly how Puma turns a request into code.

## Find which method Super is Calling

Let's say you have code that calls `super` you can find where that method is defined like this:

```ruby
def foo
  puts method(:foo).super_method.source_location
  super
end
```

I love this one since I proposed the method 😉. You can read more about `super_method` here: [Debugging Super methods in Ruby 2.2+](https://www.schneems.com/2015/01/14/debugging-super-methods-ruby-22.html).

## List all methods on an object

```ruby
object.methods
# => [:instance_of?, :public_send, :instance_variable_get, :instance_variable_set, :instance_variable_defined?, :remove_instance_variable, :private_methods, :kind_of?, :instance_variables, :tap, :is_a?, :extend, :define_singleton_method, :to_enum, :enum_for, :<=>, :===, :=~, :!~, :eql?, :respond_to?, :freeze, :inspect, :display, :send, :object_id, :to_s, :method, :public_method, :singleton_method, :nil?, :hash, :class, :singleton_class, :clone, :dup, :itself, :taint, :tainted?, :untaint, :untrust, :trust, :untrusted?, :methods, :protected_methods, :frozen?, :public_methods, :singleton_methods, :!, :==, :!=, :__send__, :equal?, :instance_eval, :instance_exec, :__id__]
```

## Get instance method location without an instance

```ruby
User.instance_method(:github_url).source_location
```

## Introspect method arguments

```ruby
def parse(input, skip_code_comments: false, ignore_whitespace: true)
  # do stuff
end
```

```ruby
method(:parse).parameters
#=> [[:req, :input], [:key, :skip_code_comments], [:key, :ignore_whitespace]]
```

Now you can see all available keyword arguments.

## See where an argument is mutated

Often times, I'll instantiate a variable

```ruby
config.thing = { "foo" => "bar" }
```

But later I'll find it was changed, but I don't know where:

```ruby
puts config.thing
# => {"bar" => "THE FOO KEY IS GONE"}
```

You can see where the value of an object was modified by first `freeze`-ing the object:

```
config.thing.freeze
```

Then later if other code modifies the object, an error will be raised:

```
config.thing.delete("foo")

# active_support/concurrency/share_lock.rb:151:in `delete': can't modify frozen Hash (RuntimeError)
#  from active_support/concurrency/share_lock.rb:151:in `yield_shares'
#  from active_support/concurrency/share_lock.rb:79:in `block in stop_exclusive'
```

There are some caveats: In this example the hash is frozen, but the keys and values are not. If you try to modify a key or value, no exception will be raised. If you're trying to freeze a complex object such as a Hash, you'll need to deep freeze it. This technique also won't work for cases where a variable is assigned instead of mutated.

Originally on my "missing pieces" list, TLo documented it [An object is being mutated but I don't know where](https://tenderlovemaking.com/2016/02/05/i-am-a-puts-debuggerer.html#an-object-is-being-mutated-but-i-dont-know-where.).

## Un-debug a gem

If you've opened a gem and added debug statements, but forget to remove them before closing the file: you'll get those debug statements every time you run your program. To reset every gem to its original state you can use `gem pristine`. For example to reset Active Support:

```sh
$ gem pristine activesupport
Restoring gems to pristine condition...
Restored activesupport-3.2.21
Restored activesupport-3.2.22
Restored activesupport-4.0.0
Restored activesupport-4.1.1
Restored activesupport-4.2.0
Restored activesupport-4.2.1
Restored activesupport-4.2.3
Restored activesupport-4.2.5.rc1
Restored activesupport-4.2.5
Restored activesupport-5.0.0.beta1
```

To reset ALL gems you can run:

```sh
$ gem pristine --all
```

> Note: this may take a LONG time, especially if you've got gems with c-extensions.

## Missing Pieces Wish List

> Warning: These things don't exist, but I wish they did. Don't try to use them, they won't work.

Here's a list of things I want to do from time to time, but haven't found a way to yet. Some of these might not be possible due to limitations in the VM. When a "missing piece" is found it is removed from this section and given it's own heading above.

- Find where a variable is over-written with a different value. While we can use the `freeze` trick to see where a value is modified, we won't see when it is replaced.

```ruby
config.thing = { "foo" => "bar" }.freeze

config.thing = nil
# No error is raised as the hash isn't being mutated, the variable is being assigned a different value
```


## Not debugging

These are a few tricks that aren't debugging related, but I've found helpful for understanding how the interpreter works.


### Disassemble Ruby code:

```ruby
code = <<~CODE
  a = 4
  b = 10
  puts a + b
CODE
puts RubyVM::InstructionSequence.compile(code).disasm
```

Generates something like this:

```
== disasm: #<ISeq:<compiled>@<compiled>>================================
local table (size: 2, argc: 0 [opts: 0, rest: -1, post: 0, block: -1, kw: -1@-1, kwrest: -1])
[ 2] a          [ 1] b
0000 trace            1                                               (   1)
0002 putobject        4
0004 setlocal_OP__WC__0 4
0006 trace            1                                               (   2)
0008 putobject        10
0010 setlocal_OP__WC__0 3
0012 trace            1                                               (   3)
0014 putself
0015 getlocal_OP__WC__0 4
0017 getlocal_OP__WC__0 3
0019 opt_plus         <callinfo!mid:+, argc:1, ARGS_SIMPLE>, <callcache>
0022 opt_send_without_block <callinfo!mid:puts, argc:1, FCALL|ARGS_SIMPLE>, <callcache>
0025 leave
```
