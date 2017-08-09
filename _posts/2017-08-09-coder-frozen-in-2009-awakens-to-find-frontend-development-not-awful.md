---
title: "Coder Frozen in 2009 Awakens to Find Frontend Development not Awful"
layout: post
published: true
date: 2017-08-09
permalink: /2017/08/09/coder-frozen-in-2009-awakens-to-find-frontend-development-not-awful/
categories:
    - ruby
---

I've not seriously touched frontend code, in years. Frankly, it scares me. To that end "front end devs are not real programmers is totally BS". I want to talk about some of the recent changes in tooling and APIs that are available so that front end development might not suck as much as it used to. You will not learn to be a CSS or JS guru with this post. If you've written much front end code, this will be mostly full of face-palm level obvious statements. Therefore, feel free to read for the laughs.

I've been working at Heroku for 5+ years and I've not shipped a production feature that touched frontend code in that time. Prior to that, I kinda dabbled a bit, but mostly just mocked up other people's interfaces. The last "real" website that I was responsible for frontend was probably circa 2009, and it was awful (both in experience and my designs).

Recently I've been updating my blog, and while it might not be the most exciting frontend project, it's my project. I wanted it to be responsive and extremely lightweight. Here's some things I've learned along the way.

> Note: If it isn't painfully obvious, I'm not an expert here.

## Async JS

If you need JS on your site, you don't have to make your visitors wait for it to download before continuing to render the rest of your page. Instead you can use an `async` tag:

```html
<script src="/assets/javascripts/application.js" async></script>
```

Now when the browser gets to this line, they start downloading it in the background.

Pros: Page loads faster, seems more responsive.


Cons: Any JS that expects to interact with the DOM must be wrapped in an event handler (more on that later).

## jQuery Isn't necessary

If you've been using jQuery as a crutch, I've got good news: you can drop it! The bad news is that you'll have to re-learn how to do the most basic of things.

Since we need to wrap every DOM manipulation in a page load event handler, we will look at how to do that first:

```js
window.addEventListener("load", function(event) {
  console.log("content is loaded yo!");
});
```

This replaces the jQuery way:

```js
$( document ).ready(function() {
  console.log("content is loaded yo!");
});
```

The next REALLY useful thing you probably used jQuery for was the document selector. You can replace `$(".hamburger")` with `document.querySelectorAll(".hamburger")` but this isn't exactly a drop-in replacement. You'll also need to iterate over each item. Which brings me to the next feature on my list: Item iteration.

I've been programming for 10 years and I still make off by one error, so whenever I can iterate based on objects instead of writing some kind of an index based iteration code, I do it. I find it makes the code more readable and that means fewer bugs.

Here's an example of iterating over all the "divs" in a page:

```js
var divList = document.querySelectorAll("div");
divList.forEach(function(elem) {
  console.log(elem);
}
```

Now we could modify each of those elements individually if we wanted to.

The last thing on my jQuery hit list was toggling visibility. jQuery gives us `show()`, `hide()` and `toggle()`. One way we can do this without jQuery is by pairing the ability to toggle class names with a bit of CSS.

In your CSS you can set:

```css
.hidden {
  display: none;
}
```

Then in your JS:

```js
var elemList = document.querySelectorAll(".toggle-visability");
elemList.forEach(function(elem) {
  elem.classList.toggle('hidden')
}
```

If the element has the class "hidden" it will be removed, otherwise it will be added.

I guess I never really talked about __why__ I wanted to get rid of jQuery. The biggest reason is page size. Even though we're serving content async this page is so simple there's no reason to use a huge framework. I don't see this preference as a failure of jQuery, but instead I see it as a validation. Many features, such as ability to query DOM based on selector, were hugely powerful and had it not been for the framework we might not see equivalents in the language. Libraries and frameworks are a lightweight way to validate experiments, and when the successful ones get merged back upstream, we all win.

When were these features added to JS and were they actually inspired by jQuery? I have no idea.

## CSS Is less awful

I'll admit that I fell in love with CSS when I first started using it. When I started making web apps it was so much fun to get this instant gratification of seeing my changes on screen. While backend logic changes are equally as "real", there's something that touches us at a human level when we can feel, see, or otherwise sense the changes we're making on the world. CSS feedback is much more visceral. Likewise it was eviscerating when it didn't work as expected.

Since I learned front end in the age of IE 6, those eviscerating times were many. I didn't mind the browser hacks at first, but over time it became too much to keep in my head and new changes would break old hacks.

On a sidenote the first time I ever got help filing my taxes I went to an H&R block and the guy entering all my data into a computer was using...IE6. This was after [Digg did a spent a bunch of time to see if they could drop IE6](http://news.softpedia.com/news/Digg-May-Drop-Support-for-Internet-Explorer-6-116478.shtml). I pointed out how insecure it was, and that they should consider upgrading. His response was "we don't have money for new stuff like that" ಠ_ಠ.

Back in the day I wanted a pure CSS way to make a responsive site that was pixel perfect in all browsers. Fast forward to today, and I got half my wish. CSS is really easy to make responsive these days. In an interesting turn of events though, the common CSS "pixel perfect" dreams have turned to "looks decent and not drastically different". While 2009 me still wishes for total pixel domination, 2017 me is pretty happy that I don't have to stress if things look a little off, as long as they look okay.

## Responsive CSS

How is a CSS only responsive site made? With media queries! They are surprisingly simple. The idea is this: You make your design in regular CSS for the smallest case, then you add a media query to see if the viewport is larger than some threshold and augment the design to accommodate the larger design.

Here's a hello world media query example

```css
.sidebar {
  background-color: white;
}

@media (min-width: 48em) {
  .sidebar {
    background-color: red;
  }
}
```

> For my website I prefer `em` and `rem` over pixels for measurements because I read once in a book that they were better or something.

So my sidebar would default to white when it is small, but once the window was stretched to 48em or larger the background color would change to red. You can have more than one set of media queries for different sized windows, but I only have two: one for "mobile" and one for "desktop".

Generally instead of colors, you'll want to modify sizes and orientation and even hide things.

## Flexbox

Flexbox is the thing you always thought CSS should have. You can use it to make columns like on a newspaper, or rows. I use flexbox in combination with media queries to make the site readable on mobile. When it's in "big" mode I have 2 columns (a sidebar and a main content area). When it's in "mobile" mode, the sidebar gets moved to the top and instead of columns the main content area becomes a row.

I accomplish this by wrapping those two sections in a top level html element:

```html
<div class="flexbox-container" >
  <div class="sidebar">
    <!-- {% include sidebar.html %} -->
  </div>
  <div class="content container">
    <!-- {{ content }}  -->
  </div>
</div>
```


Then in the css:

```css
.flexbox-container {
  display: -ms-flex;
  display: -webkit-flex;
  display: flex;
  -webkit-flex-direction: column;
  flex-direction: column;
}

.sidebar {
  flex: 1;
}

.content {
  flex: 2 1 auto;
}

@media (min-width: 48em) {
  .flexbox-container {
    -webkit-flex-direction: row;
    flex-direction: row;
  }
}
```

I have to do some other things like adjust padding, but that's the basic gist of things. It's worth pointing out that the "big" version of the site still inherits all values from the "mobile" version, you only use the media query section to change values.

## SVG

Vector graphics are amazing, use them! SVG images can be styled via code, so you don't have to go back and forth between photoshop every time you want to try out a new background color. The other cool thing about SVG images is that you can resize them with CSS (again skipping any photo manipulation tools). Unlike rasterized images, vectorized graphics will not lose clarity as they are resized up to fill a space. You can also embed them directly in your site which skips the need to have an extra asset TCP query.

## Sass isn't overkill

This isn't a CSS feature per-say, but rather an ecosystem concern. My site uses sprockets to generate assets, and even though it's __only__ a blog, it's not overkill. Why shy away from a framework like jQuery for JS but embrace a framework with CSS? Well jQuery as a dependency has to be downloaded EVERY time your site loads. Preprocessors help in development and then get out of the way in production.

I use [sprockets](https://rubygems.org/gems/sprockets) via [Jekyll Assets](https://github.com/jekyll/jekyll-assets)on my blog because it's written in Ruby. If you didn't know, I also maintain the sprockets gem as well. Yes, I know there hasn't been a release on 4.0 and I'm sorry.

Here's some things an asset framework lets me do:

- Break out my JS and CSS into multiple files in development, but concatenate them into one file for production. Smaller files are easier to manage than one huge file when you're developing. Unfortunately, TCP slow start is a pox on website performance and loading multiple small CSS files is much slower than loading 1 large file in prod.
- Fingerprinting: Each asset is compiled to have its digest in its name. This by itself isn't that great, but where it pays off is when you configure your cache-control to have far future expires.


In English: when your server responds to a web request it can choose to include a header that looks like this:

```
"Cache-Control": "public, max-age=15552000"
```

This tells the browser that the file it just downloaded doesn't have to be re-downloaded for 15552000 seconds (nearly 6 months). This is great for someone browsing your site, on the next page load they can skip downloading your CSS. However you have to invalidate this cache somehow if you want to change your CSS or JS. That's where the fingerprints come in. When you change a variable, the file name of your asset will change and then the browser will download the new file because it is a totally new name.

This is an advanced topic and also requires configuration of your webserver to add the header for assets.

- Minify: Whitespace is for chumps. Each byte you transfer over the network takes the same amount of time whether it's a newline or a curly bracket. You can run a minifier minimize file download size in prod without having to pull out your hair modifying CSS on one line with no spaces or comments in development.

- Sass > CSS: I don't leverage Sass as much as I could/should but having my assets managed by a framework means that it's just as easy to write Sass as it is to write CSS. I make a change to a file and save. It gets picked up by jekyll and when I refresh I see my change. Easy peasy.

## Dev tools in browsers are outstanding

Also not a JS or CSS concern, but dang chrome...you are fun to work with. It's really easy to prototype a change and get live feedback, right? Just make sure to keep your changes small and to copy them over to your actual stylesheet before you refresh.

## Where is my flying car?

I have to admit that I don't dislike front end coding nearly as much as I did before starting down this path. While I don't have a jetpack that I can fly with to lunch: I can make columns in CSS, and that's something, right? If it's been awhile since you've dabbled in the view layer, maybe it's time to put that curmudgeon hat back on the shelf. Working with modern CSS and JS code makes me feel the same way I did when I saw my first CSS changes, hopeful and excited. I still don't claim to know what I'm doing, but at least it's fun again.

