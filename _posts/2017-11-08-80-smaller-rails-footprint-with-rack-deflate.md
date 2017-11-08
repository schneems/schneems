---
title: "80% Smaller Rails Page Size With Rack Deflate"
layout: post
published: true
date: 2017-11-08
permalink: /2017/11/08/80-smaller-rails-footprint-with-rack-deflate/
categories:
    - ruby
---

Do you have 5 minutes? Do you want to decrease the "over the wire" size of your Rails app by 80%? Sure you do! I added Rack::Deflate to [CodeTriage.com, the best way to get started in Open Source,](https://www.codetriage.com) and went from a page size of 85,523 bytes to 15,568 bytes (over the wire). You can verify with this retro looking [web based compression tool](http://www.gidnetwork.com/tools/gzip-test.php).

First up, what does Rack Deflate do and why do we want to use it? Rack Deflate uses `Zlib::GzipWriter` to compress the body of your web page before responding to a request. Later, when the client gets the response from the server, it will see that it is compressed based on the `Content-Encoding=gzip` header and unzips the web page before attempting to render it. It might sound like a bunch of hoops to jump through, and couldn't possibly be faster than just sending the raw page, but that's not the case.  In general, CPUs are fast, and networks are slow. It's much faster to send less data "over the wire" even if we have spend time to compress and expand that data.

How much could this compression trick possibly help? Well, before I added this to CodeTriage, a page render of the homepage with me logged on took roughly 578ms

![](https://www.dropbox.com/s/gop4vasoqvvm7f4/Screenshot%202017-09-07%2016.39.09.png?dl=1).

After adding Rack Deflate it dropped to about 422ms

![](https://www.dropbox.com/s/m5d3jnk46lyyu5d/Screenshot%202017-09-07%2016.47.39.png?dl=1).

While those numbers vary a bit, it seems to be consistently about 100ms faster. It makes even more of a difference if you're on a slower connection, such as a mobile phone in a spotty area, or if you're on 3G. Not bad for a few minutes of work.

Rack Deflate ships with Rack so you don't need to add any extra dependencies. To add it to your Rails app all you need to do is add this line of code to your `config/application.rb`

```ruby
config.middleware.insert_after ActionDispatch::Static, Rack::Deflater
```

That's it. Commit to git. Push to Heroku (or wherever else deploying Rails apps is delightful for you). Watch your over-the-wire footprint drop like a rock. Here's [the commit where I added Rack::Deflater to CodeTriage](https://github.com/codetriage/codetriage/commit/b3d7a1186e21608052f48d9a9c86eb4c400b7b40).

What does this line do? If you're serving static assets from your Rails app, it's being done from the `ActionDispatch::Static` middleware. This line makes sure that the `Rack::Deflater` comes after the static asset middleware. I did this because otherwise if you're using a [recent version of Rails that supports serving GZIP files from disk](https://github.com/rails/rails/pull/16616), and a recent version of Sprockets, then some files will already be gzipped. By default Rack Deflate will [attempt to re-gzip any body that you throw at it](https://github.com/rack/rack/blob/6b942ff543416e0c82196f0790d4915c7eead4cb/lib/rack/deflater.rb#L106-L122). Gzipping a binary file or one already gzipped won't help so this helps avoid double work.

