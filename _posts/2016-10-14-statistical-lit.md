---
layout: post
title: "Statistical Literacy and You: An Intro for Programmers"
date: 2016-10-14
published: true
author_name: Richard Schneeman
author_url: https://twitter.com/schneems
---

America. World. Let's talk about statistics. Statistical literacy is a giant gaping hole in humanity's collective toolkit, and it matters a lot more when your job relies heavily on numbers. Take programmers for example - as programmers, we love determinism and don't do well with uncertainty. Yet, we work with inherently uncertain systems. How we build programs to deal with anomalies, how we generate and present data can both be greatly improved with a few basic statistical methods. If you were confused about the Cubs winning the world series, or how the polls in the US Presidential election could be "so wrong", keep reading.

## An Ode to Error

The first problem with trying to use numbers to predict something is error. Most people have a negative connotation with errors or don't know how to use them. To them, errors indicate a bad thing that should be avoided. That's the problem. One example from Nate Silver's book (which I recommend as follow-up to this post) [The Signal and the Noise](https://www.amazon.com/Signal-Noise-Many-Predictions-Fail-but/dp/0143125087) comes when a town is told that rainfall will be [49 feet](https://en.wikipedia.org/wiki/1997_Red_River_flood), which is not enough to overtake their flood barriers (built to withstand 51 feet of flooding). When the rain came, it went over the barrier and eventually came to 54 feet, 3 feet above the levee and 5 feet above what was predicted. 75% of homes were damaged or destroyed.

As a result of the low estimate, few people left the town, bought flood insurance or took any additional protections against the threat. They thought that the 49-foot estimate was a "maximum" or that it was extremely accurate. It turns out that the people doing the rainfall calculations knew their estimate was good within a range plus or minus 9 feet, which gave a 35% chance of flooding. Why didn't they give that information to the people of the town? They were afraid the people wouldn't understand and lose faith in the agency. Why didn't the people of the town demand to know the error range? The people didn't know enough to demand more so they took the number they were given and made their own assumptions. Statistical literacy is important.

Some of this may seem obvious, yet when we are given numbers we are rarely given an error range. We see a single number is given, for example, a 20% chance of rain. We rarely get the second crucial piece of data, that is the error. It may rain only 3 days out of 100 or it may rain 30. We as consumers of data can make better predictions with more data. Errors in our data isn't a bad thing, it's more data about the data. If you are planning a picnic the difference between a 20-30% chance of rain might not be much to work around, but what if you're trying to coordinate a multi-million dollar outdoor movie shoot, that extra 10% could cost you a lot of cash. Errors are good and should be celebrated. When we get numbers we should be asking how confident are those numbers. What range could they be off by? If the person giving you data can't answer that question then you don't have data, you have a guess in numerical form.

> If you're familiar with stats, you might know of error as ["standard deviation" or stdev](https://en.wikipedia.org/wiki/Standard_deviation). If you work with stats a lot, you need to understand how it's calculated. This article is more of a primer, so I refer to it as error.

## Error and the Election

Error is where most people misunderstood the polls that were presented at sites like [538](http://fivethirtyeight.com/). When you view the average, you also saw a bar representing the amount of error in the guess. The larger the bar, the larger the uncertainty. Too many people took one look at the average and immediately declared a winner. This was a bad call. If you follow Nate's writing he very firmly said that there was an equal chance of a Trump electoral win with a popular vote loss as there was a blow-out by Clinton (with an 8 percentage point lead). This is because she was largely polling around 3-4% with an uncertainty of 3% so she could have been up 7% or down as we saw, to slightly under 0% (in the electoral college) which turned out to be the case.

In 2012, Nate Silver correctly called 50 out of 50 states in the presidential election. By his own words, this was pure luck. Not that he's being humble as he was talking about being statistically lucky. One model, Florida, had a high error rate and was hovering around the 50% mark for both candidates. Meaning, that the data basically told us that there wasn't enough data. He guessed and got lucky. The media largely misread this and misrepresented his luck as an indication that he was an infallible oracle, who gazed into his crystal ball built of numbers and simulations. These types of representations are harmful. We can still celebrate his achievement of precisely predicting all the other races and even celebrate his luck in that one state, without minimizing the role of error in the forecast.

One of the ways that people get better at estimating things is the act of estimating and then re-evaluating their methods based on performance. If the actual results end up being outside of your estimated error range, then it wasn't a very good estimate at all. Rather than cry foul that a poll was "rigged" or that someone sold us snake oil, the only way we can get better as a community is to review the info with an open mind and open error rates. 538 does a good job of presenting their error rates in their model, they even talk about it extensively in blog posts and tweets. What we don't have is a general public who is capable of internalizing and consuming statistical error in a meaningful way.

## Programmer error

How can you as a programmer use error? One of the most prominent ways in my life is in performance calculations. The `benchmark/ips` gem gives you error reported by default:

```
require 'benchmark/ips'

def slow
  100.times { |i| i + 1 }
end

def fast
  1.times { |i| i + 1 }
end

Benchmark.ips do |x|
  x.report("slow") { slow }
  x.report("fast") { fast }
  x.compare!
end

# Warming up --------------------------------------
#                 slow    19.658k i/100ms
#                 fast   208.907k i/100ms
# Calculating -------------------------------------
#                 slow    196.468k (±10.3%) i/s -    982.900k in   5.061751s
#                 fast      5.329M (±12.1%) i/s -     26.322M in   5.023471s

# Comparison:
#                 fast:  5328510.2 i/s
#                 slow:   196468.1 i/s - 27.12x  slower
```

Here we see that the `fast` method is 27 times faster than `slow`. It can run 5.32 million iterations per second compared to "slow"-s measly 196 thousand. The error rate is right next to each metric (`±10.3%` for slow). This means that it can conceivably run as fast as 216K iterations or as slow as 175K iterations. This isn't that important when there is a clear winner, but is important when things are close:

```
Benchmark.ips do |x|
  x.report("slow    ") { slow }
  x.report("slow too") { slow }
  x.compare!
end

# Warming up --------------------------------------
#             slow        20.061k i/100ms
#             slow too    20.338k i/100ms
# Calculating -------------------------------------
#             slow        212.392k (± 7.5%) i/s -      1.063M in   5.040024s
#             slow too    208.185k (± 8.5%) i/s -      1.037M in   5.028060s

# Comparison:
#             slow    :   212392.3 i/s
#             slow too:   208185.1 i/s - same-ish: difference falls within error
```

Here even though "slow" wins over "slow too" it is important that we look at the error. Here, there's not a meaningful difference between the two and there shouldn't be because we are using the same method in both.

Key point: when using numbers to compare things, error matters. Tell your friends, tell your family, tell your co-workers. From now on when someone gives you a number, (politely) ask for the error.

## It's about Ethics in Data Journalism

As programmers, we generate a lot of data. Often we present raw data such as the number of likes or a dashboard of new user signups. Very seldom do we consider the ethical implications of how we are producing and showing that data.

One of my favorite "average" stories I heard on [99 percent invisible](http://99percentinvisible.org/) was about the Vietnam war. Pilots were dying at a rapid rate, not because the enemy was shooting them down but because of freak accidents, which turned out to be not so freakishly uncommon. It turns out that the cockpit was built for an "average" pilot size, which might seem reasonable. However, they didn't take into account that while there might be an average height or an average arm length, none of the pilots flying the planes were perfectly average. There is error in the average, of course, some pilots might be taller which prevented them from pulling all the way back on the flight stick. Some of them might have had shorter arms, preventing them from reaching a critical switch on the dash quickly. For the Air Force, this seemingly benign lack of error reporting was causing very real deaths.

The solution to the pilot problem was to introduce adjustable components. With adjustable seating, the number of life ending accidents come to an abrupt halt. In this case making a more accurate estimate wasn't possible but instead, the system had to change.

Imagine how many lives could have been saved if the people presenting the measurements took the time to also report how un-average most of their measurements were. They could have made this even more obvious by making models, maybe showing the average hand size from smallest to largest.

We already saw earlier how a missing error rate gave a town a false sense of flood protection. If someone presenting that data produced a graph that showed how much higher or lower than the average could have been, lives and property could have been saved. Homes could have been fortified and the rates of flood insurance purchase surely would have gone up.

Most of the data we work with aren't informing life or death decisions but that doesn't mean we should hold it to a lesser standard. By normalizing the presence of error data, we consumers of that data can make better choices. I also think we'll see a snowball effect, with the more error rates reported, the more people become familiar with how to use them and the more they will look for them. Until your consumers start asking for it, we'll have to do the hard work and figure out the best places to add this extra error info.

## Re-normalizing a Denormalized Culture of Statistics

The vast majority of humanity's exposure to statistical data is via the National Weather Service. Percentages fill up mornings with coffee and help shape weekend plans and weddings. Have you ever wondered why when there is a 20% chance of rain, it is almost a sure thing that it won't rain? While our government gives our weather data for free, most reporting agencies (such as your local weather broadcaster, The Weather Channel, or Dark Sky) will interpret it to "add value". This largely means that they add in a "wet bias".

In the case of weather forecasts, we often don't care if the high temperature is off by one or two degrees, a little error is accepted and generally ignored. However, when it rains on a day with 20% chance of rain, people generally think that the weather was "wrong". Statistically speaking it should rain 20 days for every 100 that are forecast with a 20% chance - this is 1 in 5. Yet if it rained 1 day out of a 5 day work week with a 20% chance, you would feel cheated.

Forecasters "enhance" the data then to make themselves seem more right more often. People generally don't care as much if rain is predicted but none comes. So when a forecast is low, say 5%, they will report it as 20% so when it does rain for those 5 days out of 100, it doesn't seem like the forecast was nearly as wrong.

Forecasters will also back off of aggressive estimates. Rarely do you see a 100% chance of rain (unless it's actively raining at the time of the report). Instead, you'll see a 90% chance, to account for the error in the model. If on the 1 day that it doesn't rain out of 100 with a 100% chance of rain, then forecasters won't seem stupid.

## Wet biased poll-conflation

While this might seem useful, it also gives the average statistics consumer a false idea about what those numbers mean. At one point, Hillary was predicted to have an 80% chance of winning. If you're only consuming adjusted weather reports, you might translate that to think she has a 99% chance of winning. When polls closed and 538 rolled out their final prediction before general voting, Hillary was around 66%. That means out of 100 elections, Trump would win 33% of these, which is not a trivial number. Many casual observers and pundits falsely interpreted these numbers.

## Getting better

One way that 538 tends to be better than your average poll is that they are averaged polls. One way to account for random error is to add someone else's random error, and if it's truly random then it will cancel out. Even with this optimization, their models aren't 100% perfect.

They run multiple simulations of a vote using a distribution based on the error from the average received by the polls. They do this many many times and see where the data converges. It's not perfect but that's not the point. Elections happen so infrequently that it is very hard to get enough data to brute force gains. We mentioned weather earlier due to increased data collection and computing power, so weather forecasts have gotten much better. For other estimations where data isn't as plentiful and where we have less opportunity to check our assumptions, it is much harder to make progress.

As you go about your day-to-day life, try to take note of the numbers that are being presented to you. How accurate are they? Could you make better decisions with some error info? If you speak up and let those that show you information that error is important we can start to be collectively more conscious.

If you find these concepts interesting and want to dig deeper, I recommend ["The Signal and the Noise"](https://www.amazon.com/Signal-Noise-Many-Predictions-Fail-but/dp/0143125087) by Nate Silver.

