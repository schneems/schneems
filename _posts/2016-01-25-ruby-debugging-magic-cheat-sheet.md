---
layout: post
title: "Ruby Debugging Magic Cheat Sheet"
date: 2016-01-25
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

This document is all about deciphering behavior of complicated Ruby code. I recommend you get familiar with a debugger like [pry-debugger](https://github.com/nixme/pry-debugger), this doc doesn't go into debuggers and only focuses on Ruby's ability to introspect its own code.

Many of these techniques are pulled from my first popular Ruby Conf. talk [Dissecting Ruby with Ruby](https://www.youtube.com/watch?v=UYVUSoNrM-c). This doc is open source and a living doc, send suggestions in PR form to [my blog](https://github.com/schneems/schneems/blob/master/_posts/2016-01-25-ruby-debugging-magic-cheat-sheet.md). Unless otherwise stated, all techniques work for the last major release of Ruby. Some may work with older versions of Ruby, I don't want to maintain that list, you can if you want.

## Figure out where a method was defined

```ruby
object = Object.new
puts object.method(:blank?).source_location
=> ["/gems/activesupport-5.0.0.beta1/lib/active_support/core_ext/object/blank.rb", 14]
```

This method was defined on line 14 of the file `active_support/core_ext/object/blank.rb`.

## Opening a dependency from a project

```sh
$ bundle open active_support
```

This will open the version of `active_support` you have in your `Gemfile.lock`. From here you can add debugging statements.

This command will use the value in your `EDITOR` environment variable. The default is vi or something. You can set this in your `.bashrc` file. For example I use Sublime text and have this in my `.bashrc`

```sh
export EDITOR="subl -w"
```

Google for the appropriate invocation for your editor

## Un-debug a gem

If you've opened a gem and added debug statements but forget to remove them before closing the file, you'll get those debug statements every time you run your program, to reset everything to original state you can use, `gem pristine`. To reset Active Support:

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

To reset ALL gems you can run

```sh
$ gem pristine --all
```

Note this may take a LONG time, especially if you've got gems with c-extensions.

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

This is where puma instantiated the request. If you work from the bottom and go up, you can see exactly how Puma turns a request into code, and how rack and rails work together to get to your line of code. Run `$ bundle open` to your heart's content. Its kinda interesting to see that the backtrace matches our middleware (in reverse order), where the request starts from the bottom and goes down:

```sh
$ rake middleware
use Rack::Sendfile
use ActionDispatch::Static
use ActionDispatch::LoadInterlock
use ActiveSupport::Cache::Strategy::LocalCache::Middleware
use Rack::Runtime
use Rack::MethodOverride
use ActionDispatch::RequestId
use Rails::Rack::Logger
use ActionDispatch::ShowExceptions
use WebConsole::Middleware
use ActionDispatch::DebugExceptions
use ActionDispatch::RemoteIp
use ActionDispatch::Reloader
use ActionDispatch::Callbacks
use ActiveRecord::Migration::CheckPending
use ActiveRecord::ConnectionAdapters::ConnectionManagement
use ActiveRecord::QueryCache
use ActionDispatch::Cookies
use ActionDispatch::Session::CookieStore
use ActionDispatch::Flash
use Rack::Head
use Rack::ConditionalGet
use Rack::ETag
use ActionView::Digestor::PerRequestDigestCacheExpiry
run MyRailsApp::Application.routes
```

## Find where Super is Calling

Let's say you have code that calls `super` you can find where that method is defined like this:

```ruby
def foo
  puts method(:foo).super_method.source_location
  super
end
```

I love this one since I proposed its addition 😉. You can read more about `super_method` here: http://www.schneems.com/2015/01/14/debugging-super-methods-ruby-22.html

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

## Missing Pieces Wish List

> Warning
> These things don't exist, but I wish they did. Don't try to use them, they won't work.

Here's broad things I want to do from time to time but haven't found a way to yet. I want to see where a constant was defined. Some of these might not be possible due to limitations in the VM. Let's say we have a file `foo.rb`.

```ruby
class Foo
end
```

I would love to be able to do something like call `Introspect.constant(Foo).source_location`. Even cooler is if we could see where constants were modified

```ruby
FOO = []
FOO << 1
```

Would be amazing to call `Introspect.constant(FOO).modified_at` and see where the constant was last changed, even if we had to boot our ruby process with something like `ruby --trace-constants` or something.

One other thing I would love to do is to be able to trace variable changes. Often times, i'll instantiate a variable

```ruby
config.thing = "foo"
```

But later in my code sometimes it is changed

```ruby
puts config.thing
# => nil
```

Something accidentally modifed the underlying value of `@thing` in our config object. It would be great to be able to see when it happened. Maybe something like

```ruby
config.thing = "foo"
Introspect.trace(config.thing).on_value_change |location, value|
  puts "config.thing changed on #{ location.inspect } to #{ value.inpsect }"
end
```

So as my code is running, I would get periodic debug statements.

```ruby
"config.thing changed on railties/controller_runtime.rb:18 to nil"
```

I realize I could do something like define a `thing=` method on `config` to get this information but A) it's kinda gnarly, and B) it fails for when your config is a hash that is getting mutated through something like `merge!`. Right now the only way to do this is to put the value of that variable, use caller to find where the variable came from, add a puts to see the value, and repeat until you find where in what context it changed. It's possible, but time consuming and error prone.