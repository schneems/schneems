---
title: "The Four Year Typo"
layout: post
published: true
date: 2017-04-19
permalink: /2017/04/19/the-four-year-typo/
categories:
    - ruby
---

I'm a horrible speller. I often joke that I got into programming because it doesn't matter how you spell your variables, as long as you spell them consistently. Even so, I spend a good portion of my days writing: writing docs, writing emails, writing commit messages, writing issue comments, and of course writing blogs. Before I publish an article, I run my work by an editor, which makes this typo even more exceptional.

I got a note about a typo on a [Devcenter article on Rails 5.x](https://devcenter.heroku.com/articles/getting-started-with-rails5) that I maintain. This article published over a year ago has had 4 different editors/contributors and 19 revisions. I can't give out numbers but this article has had A LOT of page views. It is the number one article I maintain by a huge margin, it was pretty surprising when I opened this note and it mentioned I had a typo.

> and if you app depends on a gem from one of these groups to run, you should move it out of the group

Did you catch it? I didn't. Here it is spelled out:

> and if you[r] app depends on a gem from one of these groups to run, you should move it out of the group

I checked and sure enough, that typo has been there from the original version of the doc. You might ask "but Rails 5 has only been out for a year, how was this typo alive for 4?". I copied the 5.x guide from the 4.x guide and sure enough, the typo in the Rails 4.x guide has the typo going back for 4 years. The 4.x document had an additional 7 contributors who didn't notice.

I messaged the reporter to thank them for the find and explained how the typo had gone unnoticed for so long, and this was their response:

> You're welcome! I'm learning to create a rails server so I had to be extra thorough 👌

Epic. I love this. I've read through these docs probably hundreds of times. I wrote an [automated build system](https://github.com/schneems/rundoc) to compile and test these docs. I've spent a good chunk of time refining and tweaking these articles. But I didn't stop and look close enough for FOUR FREAKING YEARS to see what was right in front of me. There is always value in a fresh perspective. There is value in every contributor regardless of skill level. I've been at this Ruby programming thing for 10+ years, and someone just beginning Rails development can still reach out and help. You can make an impact on whatever you like, just get involved.

My wife posted this recently which has been making me think:

 <blockquote class="instagram-media" data-instgrm-captioned data-instgrm-version="7" style=" background:#FFF; border:0; border-radius:3px; box-shadow:0 0 1px 0 rgba(0,0,0,0.5),0 1px 10px 0 rgba(0,0,0,0.15); margin: 1px; max-width:658px; padding:0; width:99.375%; width:-webkit-calc(100% - 2px); width:calc(100% - 2px);"><div style="padding:8px;"> <div style=" background:#F8F8F8; line-height:0; margin-top:40px; padding:50.0% 0; text-align:center; width:100%;"> <div style=" background:url(data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACwAAAAsCAMAAAApWqozAAAABGdBTUEAALGPC/xhBQAAAAFzUkdCAK7OHOkAAAAMUExURczMzPf399fX1+bm5mzY9AMAAADiSURBVDjLvZXbEsMgCES5/P8/t9FuRVCRmU73JWlzosgSIIZURCjo/ad+EQJJB4Hv8BFt+IDpQoCx1wjOSBFhh2XssxEIYn3ulI/6MNReE07UIWJEv8UEOWDS88LY97kqyTliJKKtuYBbruAyVh5wOHiXmpi5we58Ek028czwyuQdLKPG1Bkb4NnM+VeAnfHqn1k4+GPT6uGQcvu2h2OVuIf/gWUFyy8OWEpdyZSa3aVCqpVoVvzZZ2VTnn2wU8qzVjDDetO90GSy9mVLqtgYSy231MxrY6I2gGqjrTY0L8fxCxfCBbhWrsYYAAAAAElFTkSuQmCC); display:block; height:44px; margin:0 auto -44px; position:relative; top:-22px; width:44px;"></div></div> <p style=" margin:8px 0 0 0; padding:0 4px;"> <a href="https://www.instagram.com/p/BR90RoIggf3/" style=" color:#000; font-family:Arial,sans-serif; font-size:14px; font-style:normal; font-weight:normal; line-height:17px; text-decoration:none; word-wrap:break-word;" target="_blank">This kid makes me slow down, look at the bird, look at the boat, take an hour to walk a mile. I had thought I was supposed to be the one showing him the world...turns out he&#39;s got quite a world to show me.</a></p> <p style=" color:#c9c8cd; font-family:Arial,sans-serif; font-size:14px; line-height:17px; margin-bottom:0; margin-top:8px; overflow:hidden; padding:8px 0 7px; text-align:center; text-overflow:ellipsis; white-space:nowrap;">A post shared by Ruby Ku (@rubyku) on <time style=" font-family:Arial,sans-serif; font-size:14px; line-height:17px;" datetime="2017-03-23T03:40:24+00:00">Mar 22, 2017 at 8:40pm PDT</time></p></div></blockquote> <script async defer src="//platform.instagram.com/en_US/embeds.js"></script>

I aspire to live each day through the eyes of a beginner, to catch the moment that might otherwise go unnoticed. I want to challenge myself not just to get to the destinations, but to appreciate the journeys along the way. I think we all need a fresh perspective, I'm just hoping my next one won't take 4 more years.
