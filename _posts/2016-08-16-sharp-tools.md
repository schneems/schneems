---
layout: post
title: "Sharp Tools"
date: 2016-08-16
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

Developers love borrowing concepts from other trades to describe their work. We especially enjoy to comparing ourselves to woodworkers. The phrase "sharp tools" brings to mind a chisel chopping out an oak mortise, a hatchet splitting a well seasoned timber, and a sawmill slicing a tree into boards. Programmers use the phrase "sharp tools" to refer to tradeoff of productivity and the bloodlust and gore that awaits the careless worker. I'm a sometimes woodworker and a full time programmer and I have used truly sharp tools for both.

<blockquote class="twitter-tweet" data-lang="en"><p lang="en" dir="ltr">“Sharp tools should exist” they will hear me screaming, as they try to drag me away from the computer.</p>&mdash; The Moment Seizes (@samphippen) <a href="https://twitter.com/samphippen/status/734513408771543040">May 22, 2016</a></blockquote>
<script async src="//platform.twitter.com/widgets.js" charset="utf-8"></script>

There are two wood tools that I keep "shaving" sharp in my shop - chisels and plane blades. You probably know what a chisel is, but lots of people might be unfamiliar with a plane. It is designed to shave off bits of wood in impossibly small increments, the best can get wood shavings in 0.001 inch thicknesses. It makes more sense to see it, than to have it described:

<iframe width="560" height="315" src="https://www.youtube.com/embed/d6kOfcfnumY?t=1m55s" frameborder="0" allowfullscreen></iframe>

The blade on this device is razor sharp (literally), and it has to be. You can't see in the video, but this man, likely 180+ lbs, is putting his whole body weight to provide the forces necessary to separate the bonds and literally shave off a section of wood. If a tool is not sharp enough to shave arm hair, it's going to be much harder to make whispy thin curls of wood shavings:

<iframe width="560" height="315" src="https://www.youtube.com/embed/qqg0bWb_Gl8?t=3m12s" frameborder="0" allowfullscreen></iframe>

This is what sharp means to me. You can't buy sharp, you have to create it and maintain it. Sharp is a constant state of maintenance and honing. These tools are a joy to use. The tool does it's job remarkably well. A sharp tool is one that works with you, a dull tool constantly reminds you of its shortcomings and fights you every step along the way.

There is a fallacy common to "advanced" developers that tools designed to be "simple" or "easy" or "safe" are not sharp. They are "beginner's" tools. Some devs see a large framework and think themselves above it. They see complex tasks wrapped up in simple APIs and ask "where is the blood?". The association between effective devices and their carnage so interlinked that they cannot be separated.

While a [jointer plane](https://en.wikipedia.org/wiki/Jointer_plane) is a remarkably sharp device, I've never once cut myself while using it. This isn't a statement of skill, but rather a comment on the design of the device. It does everything I will it to, and more. Its clever design means that this razor sharp edge is barely protruding from a safe surface. When using it your hands are on the opposite end side of the body. Here's a view from the business end:

![](https://www.dropbox.com/s/njjn7jn6b1gg05j/lie-nielsen-number-4-throat.jpg?raw=1){:class="b-lazy"}

You can see the blade sticking through the "throat" of the plane. This device provides me with safety and a simple interface, it certainly isn't "just for beginners". This design is an evolution of planes over centuries of use. This safety does not diminish their usefulness to users of all skill levels. In fact, while a beginner might use this tool unaware of the full feature set of the tool, only a truly advanced user can appreciate the subtleties.

> Just because there's no blood doesn't mean your tool isn't sharp

Pain and difficulty of use do not indicate an "advanced" tool. Developers of all levels can appreciate and consume a good API. I've never met someone who complained because the documentation was too well thought out. I've never been upset about an error that was too helpful. A good tool guides and compliments the worker.

This isn't to say that all sharp tools are also bloodless. On the woodworking forums there's a number of posts reminding us that chisels can send you to the emergency room as fast as a power tool. Like a gun, don't point the dangerous end at anything you're attached to. Another tool I own is a "draw knife". You use it by pointing the sharp end towards your body and pulling. It is probably the scariest thing in my shop:

![](https://www.dropbox.com/s/amwdnaeo2qild1d/draw-knife.jpg?raw=1){:class="b-lazy"}

This brings me to the second, somewhat contradictory fallacy of "advanced" developers - they think that if a tool is simple that it must inherently hiding painful secrets.

A common example here is an ORM. On the surface they can seem very simple; automating tedious tasks. If you've used one long enough you've been bitten by it. A recent example for me was bringing down a production database. How? I used the postgres `int` datatype instead of `bigint` for a primary key. I eventually created so many records that I ran out of numbers and the database started throwing errors. Migrating all the entries locked the database for a few hours:

```sql
ALTER TABLE the_table ALTER COLUMN id SET DATA TYPE bigint
```

Why did this happen? I used a DSL provided by my ORM for creating the schema and it wasn't obvious that it was using `int` by default. I know what you're thinking and no, it wasn't Active Record. While the ORM was originally super fast in helping me define and migrate my schema, when I slipped with it, it wasn't pleasant.

![](https://i.imgur.com/FPrM4o6.gif){:class="b-lazy"}

This was an extremely painful experience. As humans we learn from pain, we try to avoid it. The longer you've been programming the more adverse to specific pain points you become.

> "Fool me once, shame on you, use an ORM again, shame on me."

This type of mentality ends up with a massive case of [NIH](https://en.wikipedia.org/wiki/Not_invented_here). The fallacy is equating the inherent pain caused to the ease of use with simplicity of the tool. The solution in the user's mind is clear. If we make something more complex and explicit we wouldn't have hit that pain. Either people will go to hand crafted artisanal SQL, or to a smaller home brew ORM. Unfortunately it's usually too late when they realize their micro library has a SQL injection vulnerability, or another critical mistake. More blood.

If simplicity hides pain, and complexity also hides pain, what's the solution?

To avoid pain...find where pain lives and take steps to avoid it.

While working in the shop I wear canvas apron and use a bench that is bolted to the floor. I clamp my wood securely to the table. My tool might slip, but it's not compounded by additional failures.

In some cases you can modify a tool to your needs. For example you can use the drawknife for cutting corners on square stock. For this one off task you can attach bronze drawknife guides:

![](https://www.dropbox.com/s/2tivwmzh5y59yvx/draw-knife-guides.jpg?raw=1){:class="b-lazy"}

It won't prevent all nicks and cuts, but it will provide an extra layer of safety when things do go wrong. It also helps us do this one task faster than we could without any protection at all. A good tool helps to guide our work.

In the case of the ORM, instead of giving up we can find the pain and fix it. For this case we can [default foreign key columns to bigserial](https://github.com/rails/rails/pull/24962). This doesn't make the ORM a "tool for beginners" it makes it a tool for everyone.

> On a sidenote you can use [pg:diagnose on Heroku](https://devcenter.heroku.com/articles/heroku-postgresql#pg-diagnose) to see if you're using an integer primary key and are running out of numbers.

The difference between an "advanced" and a "beginner" programmer is not the tools we choose. The difference is that when a senior programmer experiences pain, they dig in with a retrospective. Why did we use that tool incorrectly? Was there documentation that explained that problem? Why not? Can we make this tool safer without sacrificing performance or usability? Yes? Let's raise awareness by opening an issue. Fix it by opening a pull request. At the very least write some docs.

An example of this process could be my PR [preventing destructive actions in production databases](https://github.com/rails/rails/pull/22967). If there's not an easy technical solution, maybe you need to [grab a soap box and raise awareness](https://blog.codeship.com/optimists-guide-pessimistic-library-versioning/). A shoddy worker blames their tools, a good worker makes better tools.

There are times when we experience pain even with good documentation and safeguards. It doesn't mean bloodshed has to be avoided at all costs. It's natural to recoil when we hit pain. Seasoned developers can learn from that pain and reach deep into their tools to make them better. Their work isn't always selfless or charitable. It's not always about "giving back", if anything they are "fixing forwards". The next time they're tired and frustrated they'll be glad they spent the extra effort making sure that pointy corner was rounded.

The beauty of open source is that we can all learn from each other's mistakes. The tragedy is that so many people fail to realize they aren't alone and don't share their lessons. Some have never used a truly powerful "sharp" interface that is also effective and safe. Some have, but the experience was so seamless the presence of the tool wasn't even noticed. When such an interface is missing, they don't spend much time thinking of how to create it.

While using woodworking is fun for me, there is a mantra in the shop. Be present or be hurt. You might be the best worker in the world but if you go into the shop tired, upset, hungry, or drunk you'll be sorry. The same is true for programmers. We shrug exhaustion and wear it as a badge of honor. We drink beers at happy hour then get paged. We push our bodies and minds to such lengths that frustration doesn't even begin to describe our mental state. When we do this, we are all beginners. Either we only use tools when we're inspired and working at 100%, or we start accepting that sharp tools need to be forgiving of our mistakes. A good tool can be appreciated by the elite, a great tool can be appreciated by everyone.

Stay safe. Stay productive. Stay sharp.

---
If you like this post you might also enjoy [Do you Believe in Programming Magic?](https://blog.codeship.com/programming-magic/). You can get these and other articles like them [direct to your inbox](https://schneems.us3.list-manage.com/subscribe?u=a9095027126a1cf15c5062160&id=17dc267687).
