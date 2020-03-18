---
title: "Lies, Damned Lies, and Averages: Perc50, Perc95 explained for Programmers"
layout: post
published: true
date: 2020-03-17
permalink: /2020/03/17/lies-damned-lies-and-averages-perc50-perc95-explained-for-programmers/
image_url: https://www.dropbox.com/s/mdghbzitg3pijw8/Screenshot%202019-12-24%2013.10.56.png?raw=1
categories:
    - ruby
    - statistics
---

I got a customer ticket the other day that said they weren't worried about response time because "New Relic is showing our average response time to be sub 200ms". Sounds good, right? Well, when it comes to performance - you can't use the average if you don't know the distribution. It's usually best to use the median, which is also perc50, though you'll also want to look at your long tail of responses. If you're not following, then this post is for you.

## Normal distributions and you

What is a distribution? It's the shape of the values that you get when you plot them in a histogram. Mainly you're looking at how frequently does a number show up in your data set. If that sounds like a "bell curve," then you're right, but only for a normal distribution. Here's a histogram of values generated from this code:

```ruby
require 'rubystats'

average = 178
std_dev = 10
rand = Rubystats::NormalDistribution.new(average, std_dev)

1000.times.each { puts rand.rng }
```

> Got the idea of using the `rubystats` gem from this [post on generating random numbers for in Ruby](https://blog.appsignal.com/2018/07/31/generating-random-numbers-in-ruby.html).

![](https://www.dropbox.com/s/cj8l6w7ya50e0kd/Screenshot%202019-12-24%2013.06.01.png?raw=1)

With a normal distribution, the "median" is roughly the same as the average. In the data set I used to generate this image the average was 177.8 and the median is 178.1. You might recall that the median is essentially the middle point of the sorted data set.

If the average and median are pretty close, why would I recommend you not use averages? Well, they're only close if you've got a particular set of distributions such as a normal or flat distribution. Here are some numbers I pulled from a recent benchmark:

![](https://www.dropbox.com/s/mdghbzitg3pijw8/Screenshot%202019-12-24%2013.10.56.png?raw=1)

In this case, red and blue represent different measurements of code changes before and after. You can see the shape of the distributions is different. If you use an average here, then the values are pretty far apart. The min and max values have a difference in this data set of 0.78 (seconds), and the difference between median and average is 0.17 (seconds). That means comparing average values instead of medians means that the values would be off by about 17% of the entire range, which is not great.

The blue and red graph above showing the non-normal distribution is pretty standard in web performance. Most of the requests are clustered around common values, but then there are a tiny fraction of requests that are significant outliers. In this data set, you can see the median for red is about 3.18, while it's maximum value is almost 4. In an ideal world we'll be able to see a histogram of values while comparing performance, but that's not always possible. The key in this section is to know that web performance likely does not follow a normal distribution, and using an average, to sum up, those calculations are a terrible idea.

## Perc50 and Perc95

Previously I mentioned "perc50" and "perc95", what exactly do those terms mean? The term "perc" stands for percentage, and the number indicates what percentage. The term "perc50" indicates you're looking at a number where 50% of requests are at or below that number. Here's how that looks in code:

```ruby
def perc(number, values)
  sorted_values = values.sort
  index = values.size * (number / 100.0)

  raise "Not a valid perc number #{number}" if number > 100 || number < 0

  return (sorted_values[index.ceil] + sorted_values[index.floor]) / 2.0
end
```

If we use this to find perc50 of the normal distribution we generated earlier, then it gives a similar answer:

```ruby
require 'rubystats'

average = 178
std_dev = 10
rand = Rubystats::NormalDistribution.new(average, std_dev)

normal_values = 1000.times.map { rand.rng }

puts perc(50, normal_values)
# => 178.1
```

How would this look on a histogram? Here's how I think of it:

![](https://www.dropbox.com/s/36tp52r8gzsruy7/Screenshot%202019-12-24%2013.39.53.png?raw=1)

Essentially that value `178.1` is saying that 50% of items in our array will be that value or less. When you increase to perc95 here's what it would look like:

```ruby
perc(95, normal_values)
# => 194.9
```

![](https://www.dropbox.com/s/roudr2s9xfe0yw9/Screenshot%202019-12-24%2013.42.49.png?raw=1)

Here we're saying that 95% of all values are `194.9` or lower.

## Heroku response time percentiles

When you look at your Heroku dashboard, you'll get a perc50, perc95, perc99, and "max" values. The idea here is to give you a snapshot of the distribution of your data. Here's a screenshot of my app [CodeTriage which helps people contribute to open source](https://www.codetriage.com):

![](https://www.dropbox.com/s/9cb2zap5jd0756y/Screenshot%202019-12-24%2013.45.34.png?raw=1)

The median is lightning fast at 47ms, so at least half of all requests are that fast (or faster). But it looks like we've got a pretty long tail, perc95 is more than double our median and perc99 is more than six times our median. The "max" value (which is essential perc100) is even worse. When you're visualizing these numbers, you would imagine a clustered peak right around 47ms and then a really wide graph that ended at 3,071ms.

What this says to me is that, on average, my app is pretty fast. But at the fringes, people are waiting multiple seconds just to get a response from the server.

## Lies and averages

In the case of my customer, they were absolutely right that their average was perfectly fine. But what they didn't see is their perc95 was in the 10s of seconds. That is an eternity to wait for a page to render. While it's perhaps a bit disingenuous to say the average was a "lie," it was certainly not the best representation of their data.

The next time someone gives you a single numerical answer for how fast something is, ask if it's an average or a median or something else. For bonus points, ask for the distribution or a histogram. As humans we tend to prefer reassuring lies over hard truths and this certainly applies to benchmarks and profiling data. By learning about these essential measurements, you're arming yourself to have a better understanding of your code, your performance characteristics, and the world.

> If you liked this post, you might also like [Statistical Literacy and You: An Intro for Programmers](https://www.schneems.com/2016/11/14/statistical-lit.html).

