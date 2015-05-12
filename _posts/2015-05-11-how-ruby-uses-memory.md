---
layout: post
title: "How Ruby Uses Memory"
date: '2015-05-11 08:30:00 -0500'
published: true
tags: debugging, ruby, performance, memory
---

I’ve never met a developer who complained about code getting faster or taking up less RAM. In Ruby, memory is especially important, yet few developers know the ins-and-outs of why their memory use goes up or down as their code executes. This article will start you off with a basic understanding of how Ruby objects relate to memory use, and we’ll cover a few common tricks to speed up your code while using less memory.

[Keep Reading on Sitepoint.com](http://www.sitepoint.com/ruby-uses-memory/)

If you're still hungry for more information on memory and performance you can also check out my latest talk at RailsConf 2015.

## Memory talk at RailsConf 2015

#### Speed science Video

<iframe width="560" height="315" src="https://www.youtube.com/embed/m2nj5sUE3hg" frameborder="0" allowfullscreen></iframe>

#### Speed science Slides

<script async class="speakerdeck-embed" data-id="d4fc94b2d32d4e6baa6e185e380c634d" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

Note: I was wrong about my statements in the video that "Ruby never releases memory". For more information you can read about how it does free memory very slowly in [How Ruby uses memory](http://www.sitepoint.com/ruby-uses-memory/).
