---
layout: post
title: "Going the Distance - How Levenshtein Spelling Suggestion Algorithm Works"
date: '2014-12-27 08:00:00'
published: true
tags: algorithms, levenshtein, spelling, ruby, videos
---

I'm not what you would cosider an algorithm guy, but after needing to use a bit of spell checking in some code, I became fascinated with the [Levenshtein distance](https://en.wikipedia.org/wiki/Levenshtein_distance). I found plenty of resources explaining what it did, I also found plenty of resources with example implementations. What I couldn't find were any really simple explanations for exactly HOW it worked.

I'm a big believer in conference driven development, so I signed up to give some talks on the algorithm and then got to work dissecting it. To help I
[kept distance measurement notes](https://github.com/schneems/going_the_distance) and wrote [scripts that visualized different distance measurement methods](https://github.com/schneems/going_the_distance/tree/master/lib). The talk was a huge successs, I ended up giving it in [RubyKaigi](https://rubykaigi.org/2014/presentation/S-RichardSchneeman) in Japan, [Rails Pacific](https://railspacific.com/#sessions) in Taiwan and [RubyConf](https://rubyconf.org/program#prop_588) in San Diego.

I could tell you all about it, but I would rather you watched the video.

## Video

<iframe width="560" height="315" src="//www.youtube.com/embed/PcINjHjIllk" frameborder="0" allowfullscreen></iframe>

Note: While there are 3 versions of me giving this talk, this is the only time I made the audience do the CanCan.

## Slides

You can also review the slides:

<script async class="speakerdeck-embed" data-id="5e8cd5f024da01321f5106622b3e4870" data-ratio="1.33333333333333" src="//speakerdeck.com/assets/embed.js"></script>

## Notes and Scripts

[Download and Run my scripts](https://github.com/schneems/going_the_distance).

## Fin

I learned a ton presenting this unique and useful algorithm, I highly encourage you to not only use these resources but to also explore the algorithm world.

---
If you like algorithms, distance measurements, or Ruby things follow [@schneems](https://ruby.social/@Schneems)
