---
layout: post
title: Speeding up Sprockets
subtitle:
date: 2016-02-22
published: true
author_name: Richard Schneeman
author_url: http://www.schneems.com
permalink: blogs/2016-02-18-speeding-up-sprockets
---

The asset pipeline is the slowest part of deploying a Rails app. How slow? On average, it's over 20x slower than installing dependencies via `$ bundle install`. Why so slow? In this article, we're going to take a look at some of the reasons the asset pipeline is slow and how we were able to get a 12x performance improvement on some apps with [Sprockets version 3.3+](https://rubygems.org/gems/sprockets/versions/3.5.2).

> Originally Posted: [Speeding up Sprockets on Heroku's Engineering Blog](https://engineering.heroku.com/blogs/2016-02-18-speeding-up-sprockets/)

The Rails asset pipeline uses the [sprockets](github.com/rails/sprockets) library to take your raw assets such as javascript or Sass files and pre-build minified, compressed assets that are ready to be served by a production web service. The process is inherently slow. For example, compiling Sass file to CSS requires reading the file in, which involves expensive hard disk reads. Then sprockets processes it, generating a unique "fingerprint" (or digest) for the file before it compresses the file by removing whitespace, or in the case of javascript, running a minifier. All of which is fairly CPU-intensive. Assets can import other assets, so to compile one asset, for example, an `app/assets/javascripts/application.js` multiple files may have to be read and stored in memory. In short, sprockets consumes all three of your most valuable resources: memory, disk IO, and CPU.

Since asset compilation is expensive, the best way to get faster is not to compile. Or at least, not to compile the same assets twice. To do this effectively, we have to store metadata that sprockets needs to build an asset so we can determine which assets have changed and need to be re-compiled. Sprockets provides a cache system on disk at `tmp/cache/assets`. If the path and mtime haven't changed for an asset then we can load the entire asset from disk. To accomplish this task, sprockets uses the cache to store a compiled file's digest.

This code looks something like:

```ruby
# https://github.com/rails/sprockets/blob/543a5a27190c26de8f3a1b03e18aed8da0367c63/lib/sprockets/base.rb#L46-L57

def file_digest(path)
  if stat = File.stat(path)
    cache.fetch("file_digest:#{path}:#{stat.mtime.to_i}") do
      Digest::SHA256.file(path.to_s).digest
    end
  end
end
```

Now that we have a file's digest, we can use this information to load the asset. Can you spot the problem with the code above?

If you can't, I don't blame you&mdash;the variables are misleading. `path` should have been renamed `absolute_path` as that's what's passed into this method. So if you precompile your project from different directories, you'll end up with different cache keys. Depending on the root directory where it was compiled, the same file could generate a cache key of:
`"file_digest:/Users/schneems/my_project/app/assets/javascripts/application.js:123456"`
or:
`"file_digest:/+Other/path/+my_project/app/assets/javascripts/application.js:123456"`.

There are quite a few Ruby systems deployed using Capistrano, where it's common to upload different versions to new directories and setup symlinks so that if you need to rollback a bad deploy you only have to update symlinks. When you try to re-use a cache directory using this deploy strategy, the cache keys end up being different every time. So even when you don't need to re-compile your assets, sprockets will go through the whole process only stopping at the very last step when it sees the file already exists:

```ruby
# https://github.com/rails/sprockets/blob/543a5a27190c26de8f3a1b03e18aed8da0367c63/lib/sprockets/manifest.rb#L182-L187

if File.exist?(target)
  logger.debug "Skipping #{target}, already exists"
else
  logger.info "Writing #{target}"
  asset.write_to target
end
```

Sprockets 3.x+ is not using anything in the cache, and as has been reported in [issue #59]( https://github.com/rails/sprockets/issues/59), unless you're in debug mode, you wouldn't know there's a problem, because nothing is logged to standard out.

It turns out it's not just an issue for people deploying via Capistrano. Every time you run a `$ git push heroku master` your build happens on a different temp path that is passed into the buildpack. So even though Heroku stores the cache between deploys, the keys aren't reused.

## The (almost) fix

The first fix was very straightforward. A [new helper class](https://github.com/rails/sprockets/pull/89) called `UnloadedAsset` takes care of generating cache keys and converting absolute paths to relative ones:

```
UnloadedAsset.new(path, self).file_digest_key(stat.mtime.to_i)
```

In our previous example we would get a cache key of `"file_digest:/app/assets/javascripts/application.js:123456"` regardless of which directory you're in. So we're done, right?

As it turns out, cache keys were only part of the problem. To understand why we must look at how sprockets is using our 'file_digest_key'.

## Pulling an asset from cache

Having an asset's digest isn't enough. We need to make sure none of its dependencies have changed. For example, to use the jQuery library inside another javascript file, we'd use the `//= require` directive like:

```js
//= require jquery
//= require ./foo.js

var magicNumber = 42;
```

If either `jquery` or `foo.js` change, then we must recompute our asset. This is a somewhat trivial example, but each required asset could require another asset. So if we wanted to find all dependencies, we would have to read our primary asset into memory to see what files it's requiring and then read in all of those other files; exactly what we're trying to avoid. So sprockets stores dependency information in the cache.

Using this cache key:

```ruby
"asset-uri-cache-dependencies:#{compressed_path}:#{ @env.file_digest(filename) }"
```

Sprockets will return a set of "dependencies."

```
#<Set: {"file-digest///Users/schneems/ruby/2.2.3/gems/jquery-rails-4.0.4", "file-digest///Users/schneems/app/assets/javascripts/foo.js"}>
```

To see if either of these has changed, Sprockets will pull their digests from the cache like we did with our first `application.js` asset. These are used to "resolve" an asset. If the resolved assets (and their dependencies) have been previously loaded and stored in the cache, then we can pull our asset from cache:

```ruby
# https://github.com/rails/sprockets/blob/9ca80fe00971d45ccfacb6414c73d5ffad96275f/lib/sprockets/loader.rb#L55-L58

digest = DigestUtils.digest(resolve_dependencies(paths))
if uri_from_cache = cache.get(unloaded.digest_key(digest), true)
  asset_from_cache(UnloadedAsset.new(uri_from_cache, self).asset_key)
end
```

But now, our dependencies contain the full path. To fix this, we have to "compress" any absolute paths, so that if they're relative to the root of our project we only store a relative path.

Of course, it's never that simple.

## Absolute paths everywhere

In the last section I mentioned that we would get a file digest by resolving an asset from `"file-digest///Users/schneems/app/assets/javascripts/foo.js". That turns out to be a pretty involved process. It involves a bunch of other data from the cache, which as you guessed, can have absolute file paths. The short list includes: Asset filenames, asset URIs, load paths, and included paths, all of which we handled in [Pull Request #101](https://github.com/rails/sprockets/pull/101). But wait, we're not finished, the list goes on: Stubbed paths, link paths, required paths (not the same as dependencies), and sass dependencies, all of which we handled in [Pull Request #109](https://github.com/rails/sprockets/pull/109), phew.

The final solution? A pattern of "compressing" URIs and absolute paths, before they were added to the cache and "expanding" them to full paths as they're taken out. [URITar](https://github.com/rails/sprockets/blob/9ca80fe00971d45ccfacb6414c73d5ffad96275f/lib/sprockets/uri_tar.rb) was introduced to handle this compression/expansion logic.

All of this is available in [Sprockets version 3.3+](https://rubygems.org/gems/sprockets/versions/3.3.3).

## Portability for all

When tested with an example app, we saw virtually no change to the initial compile time (around 38 seconds). The second compile? 3 seconds. Roughly a 1,200% speed increase when using compiled assets and deploying using Capistrano or Heroku. Not bad.

Parts of the `URITar` class were not written with multiple filesystems in mind, notably Windows, which was fixed in [Pull Request #125](https://github.com/rails/sprockets/pull/125/commits) and released in version 3.3.4. If you're going to write code that touches the filesystems of different operating systems, remember to use a portable interface.

## Into the future

Sprockets was originally authored by one prolific programmer, [Josh Peek](https://github.com/rails/sprockets/graphs/contributors). He's since stepped away from the project and has given maintainership to the Rails core team. Sprockets 4 is being worked on with support for source maps. If you're running a version of Sprockets 2.x you should try to upgrade to Sprockets 3.5+, as Sprockets 3 is intended to be an upgrade path to Sprockets 4. For help upgrading see the [upgrade docs in the 3.x branch](https://github.com/rails/sprockets/blob/3.x/UPGRADING.md).

Sprockets version 3.0 beta was released in September 2014; it took nearly a year for a bug report to come in alerting maintainers to the problem. In addition to upgrading Sprockets, I invite you to open up issues at [rails/sprockets](https://github.com/rails/sprockets) and let us know about bugs in the latest released version of Sprockets. Without bug reports and example apps to reproduce problems, we can't make the library better.

This performance patch was much more involved than I could have imagined when I got started, but I'm very pleased with the results. I'm excited to see how this affects overall performance numbers at Heroku&mdash;hopefully you'll be able to see some pretty good speed increases.

Thanks for reading, now go and upgrade your sprockets.

---
Schneems writes code for Heroku and likes working on open source performance patches. You can find him on his [personal site](http://www.schneems.com).
