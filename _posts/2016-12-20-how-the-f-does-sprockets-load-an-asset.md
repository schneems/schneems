---
title: "How the F does Sprockets Load an Asset?"
layout: post
published: true
date: 2016-12-20
permalink: /2016/12/20/how-the-f-does-sprockets-load-an-asset/
categories:
    - ruby
    - assets
    - asset pipeline
    - sprockets
---

How does an asset get compiled? It's less of a pipeline and more of a recursive ball of, well assets. To understand the process we will, start off with an asset with no directives (no `require` at the top). We'll then walk through all the steps Sprockets goes through until a usable asset is loaded into memory. For this example we will use a `js.erb` file to see how a "complex" file (i.e. multiple extensions) type gets compiled. All examples are with Sprockets 4 (i.e. master branch). Here's the file:

```
$ cat assets/users.js.erb
var Users = {
  find: function(id) {
    var t = '<%= Time.now %>';
  }
};
```

When we compile this asset we get:

```
var Users = {
  find: function(id) {
    var t = '2016-12-13 11:01:00 -0600';
  }
};
```

This is with the simplest of sprockets setup:

```ruby
@env = Sprockets::Environment.new
@env.append_path(fixture_path('asset'))
@env.cache = {}
```

What happens first? We call

```ruby
@env.find_asset("users.js")
```

This calls the `find_asset` method in `Sprockets::Base`. The contents are deceptively simple

```ruby
uri, _ = resolve(*args)
if uri
  load(uri)
end
```

The `resolve` method comes from `sprockets/resolve.rb` and the `load` method comes from `sprockets/load.rb`. Resolve will find where the asset is on disk and give us a "uri". We'll skip over exactly how resolve works, its task is relatively straightforward, find an asset on disk that satisfies the requirement of resolving to a `users.js` file. We can go into it in detail some other time.

A "uri" in sprockets looks like this:

```ruby
"file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript"
```

It has a schema with the type of thing it is (in this case a file). We can tell that it is an absolute path because after the schema `file://` it starts with a slash. The full path to this file is `/projects/sprockets/test/fixtures/asset/users.js.erb`. Then in the query params we carry extra info, in this case we are storing the mime type, which is `application/javascript`. While the file itself is a `.js.erb` the expected result of loading (compiling) this file is to be a `.js` file.

Internally Sprockets mostly doesn't care about file extensions, it really cares about mime types. It only uses file extensions to generate mime types. When you register any processors, you register via a mime type.

The body of the `load` method from `sprockets/loader.rb` is fairly complicated. It handles a few cases.

- Asset has an `:id` param, which is a fully digested hash, meaning that the asset is fully resolved and we can attempt to load it from the cache. This has two outcomes
  - Asset is in cache, use it
  - Asset is not in cache, delete the `:id` parameter and try to load normally.

- Asset does not have an :id param, we call `fetch_asset_from_dependency_cache` which returns a block. This method does a lot, it has method docs that are fairly comprehensive, go check them out for full details. Essentially it has two modes. Looking for an asset based on dependency history, or not.
  - Looking for asset based on history:
    - If all dependencies for an asset are in the cache, then we can generate an asset from the cache. Otherwise we move on.
  - Not found based on history:
    - We've proven at this point that the asset isn't in cache or one or more of it's dependencies aren't in the cache. At this point we have to load the entire asset.

We're going to assume a fresh cache for our example. That means that we hit the `fetch_asset_from_dependency_cache` method and fall back to the `"not found based on history" case so we have to load it.

## Loading an unloaded asset (pipeline = nil/:default)

The bulk of work happens in the method `load_from_unloaded`. We're going to start getting really technical and low level, so [follow along in the code for better comprehension what I'm talking about](https://github.com/rails/sprockets/blob/c9ab1b45d560a5527caba1e0815ef2e6953fce51/lib/sprockets/loader.rb#L100). We first generate a "load" and a "logicial" path:

```ruby
puts load_path.inspect
# => "/projects/sprockets/test/fixtures/asset"

puts logical_path.inspect
# => "users.js.erb"
```

There is an edge case that is handled next. In sprockets `foo/index.js` can be resolved to `foo.js`, it's a convention in some NPM libraries. That doesn't apply to this case. Next we generate an `extname` and a `file_type`

```ruby
puts extname.inspect
# => ".js.erb"

puts file_type.inspect
# => "application/javascript+ruby"
```

The `file_type` is the mime type for our `.js.erb` extension. Note the `+ruby` which designates that this is an erb file. I think this is a Sprockets convention. This mime type will be very important.

In this case the only `params` we have are `{:type=>"application/javascript"}` so we skip over the `pipeline` case.

We do have a `:type` so we'll run that part. The `logical_path` was trimmed down to remove the extension

```ruby
puts logical_path.chomp(extname)
# => "users"
```

Now we pull an extension based off of our mime type and add it to the logical path

```ruby
puts config[:mime_types][type][:extensions].first
# => ".js"
```

Putting these together our new logical path is:

```ruby
"users.js"
```

We'll use this later. This should match the original thing we looked for when we used `@env.find_asset`.

Next comes a sanity check. Either we're working with a mime type which we're requesting, or we're working with a mime type that can be converted to the one we're requesting. We check our `transformers` which is an internal concept to Sprockets, see [guides/extending_sprockets.md]() for more info on building a transformer. They essentially allow you to convert one file into another. Sprockets mostly cares about mime types so we check the transformers to see if it's possible to transfer the existing mime type into the desired mime type i.e. we want to convert `application/javascript+ruby` to `application/javascript`.

Next we grab the "processors" for our mime type. These can be `transformers` as mentioned earlier, or they can be processors such as `DirectiveProcessor` which is responsible for expanding directives such as `//= require foo.js` in the top of your file.

Into this `processors_for` method we also pass a "pipeline". For now it is `nil`, which means that the `:default` pipeline is used.

A pipeline is registered like a transformer or a processor. They're an internal concept. Here is what the default one looks like

```ruby
register_pipeline :default do |env, type, file_type|
  # TODO: Hack for to inject source map transformer
  if (type == "application/js-sourcemap+json" && file_type != "application/js-sourcemap+json") ||
      (type == "application/css-sourcemap+json" && file_type != "application/css-sourcemap+json")
    [SourceMapProcessor]
  else
    env.default_processors_for(type, file_type)
  end
end
```

Here if we're requesting a sourcemap we only want to run the `[SourceMapProcessor]` otherwise we find the "default" processors that are valid to our `type` (in this case `application/javascript`) from our `file_type` (in this case `application/javascript+ruby`). Default processors are defined here:

```ruby
def default_processors_for(type, file_type)
  bundled_processors = config[:bundle_processors][type]
  if bundled_processors.any?
    bundled_processors
  else
    self_processors_for(type, file_type)
  end
end
```

Either we return any "bundled" processors for the `type` or we return "self" processors. In our case there is a bundle processor registered `Sprockets::Bundle`. It was registered. In `sprockets.rb`:

```ruby
require 'sprockets/bundle'
register_bundle_processor 'application/javascript', Bundle
```

Now we're back to the `loader.rb` file. We have our `processors` array which is simply `[Sprockets::Bundle]`. We call `build_processors_uri`. This generates a string like:

```ruby
"processors:type=application/javascript&file_type=application/javascript+ruby"
```

This string gets added to the "dependencies". This array is used for determining cache keys, so if a processor gets added or removed the cache key will change (I think).

Now we have to call each of our processors. First we `resolve!` the original filename, but with a different pipeline i.e. `pipeline: :source`. The `resolve!` method raises an error if the file cannot be found.

After we resolve the file we get a `source_uri` that looks like this:

```ruby
"file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript+ruby&pipeline=source"
```

Now here's where things get complicated (I know right). We load the exact same file that is already being loaded with this new `pipeline=source`.

## Recursive asset loading is recursive (pipeline=source)

At this point we get recursive, we call repeat everything in `load_from_unloaded` but with `pipeline=source`. The results should be the same but with a different pipeline. The `:source` pipeline looks like this:

```ruby
register_pipeline :source do |env|
  []
end
```

In this case the `processors` returned is an empty array `[]`.

We skip over the processor section, and instead hit this:

```ruby
dependencies << build_file_digest_uri(unloaded.filename)
metadata = {
  digest: file_digest(unloaded.filename),
  length: self.stat(unloaded.filename).size,
  dependencies: dependencies
}
```

The file is digested to create a "digest" and the length is added via stat. Also "dependencies" are recorded which look like this:

```
#<Set: {"environment-version", "environment-paths", "processors:type=application/javascript+ruby&file_type=application/javascript+ruby&pipeline=source", "file-digest:///projects/sprockets/test/fixtures/asset/users.js.erb"}>
```

After this we build an asset hash:

```ruby
asset = {
  uri:          unloaded.uri,
  load_path:    load_path,
  filename:     unloaded.filename,
  name:         name,
  logical_path: logical_path,
  content_type: type,
  source:       source,
  metadata:     metadata,
  dependencies_digest:
                DigestUtils.digest(resolve_dependencies(metadata[:dependencies]))
}
```

Which is then used to generate a `Sprockets::Asset` and is returned by our `load` method.

## Jumping back up the stack (`pipeline=default`)

Now that we have a "source" asset we can go back and finish running the processors for `pipeline=default`

We did all that work, just to get a digest path:

```ruby
source_uri, _ = resolve!(unloaded.filename, pipeline: :source)
source_asset = load(source_uri)

source_path = source_asset.digest_path
# => "users.source.js-798a333a5596e1495e1cc4870f11c7729f168350ee5972637053f9691c8dc326.erb"
```

Which kinda seems insane, maybe we don't have to __need__ go all recursive to get this tiny piece of information, but whatevs. If there's one thing I've learned from working on Sprockets, is that the code resists refactoring and most of the seemingly "clever" code is actually a very clean way of accomplishing tasks. That is to say, I'm not going to change this without a lot more research.

Now we execute the `call_processors` pass in our array of processors `[Sprockets::Bundle]` and our asset hash:

```ruby
{
  environment:  self,
  cache:        self.cache,
  uri:          unloaded.uri,
  filename:     unloaded.filename,
  load_path:    load_path,
  source_path:  source_path,
  name:         name,
  content_type: type,
  metadata: {
    dependencies:
                dependencies
}
```

If we had more than one processor this would call each of them in reverse order and merge the results before calling the next. In this case there's only one processor. Guess it's time to figure out what that one does.

## Bundle processor (still on pipeline=default)

The bundle processor is defined in `sprockets/bundle.rb`. Open it up to follow along. We pull out dependencies from the hash. For now it is very simple:

```
#<Set: {"environment-version", "environment-paths", "processors:type=application/javascript&file_type=application/javascript+ruby"}>
```

The next thing we do is we resolve the file (yes, again) this time using `pipeline=self`

```ruby
processed_uri, deps = env.resolve(input[:filename], accept: type, pipeline: :self)

puts processed_uri.inspect
# => "file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self"

puts deps.inspect
# => #<Set: {"file-digest:///projects/sprockets/test/fixtures/asset/users.js.erb"}>
```

We merge this `deps` with the `dependencies` from earlier. The `file-digest://` that was returned from the `resolve` method indicates that there is a dependency on the contents of the file on disk, if the contents change, the digest should change.

You ready for some more recursion? You better hold onto your butts.

The next thing that happens is we build a proc

```ruby
find_required = proc { |uri| env.load(uri).metadata[:required] }
```

This proc takes in a uri and loads it, then returns a set of "required" files. Sprockets uses this proc to do a depth first search of our `processed_uri` (i.e. the pipeline=self uri). We can look at the dfs now:

```ruby
def dfs(initial)
  nodes, seen = Set.new, Set.new
  stack = Array(initial).reverse

  while node = stack.pop
    if seen.include?(node)
      nodes.add(node)
    else
      seen.add(node)
      stack.push(node)
      stack.concat(Array(yield node).reverse)
    end
  end

  nodes
end
```

The purpose of this search is that we want to make sure to only evaluate each file once and only once. Otherwise if we had an `a.js` that required a `b.js` that required a `c.js` that required `a.js` if we didn't keep track, then we would be stuck in an infinite loop. There is more involved in making sure infinite loops don't happen, but that's maybe for another post.

For the first iteration this creates an array with only our URI in it:

```ruby
puts stack.inspect
# => ["file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self"]
```

It then adds this uri to the "seen" set and puts it back on the stack. The next line is a little tricky

```ruby
stack.concat(Array(yield node).reverse)
```

Here the `node` is:

```ruby
"file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self"
```

So we call the block with that `node`, remembering our block is

```ruby
find_required = proc { |uri| env.load(uri).metadata[:required] }
```

So our DFS method invokes this block and passes it our `pipeline=self` uri, which invokes our `load` method again.

## Load recursion kicked off from within bundle (pipeline=self)

I feel like we can't get out of this `load` method, here we are again. This is what our `pipeline=self` looks like:

```ruby
register_pipeline :self do |env, type, file_type|
  env.self_processors_for(type, file_type)
end

This method `self_processors_for` is non-trivial:

```ruby
def self_processors_for(type, file_type)
  processors = []

  processors.concat config[:postprocessors][type]
  if type != file_type && processor = config[:transformers][file_type][type]
    processors << processor
  end
  processors.concat config[:preprocessors][file_type]

  if processors.any? || mime_type_charset_detecter(type)
    processors << FileReader
  end

  processors
end
```

First we grab any `postprocessors` that are registered for `application/javascript` mime type. There are no postprocessors registered by default, so I don't know why they exist, but you can register one using `register_postprocessor`.

Next up, we pull out a transformer for our file type. This returns us a `Sprockets::ProcessorUtils::CompositeProcessor`. This is a meta processor that contains possibly several transformers. It is generated via a call to `register_transformer`. In this case the full processor looks like this:

```
#<struct Sprockets::ProcessorUtils::CompositeProcessor
  # ...
  processors=
   [#<Sprockets::Preprocessors::DefaultSourceMap:0x007fb24d3271a0>,
    #<Sprockets::DirectiveProcessor:0x007fb24d356400
     @header_pattern=/\A(?:(?m:\s*)(?:(?:\/\/.*\n?)+|(?:\/\*(?m:.*?)\*\/)))+/>,
    Sprockets::ERBProcessor]>
```

It's doing some things with source maps and you can see now we have our `ERBProcessor` in there as well a `DirectiveProcessor`.

Next up, we gather any preprocessors, of which there are none. Finally, if there are any processors in our list we add a `FileReader` if we detect that it is not binary. Sprockets assumes a text file if the mime type has a `charset` defined. This is pretty standard.

So now we have our meta CompositeProcessor as well as our `FileReader` processor.

Now we call each of the processors in reverse order. First up is the `FileReader`.

```ruby
class FileReader
  def self.call(input)
    env = input[:environment]
    data = env.read_file(input[:filename], input[:content_type])
    dependencies = Set.new(input[:metadata][:dependencies])
    dependencies += [env.build_file_digest_uri(input[:filename])]
    { data: data, dependencies: dependencies }
  end
end
```

It takes in filename, reads that file from disk and adds to the `:data` key of the hash. It also adds a dependency of the file, in case there isn't already one:

```ruby
"file-digest:///projects/sprockets/test/fixtures/asset/users.js.erb"
```

After the file is done being read from disk, next up is the `CompositeProcessor`. This delegates to its other processors in reverse order so these get called

```
Sprockets::ERBProcessor
#<Sprockets::DirectiveProcessor:0x007f85b1322448 @header_pattern=/\A(?:(?m:\s*)(?:(?:\/\/.*\n?)+|(?:\/\*(?m:.*?)\*\/)))+/>
#<Sprockets::Preprocessors::DefaultSourceMap:0x007f85b12f33a0>
```

First up is the ERBProcessor, it takes the `input[:data]` which is the contents of the file and runs it through an ERB processor. There's a little magic in that file to detect if someone is using an ENV variable in their erb, in which case we auto add that as a dependency.

Next the DirectiveProcessor looks for any directives such as `//= require foo.js` of which there are none in this file. Finally we call `DefaultSourceMap`. This processor adds a 1-to-1 source map if one isn't already generated. If you're not familiar with source maps check out [guides/source_maps.md]() which has some of my notes.

Now all of our processors for `pipeline=self` have been run, the `load` call completes and now we go back to where we were in our Bundle processor for `pipeline=default`.

## Return to Bundle for (pipeline=default)

You may remember that we were in the middle of a depth first search.

```ruby
def dfs(initial)
  nodes, seen = Set.new, Set.new
  stack = Array(initial).reverse

  while node = stack.pop
    if seen.include?(node)
      nodes.add(node)
    else
      seen.add(node)
      stack.push(node)
      stack.concat(Array(yield node).reverse)
    end
  end

  nodes
end
```

ALL that last section happened during the `yield node` section of this code. The return was an array of dependencies, which are reversed and added onto the stack. In our case there are no "required" files for `file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self` so that yield call returns an empty set`.

The only node on the stack has already been "seen" so it is added to our `nodes` set. This was the last thing on the stack so we return that array. Our required list looks like this:

```
#<Set: {"file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self"}>
```

If we were using a required directive such as `//= require foo.js` then we would have more things in this set. Another concept that Sprockets has is a "stubbed" list. Gonna be totally honest, I have no idea why you would need it but it is there. From the method docs: "Allows dependency to be excluded from the asset bundle". So there you go. To get this list we call into load AGAIN

```ruby
stubbed  = Utils.dfs(env.load(processed_uri).metadata[:stubbed], &find_required)
```

Though there is one thing I never mentioned, not all calls to `load` are created equal:

## Cached Environment

Something I've failed to mention is that all calls to an `env` are not created equal. There is a `Sprockets::Environment` and a `Sprockets::CachedEnvironment`. The cached environment wraps the `Sprockets::Environment` and caches certain calls such as `load` so in the above example `env.load(processed_uri)` is returning a cached value and not actually calling into `load`, that's a relief.

It turns out that this whole time I was somewhat misleading you, we weren't using the version of `fine_asset` from `Sprockets::Base` but rather we were using `Sprockets::Environment`

```ruby
def find_asset(*args)
  cached.find_asset(*args)
end
```

This call to `cached` creates a `CachedEnvironment object:

```ruby
def cached
  CachedEnvironment.new(self)
end
```

Now any duplicate calls to `load` (with the EXACT same url) will return a cached copy. The rest of the implementation of `find_asset` is from the `Sprockets::Base`.

The first time we hit the cache in this example was with

```ruby
file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript+ruby&pipeline=source
```

It is first put in the cache at:

```
/projects/sprockets/lib/sprockets/loader.rb:149:in `load_from_unloaded'
```

> Note some of my line numbers might not match perfectly due to changes in source, also I'm adding in debug statements etc.

Or this line:

```ruby
source_uri, _ = resolve!(unloaded.filename, pipeline: :source)
source_asset = load(source_uri) # <========== THIS LINE ===========

source_path = source_asset.digest_path
```

When we pull it from cache we do so in the bundle processor:

```
/projects/sprockets/lib/sprockets/bundle.rb:35:in `block in call'
```

Which corresponds to this code:

```ruby
(required + stubbed).each do |uri|
  dependencies.merge(env.load(uri).metadata[:dependencies]) #< === Called from cache here
end
```

Which brings us back to the bundle processor we were looking at before:

## Finish the bundle processor (pipeline=default)

We loop through our required set (which is `#<Set: {"file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self"}>`) minus our stubbed set (which is empty).

For each of these we merge in dependencies. Our final dependencies set looks like this:

```
#<Set: {
  "environment-version",
  "environment-paths",
  "processors:type=application/javascript&file_type=application/javascript+ruby&pipeline=self",
  "file-digest:///projects/sprockets/test/fixtures/asset/users.js.erb"}>
```

We then look up "reducers" and get back a hash of keys and callable objects:

```ruby
{:data=>
  [
    #<Proc:0x007ffef7b74460@/Users/richardschneeman/Documents/projects/sprockets/lib/sprockets.rb:129>,
    #<Proc:0x007ffef7b74398 (lambda)>
  ],
:links=>
  [
    nil,
    #<Proc:0x007ffef7b74118(&:+)>
  ],
:sources=>
  [
    #<Proc:0x007ffef8027c50@/Users/richardschneeman/Documents/projects/sprockets/lib/sprockets.rb:131>,
    #<Proc:0x007ffef7b74118(&:+)>
  ],
:map=>
  [
    #<Proc:0x007ffef8027278@/Users/richardschneeman/Documents/projects/sprockets/lib/sprockets.rb:132>,
    #<Proc:0x007ffef8027070 (lambda)>
  ]
}
```

A reducer can be registered like so:

```ruby
register_bundle_metadata_reducer '*/*', :data, proc { String.new("") }, :concat
register_bundle_metadata_reducer 'application/javascript', :data, proc { String.new("") }, Utils.method(:concat_javascript_sources)
register_bundle_metadata_reducer '*/*', :links, :+
register_bundle_metadata_reducer '*/*', :sources, proc { [] }, :+
register_bundle_metadata_reducer '*/*', :map, proc { |input| { "version" => 3, "file" => PathUtils.split_subpath(input[:load_path], input[:filename]), "sections" => [] } }, SourceMapUtils.method(:concat_source_maps)
```

It acts on a key such as `:data` to transform or "reduce" individual keys.

If we had some "required" files do to the directive processor

```ruby
assets = required.map { |uri| env.load(uri) }
```

Then this last line is where they would be concatenated via our reducers:

```ruby
process_bundle_reducers(input, assets, reducers).merge(dependencies: dependencies, included: assets.map(&:uri))
```

In this case our only "required" asset is from `file:///projects/sprockets/test/fixtures/asset/users.js.erb?type=application/javascript&pipeline=self` which is important because you'll remember that the `pipeline=self` is when the `FileReader` and `ERBProcessor` were run.

Finally we can return from our original `pipeline=nil/:default` case since all of our pipelines have been executed. In our original call to `load`.

The rest of the code is just doing things like taking digests and building hashes, we've already covered it in a previous section.

Finally a `Sprockets::Asset` is generated and returned from our original `@env.find_asset` invocation.

Yay!

## 2020 Hindsite

There's a few confusing things going on here. It isn't always clear that calls to an `env` are going to `CachedEnvironment` and its even less clear if we're calling something that has already been cached or loading something new.

The pattern of loading files that Sprockets uses is a reactor. It stores state via `pipeline=<whatever>` and essentially loops with different pipeline variations until it gets its desired output. While this is very powerful, it's also really hard to wrap your brain around. Most of the code, especially in the Bundle processor are indecipherable if you don't know minute details about how things work inside of all of Sprockets. These two designs, the recursive-ish `load` reactor pattern and the `CachedEnvironment` are sometimes difficult to wrap your mind around. Especially this pattern of loading files creates a forking back trace, so if you're trying to debug it's not always immediately clear what's going on. Debug statements are usually output several times per each method call.

The other thing that makes Sprockets hard to understand is the plugin ecosystem. Sprockets is less a library and more a framework that uses itself to build an asset processing framework. Things like `transformers`, `preprocessors`, `compressors`, `bundle_processors`, etc. make it confusing exactly where work gets done. Some of the processors are highly coupled, such as the `Bundle` processor and the `DirectiveProcessor`. Again it's extremely powerful and makes the library very flexible but difficult to reason about.

Much of Sprockets resists refactoring. Many of the design decisions are very coupled to the implementation. I've spent hours trying to tease out `CachedEnvironment` into something else, but eventually gave up. One thing to consider if you're prone to judging code like I am, this project is 70%+ written by one person. These design decisions are all very powerful and many times very beautiful in their simplicity. If you're the only one that works on a project, sometimes it pays to pick a powerful abstraction over one easier to read and understand.

I've got some ideas on how we could tease some abstractions, but it's a hard thing to do. We have to be backwards compatible, and bake in room for future features & growth. We also need to be performance conscious.

There are other features that I haven't covered in this example such as how files get written to disk, and how manifest files are generated, but how an asset gets loaded is complicated enough for now. How is your life better now that you know how the "F" Sprockets loads an asset? I have no idea, but I'm sure there's something good about it. If you enjoyed this technical deep dive check out [my post where I live-blog a writing a non-trivial Rails feature](https://www.schneems.com/2016/11/21/writing-a-rails-feature-blow-by-blow/). Thanks for reading!

----
If you liked this post (or even if you didn't) you can subscribe to my [mailing list](https://eepurl.com/bbuvuz) to get updates when I post new content. I average a little less than a post a week, often fewer. The more subscribers I get, the more incentive I have to put out content consistently.

