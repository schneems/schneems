---
title: "Self Hosted Config: Introducing the Sprockets manifest.js"
layout: post
published: true
date: 2017-11-22
permalink: /2017/11/22/self-hosted-config-introducing-the-sprockets-manifestjs/
categories:
    - ruby
    - configuration
    - sprockets
    - library design
---

Sometimes it's easier to do a simple task manually than to figure out what hoops you need to jump through to correctly configure a framework to do what you want. I run into this all the time. I know a framework can be configured to perform a certain action, or behave in a certain way. However, I get lost in a sea of documentation (or no documentation) and the search for that one magical config key takes just a tad bit too long. It's a productivity sink, and worse than the time delay it adds to my frustration throughout the day. When I hit `ETOOMUCHFRUSTRATION`, then I'm definitely fighting the framework. One way to alleviate this configuration fatigue is by making configuration consistent and composable. That's what Sprocket's new "manifest.js" seeks to do.

Before we get into what the `manifest.js` does, let's look at what it is replacing. When sprockets was introduced, one of the opinions that it held strongly is that assets such as CSS and JS should be bundled together and served in one file.

This has a few big advantages. If the alternative was to have multiple scripts or stylesheet links on one page, that would trigger multiple HTTP requests. Multiple requests mean multiple connection handshakes for each link "hey, I want some data", "okay, I have the data", "alright I heard that you have the data, give it to me" (SYN, ACK, SYNACK). Even once the connection is created there is a feature of TCP called [TCP slow start](https://en.wikipedia.org/wiki/TCP_congestion_control) that will throttle the speed of the data being sent at the beginning of a request to a slower speed than the end of the request. All of this means transferring one large file is faster than transferring the same data split up into several small files.

Another benefit of having all the assets in one file is that on subsequent page loads a browser can potentially re-use the same asset it has in cache (provided cache control headers are sent) instead of having to download say, a new stylesheet for new Rails controller.

To have this bundling feature, Sprockets has a custom set of "directives" that are implemented in comments where you can tell it what files you want concatenated into your primary file, by default `application.(js/css)`. If you've used Sprockets you've seen the `require` directive:

```js
//= require tab_navigation.js
//= require global.js
//= require badge.js
//= require homepage.js
```

From the [sprockets guide](https://github.com/rails/sprockets/blob/master/guides/end_user_asset_generation.md#default-directives) the `require` will:

```
`require` *path* inserts the contents of the asset source file
specified by *path*. If the file is required multiple times, it will
appear in the bundle only once.
```

That's how a user declares what they want in their final bundled asset. However there's a problem. What if there're some assets that are used really infrequently? For example, what if your site has a customer interface and an "admin" interface? If the two have totally different designs and features, then it might be considerable overhead to ship the entirety of the admin interface to every customer on the regular site. In this case developers needed a way to tell Sprockets that it should also generate an additional `admin.js` in addition to the `application.js`.

How was this feature implemented?

Well it wasn't really. In Rails you could configure this behavior through a config key:

```ruby
config.assets.precompile += ["admin.js", "admin.css"]
```

But what was the Sprockets interface? If someone was trying to build the same feature in another Ruby library, how would they do it? The answer is a bit obtuse, but here it is. Sprockets has a class `Sprockets::Manifest` that handles high level compilation of a series of assets, to compile a new asset and make it available to end users Rails has to call the `find` method on that class for each of the assets in our precompile list. This would force it to be loaded and generated.

What don't I like about this `config.assets.precompile` style of configuration? It feels artificial. While Sprockets is opinionated about bundling and generating assets, this config flag isn't natively implemented in Sprockets. If you were to go and use another app, such as Jekyll or Sinatra (or some other library) that also used Sprockets, how could you configure it to also generate an `admin.js`? No clue. Go look at the docs. It would be nice if such a core part of Sprocket's library configuration remained (at least somewhat) consistent between different installations of it.

Another thing I don't like: our asset behavior is decoupled from the assets. If you're mucking around in your `app/assets` folder, then you have to first know that such a config exists, and then hunt it down in a totally different `config` folder. It would be nice if, while we're working in asset land, we didn't have to mentally jump around.

Another big issue is that the config wasn't really expressive enough. From the beginning Rails needed a way to say "only compile `application.css` and `application.js`, but compile ALL images" by default. With our previous interface, we're limited to only strings. So sprockets accepts lambdas that can be called instead. Here's what the Rails lambda that does this looks like:

```ruby
LOOSE_APP_ASSETS = lambda do |logical_path, filename|
  filename.start_with?(::Rails.root.join("app/assets").to_s) &&
  !['.js', '.css', ''].include?(File.extname(logical_path))
end
```

That's pretty gnarly. While the name of the constant `LOOSE_APP_ASSETS` gives me some idea of what it does, it still takes a second to wrap your mind around. If you were trying to figure out what assets are being precompiled and you did a `puts config.assets.precompile` that lambda object would be utterly baffling.

The interface also supports regular expressions as well. Here's another default value in the `precompile` list `/(?:\/|\\|\A)application\.(css|js)$/`.

It's nice that the framework is flexible enough to let us accomplish our goals, but, it's all very obtuse. It's hard to understand what exactly we're getting in our final output, and even harder to figure out what inputs we need to change or modify to get a desired output.

One last minor nit. The config examples are all using the `+=` operator. Which is dangerously close to the `=` operator. It's easy to accidentally do something like this:

```
config.assets.precompile = ["admin.js", "admin.css"]
```

Where you’ve overwritten the original config by mistake, and then you spend minutes or hours trying to figure out why your images and `application.css` won't load. While such an error might not be common, it will be painful when it does happen.

I guess in short you could say that I don't like this interface very much.

Remember before how we had a grammar that could tell Sprockets what files we wanted bundled together? The one using `require`? What if we had another directive we could use that told sprockets to compile a file and make it publicly available, but not to concatenate it?

Well it turns out we've already got it, introducing the `link` directive:

```
`link` *path* declares a dependency on the target *path* and adds it to a list
of subdependencies to automatically be compiled when the asset is written out to
disk.
```

So instead of having this confusing maze of lambdas, regexes, and strings, we could, in theory, introduce a single entry point of configuration for Sprockets to use, and in that file declare all assets we wanted to compile. Well, that's exactly what the `manifest.js` file is.

If you're using Rails and Sprockets 4 you'll have an `app/assets/config/manifest.js` file. By default it should look something like this:

```js
//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css
```

The first line `link_tree ../images` says to go through every file in the `images` directory tree and generate it as an asset. The next `//= link_directory ../javascripts .js` generates a javascript file for each file ending in `.js` in the `javascripts` folder (but not in sub folders). If you wanted to only generate one `application.js` file you could change it to

```
//= link ../javascripts/application.js
```

What do I like about this? It feels more declarative to me. I look at that file and it doesn't take too long to understand what the output will be. If I need to add a file, it doesn't take too long to consider using a `link` directive. The config lives the assets section as well, which is a plus. The grammar here is also consistent with other Sprockets directives. For example `require` also has a `require_tree` and a `require_directory`. If you've used these then it will feel familiar.

The way it's implemented in Rails is very straightforward, instead of calling find for a lambda and a regex by default it only looks for `manifest.js` with the `Sprockets::Manifest` class. This provides a single entry point that other implementations can use and build on. It's a convention, if you will, that can be used by other future frameworks, rather than configuration.

What don't I love about this configuration method? The `link` name is not very helpful, it doesn't explain what it does very well. The name makes me think of "The Legend of Zelda". I imagine the original Sprockets author saying "It's dangerous to go alone" and then handing me a javascript file.

I didn't name the directive, or invent the concept of the `manifest.js`, I'm just pushing it across the finish line. We could add a directive that is an alias to `link` in the future with little work, but `link` will continue to live due to legacy concerns.

Another thing I don't like is the name of the config file `manifest.js`. Internally sprockets has the concept of a manifest already `Sprockets::Manifest`, but the two aren't directly coupled. We also already have a "manifest" JSON file that gets generated in `public/assets/` and has manifest in the name `.sprockets-manifest-140998229eec5a9a5802b31d0ef6ed25.json`. I know one is a JS file and one is a JSON file, but it's a bit confusing to talk about.

As we know, naming is hard. So if these are the only two nits I have with the feature, that's not too bad.

New config is scary. If you're going to upgrade to Rails 4 here's what you need to do:

```term
$ mkdir -p app/assets/config
$ touch app/assets/config.manifest.js
```

Then copy and paste this in there:

```js
//= link_tree ../images
//= link_directory ../javascripts .js
//= link_directory ../stylesheets .css
```

That's it. If you have a previous "precompile" array, in your app config, it will continue to work. For continuity sake I recommend moving over those declarations to your `manifest.js` file so that it will be consistent.

If you miss a configuration, you'll get a helpful error (added by yours truly):

```
Asset `admin.js` was not declared to be precompiled in production.
Declare links to your assets in `app/assets/config/manifest.js`.

  //= link admin.js

and restart your server
```

Also if you forget to add the manifest file, you'll get an exception with a helpful error.

While I certainly don't think that all configuration should be "self hosted" in this kind of way, I do think programmers can try to be aware of their configuration systems and the cognitive overhead they impose on people.



