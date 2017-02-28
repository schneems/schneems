---
title: "Bundler Changed Where Your Canonical Ruby Information Lives: What You Need to Know"
layout: post
published: true
date: 2017-02-28
permalink: /2017/02/28/bundler-changed-where-your-canonical-ruby-information-lives-what-you-need-to-know/
categories:
    - ruby
    - bundler
---

Heroku bumped its Bundler version to 1.13.7 almost a month ago, and since then we've had a large number of support tickets opened, many a variant of the following:

```
Your Ruby version is <X>, but your Gemfile specified <Y>
```

> This post originally published on [the Heroku blog](https://blog.heroku.com/bundler-and-canonical-ruby-version).

I wanted to talk about why you might get this error while deploying to Heroku, and what you can do about it, along with some bonus features provided by the new Bundler version.

First off, why are you getting this error? On Heroku in our [Ruby Version docs](https://devcenter.heroku.com/articles/ruby-versions), we mention that you have to use a Ruby directive in your `Gemfile` to specify a version of Ruby. For example if you wanted `2.3.3` then you would need this:

```
# Gemfile

ruby "2.3.3"
```

This is still the right way to specify a version, however recent versions of Bundler introduced a cool new feature. To understand why this bug happens you need to understand how the feature works.

## Ruby Version Specifiers

If you have people on your team who want to use a more recent version of Ruby, for example say Ruby 2.4.0 locally, but you don't want to force EVERYONE to use that version you can use a Ruby version specifier.

```
ruby "~> 2.3"
```

> Note: I don't recommend you do this since "2.3" isn't a technically valid version of Ruby. I recommend using full Ruby versions in the version specifier; so if you don't have a Ruby version in your Gemfile.lock `bundle platform --ruby` will still return a valid Ruby version.

> You can use multiple version declarations just like in a `gem` for example: `ruby '>= 2.3.3', '< 2.5'`.

This says that any version of Ruby up until 3.0 is valid. This feature came in Bundler 1.12 but wasn't made available on Heroku until Bundler 1.13.7. In addition to the ability to specify a Ruby version specifier, Bundler also introduced locking the actual Ruby version in the Gemfile.lock:

```
# Gemfile.lock

RUBY VERSION
   ruby 2.3.3p222
```

When you run the command

```
$ bundle platform --ruby
ruby 2.3.3p222
```

You'll get the value from your `Gemfile.lock` rather than the version specifier from your `Gemfile`. This is to provide you with development/production parity. To get that Ruby version in your Gemfile.lock you have to run `bundle install` with the same version of Ruby locally, which means when you deploy you'll be using a version of Ruby you use locally.

> Sidenote: Did you know this is actually how Heroku gets your Ruby version? We run the `bundle platform --ruby` command against your app.

So while the version specifier tells bundler what version ranges are "valid" the version in the Gemfile.lock is considered to be canonical.

## An Error By Any Other Name

So if you were using the app before with the specifier `ruby "~> 2.3"` and you try to run it with Ruby 1.9.3 you'll get an error:

```
Your Ruby version is 1.9.3, but your Gemfile specified ~> 2.3
```

This is the primary intent of the bundler feature, to prevent you from accidentally using a version of Ruby that may or may not be valid with the app. However if Heroku gets the Ruby version from `bundle platform --ruby` and that comes from the Gemfile and Gemfile.lock, how could you ever be running a version of Ruby on Heroku different from the version specified in your Gemfile?

One of the reasons we didn't support Bundler 1.12 was due to a [bug in that allowed incompatible Gemfile and Gemfile.lock Ruby versions](https://github.com/bundler/bundler/issues/4627). I reported the issue, and the bundler team did an amazing job patching it and releasing the fix in 1.13. What I didn't consider after is that people might still be using older bundler versions locally.

So what is happening is that people will update the Ruby version specified in their `Gemfile` without running `bundle install` so their `Gemfile.lock` does not get updated. Then they push to Heroku and it breaks. Or they're using an older version of Bundler and their `Gemfile.lock` is using an incompatible version of Ruby locally but isn't raising any errors. Then they push to Heroku and it breaks.

So if you're getting this error on Heroku run this command locally to make sure your Bundler is up to date:

```
$ gem install bundler
Successfully installed bundler-1.13.7
1 gem installed
Installing ri documentation for bundler-1.13.7...
Installing RDoc documentation for bundler-1.13.7...
```

Even if you haven't hit this bug yet, go ahead and make sure you're on a recent version of Bundler right now. Once you've done that run:

```
$ bundle install
```

If you've already got a Ruby version in your `Gemfile.lock` you'll need to run

```
$ bundle update --ruby
```

This will insert the same version of Ruby you are using locally into your `Gemfile.lock`.

If you get the exception locally `Your Ruby version is <X>, but your Gemfile specified <Y>` it means you either need to update your Gemfile to point at your version of Ruby, or update your locally installed version of Ruby to match your Gemfile.

Once you've got everything working, make sure you commit it to git

```
$ git add Gemfile.lock
$ git commit -m "Fix Ruby version"
```

Now you're ready to `git push heroku master` and things should work.

## When Things Go Wrong

When these type of unexpected problems creep up on customers we try to do as much as we can to make the process easier. After seeing a few tickets come in, the information was shared internally with our support department (they're great by the way). Recently I [added documentation to the devcenter](https://devcenter.heroku.com/articles/ruby-versions#your-ruby-version-is-x-but-your-gemfile-specified-y) to document this explicit problem. I've also added some checks in the [buildpack to give users a warning that points them to the docs](https://github.com/heroku/heroku-buildpack-ruby/pull/514). This is the best case scenario where not only can we document the problem, and the fix, but also add docs directly to the buildpack so you get it when you need it.

I also wanted to blog about it to help people wrap their minds around the fact that the `Gemfile` is no longer the canonical source of the exact Ruby version, but instead the `Gemfile.lock` is. While the `Gemfile` holds the Ruby version specifier that declares a range of ruby versions that are valid with your app, the `Gemfile.lock` holds the canonical Ruby version of your app.

As Ruby developers we have one of the best (if not the best) dependency managers in bundler. I'm excited for more people to start using version specifiers if the need arises for their app and I'm excited to support this feature on Heroku.

