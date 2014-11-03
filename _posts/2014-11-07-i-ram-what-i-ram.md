---
layout: post
title: "I RAM what I RAM: Smaller App Footprints through Benchmarking"
date: '2014-11-07 08:00:00'
published: true
tags: performance, benchmarking, ruby
---

America is in the middle of an obesity epidemic, and your Ruby app might be suffering from bloat. While people suffer from overeating, and lack of exercise apps get bigger for other reasons. One of the largest memory sinks in a Ruby app can come not from your code, but from libraries you require. Most developers have no idea what kind of a penalty they incur by adding in a library, and for good reason. Until now, it's been hard to measure.

Recently I introduced [Derailed Benchmarks to performance test your Rails apps](https://github.com/schneems/derailed_benchmarks) and was able to find that default Rails apps were using 36 percent  more RAM than they needed to be. How? I patched [Kernel's require method](https://github.com/schneems/derailed_benchmarks/blob/master/lib/derailed_benchmarks/tasks.rb#L134-L165) so that we take a memory measurement of the current Ruby process before and after we require a file. Next, I sort those nested requires and output the data. After setting up the benchmarks on a brand-new Rails app I was able to run:

```
$ bundle exec rake -f perf.rake perf:require_bench
```

This output the total memory usage and breaks down usage by require:

```
application: 60.8242 mb
  mail: 39.2734 mb
    mail/parsers: 19.2461 mb
      mail/parsers/ragel: 18.7031 mb
        mail/parsers/ragel/ruby: 18.6797 mb
          mail/parsers/ragel/ruby/machines/address_lists_machine: 7.2734 mb
          mail/parsers/ragel/ruby/machines/received_machine: 4.7578 mb
          mail/parsers/ragel/ruby/machines/envelope_from_machine: 2.2305 mb
          mail/parsers/ragel/ruby/machines/message_ids_machine: 1.5625 mb
          mail/parsers/ragel/ruby/machines/date_time_machine: 0.5977 mb
          mail/parsers/ragel/ruby/machines/content_disposition_machine: 0.4961 mb
          mail/parsers/ragel/ruby/machines/content_type_machine: 0.4648 mb
          mail/parsers/ragel/ruby/machines/content_location_machine: 0.3359 mb
          mail/parsers/ragel/ruby/machines/content_transfer_encoding_machine: 0.3281 mb
          mail/parsers/ragel/ruby/machines/phrase_lists_machine: 0.3086 mb
    mime/types: 18.4922 mb
    mail/field: 0.3125 mb
```

In this example, our app is using 60 mb of RSS memory and a whopping 39 mb of that is due to requiring the mail (2.6.1) gem. You can see most of the memory use comes from `mail/parsers`. With this info I [opened an issue on the Mail gem](https://github.com/mikel/mail/issues/812) where we figured out the extra memory came from switching the parser (used when your app receives and needs to parse email). The switch increased the speed dramatically but also made the gem's footprint larger. After talking about options, we decided that it didn't make sense to load this code by default. Most applications don't need to parse incoming emails.

Moving this code to be lazily loaded in [mikel/mail#817](https://github.com/mikel/mail/pull/817) (thanks, Benjamin Fleischer and Michael Grosser) we see an enormous savings:


```
application: 38.3477 mb
  mail: 19.0938 mb
    mime/types: 17.6016 mb
    mail/field: 0.4141 mb
    mail/message: 0.3398 mb
```

The parsers aren't loaded and memory use is down in the total app by 36 percent with the patch [Mikel pushed mail version 2.6.3](https://github.com/mikel/mail/pull/817#issuecomment-61474145) and now you can enjoy these memory savings right from the comfort of your own Rails app.

## Update Mail to 2.6.3 or Higher

To see these cost savings in your app all you have to do is run:

```
$ gem install mail
Successfully installed mail-2.6.3
$ bundle update mail
```

Boom, now your app is 36 percent lighter on boot up. You may be wondering about this line:

```
mime/types: 17.6016 mb
```

The mail gem depends on the [mime-types gem](https://github.com/halostatue/mime-types/). When loaded, this gem accounts for `17.6/60 # => 29%` of overall application size. Without it, the mail gem would be sitting pretty at only around 2mb of require memory instead of 19mb. Can we get rid of this mime/types gem? Maybe defer loading such large files or somehow decrease the require cost?

Unfortunately, we cannot. The mime/types gem loads a ton of constants into memory that are never garbage collected. This is on purpose as the gem is designed to be fast. When you need to look up a mime-type, you expect it to be already defined. However, this isn't exactly all bad though.



## Speed versus RAM

Often when we think of an app that is maxing out its available RAM, we think of a slow app crawling along. In reality, applications are generally greedy when it comes to RAM and can see benefits by calculating and storing values so the computer doesn't have to do the same calculations twice. On a very high level, this is how Ruby 2.1 was able to see a massive speed increase. It uses slightly more memory (by garbage collecting fewer objects) but it runs dramatically faster. These are considerations programmers must take into account when writing algorithms and using libraries. Just because you see a library using lots of RAM doesn't mean it is slow, it may have been done on purpose.

That being said; you want to make sure the tradeoffs are worth it. In the case of mime-types maybe we can come up with some way to lazily fetch mime-types or declare the ones we think we'll need. Neither of these clearly wins as they would either introduce additional complexity or make an app slower. These types of tradeoffs are at the heart of performance tuning.

## Benchmarking is Performance Visibility

Benchmarking is the only way to know if performance tradeoffs are worth while. Run real-world code and take real measurements. I explicitly designed [derailed benchmarks](https://github.com/schneems/derailed_benchmarks) so that they can be run on any Rails app (with perhaps a bit of tweaking on the app side). If you don't know why your application is taking up a ton of RAM at boot time, you won't know where to start optimizing.

Many Ruby programmers follow the Red/Green/Refactor methodology. They write a failing test, write code until the test turns green,  after which, they refactor their code to be maintainable and easier to work with. Similarly when performance-tuning an application, if you have a set of repeatable benchmarks, you can take measurements before and after your patches, giving you instant feedback as to whether things got better and by how much.

Now here's your homework: upgrade to Mail 2.6.3 or above and start benchmarking your application. For extra credit, you can work with the libraries you use every day to make them faster for everyone! Don't forget to include your benchmark methodology and results.

---
If you like high-speed applications, benchmarking Rails or photos of dachshunds follow [@schneems](https://twitter.com/schneems)

