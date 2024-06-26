---
title: "Get your SVGs out of your HTML"
layout: post
published: true
image: og/svg-in-css.png
date: 2018-01-04
permalink: /2018/01/04/get-your-svgs-out-of-your-html/
categories:
    - ruby
    - frontend
    - svg
    - css
    - data url
    - performance
---

After this holiday season many of us would like to lose a little weight, page weight that is. In my app [CodeTriage](https://www.codetriage.com) I make extensive use of SVG elements for images, the logo, and icons. Until recently, I've been rendering the SVG elements directly in the HTML. This was the easiest thing to do. As you might guess by my intro sentence, I've been working on decreasing page weight by removing SVG elements from the HTML. How well did it work? Before making changes the homepage was 14kb (77kb unzipped). After the change, the homepage is 6kb (30kb unzipped). That's a 57% reduction in "over the wire" bytes per page load. What exactly did I do, and what were the trade-offs I made to get to a smaller page? Let's look at how I was previously using SVG.

On the main page I have a "warning" icon that is SVG. It looks like this:

<center>
  <svg f class="issue-icon" version="1.1" viewBox="0 0 16 16" height="20" width="20" xmlns="http://www.w3.org/2000/svg">
  <path d="m8 0c-4.418 0-8 3.582-8 8s3.582 8 8 8 8-3.582 8-8-3.582-8-8-8zm0 14c-3.309 0-6-2.692-6-6s2.691-6 6-6c3.307 0 6 2.692 6 6s-2.693 6-6 6z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,3h-1C7.224,3,7,3.224,7,3.5v6C7,9.776,7.224,10,7.5,10h1 C8.776,10,9,9.776,9,9.5v-6C9,3.224,8.776,3,8.5,3z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,11h-1C7.224,11,7,11.224,7,11.5v1C7,12.776,7.224,13,7.5,13h1 C8.776,13,9,12.776,9,12.5v-1C9,11.224,8.776,11,8.5,11z" clip-rule="evenodd" fill-rule="evenodd"/>
  </svg>

  <svg f fill='fffff' class="issue-icon" version="1.1" viewBox="0 0 16 16" height="20" width="20" xmlns="http://www.w3.org/2000/svg">
  <path d="m8 0c-4.418 0-8 3.582-8 8s3.582 8 8 8 8-3.582 8-8-3.582-8-8-8zm0 14c-3.309 0-6-2.692-6-6s2.691-6 6-6c3.307 0 6 2.692 6 6s-2.693 6-6 6z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,3h-1C7.224,3,7,3.224,7,3.5v6C7,9.776,7.224,10,7.5,10h1 C8.776,10,9,9.776,9,9.5v-6C9,3.224,8.776,3,8.5,3z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,11h-1C7.224,11,7,11.224,7,11.5v1C7,12.776,7.224,13,7.5,13h1 C8.776,13,9,12.776,9,12.5v-1C9,11.224,8.776,11,8.5,11z" clip-rule="evenodd" fill-rule="evenodd"/>
  </svg>
</center>


Here's the raw SVG:

```
<?xml version="1.0" encoding="UTF-8"?>
<svg fill="#fff" class="issue-icon" version="1.1" viewBox="0 0 16 16" xmlns="http://www.w3.org/2000/svg">
  <path d="m8 0c-4.418 0-8 3.582-8 8s3.582 8 8 8 8-3.582 8-8-3.582-8-8-8zm0 14c-3.309 0-6-2.692-6-6s2.691-6 6-6c3.307 0 6 2.692 6 6s-2.693 6-6 6z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,3h-1C7.224,3,7,3.224,7,3.5v6C7,9.776,7.224,10,7.5,10h1 C8.776,10,9,9.776,9,9.5v-6C9,3.224,8.776,3,8.5,3z" clip-rule="evenodd" fill-rule="evenodd"/>
  <path d="M8.5,11h-1C7.224,11,7,11.224,7,11.5v1C7,12.776,7.224,13,7.5,13h1 C8.776,13,9,12.776,9,12.5v-1C9,11.224,8.776,11,8.5,11z" clip-rule="evenodd" fill-rule="evenodd"/>
</svg>
```

I had it defined as a Rails "helper" that would be rendered directly into the HTML. This element was repeated many times on the page, each time we had to send the exact same SVG string which added the same number of bytes to the page size. To fix the issue I moved the SVG code to my image directory and then I used Sprockets to "inline" the image via a data-url.

How does a data url work? Normally a url in the background of a CSS element would say "go out and grab this asset at a different URL. A "data" url instead encodes all the data needed to render the image without making a new network request. Here's an example of what one might look like:

```
background: url("data:image/svg+xml;charset=utf-8,
  %3Csvg
  version='1.1'
  xmlns='http://www.w3.org/2000/svg'
  xmlns:xlink='http://www.w3.org/1999/xlink'
  width='512'
  height='512'
  viewBox='0 0 512 512'
  %3E%3Cpath d='M224 387.814v124.186l-192-192 192-192v126.912c223.375 5.24 213.794-151.896 156.931-254.912 140.355 151.707 110.55 394.785-156.931 387.814z'
  %3E%3C/path%3E
  %3C/svg%3E");
```

This "url" contains the entire image contents, no need to make an HTTP request.

In Sprockets, data urls are currently supported via making a Base64 string of the file, but in future releases it will [be URL escaped instead](https://github.com/rails/sprockets/pull/520) to avoid the extra overhead of using Base64. You can read more about [why not to base64 SVG inlined images here](https://css-tricks.com/probably-dont-base64-svg/).

Previously I said I used Sprockets to make this change. In my project this is the `sass-rails` incantation to add the `warning.svg` as a data-url to my css:

```css
.warning-svg {
  width: 16px;
  height: 16px;
  display: inline-block;
  background: asset-data-url("warning.svg");
}
```

The `asset-data-url` is interpreted as a directive, it takes the contents of the `warning.svg` image and "inlines" them so that no extra HTTP request needs to be made. If you're using ERB then it might look like this:

```css
.warning-svg {
  width: 16px;
  height: 16px;
  display: inline-block;
  background: url(<%= asset_data_uri 'warning.svg' %>);
}
```


Now when you visit the page, the SVG element is only sent once over the wire via `application.css`, and is then re-used many times via the `warning-svg` class. This means that it takes less time to download the HTML for end users, and since the assets are served with far future cache headers, they will only be downloaded once by the browser. Even better, the site is being served behind the cloudflare CDN, so there is no additional burden on the app server for the slightly larger CSS files.

> You can see the [pull request where I implemented this change](https://github.com/codetriage/codetriage/pull/664).

Are there any downsides? The biggest issue of this approach (for me) is that I lost the ability to control the `fill` (color) for the SVG element via CSS. Previously with the SVG in the HTML, if I wanted to change the color of an element, it was very simple, I did it in CSS. Here's an example of changing fill color to red on hover using CSS:

![change logo color to red on hover](https://www.dropbox.com/s/d66dfd8w94tmye4/codetriage-red-logos.gif?raw=1)

Once I moved the SVG element out of the page I wasn't able to make this type of modification through pure CSS. For this case I settled on transforming the element to make the hover state apparent instead:

![expand logo on hover](https://www.dropbox.com/s/32n7r5kyn9ufoi7/codetriage-expand-logos.gif?raw=1)

If the color change was absolutely needed, then I could have generated two SVG elements with different fill values and changed the background element on hover. You can see a [stack overflow thread on alternatives](https://stackoverflow.com/questions/13367868/modify-svg-fill-color-when-being-served-as-background-image).

In addition to using the "warning" SVG on the main page I also use it on the "repo show" page, but it had a different fill. It was gray instead of white. In this case it wasn't appropriate to get rid of the color change; however I was able to approximate a color change by using the `opacity` CSS property which will affect the SVG element.

If you don't want to use a data url in CSS, you can also render it as a normal image via `<img >` tag. You can also leverage the [use tag](https://developer.mozilla.org/en-US/docs/Web/SVG/Element/use) which lets you send the element once via HTML but then re-use and manipulate as if it were directly in the HTML.

In my case all of the elements being rendered were present in the vast majority of my pages, so it makes sense to put them in places that will be globally cached by browsers and my CDN.

Some notes on converting a SVG element into an inline CSS element: You'll need to make sure you're setting a height and width to your element since the SVG is only the "background". You'll also need to make sure that the SVG is being formatted and served properly. For me I had one SVG element that was missing the xml declaration:


```xml
<?xml version="1.0" encoding="UTF-8"?>
```

And the same one was missing the `xmlns="http://www.w3.org/2000/svg"` property. If you click on the image url via the CSS inspector in your browser, it should show you if there are errors. You'll also need to explicitly set a `fill` property in the image, otherwise they will default to black.

Overall the change was pretty simple, and a 57% smaller page isn’t too shabby.

While there are still reasons you might want to put your SVG elements directly in your HTML, consider the page weight implications and costs first.


**Update 1:** Looks like you can use the `<use>` with an external source meaning that you get the benefits of HTTP caching and a re-usable element along with the ability to style it as if it were inline. Here's more info on [External SVG with the use tag](https://css-tricks.com/svg-use-external-source/). The only downside is it's not supported natively with IE, but there is a polyfill. Thank's to [this comment on lobste.rs](https://lobste.rs/s/gubq9w/get_your_svgs_out_your_html#c_f3uidx).

**Update 2:** On Reddit it was mentioned not to use "background" for an icon. Here's a good explanation of why, and an example of what you could use instead [Comments on Reddit](https://www.reddit.com/r/ruby/comments/7o5t1d/get_your_svgs_out_of_your_html/ds89c7l/).

> BTW you may have noticed that I haven't posted anything in awhile. I had a baby (my second) and I'm taking 2 months off for paternity leave. I may post a bit about fatherhood or other thoughts, but don't count on any kind of a regular schedule. My priority right now is my family (I wrote this post before the little one came along).
