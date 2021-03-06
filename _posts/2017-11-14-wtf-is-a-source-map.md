---
title: "WTF is a Source Map"
layout: post
published: true
date: 2017-11-14
permalink: /2017/11/14/wtf-is-a-source-map/
image: og/sourcemaps.png
categories:
    - ruby
    - assets
    - js
    - css
    - frontend
    - transpile
    - sourcemap
---

These days web assets such as JS and CSS aren't simple text files. Instead, they're typically minified or come from a complex build process involving compiling or transpiling. For example, CSS can be generated from a SASS file. JS can be compiled from ES6 using Babel. These toolchains make working with assets easier for developers, and make following best practices such as minification much easier. Yet, there's a problem. What do we do when there's a error? If there's an exception in your JS and it's minified, you will have short variable names which are all on one line and it's impossible to see where the error comes from. Source maps seek to solve this problem.

What is a source map? At its core, a source map allows a browser to map the source of an asset to the final product. In our previous example of an error happening in a JS file, if the JS file had a source map, it would allow the browser to translate the location of the error to the original unmodified file on disk. Pretty cool.

How exactly do source maps work? First, your asset build tools need to be able to generate a source map. Once a source map is available, the build tool needs to let the browser know it exists somehow. This is accomplished by a special comment at the bottom of the asset file. For example, if you're serving an `application.js` then the bottom of the file may link to a source map like this:

```js
//# sourceMappingURL=application.js-27b6d64dc918dd82a8f02f9537b12d8e059524bc53d6f2dac0f04825a60023f5.map
```

Okay, so that's how a browser know a source map exists. What does the source map file look like? Here's an example:

```json
{
  "version":3,
  "file":"application.js",
  "mappings": "AAAA;AACA;AACA;#...",
    "sources": [
      "jquery.source-56e843a66b2bf7188ac2f4c81df61608843ce144bd5aa66c2df4783fba85e8ef.js",
      "jquery_ujs.source-e87806d0cf4489aeb1bb7288016024e8de67fd18db693fe026fe3907581e53cd.js",
      "local-time.source-b04c907dd31a0e26964f63c82418cbee05740c63015392ea4eb7a071a86866ab.js"
    ],
    "names":[]
}
```

What do each of those keys mean?

- `version` The version of the source map specification we are using. The current is version 3.
- `mappings` The secret sauce, this includes a [VLQ base 64](https://en.wikipedia.org/wiki/Variable-length_quantity) encoded string that tells the browser how to map lines and locations in the generated file to files. I truncated it here because it can be REALLY long.
- `file` This is the current file that the sources are mapped to.
- `sources` An array of source files, these are the files used to generate `application.js`. In this case, we can see `jquery`, `jquery_ujs` and `local-time` javascript files were used to generate the `application.js` file.
- `names` Names of functions if available

If the source file is served to the browser with a source map comment and that comment leads to a correctly generated source map file, then when you get exceptions in the console it should point to the original source file that generated the asset.

I know what you're probably thinking "Richard, you usually write about things you're working on or thinking about, why are you talking about source maps?" That's an excellent question.

Source maps are not new, you can read the proposal for [Source Maps version 3](https://docs.google.com/document/d/1U1RGAehQwRypUTovF1KRlpiOFze0b-_2gc6fAH0KY0k/edit) which is strangely in a Google doc. Version 3 of source maps was originally introduced in 2011. If you're using JS tooling they're likely already generating and using source maps without you knowing it. However, not all assets are generated via JS tooling. I maintain [Sprockets](https://rubygems.org/gems/sprockets), a little library with 98 million downloads for generating assets for Ruby applications. It's the main component in the "Rails Asset Pipeline". You may have seen my post about [Saving Sprockets](https://www.schneems.com/2016/05/31/saving-sprockets.html).

> Update: The author of source maps [responded to my article and explained the history of source maps](https://news.ycombinator.com/item?id=15705190) including why a google doc is used. Apparently the very first source maps were introduced back in 2009 at Google.

I'm writing about source maps because Sprockets is getting them, or rather, Sprockets 4 beta has had them since February 2016.

What exactly is Sprockets using source maps for? In production, Sprockets combines files together and minifies them when possible. This makes serving HTTP 1.x traffic faster, but if there is an error in your assets, it becomes very difficult to debug. In the Rails Asset Pipeline, it was the convention to not concatenate these files in development, so instead of serving 1 file, you might see 10 or so. With this system when you get an exception, the stack trace points back to the generated file instead of the original.

Lets say you have a coffeescript file `foo.coffee` that is has a bug in it. Previously with sprockets this would be compiled into javascript `foo.js`.  When you get the error, the browser will point out the location of the error in the `foo.js` javascript file. Then you have to mentally be able to reverse-map that javascript code to your coffeescript `foo.coffee` file to understand where what generated that exception. With source maps, the exception maps back to the line and column in the `foo.coffee` file. No mind-bending required.

By using source maps in development instead of having branching behavior, we bring development/production parity and make the experience of debugging assets generated by Sprockets similar to those generated by JS tooling. You can try the beta if you want now, but there are still (lots of) bugs, which is why it's not released yet.

If you're curious about source maps, I had to learn about them from scratch. You can follow along with that journey over in the [Sprockets guides for source maps](https://github.com/rails/sprockets/blob/master/guides/source_maps.md). Specifically, you can learn to:

- [Encode/Decode a source map with NPM tools](https://github.com/rails/sprockets/blob/master/guides/source_maps.md#encodedecode-source-map)
- [Learn about how the VLQ encoding works in the source map format](https://github.com/rails/sprockets/blob/master/guides/source_maps.md#source-map-file)
- [Understand how sprockets supports source maps internally](https://github.com/rails/sprockets/blob/master/guides/source_maps.md#sprockets-internal-map-support)

Now that you know what "source maps" are. Hopefully, you'll be able to use them in your own tooling or with the Rails Asset Pipeline soon. I'm juggling a full-time job, a Master's in CS classes, and I'm about to have a second kid, so progress is slow. Anyhoo, you know what source maps are now, and that's really all I wanted to say.
