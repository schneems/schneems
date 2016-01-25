---
layout: post
title: "Upgrading to Rails 5 Beta - The Hard Way"
date: 2016-01-25
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

Rails 5 has been brewing for more than a year. To take advantage of new features, and stay on the supported path, you'll need to upgrade. In this post, we'll look at the upgrade process for a production Rails app, [codetriage.com](http://www.codetriage.com). The codebase is open source so you [can follow along](https://github.com/codetriage/codetriage/pull/435). Special thanks to [Prathamesh](https://twitter.com/_cha1tanya) for his help with this blog post.


> This post originally published to the Heroku blog [Upgrading to Rails 5 beta](https://blog.heroku.com/archives/2016/1/22/rails-5-beta-upgrade).


## How Stable is the Beta?

In Rails a beta means the API is not yet stable, and features will come and go. A Release Candidate (RC) means no new features; the API is considered stable, and RCs will continue to be released until all reported regressions are resolved.

Should you run your production app on the beta? There is value in getting a beta working on a branch and being ready when the RC or upcoming release is available. Lots of companies run Beta and RC releases of Rails in production, but it's not for the faint of heart. You'll need to be pretty confident in your app, make sure your test suite is up to par, and that manual quality control (QC) checks are thorough. It's always a relief to find and fix bugs before they arrive in production. Please report regressions and bugs you encounter -- the faster we uncover and report them, the faster these bugs get fixed, and the more stable Rails becomes. Remember, no one else is going to find and report the regressions in your codebase unless you do it.



## Upgrade your Gemfile

Step zero of the process is changing your Rails dependency, after which you'll want to `$ bundle install`, see what is incompatible and update those dependencies.

If you want to run on Heroku, I recommend avoiding the beta1 release on rubygems.org. It doesn't include a [fix to stdout logging](https://github.com/rails/rails/pull/22933) that is available in master. CodeTriage is running with this SHA of Rails from master:

```ruby
# Gemfile
gem "rails", github: "rails/rails", ref: "dbf67b3a6f549769c5f581b70bc0c0d880d5d5d1"
```

You'll need to make sure that you're running a current Ruby; Rails now requires Ruby 2.2.2 or greater. At the time of writing, I recommend 2.2.4 or 2.3.0. CodeTriage is running 2.3.0.

```ruby
# Gemfile
ruby "2.3.0"
```

If you can't bundle, you'll need to modify your dependencies in your Gemfile, or `bundle update <dependency>`

Once you've completed a `$ bundle install` you're well on your way to getting the upgrade started.

## Gems Gems Gems

Just because a gem installs correctly doesn't mean it's compatible with Rails 5. Most libraries that specify Rails as a runtime dependency do not specify an upper bounds in their gemspec (like a Gemfile for gems). If they said "this gem is valid for rails versions 3-4" then bundler would let you know that it couldn't install that gem. Unfortunately since most say something like "this is good for Rails version 3 to infinity," there's no way by versioning alone. You'll have to investigate which of your dependencies are compatible manually; don't worry, there are some easy ways to tell.

## Rails Console

The first thing you'll want to do is boot a console:

```sh
$ rails console
Loading development environment (Rails 5.0.0.beta1)
irb(main):001:0>
```

Did that work? Great, skip to the next step. If not, use backtraces to see where errors came from, and which gems might be having problems.

When you get a problem with a gem, check https://rubygems.org and see if you're using the latest. If not, it's a good idea to try using the most recently released version. If you still get an error, try pointing at their master branch, some libraries have fixes for Rails 5 that haven't been released yet. Many libraries that depend on Rack have not released a version that supports Rack 2, however many of them have support for it in master or in another branch. When in doubt ask a gem maintainer.

Here's an example of an error that CodeTriage saw:

```sh
$ rails console
/Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/failure_app.rb:9:in `<class:FailureApp>': uninitialized constant ActionController::RackDelegation (NameError)
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/failure_app.rb:8:in `<module:Devise>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/failure_app.rb:3:in `<top (required)>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/mapping.rb:122:in `default_failure_app'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/mapping.rb:67:in `initialize'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise.rb:325:in `new'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise.rb:325:in `add_mapping'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/rails/routes.rb:238:in `block in devise_for'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/rails/routes.rb:237:in `each'
  from /Users/richardschneeman/.gem/ruby/2.3.0/gems/devise-3.5.3/lib/devise/rails/routes.rb:237:in `devise_for'
  from /Users/richardschneeman/Documents/projects/codetriage/config/routes.rb:9:in `block in <top (required)>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/actionpack/lib/action_dispatch/routing/route_set.rb:389:in `instance_exec'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/actionpack/lib/action_dispatch/routing/route_set.rb:389:in `eval_block'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/actionpack/lib/action_dispatch/routing/route_set.rb:371:in `draw'
  from /Users/richardschneeman/Documents/projects/codetriage/config/routes.rb:3:in `<top (required)>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:40:in `block in load_paths'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:40:in `each'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:40:in `load_paths'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:16:in `reload!'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:26:in `block in updater'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/activesupport/lib/active_support/file_update_checker.rb:75:in `execute'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:27:in `updater'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/routes_reloader.rb:7:in `execute_if_updated'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application/finisher.rb:69:in `block in <module:Finisher>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/initializable.rb:30:in `instance_exec'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/initializable.rb:30:in `run'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/initializable.rb:55:in `block in run_initializers'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:228:in `block in tsort_each'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:350:in `block (2 levels) in each_strongly_connected_component'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:431:in `each_strongly_connected_component_from'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:349:in `block in each_strongly_connected_component'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:347:in `each'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:347:in `call'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:347:in `each_strongly_connected_component'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:226:in `tsort_each'
  from /Users/richardschneeman/.rubies/ruby-2.3.0/lib/ruby/2.3.0/tsort.rb:205:in `tsort_each'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/initializable.rb:54:in `run_initializers'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application.rb:350:in `initialize!'
  from /Users/richardschneeman/Documents/projects/codetriage/config/environment.rb:5:in `<top (required)>'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/application.rb:326:in `require_environment!'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/commands/commands_tasks.rb:157:in `require_application_and_environment!'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/commands/commands_tasks.rb:77:in `console'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/commands/commands_tasks.rb:49:in `run_command!'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/command.rb:20:in `run'
  from /Users/richardschneeman/.gem/ruby/2.3.0/bundler/gems/rails-dbf67b3a6f54/railties/lib/rails/commands.rb:19:in `<top (required)>'
  from bin/rails:4:in `require'
  from bin/rails:4:in `<main>'
```

The gem in the backtrace above is devise 3.5.3; we were able to get things working by pointing to master, which may be released by now.

Repeat this until your `rails console` works. If you're already on the master version of a gem and it's still failing to boot, it might not support Rails 5 yet. Try debugging a little, and see if there's any open issues about Rails 5 on the tracker. If you don't see anything, open a new issue giving your error message and description of what's going on, and try to be as instructive as possible. Before you do this, you might want to try using the master version of their gem in a bare-bones `rails new` app to see if you can reproduce the problem. If the problem doesn't reproduce it may be an issue with how you're using the gem instead of the gem itself. This will help you uncover differences there. If you do reproduce the problem, then push it up to Github and share it in the issue. The maintainer will be able to fix an easily reproducible example much faster.

When you're not able to upgrade around a fix, sometimes you might not need that gem, or you might want to remove it temporarily so you can work on upgrading the rest of your app while the maintainer works on a fix.

## Shim Gems

Sometimes functionality is taken out of Rails but provided via smaller gems. For example. While upgrading we had to use `record_tag_helper` and `rails-controller-testing` to get the app working.

## Rails Server

Once you've got your console working, try your server. Just like with console, get it to boot. Once it's booted try hitting the main page and some other actions. You'll be looking for exceptions as well as strange behavior, though not all bugs cause exceptions. In the case of CodeTriage, a strange thing was happening. An error was getting thrown, but there was nothing in the logs and no debug error page in development. When this happens it's usually a bug in a rack middleware. You can get a list of them by running

```sh
$ rake middleware
use Rack::Sendfile
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
use Warden::Manager
use ActionView::Digestor::PerRequestDigestCacheExpiry
use Bullet::Rack
use OmniAuth::Strategies::GitHub
run CodeTriage::Application.routes
```

The request enters at the top and goes to each middleware until finally it hits our application on the bottom `CodeTriage::Application.routes`. If the error was being thrown by our app, then the `ActionDispatch::DebugExceptions` middleware outputs error logs and would show a nice exception page in development. In my case that wasn't happening, so I knew the error was somewhere before that point.

I bisected the problem by adding logging to `call` methods. If the output showed up in STDOUT then I knew it was being called successfully and I should go higher up the Rack stack (which is confusing, because it is lower on this middleware list). After enough debugging, I finally found the exception was coming from `WebConsole::Middleware`, which is naturally the last possible place an exception could occur before it gets caught by the `DebugExceptions` middleware. Upgrading to master on web-console gem fixed the error. It turns out that placement is not by accident and web-console inserts itself before the debug middleware. I [opened an issue with web-console](https://github.com/rails/web-console/issues/178) and [@gsamokovarov](https://github.com/gsamokovarov) promptly added some code that detects when an internal error is thrown by web-console and makes sure it shows up in the logs. My rule of thumb is if something takes me over an hour to fix that could have been made much easier by exposing the errant behavior (such as logging an exception), then I report it as an issue to raise awareness of that failure mode. Sometimes the bug is well known but often maintainers don't know what is difficult or hard to debug. If you have ideas on things to add to make using a piece of software easier, sharing it in a friendly and helpful way is good for everyone.

Keep manually testing your app until no errors and all errant behavior is gone. Once you've done this, you're on the home stretch.

## Testing

Now the server and console are working, you want to get your test suite green `$ rake test`. Rails 5 now includes a nice test runner `$ rails test`; you can specify a particular file or a specific line to run `$ rails test test/unit/users.rb:58`.

This step was bad, resulting in cryptic failures. I recommend picking 1 failure or error and focusing on it. Sometimes you'll see 100 failures, but when you fix one, it resolves them all, as they were the same issue.

For CodeTriage, we were getting errors

```sh
UserUpdateTest#test_updating_the_users_skip_issues_with_pr_setting_to_true:
NoMethodError: undefined method `normalize_params' for Rack::Utils:Module
    test/integration/user_update_test.rb:50:in `block in <class:UserUpdateTest>'
```

A grep of my project indicated `normalize_params` wasn't being used. The error didn't have a long backtrace. On that line `test/integration/user_update_test.rb:50` we are using a [capybara](http://jnicklas.github.io/capybara/) helper:

```ruby
click_button 'Save'
```

On a whim, I updated capybara and it resolved the error. Not sure why the backtrace was so short, that might be worth digging into later, as it would have made debugging faster.

## Other gotchas

The Strong Params that you get in your controller have changed and are no longer inheriting from a hash. At the time, there was no deprecation, so I [added one](https://github.com/rails/rails/pull/23123). It's just a deprecation, but you should still make sure you're only using the approved API.

There was a change to `image_tag` where it no longer takes `nil` as an argument, this wasn't used in production, but the tests (accidentally) depended on it.

With all of this together, we were ready for Rails 5 in the prime time. Here's the [PR]( https://github.com/codetriage/codetriage/pull/435)

## After the Upgrade

We're almost done! The last thing we need to do is to look for deprecations. They'll show up in your logs like:

```sh
DEPRECATION WARNING: ActionController::TestCase HTTP request methods will accept only
keyword arguments in future Rails versions.
```

Or

```sh
DEPRECATION WARNING: `redirect_to :back` is deprecated and will be removed from Rails 5.1. Please use `redirect_back(fallback_location: fallback_location)` where `fallback_location` represents the location to use if the request has no HTTP referer information. (called from block in <class:RepoSubscriptionsControllerTest> at /Users/richardschneeman/Documents/projects/codetriage/test/functional/repo_subscriptions_controller_test.rb:63)
```

A good deprecation will include the fix in the message. While you technically don't __have__ to fix every deprecation, you'll be glad you did when Rails 5.1 is released, because that upgrade will be even easier.

## Regressions

As you rule out bugs coming from gems or your own code, you'll want to report any regressions to https://github.com/rails/rails/issues. Please check for existing issues first. Unfortunately the tracker is only for bugs and pull requests, we can't use it to help you with "my application won't work" type problems. Take those issues to [Stack Overflow](http://stackoverflow.com).

## Deploy and You're Done

Once your code works locally and your tests pass, make sure you're happy with manually looking for regressions. I recommend either deploying to a staging app first or using Heroku's [GitHub Review apps](https://devcenter.heroku.com/articles/github-integration#review-apps). -- That way you'll have a production-ish copy of your web app attached to your pull request that everyone involved can review. Once you're happy commit to git and then:

```sh
$ git push heroku master
```

Watch your logs or bug tracking add-on for exceptions, remember you can always [rollback](https://devcenter.heroku.com/articles/releases#rollback) if a critical problem comes up.

Upgrading takes time and patience but isn't that complex. The earlier you upgrade the earlier bugs get found, reported, and fixed. Give it a try on a branch and see what happens.

