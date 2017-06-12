---
title: "Writing a Rails Feature - Blow by Blow"
layout: post
published: true
date: 2016-11-21 21:57
permalink: /2016/11/21/writing-a-rails-feature-blow-by-blow/
categories:
    - ruby
---

My favorite part of seeing someone live code is all the mistakes they make, but not because I'm a mean awful person who likes to see others fail. Watching others recover from mistakes helps me recover from my mistakes. It also makes me feel better when I see they mess up the same ways that I do. Too often, programmers beat themselves up when they can't remember an API and have to Google it, or they lose an hour to a simple spelling mistake. Everyone does these things.

I have another confession, which is that I love taking notes while programming. It's been a game changer for when I'm working on systems too large to fit inside of my head, which these days is pretty much all the time. (maybe my head is getting smaller).

I've mentioned this before at several conferences, and one of the tricks I use to make sure my notes are thorough is to pretend I'm preparing to write a blog post. I usually take it one step further and actually use my notes to generate a blog post. While this helps me do feature work, and hopefully is helpful in some of the writing I publish, you're getting a polished and refined version of my notes.

I had an idea for a new feature in Rails that I wanted to build recently but it was such a large change that I couldn't make myself work on it. I would start, get demoralized and quit constantly, so I decided to try something new. I took notes, yes, but I also noted all my mistakes as well. The result is a play-by-play of me implementing a non-trivial feature in Rails. You'll see me make progress, make mistakes, reflect on my process as I go, and read the whole thing pretty much as it unfolded.

## Problem Statement

Before we get started, here's some context. I maintain Sprockets after the original maintainer left. One of my major goals with the project is to make debugging problems much easier. I love good error messages when you made an obvious mistake and the library catches it and gently corrects your behavior. Prior to my patch, Sprockets wasn't allowed to raise errors like this because the Rails asset pipeline expected that when an asset is not found, the original string gets returned. For example, a valid asset lookup might return

```ruby
asset_path("application.css")
#=> "assets/application-ai189cm58bvmadosifu913248.css"
```

While an invalid asset will return the original string

```ruby
asset_path("ap1ic4ti0n.czz")
#=> "ap1ic4ti0n.czz"
```

This behavior may seem strange, however in the original days when the pipeline was introduced, everyone put their assets in the `public/` folder, as to allow people to use "the asset pipeline" with these files, and the fallback was allowed.

I want to add errors to Sprockets, but before I can do that I need to know 100% for sure that the user expected an asset from the pipeline before I can raise an error, that means I need to make the API in Rails explicit. My original idea was to have `asset_path` be for asset pipeline and `public_asset_path` for things you didn't expect Sprockets to find. It might look like an easy change on the surface, but it wasn't.

I eventually implemented and shipped a feature pretty similar to what I wanted so that in the future, Sprockets will give you a better experience. Keep reading and follow me on the journey of implementing a fairly invasive Rails feature.

## In the Beginning

> I went back and added some narrative, so you wouldn't be totally confused, the code examples and most of the commentary are actually part of my original notes.

How does Sprocket hook into Rails to form the asset pipeline? Your Rails app will use something like `asset_path('smile.png')` in a view. This is implemented by `action_view/helpers/asset_url_helper.rb` which has this magical line:

```ruby
if source[0] != ?/
  source = compute_asset_path(source, options)
end
```

If you don't have `Sprockets-Rails` in your app then the public path will be used:

```ruby
def compute_asset_path(source, options = {})
  dir = ASSET_PUBLIC_DIRECTORIES[options[:type]] || ""
  File.join(dir, source)
end
```

But if you do have `Sprockets-Rails` that method gets over-written:

```ruby
def compute_asset_path(path, options = {})
  debug = options[:debug]

  if asset_path = resolve_asset_path(path, debug)
    File.join(assets_prefix || "/", legacy_debug_path(asset_path, debug))
  else
    super
  end
end
```

Sprockets-rails will be used to see if the asset exists as part of the pipeline if it doesn't exist it falls back to the original `compute_asset_path` method from Action View.

> Keep in mind as you read, that the majority of these statements and assertions are things I'm having to look up and discover via debugging. I didn't roll out of bed with this info.

This is the secret sauce because every `*_path` call from `javscript_path` to `image_path` all call out to `asset_path`. Likewise, their counterparts the `*_url` methods also use the `asset_path` helper to compute their output. So everything hits `asset_path` and `asset_path` hits `compute_asset_path` inside of `Sprockets-Rails`.

There is some more magic for debugging purposes but that's the general gist.

What we need to do is to introduce a public API that purposely bypasses Sprockets for non-asset-pipeline public files.

> I like to list out goals in my notes to remind myself of my intentions. It helps me pick up where I left off.

Here are public `*_path` helpers:

- compute_asset_path
- resolve_asset_path
- legacy_debug_path
- asset_digest_path
- asset_path
- image_path
- video_path
- audio_path
- font_path
- javascript_path
- stylesheet_path

> Keeping track of work to be done, in this case, methods that need a `public_*` counterpart helps me retain focus.

Before we can change any APIs we need to implement deprecations and warnings. Of these methods, here are the ones we want warning on:

- asset_path
- image_path
- video_path
- audio_path
- font_path
- javascript_path
- stylesheet_path

So now the question is what exactly does `asset_path` do?

- It checks for `nil`, which is nice.
- It calls `to_s` on any source passed in.
- It returns an empty string `""` if the source was blank
- It returns the string if the source matches `URI_REGEXP`, which means that you're giving a full URI i.e. if you pass in `https://foo.com/whatever`. This is needed so that we can mix in controlled and remote assets in things like `javascript_path` which doesn't require managed assets.
- It then pulls out any query params such as `?utm_tracking=foo` and preserves them as a "tail"

> If you find yourself taking notes on what a method does consider going back and making a documentation PR to make all that behavior more obvious to future developers.

After that it gets into conditional logic. We pass the source into this method:

```ruby
def compute_asset_extname(source, options = {})
  return if options[:extname] == false
  extname = options[:extname] || ASSET_EXTENSIONS[options[:type]]
  extname if extname && File.extname(source) != extname
end
```

I don't know what this does despite method docs, I'm going to blame to see when it was added and see if I can find more context. It was added in 2012 as part of ["Refactor AssetUrlHelper"](https://github.com/rails/rails/pull/7927). Based off of [this earlier commit](https://github.com/rails/rails/commit/1e2b0ce95e48463361111ceae6eed7d4ad5462f0#diff-b49818a9ab54bba8552381385a23f17bR130) it looks like it allows you to do something like call `javascript_path("application")` and there is an API where `.js` can be auto added.

> P.S. if you're blame diving get the [blame parent](https://chrome.google.com/webstore/detail/github-blame-parent/kafcedgenijobphganhaeiignhlipdij) chrome extension. It allows you to press and hold "ALT" when viewing a blame view on GitHub. When you do that you get a little `^` next to the commit SHA that allows you to go to the parent of that commit SHA. Basically the same as going to that commit and seeing what the previous was before that one.

Then we check to see if the source passed in starts with a slash `/`. If so, we skip the asset pipeline and assume it's a fully qualified path and this is surprising behavior to me:

```ruby
if source[0] != ?/
  source = compute_asset_path(source, options)
end
```

Then there is code supporting "relative_url_root" we can see it here:

```ruby
relative_url_root = defined?(config.relative_url_root) && config.relative_url_root
if relative_url_root
  source = File.join(relative_url_root, source) unless source.starts_with?("#{relative_url_root}/")
end
```

What does it do? A quick grep gives us the docs for `relative_url_root`:

* `config.action_controller.relative_url_root` can be used to tell Rails that you are [deploying to a subdirectory](configuring.html#deploy-to-a-subdirectory-relative-url-root). The default is `ENV['RAILS_RELATIVE_URL_ROOT']`.

So basically this lets us tack on a few folders to the front of our assets if the Rails app isn't in the same directory as the process was booted.

Finally, we add a host if one is declared:

```ruby
if host = compute_asset_host(source, options)
  source = File.join(host, source)
end
```

You might want to do this if you're using a CDN for example. Since both `*_path` and `*_url` helpers go through `asset_path` there are options in here for optionally telling the method that you, in fact, want a full on URL to come out of the helper.

The very last thing is that anything in the params i.e. "tail" such as `?utm_source=foo` will be added to the end.

## Now what

We've got a single entry point where Rails interfaces with Sprockets to make the asset pipeline. We need an entry point to public URLs that isn't over-written by Sprockets-Rails. My first idea there is to alias `compute_asset_path` to make callable even when Sprockets-Rails writes over it.

We are going to use an alias to preserve the original method:

```ruby
alias :public_compute_asset_path :compute_asset_path
```

> If you're not familiar this is creating a new method `public_compute_asset_path` that is essentially a copy of the original `compute_asset_path` method. This means that even if the `compute_asset_path` method is modified, or over-written, our `public_compute_asset_path` will still implement the original behavior.

Now since everything goes through `asset_path` we can add logic there to explicitly call this method. Maybe the option is `:public_folder` and we can add logic to `asset_path`

```ruby
if options[:public_folder]
  source = public_compute_asset_path(source, options)
else
  source = compute_asset_path(source, options) if source[0] != ?/
end
```

Now that we have a way to explicitly call the `public_compute_asset_path` method, we need to expose a bunch of new helpers.

- public_asset_path
- public_image_path
- public_video_path
- public_audio_path
- public_font_path
- public_javascript_path
- public_stylesheet_path

For example:

```ruby
def public_asset_path(source, options = {})
  asset_path(source, options.merge(public_folder: true))
end
```

Since we're using Rails 5.1 we can use named arguments (the minimum required Ruby version is 2.2) to make the method signatures a bit clearer.

```ruby
def asset_path(source, public_folder: false, **options)
```

And then in our new method:

```ruby
def public_asset_path(source, options = {})
  asset_path(source, public_folder: true, **options)
end
```

Now we can repeat for all our other assets.

Hold up. That named asset change looks heavy handed so let's work with what we've got now and maybe come back and add it in later. We can change all the method signatures at the same time to make things easier afterward.

I reverted the method signature back to something like:

```ruby
def public_stylesheet_path(source, options = {})
  path_to_stylesheet(source, {public_folder: true}.merge!(options))
end
```

Some subtle things here, we're preferring the internal name `path_to_stylesheet` over `stylesheet_path` which someone might be using if they've defined a `stylesheet` route. Also for performance we have to allocate a hash to merge with options, if we used regular `merge` then we would allocate 2 hashes, by merging the first allocated hash in place we can save an allocation. This is only possible because the hash `{public_folder: true}` is not passed into the method which means that there are no other parts of the program that have a reference to it and would expect it to not be mutated.

I'm going to skip over the `*_url` methods for now, that's just busy work. We implement them just like the `*_path` helpers.

The question we have now is how can we detect when Sprockets has fallen through and couldn't find an asset? Two options come to mind. The first would be to check to see if the `public_compute_asset_path` matches `compute_asset_path` and deprecate. However, this poses some problems. It's a performance concern since we're now doing up to twice the work. There's also the case where Sprockets isn't being used and the path will always match since the method is being over-written by Sprockets-Rails. That's not a great option.

The second option I can think of is for `Sprockets-Rails` to raise an error when it cannot find an asset. This is eventually what we want to happen, however, we can't simply start raising errors on code that worked last week. We need to go through a deprecation cycle instead. We could catch the error and instead issue a deprecation. This causes some performance issues as well and exceptions in Ruby are really expensive (i.e. raising and catching exceptions is slow). There are other ways to communicate such as `catch/throw` but that would require Action View to know too much about Sprockets-Rails.

A third option could be to put the deprecation inside of sprockets-Rails. Something like:

```ruby
def compute_asset_path(path, options = {})
  debug = options[:debug]

  if asset_path = resolve_asset_path(path, debug)
    File.join(assets_prefix || "/", legacy_debug_path(asset_path, debug))
  else
    # Deprecate the code here, right here <====================================
    super
  end
end
```

However, this isn't a great spot for a user to deprecate. The `Sprockets-Rails` gem doesn't know what method you're using. Ideally, we want the deprecation to be something like:

```
DEPRECATION: You are using `stylesheet_path` with an asset not managed by the asset pipeline instead use `public_stylesheet_path`
  app/views/layouts/application.html.erb:23
```

If we deprecate from the the inside of that `compute_asset_path` in Sprockets-Rails we don't know what top level method exactly you're trying to use.

There's another option. We can port all the logic of `public_*_path` to `Sprockets-Rails`. We can also have our own custom `asset_path` provided by `Sprockets-Rails`.

Ughhh, this is hard. Right now I'm stuck. We are still stuck with the same problem - that the place where the logic is implemented isn't where the deprecation needs to be. We can do fancy metaprogramming (ish) to grab the `caller` object, walk back up the stack to see what method was being called before, but that would fail if someone is writing their own library to call these methods and adding another layer, which I guess isn't a bad thing.

Stop.

Right now is a good place to stop. We have a big question, we have lots of options and there's no clear winner. Shower, walk, do errands, go work on something else. Come back in a bit. Think about the problem when the mood strikes, but don't force it. Let your unconscious mind work the problem. If you go for a month without ever thinking of this problem again maybe it's not a problem worth solving, or maybe you don't like programming. Maybe you had a really busy month. Who knows. Anyway, BBIAB.

> This whole process happened over the course of weeks. What takes minutes to read might take hours to implement.

Okay, I'm back. What now? Well, I'm going to re-read what I wrote before I left. Haven't had any brilliant epiphanies yet, let's hope that changes. I'm going to look into being clever and using the caller inside of `asset_path`, however,, I'm going to do this within Sprockets-Rails.

> When stuck with multiple options and no clear winner, pick one and start working on it. Even if it's the wrong way to go, working on the problem gives you more context to pick the right solution.

I spent a bunch of time playing with code, no real direction - about 30 minutes to an hour. Mostly trying to re-remember throw/catch syntax and then debugging my mistakes. Forgot to write anything in my notes.

This is the solution I came up with, it's relatively elegant but know that it wasn't the first thing that came out of my fingers. In Sprockets-Rails,, we over-write `asset_path` then inside of the `compute_asset_path` which is called by `asset_path` we "throw" when we there is an asset miss.

Here is the code I came up with:

```ruby
def compute_asset_path(path, options = {})
  debug = options[:debug]

  if asset_path = resolve_asset_path(path, debug)
    File.join(assets_prefix || "/", legacy_debug_path(asset_path, debug))
  else
    result = super
    if respond_to?(:public_asset_path)
      throw(:asset_not_found, result) # <===== Note the throw
    else
      result
    end
  end
end

def asset_path(*args)
  catch_asset_not_found = catch(:asset_not_found) do
    return super(*args)
  end
  # ... # <======== Here we can implement deprecation
end
```

Now if the asset is found, the behavior is exactly the same, however if code ever get's past the `catch` block it means that the asset wasn't found and that a `public_asset_path` exists which means we can safely assume that you're running on a version of Rails that supports this behavior. Keep in mind that `Sprockets-Rails` has to run on multiple versions of Rails and Sprockets at a time.

The full `asset_path` method looks like this:

```ruby
def asset_path(*args)
  catch_asset_not_found = catch(:asset_not_found) do
    return super(*args)
  end

  result = catch_asset_not_found
  deprecate_invalid_asset_lookup(result, caller)
  result
end
```

I wanted to move the deprecation code to its own method since it's pretty gnarly. It looks like this:

```ruby
private

  def deprecate_invalid_asset_lookup(name, call_stack)
    message =  "The asset #{ name.inspect } you are looking for is not present in the asset pipeline.\n"
    message << "The public fallback behavior is being deprecated and will be removed.\n"

    method_name = call_stack.first.split("in ".freeze).last.gsub(/`|'/, ''.freeze)

    if method_name.end_with?("_path".freeze) || method_name.end_with?("_url".freeze)
      message << "please use the `public_*` helper instead. For example `#{ "public_#{ method_name }" }`.\n"
      call_stack.shift
    else
      message << "please use the `public_*` helper instead for example `public_asset_path`.\n"
    end
    ActiveSupport::Deprecation.warn(message, call_stack)
  end
```

I'm being a bit "clever" (not normally a good thing) here. I'm using the caller to determine the last method that was called. If it ends in `_path` or `_url` then it's safe to assume that you're using something like `stylesheet_path` and that's the method you care about, if it's not then you're probably using `asset_path`. We can refine this over time, maybe check to see if there is a valid `public_*` method that the object responds to.

Issuing this deprecation isn't fast, however, neither is the asset pipeline lookup. If we can get the user to use `public_stylesheet_path` instead of `stylesheet_path` then they'll avoid the deprecation and also get faster code, it's a win-win.

The final message looks like this:

```
$ rails c
Loading development environment (Rails 5.1.0.alpha)
irb(main):001:0> helper.public_audio_path("blah")

DEPRECATION WARNING: The asset "/audios/blah" you are looking for is not present in the asset pipeline.
The public fallback behavior is being deprecated and will be removed.
please use the `public_*` helper instead. For example `public_audio_path`.
 (called from irb_binding at (irb):1)
```

There is one piece I want to deprecate inside of `asset_path` directly. We already had bypass code when your path starts with a slash `/`. This is not intuitive. I want to remove this so that you must be explicit about either using a `public_` helper if you don't want any warnings or errors.

```ruby
source = compute_asset_path(source, options) if source[0] != ?/
```

I'm going to change this to:

```ruby
if source[0] != ?/
  source = compute_asset_path(source, options)
else
  message =  "Skipping computing asset path since asset #{ source.inspect } starts with a slash `/`.\n"
  message << "This behavior is deprecated and will be removed. Instead explicitly declare that\n"
  message << "Use a `public_*` helper instead."
  ActiveSupport::Deprecation.warn(message)
end
```

Here, I'm not doing that fancy method guessing via the caller, I'm hoping that valid use cases of starting an asset with a slash are minimal or likely accidental. Hopefully, the owner of the code will be able to figure out where they are calling the asset based on the full source name since they can grep their project to find it. Technically the `public_compute_asset_path` isn't exactly the same as not adding the source, i.e. if there is a type specified when passing to `public_compute_asset_path` then we'll auto add a directory.

The behavior actually makes a bit more sense now. I think that is so you can do something like:

```ruby
stylesheet_path("application", "/path/directly/to/stylesheet")
```

Otherwise you'll get `/stylesheets` prepended to the source you pass in. For this I think it's fine since they're going against convention of where to place those external stylesheets to make them break that up into two separate calls. However we will need a bypass mechanism. I'm thinking we allow a key called `:raw` which does not do the transformation. So you could do something like:

```ruby
stylesheet_path("application")
public_stylesheet_path("path/directly/to/stylesheet", raw: true)
```

With that in mind, we need to implement this behavior if we're going to deprecate.

```ruby
if source[0] != ?/
  source = compute_asset_path(source, options)
elsif !options[:raw]
  message =  "Skipping computing asset path since asset #{ source.inspect } starts with a slash `/`.\n"
  message << "This behavior is deprecated and will be removed. Instead explicitly declare that\n"
  message << "Use a `public_*` helper instead. Optionally pass in `raw: true` to get the exact same behavior."
  ActiveSupport::Deprecation.warn(message)
end
```

Granted, somewhere else in Rails might be relying on this behavior so I'm not 100% confident we can deprecate and change it. But it's worth looking into. We always need a way to avoid the deprecation notice, and when the previous use case is valid, we need to provide a 100% compatible replacement.

As a side note, I would probably like error checking when calling `public_` methods so that we error out when you're referencing a file that doesn't exist on disk. We have to be careful about performance though. I would likely only want to do it in development and make it easy to turn off. Could perhaps use something like the evented file watcher and store all public contents in memory. Just some thoughts.

At the end of the day, our goal is a better development experience and the only way to get that is with requiring more explicit behavior from the user so we can raise helpful error messages.

The other piece of the puzzle is I'm not sure how to best add errors into Sprockets. We can't simply start raising errors inside of Sprockets when an asset isn't found. That would break lots of stuff. While `Sprockets-Rails` is linked to a version of Sprockets, there's nothing to stop someone from using Sprockets-Rails 3.0.4 with Sprockets version 9000

```ruby
s.add_dependency "sprockets", ">= 3.0.0"
```

We'll need to move both of those pieces in lock step when we do add errors to Sprockets. We likely want to put a maximum version on the dependencies of `Sprockets-Rails` so that when we add errors (likely in Sprockets 5) then we can make sure a version of `Sprockets-Rails` exists that understands the errors. Otherwise, bad things will happen.

Up to this point, I've not put anything in GIT. This is really bad. I usually at least make a `WIP` commit at the end of a working session but I previously forgot. I tend to not commit a ton because I refactor as I go and would have a bunch of bad commit points with errors and `'bugfix'` commits which I don't love. To each their own. I'm making my "initial" commit.

We typically ask contributors to put things in only one commit for PRs as it makes blaming and reverting easier. I've got commit access so socially the rules are a little more lax. It makes sense to break out a large PR like this into several commits in case a direction I was intending to go didn't work out and it makes it easier for me to roll back. We can always rebase later if we need to.

With the initial proof of concept done we need to flesh out the PRs. We need to add `*_url` methods like we did with paths. We also need to alias all the methods so they're not accidentally over-written by someone who adds a `pulic_audio` route to their routes.rb. After that, I want to look into changing method signatures, writing tests and adding docs. With feature work, I typically don't know what the outcome will look like until I'm done so I wait to write a regression test. With bug work, I sometimes try to write a test first. Sometimes finding the right place to write a test and writing a good test takes longer than the actual code. I always write a test, however very little of what I do is considered "TDD". [I wrote a piece on this a while back](https://www.schneems.com/2014/05/08/design-driven-tests.html).

> Protip: If you can't find a good place to add a test, break something else in the same file you're working in (comment out a random line or add a `raise` somewhere) and run your test suite. The test files that show the most failures and exceptions are a good place to look.

In the process of adding url helpers:

```ruby
def public_font_url(source, options = {})
  url_to_font(source, {public_folder: true}.merge!(options))
end
alias_method :path_to_public_font, :public_font_path # aliased to avoid conflicts with an font_path named route
```

I found that my hack for deciphering the best deprecation message wasn't valid since it assumed that the correct caller was only 1 back in the stack. In the case of `_url` helpers we call `asset_url` which then calls `asset_path` which means our correct method is 2 back on the stack. To account for this I split out the method extraction logic into it's own method and updated the deprecation builder to also check to see if `self` responds to the public_ url:

```ruby
private
  def extract_method_from_call_frame(frame)
    frame.split("in ".freeze).last.gsub(/`|'/, ''.freeze)
  end

  def deprecate_invalid_asset_lookup(name, call_stack)
    message =  "The asset #{ name.inspect } you are looking for is not present in the asset pipeline.\n"
    message << "The public fallback behavior is being deprecated and will be removed.\n"

    path_method_name = extract_method_from_call_frame(call_stack[0])
    url_method_name  = extract_method_from_call_frame(call_stack[1])
    if url_method_name.end_with?("_url".freeze) && respond_to?("public_#{ url_method_name }")
      message << "please use the `public_*` helper instead. For example `#{ "public_#{ url_method_name }" }`.\n"
      call_stack.shift
      call_stack.shift
    elsif path_method_name.end_with?("_path".freeze) && respond_to?("public_#{ path_method_name }")
      message << "please use the `public_*` helper instead. For example `#{ "public_#{ path_method_name }" }`.\n"
      call_stack.shift
    else
      message << "please use the `public_*` helper instead for example `public_asset_path`.\n"
    end
    ActiveSupport::Deprecation.warn(message, call_stack)
  end
```

Which gives us the correct deprecations:

```
irb(main):003:0* helper.font_url("balksdjf")
DEPRECATION WARNING: The asset "/fonts/balksdjf" you are looking for is not present in the asset pipeline.
The public fallback behavior is being deprecated and will be removed.
please use the `public_*` helper instead. For example `public_font_url`.
 (called from irb_binding at (irb):3)
=> "/fonts/balksdjf"
irb(main):004:0> helper.font_path("balksdjf")
DEPRECATION WARNING: The asset "/fonts/balksdjf" you are looking for is not present in the asset pipeline.
The public fallback behavior is being deprecated and will be removed.
please use the `public_*` helper instead. For example `public_font_path`.
```

Turns out that it's easier to copy-paste the same method + docs and edit all the things at once using CMD+d with my editor. I use Sublime Text.

I was asking questions about where to test things in Rails Contributors Basecamp chat, it looks like railties might have some integration tests for assets. I prefer integration tests whenever possible as they're closer to how a user would use our code.

Also, the case of things like `image_tag` was brought up. Do we want to go through __all__ the tags and make a `public_image_tag` etc? That's a lot of helpers. Ideally, we want to be very explicit about when we expect the asset pipeline and when we don't. There may need to be some middle ground about when we want fallback behavior in the `asset_path` but I still think this is bad. I'm going to think on it for a bit and keep working down the current implementation.

I found `asset_debugging_test.rb` in railties. See, the asset pipeline works by over-writing asset behavior. By default, without `Sprockets-Rails` any `public_*` method will be identical to its' non `public_*` counterpart. So we need to test in an environment where the over-writes are in play. This test boots a test rails app that uses the asset pipeline and hits an endpoint. Going to loop through all our helpers and assert we're getting a good match.

```ruby
test "public paths" do
  contents = "doesnotexist"
  cases = {
    public_image_path: %r{/images/#{ contents }},
    public_asset_path: %r{/#{ contents }},
  }

  cases.each do |(view_method, tag_match)|
    app_file "app/views/posts/index.html.erb", "<%= #{ view_method } '#{contents}' %>"

    app "development"

    class ::PostsController < ActionController::Base ; end

    get '/posts?debug_assets=true'

    body = last_response.body
    assert_match(tag_match, body, "Expected `#{view_method}` to produce a match to #{ tag_match }, but did not: #{ body }")
  end
end
```

Good thing I added tests, I accidentally used `options` instead of `options = {}` in a few places.

Normally I like to test for positive and negative cases. I.e. make sure that the behavior is different between `public_asset_path` and `asset_path`. We can do this pretty easily by adding another test case:

```ruby
test "public path methods do not use the asset pipeline" do
  cases = {
    asset_path:        /\/assets\/application-.*.\.js/,
    public_asset_path: /application.js/
  }

  cases.each do |(view_method, tag_match)|
    app_file "app/views/posts/index.html.erb", "<%= #{ view_method } 'application.js' %>"

    app "development"

    class ::PostsController < ActionController::Base ; end

    get '/posts?debug_assets=true'

    body = last_response.body.strip
    assert_match(tag_match, body, "Expected `#{view_method}` to produce a match to #{ tag_match }, but did not: #{ body }")
  end
end
```

Ideally,, we would also test the deprecation notice, but that's coming from `Sprockets-Rails` so we'll have to work on that separately.

That's it for today I think. This is a pretty good stopping point. I want to think about the `image_tag` problem a bit, so I'll go work on something else. If you're curious it's 2:07pm right now. I started at around 9am. BBIAB.

## 2 months later

Has it really been about 2 months since I last worked on this? Other stuff came up, this wasn't a priority. It honestly still isn't a priority, but I'm stuck on some other even harder project and want to get this shipped in Rails 5.1 if possible.

What now? Good thing I wrote all those notes, because I have no idea where I left off. I wish I came back to this earlier, 2 months is too much. I forgot to meditate on the problem at hand, but hopefully, I've got something stashed at the back of my brain when I start looking at the problem again.

I previously wrote "I want to think about the `image_tag` problem a bit" so I'm going to start there. No clue, what I meant, going to run tests.

Looking at `asset_tag_helper.rb` here's all the methods:

- javascript_include_tag
- stylesheet_link_tag
- auto_discovery_link_tag
- favicon_link_tag
- image_tag
- video_tag
- audio_tag

Previously based on my notes, I was worried that changing __all__ the helpers would be too much work, this isn't so bad. I'm going to take a shot at modifying these few with `public_` alternatives.

> When stuck at a crossroads, pick a path. You can always backtrack when you have more information.

All these methods use a `tag` method. We can put our deprecation notice there. So it turns out that while I did put the the code in Rails in GIT, I didn't save any of my code from Sprockets-Rails. Ugh. Luckily I took very detailed notes that also included code examples.

Before I make those changes, I'm going to add public tag helpers.

The `image_tag` method uses `path_to_image` helper. We can modify it to pass a `public_folder` if present:

```ruby
def image_tag(source, options={})
  options = options.symbolize_keys
  check_for_image_tag_errors(options)
  path_to_image(source, .merge!(options))

  src = options[:src] = path_to_image(source, { public_folder: options.delete(:public_folder) })

  unless src =~ /^(?:cid|data):/ || src.blank?
    options[:alt] = options.fetch(:alt){ image_alt(src) }
  end

  options[:width], options[:height] = extract_dimensions(options.delete(:size)) if options[:size]
  tag("img", options)
end
```

Now we add a method:

```ruby
def public_image_tag(source, options={})
  image_tag(source,  { public_folder: true }
end
```

Not too bad. Let's test it. We can plug in another case to our existing test:

```
public_image_tag:        %r{<img src="/images/#{ contents }"},
```

This works. Moving on to the next item. `favicon_link_tag` we can use the same approach:

```ruby
def favicon_link_tag(source='favicon.ico', options={})
  tag('link', {
    :rel  => 'shortcut icon',
    :type => 'image/x-icon',
    :href => path_to_image(source, { public_folder: options.delete(:public_folder) })
  }.merge!(options.symbolize_keys))
end

def public_favicon_link_tag(source='favicon.ico', options={})
  favicon_link_tag(source, { public_folder: true }.merge!(options))
end
```
*******************STOPPED HERE**********************

Tests work. The `auto_discovery_link_tag` is meant to link to a URL and not an asset, so I don't think we need to do anything there. It uses `url_for` under the hood.

The `javascript_include_tag` and public_stylesheet_link_tag already pass options so our job is much simpler. We only need to list `public_folder` as a valid option.

```ruby
def javascript_include_tag(*sources)
  options = sources.extract_options!.stringify_keys
  path_options = options.extract!('protocol', 'extname', 'host', 'public_folder').symbolize_keys
```

That leaves us with `video` and `audio` tags. Both of these use the `multiple_sources_tag` helper.

```ruby
def audio_tag(*sources)
  multiple_sources_tag('audio', sources)
end

def public_audio_tag(*sources)
  options = sources.extract_options!
  audio_tag(*sources, { public_folder: true }.merge(options))
end
```

Then we add an options hash to `multiple_sources_tag` and pass them into the send it is using:

```ruby
options[:src] = send("path_to_#{type}", sources.first, options)
```

We do the same with `video_tag` now. Except there's a slight hitch.
Turns out that it does 2 things: not only does it convert the "video" you pass in it but it also converts the "poster" which is essentially the screenshot show before the video loads. So there can be 4 different cases:

- Video is in public, image is from pipeline
- Video is in public, image is in public
- Video is in pipeline, image is in pipeline
- Video is in pipeline, image is in public

> Seems a tad repetitive to list out all the cases, but so was working on this section of code. These notes were to keep me on track and make sure I handled all the edge cases.

Instead of going overboard with `public_video_tag` and `public_video_tag_with_public_poster_tag` I'm going to assume if you're using one static all of them are. This is a flexible assumption. As people use this they can chime in on what they want the API to be.

Okay, we've got all of our `*_tag` helpers working. Now I need to add docs.

After adding docs I realized that in a few places I added an options hash to a method that is using a splat, which may already contain an options hash. I have to extract and merge first.

Took about 15 minutes to fix syntax errors, rename a few variables, and fix other things. Oddly enough I had this in my code:

```ruby
path_to_image(source, )
```

And it didn't throw an error, apparently, that's valid Ruby code, who knew!?

Anyway, I think I'm pretty much done(ish) with the Rails code. I need to modify `Sprockets-Rails`. I want to push a PR to both projects at the same time. Now I get to roll back through this document and re-implement everything.

It turns out I did still have all my changes for Sprockets-Rails, but I never committed them, whoops. At least I didn't lose all that work. I made a branch in Sprockets--Rails `schneems/deprecate-fallback-behavior`

> I write the branch name in my notes so I can find it easier next time.

## The PR

I made two PRs:

- [rails/rails: Make public asset use explicit #26226](https://github.com/rails/rails/pull/26226)
- [rails/sprockets-rails: Deprecate asset fallback #375](https://github.com/rails/sprockets-rails/pull/375)

There is a famous quote from Mike Tyson: "Everyone has a plan until they get punched in the mouth". This is also true of pull requests and feature work. A PR isn't really a finished feature, it's more like a prototype, a concept of an implementation of a feature. While building a feature, we make many assumptions, and when we go through the review process we often see those assumptions come apart. This is a good thing. When we challenge our assumptions (in a healthy environment), we formulate stronger and better models of reality.

It was decided that we could do without all the `public_` helpers by exposing the `public_folder: true` API directly to the user. Now I'm going to add a commit that removes all the helpers. It seems like I did a bunch of unnecessary work but really adding all those helpers helped me in the API design. The `public_*` helpers only work if they're all aware of the `public_folder:` key, so it wasn't totally useless.

Hopefully, this means that all I need to do is delete the helpers and change the tests.

Also, I'm changing `multiple_sources_tag` to `multiple_sources_tag_builder` since that's what it's doing. It's a private method anyway. If I do that then I can detect where to show the deprecation backtrace easier in the sprockets-rails patch.

We later talked about using `asset_path` with an asset that starts with a slash. There is prior art there and your assets won't render if you're using it incorrectly anyway. I'm not a huge fan of NOT removing and deprecating that, but we could come back to it in another PR.

In the `sprockets-rails` patch we introduced a config option `config.assets.unknown_asset_fallback` that lets you decide if you want the asset pipeline to fall back or not. We also changed `public_folder` key to be `skip_pipeline`  to make it more descriptive.

I didn't take as many notes during the PR process, since much of it was reacting to comments. You can go back and read the comments. One thing to notice is that the PR messages don't have the original interface I proposed. When I change the top level API I often go back and update the PR message to match, in this case I did that but it's still not 100% perfect. Using this method I was able to make the deprecation notifications less "clever" by saying we can pass in the value and not having to mention the specific method name.

I was also able to get rid of the catch/throw logic and put the deprecation directly inside of `compute_asset_path`. I would say that I put about an equal amount of time into updating and re-working the PR as I did working on getting to a point where I could make a PR.

The other thing a major feature needs before it can ship is docs. We need method docs, and to update the Rails guides. It's hard taking notes while writing docs, as docs are a kind of generalized note taking.

## Finished

The PRs were accepted, and now we have a way to deprecate and raise when an asset isn't found as part of the pipeline. If you're not using any assets from the public directory you can go ahead and use the flag if you upgrade to the latest `sprockets-rails`:

```ruby
config.assets.unknown_asset_fallback = false
```

If you are using assets in the public folder and need the `skip_pipeline` flag, you'll need to wait for Rails 5.1 to come out.

## Don't give up

Some things that are interesting to me is that much of the original code examples I posted in these notes were not the ones that shipped with the PR. It reminds me of the famous Mark Twain quote "I didn't have time to write a short letter, so I wrote a long one instead.". As we gain clarity through the PR process and get feedback from our peers our code often gets better, clearer, and sometimes - shorter.

If you've never submitted a feature PR to a major open source project, don't let this dissuade you. They're not all this long or complicated. Think of this as the worst case scenario. Also remember that I did this work over weeks and months, so you can too. Breaking up a large PR into smaller manageable tasks and working on it when inspiration hits can help. Just don't forget to take notes so you can pick up where you left off. The more you do these, the easier they get.

If you wanted to make a change this large, if it all possible if you can make it as a gem first it's best so even if the core team doesn't immediately want your patch, others (including you) can still use it. On the flip side, if you're in the middle of a really gnarly patch and the back and forth with the maintainers seems to take forever, don't give up. It can be normal, even for someone who does this kind of work on a daily or weekly basis.

---
If you liked this consider [following @schneems on twitter](https://twitter.com/schneems) or signing up to get [new articles in your inbox](https://eepurl.com/bbuvuz) (about 1 email a week when I'm on a roll).
