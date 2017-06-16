---
title: "Bayes is BAE"
layout: post
published: true
date: 2017-06-12
permalink: /2017/06/12/bayes-is-bae/
categories:
    - ruby
---

Before programming, before formal probability there was Bayes. He introduced the notion that multiple uncertain estimates which are related could be combined to form a more certain estimate. It turns out that this extremely simple idea has a profound impact on how we write programs and how we can think about life. The applications range from machine learning and robotics to determining cancer treatments. In this talk we'll take an in depth look at Bayes rule and how it can be applied to solve problems in programming and beyond.

This is the talk that I gave at RailsConf 2017. It's about math, probability and programming.

If you're interested in going down the deep end in probability and Kalman Filter's I hope you enjoy my talk.

## Video

<iframe width="560" height="315" src="https://www.youtube.com/embed/bQSzZrDDV80" frameborder="0" allowfullscreen></iframe>

> BTW watch conf videos at 1.5x speed. You'll thank me later.

## Slides

<script async class="speakerdeck-embed" data-id="26015c2545544d9d9d689f17a903bc43" data-ratio="1.77777777777778" src="//speakerdeck.com/assets/embed.js"></script>

> There's a lot of transitions and video which don't translate to export to PDF, also I have a technique of putting multiple slides of the same content in a row so that I can get different speaker notes without you knowing that i'm flipping slides. In sort the slides were meant to be presented, not viewed statically on the web, yet here we are.

## Transcript

What if you could predict the future? What if we all could? I'm here today to tell you ... That you can. We all can. We have the power to predict the future. The bad news, is that we're not very good at it. The good news? Is that even a bad prediction can tell us something about the future. Today, we will predict. Today, we will learn. Today, we will discover why Bayes is bae.

Introducing our protagonist, this is Thomas Bayes.

Thomas was born in 1701, maybe, we don't exactly know.

He was born to a town called Hertfordshire.

 No? No, close?

 Possibly, we can't know for certain.

 We don't actually even know what Bayes looked like.

 What we do know is that Bayes was a Presbyterian minister and a statistician. We also know that his most famous work was published, a paper, that gave us Bayes Rule, was not published until after his death. Before this he published two other papers. "The Diving Benevolence, or an Attempt to Prove That the Principal End of the Divine Providence and Government is the Happiness of his Creatures". Yes, that is one title. As well as, "An Introduction of the Doctrine of Fluxions, and a Defense of the Mathematicians Against the Objections of the Author of The Analyst". I like my titles a little bit shorter but everybody has different preferences.

Why do we care about this? Well, Bayes contributed significantly to probability with the formulation of Bayes Rule. Again, even though it wasn't published until after his death, let's travel back and put our minds in a commoner of the era. The year is 1720. Sweden and Prussia just signed the treaty of Stockholm. Anna Maria Mozart, the mother of the person who wrote the requiem that we just enjoyed, Wolfgang Amadeus Mozart, so not Mozart, but his mother was born in 1720. Statistics is all of the rage, as well as probabilities. At the time, we can know things like, "Given we know the umber of winning tickets at a raffle, what is the probability of any one given ticket will be a winner?"

In the 1720s, the book "Gulliver's Travels" was published. This is 45 years before the American revolution. 45 years before we went to battle with Britain and gained our independence. Also, in the 1720s, Easter Island is "discovered". People knew it was there before, but the Dutch didn't. I don't know if you know this, or if you've seen this, but there's actually a lot more to the statues. There's a lot more underneath the surface. Which is also very true of probability as well. See, what we knew, how to get the probability of a winning ticket, what we didn't know how to do was the inverse. An inverse probability says that, "Okay, well if we draw a 100 tickets and we know, and we find that ten of them are a winner, what does that say about the probability of drawing a winner?"

Well, in this case it's pretty simple. Ten are winners, we drew a 100 tickets, it's about 10 percent. What if we had fewer samples? What if we have one sample? We drew one ticket and it was a winner. Does that mean that a 100% of tickets are winners? Is that what we're going to guess?

The answer is no. We wouldn't guess that, well, maybe it's a really weird raffle but, I've not found any raffles that are like that. The reason why you were able to correctly answer that is because you can predict the future. Even if that prediction is wrong, not dead on, it's still better than making no prediction at all.

This was Bayes insight. That we can take two probability distributions that are related and even if they're both inaccurate, the result will be more accurate. We can do things with this such as machine learning and artificial intelligence. I'll be focusing on artificial intelligence in this talk.

I want to take a second and introduce myself. My name is Schneems, it's pronounced like schnapps, it's got the little fun `sch` at the beginning. I maintain sprockets, poorly.

I have commit to Rails as well as Puma and I'm also taking a Masters in CS at Georgia Tech with their online program. I went there for my Bachelors for a mechanical engineering degree and absolutely hated it. It was brutal and not very much fun. They're only charging me seven grand for the entire Masters program, so it's pretty cheap. Not a bad deal.

I work full time for a time-share company. It's basically time share with computers. That's what we do. You hopefully, some of you already know what Heroku is. Instead of pitching, or explaining Heroku, I'm going to explain some new features you might not have heard of. We have a thing introduced called Automatic Certificate Management. This will prevision a lets encrypt cert for your app and automatically rotate it every 90 days, which is pretty sweet. We also have SSL for free, and that was on all paid and [inaudible 00:06:55]. The SSL that we offer for free is what's known as SNI SSL. I don't know if you heard about the legislation that went through Congress that was like, "Hey, FCC, you can not protect people's privacy." Anybody hear about that?

Okay, yeah, so adding SSL onto your server is going to help your clients get a little bit of protection. The free version of SSL that we have, which is SNI, does leak the host name to your ISP. We also have an air-quotes "NSA grade SSL", which is an add-on that you have to add and then you also have to provision and maintain your own certificate. We have Heroku CI, which is continuing integration, it's in beta, you can give that a shot. Review apps, which I absolutely, positively love. Try these if you haven't. Every time you make a PR request, Heroku will automatically deploy a staging server just for that PR request. So you're like, "Hey, I fixed this CSS bug," it's like, "Did you really? Did you?" The person reviewing can click through, see an actual live deployed app, and verify that. That's it for the company I work for.

Typically, this would be the time when I do a little bit of self promotion. Typically, I would do something like promote the service that I run, called [CodeTriage](https://www.codetriage.com), which is the best place to get started contributing to open source. Since I'm not going to be talking about [CodeTriage](https://www.codetriage.com), instead what I want to talk about is the biggest problem our country faces. Especially, I come from Texas, and the state of Texas faces gerrymandering, which is awful and unlike [CodeTriage](https://www.codetriage.com), gerrymandering is very bad. Anyway, so this is gerrymandering. Basically, given a population, you could represent it perfectly and say, okay, well there are more blue squares than there are more red squares so we should have more blue districts than red districts. But, if you look all the way over on the side, you can create those districts in such a way that oh, magically, now there are more red districts.

This is where I live. This is the district in Texas that stretches from San Antonio to Austin. I don't know if you know but that's a really far away. Yeah, I mean like, just look at it. Seriously! Gerrymandering takes away your voice, and diminishes the power of your vote. I think we need country wide redistricting reforms and it's not just me who thinks this. My district was actually ruled illegal by the state of Texas, by the judicial branch. Unfortunately, an illegal district will not deter the people in charge of redistricting in Texas and they're refusing to hear any bills on the issue. You might say, wow, that's a really important issue, okay, what can I do?

I highly recommend looking up your state representatives. You have a house representative and a senate representative. Find them. Mine are Kirk Watson and Eddy Rodriguez, I have their phone numbers in my phone. Then, call them and let them know, like, "Hey, I care about redistricting and I care about gerrymandering and like, I want this to be an issue that we should push." You might say, "Oh, well is there more that I can do?" Well, there are local organizations. For example in Texas, there's [Degerrymander Texas](http://degerrymandertexas.org), which is a really long Twitter handle. They give guides and talk about current legislation and those types of things. Yeah, I just think that gerrymandering is very unpatriotic, un-Texan, it can be un-Arizonan too. No bias. It really just takes away the freedom to elect people who represent us.

So, okay, yeah, back to Bayes. Artificial intelligence. For this talk, I'm going to be talking about some examples for the grad course that I've been taking at Georgia Tech, where we've been using Bayes Rule for artificial intelligence with robotics. If you're not familiar, this is what a robot looks like:

Speaker 2:     We are robots.

Speaker 3:     The world is very different ever since the robotic uprising of the mid nineties. There is no more unhappiness.

Speaker 2:     Affirmative.


Okay, can I get the audio just like a little bit? Okay. There we go. When we have a robot and we need to get that robot somewhere, we need two things. We need to know where the robot is, and then we also need to have a plan on how to get them there. Robots don't see the world the same way we see them. They see them through sensors, and those sensors are unfortunately noisy, so they don't see the world perfectly clearly. Given the case that we have a robot and a really simple robot can move, let's say just right and left, if we take a measurement it will tell us about where it is. We can represent this by putting it on a graph and this is a normal distribution.

So, here we have a robot. It's at position zero, but we don't know for sure that it's at position zero. It could be further away, it could be all the way over at point six, but this is a lot less likely. It's not very probable. The more accurate our measurement, the steeper our curve will be. At this point in time, it's almost impossible that it would be at point six and it's much more likely that it would be a lot closer to point zero. So, a robot is an example of a low information state system. We could take thousands or hundreds of measurements of that robot as it's just sitting there and average them together, but what if our world is changing? What if there's other things impacting our sensors? Or, it's like hey, our robot needs to move and do things.

One of the things that we can do is use Bayes Rule. We can make a prediction and with that prediction, use it to increase the accuracy of the estimate of where the robot is. Previously, we thought we were at position zero, plus or minus some error. Well, then we can predict what the world would look like if we were to drive forwards by ten feet. If we did that, it would look something kind of like this. We were at zero, now we're at ten. We want to be sure, so we take a measurement and it says, we're not at ten, it's showing that we're at five. So, what do we do? Our measurement and our prediction disagree. Probably a good guess might be somewhere right in between the two. We can take our measurement and our prediction and make a convolution, which is a really fancy way of saying the product of two functions.

> Note the shapes of the graph representing a convolution are not correct, but the concept still stands. A convolution is a simple addition of two signals. So for there to actually be a new higher peak, one of the signals would need to be flatter and overlap the other signal a lot more.

The result is actually more accurate than either of our guesses individually. Even though our measurement was noisy, we don't actually know if we're at five, and our prediction was noisy, we're not actually at ten, the end result is more reliable. This gives us a Kalman Filter. A Kalman Filter can be used any time you have a model of motion and some noisy data that you want to produce a more accurate prediction. How good is a Kalman Filter, you might ask? This is an example of a homework assignment that was given to us. The green represents an actual robot's path, where all of the little red dots are the noisy measurements. It's so noisy that if you just take two subsequent points, two measurements, you can't tell which direction the robot is moving in because the second point might actually be way behind the first point. It's incredibly, incredibly noisy. This is part of the class. You can actually go to Udacity and take the course for free, and this is the final thing that they do in the course. If you end up going to Georgia Tech, there's a little bit more involved.

To make things even more interesting, not only do you have to figure out where the robot is, you have your own robot that moves slightly slower than the one you're trying to find and you have to chase it. So, you have to predict where it will be a time or two into the future, and then be there. Sorry for anybody who's colorblind, they picked the colors, not me. What does this look like? Well, we can apply a Kalman Filter and we end up something kind of like this. Before, our red dots were virtually unusable. As I mentioned, given two points, we can't even determine the direction, but with this correctly implemented: we can see our chaser robot getting closer and closer.

I like a little bit of audience participation. Who here likes money? Okay. All right, I think some people didn't raise their hands, it's okay. Before we look at how a Kalman Filter looks like, let's look at some cold hard cash. This is a 1913 Liberty Head Nickel. It was produced without the approval of the U.S. mint and, as a result, they only made five of them. Only five of these got into circulation. As a result, it's incredibly, incredibly rare and if you find this it's worth three point seven million dollars. So, yeah, I'd say that's a pretty penny. I'll be here all week, folks.

This is not a Liberty Head Nickel. This is a trick coin that, for some reason, your coin collecting friend happened to have that has two heads instead of being the actual Liberty Head Nickel.

This coin collecting friend also has a three-point-seven million dollar coin. For some strange reason, they put two coins into a bag and shake it up and draw one. So, we have one fair coin and one trick coin in our bag. They say, "Hey, you know what, do you want to play a game? Do you want to make three point seven million dollars, eh?"

 So they take a coin out, they flip it, and they say, "Oh, okay, it landed on heads." From here on they might try and make some sort of a wager or bet. Like, "Okay, well, if it's the $ 3.7 million coin, you can keep it but otherwise you have to, I don't know, mow my lawn or something?" I mean, it's fairly equivalent, right?

But, would that be a good bet or not? In order to know, we have to know what is the probability of given that the coin landed on heads that we have our fair coin. To do this, we can use Bayes Rule. This is what it looks like.

To explain a little bit of the syntax, the P stands for probability. We are saying what the probability of A, given B. So, this is the probability that we have a $ 3.7 million coin, given that we know it was heads. That's the information. That's all we knew. In order to do this, we can flesh this out piece by piece. The probability of heads. Well, what is the probability of heads? We have three total chances of getting heads and one chance of getting tails. So, we have a three out of four, or 75 percent chance of getting heads.

Another way that we can do this is say, well, there's a 50 percent chance that we get our fair coin and, if we get that fair coin, there's a 50 percent chance that it's heads. We can add that to a 50 percent chance of getting our trick coin and if we get our trick coin, there's a 100 percent chance that we're going to get heads. When you do that, you end up with the exact same result, this is just the more math-y way of achieving that instead of intuition, because later on I tried to teach my program intuition. It didn't work out too well. Also, so this is a talk on artificial intelligence and I have to admit, I don't know a how lot about artificial intelligence or I would've written an artificial intelligence to write my talk. Thank you.

Okay, so we're going to add this onto our equation and keep moving. Now we want to know what is the probability of A? The probability of getting that $ 3.7 million coin? Well, we know we have two different cases, they're equally probable. We have a 50 percent chance of getting that coin and we can add this back to our equation. The last piece is the probability of heads given that we have a fair coin. Given that we have this $ 3.7 million coin. In that case, assuming that we have the fair coin, we flip it. There's only a one out of two chance that we have heads, so that's 50 percent, we can add it here. When we put all of that together, we end up with a one in three, or zero point three three percent, a 33 percent chance of owning a multimillion dollar, 1913 Liberty Head Nickel.

One in three, it's not great but it's not nothing. This is what we can do with Bayes Rule, given two related probabilities, in this case what is the probability that you will get heads. Also, what is the probably that will draw our money coin? We can accurately predict that relationship. [Kahn academy has a really good resource on Bayes Rule](https://www.khanacademy.org/math/ap-statistics/probability-ap/stats-conditional-probability/v/bayes-theorem-visualized) and instead, another way to teach this, this is the very math-y way. One other way to look at this is with trees. Here's essentially that.

"To answer this question, we need only rewind and grow a tree. The first event, he picks one of two coins, so our tree grows tree branches, leading two equally likely outcomes, fair or unfair. The next event, he flips the coin, we grow again. If he had the fair coin, we know this flip can result in two equally likely outcomes, heads and tails. While the unfair coin results in two outcomes, both heads. Our tree is finished and we see it has four leaves, representing four equally likely outcomes. The final step, new evidenc."

"Whenever we gain evidence, we must trim our tree. We cut any branch leading to tails because we know tails did not occur. That is it. So, the probability that he chose the fair coin is the one fair outcome leading to heads divided by the three possible outcomes leading to heads. Or, one third."

All right, so if we use trees, or we use Bayes Rule, we get the same outcome. I'm not an expert in probability but that's probably a good thing. One element I mentioned but didn't dwell on was total probability. Also, I'm very terribly sorry, I lied about Bayes Rule. That isn't all of Bayes Rule, it actually looks a little bit more like this. So, this is the expanded form and to see both side by side, this is just expanded the total probability of B expanded on the bottom. What exactly is total probability? If we're going to look at our problem another way, we can say we have a 50 percent chance of our actual coin or the zero-dollar-trick-coin. In this problem space, if we're going to land on heads, heads is going to completely take up the trick coin case. If we have the trick coin, there's a hundred percent chance of heads. However, it only takes up half the $ 3.7 million coin. If we land on tails, tails falls entirely inside of the $ 3.7 million coin, and we have a 100 percent chance that that is a fair coin.

What we want to know: is the probability, the total probability, of getting heads. In order to do that, we can calculate it by adding up this section along with this section and that will give us the total probability. To write it out long form, we have the probability of heads given that we have our fair coin, times the probability of a fair coin, plus the probability of heads times the trick coin, multiplied by the probability of getting that trick coin. It's just the summation and we did this previously when I showed you this slide but I didn't explain exactly why we did it, or where we're getting that math from. This is where it came from.

We can make this a little bit tougher, though. What if we flipped two coins? Or what if we flipped the coin twice and it landed on heads both times? In order to do that, it makes it actually a little simpler if we use the expanded form. I'm not going to dwell on exactly where we got all of the numbers from as much, but here the suffix "i" indicates each of the different cases. We could have a coin that's a fair coin or we could have a coin that is the not-a-fair coin (trick). The probability of landing on heads twice, given our fair coin, is going to be, you flip it and it's a 50 percent chance of heads. You flip it again, it's a 50 percent chance of heads. Multiply those two together.

The probability of getting that fair coin hasn't changed. It never will. There's always a 50 percent chance of getting one out of two coins.

Then, we can flesh out this summation and at the bottom, again, it's 0.25 times a 0.5, if we get heads. Or if we have the trick coin, it's a 100 percent probability so it's 1.0 times the probability of getting the trick coin, which is 0.5. Y'all with me? Okay, all right. So, if you add all of this together you end up with a fifth, which is 0.2. Now Bayes Rule doesn't claim certainty. Our values are going down, it is more and more and more likely that we do not have the fair coin. But, it's never going to actually reach zero, and that's a very important part, because if it does reach zero and then we flipped it again and it turned out to be tails, well, the way Bayes Rule is written, it would never recover from that. Mathematically it would never recover from that. Sorry to get a little bit math-y but we need it.

Is anybody ready for a break from math? All right. So, we are going to take a break from math with some more math. For that, I'm going to put on my math jacket. I do appreciate you all baring with me. If we look back at Bayes Rule again, one of the, one way to represent it would be splitting the equation out. This is exactly what we had before, but on one side we basically have a constant. The probability of getting our fair coin every single time was exactly the same. This is going to be called our prior. Without any information, at all in the system, we can say that would be the probability of getting our coin. This other section is after we have information so it's the posterior, so "post" information. Even, if our prior is 0.5, our posterior, if we have the case where we got a tails, our posterior is so large that it actually pulls the 0.5 up all the way to be a 100 percent and say we definitively have a fair coin.

A Kalman Filter is a recursive Bayes estimation and I can guarantee you that all of these are words. Previously we looked at a graph and we had a prediction, and so that's actually going to be our prior. We also had a measurement and that's going to be our posterior. This is the thing that updated after we got new information. Our convolution, we're going to be somewhere in between. We don't exactly know where. That's where actually implementing a Kalman Filter comes from. The next example comes from Simon D. Levy. I have a link to this resource (at the end). [The linke goes] Step by step through and really explains the math. I know your heads might be hurting a little bit but like, I'm barely skimming the surface. Some of it's really interesting. He also has a fairly unique and fairly simple example that I'm going to walk through how to implement it in a Kalman Filter.

So, let's say we've got a plane. This plane is really simple. All it can do is land, apparently. The way you control it is by multiplying your current altitude by some other value. In this case it's 0.75. This gives us a nice, it's a nice steady landing. Towards the end it's moving in smaller and smaller increments until eventually we kind of touch down. Unfortunately, our measurements are really, really noisy. This is that line but with 20 percent noise. We're actually going below the ground here. We're going negative measurements. According to our measurements we're repeatedly slamming into the ground. I know like visually, mentally, you're just like, "Oh yeah, there's a nice little line in there." But if you are writing a system that depends on those measurements, we need it to be a nice straight line, nice smooth line. Instead of this jagged thing that sometimes indicates we're below the ground.

We're going to actually program this in a Kalman Filter. We're going to start off with our rate of descent, just 0.75, our initial position, and our measurement error. We're going to then just make a guess. We're going to say, "Well, let's just assume you were at the very first position that you were measured at." We also introduce a new thing called P, which is our estimation error. This is our prediction error. It's going to be a value between 0 and 1 that we're going to use, remember how we kind of adjusted our robot sort of back and forth? Is it closer to the prediction, is it closer to the measurement? That's how we're going to do that.

To get started, we pull a measurement off of our measurement array. Oh, and I do apologize, this is in Python. Yeah, I assume everybody here's a polyglot (this was tounge in cheek, I clearly don't expect everyone to be a polyglot). Luckily, all of the code is identical to what it would be in Ruby, except for the very top line, the for loop. All right, so we start off with our guess. We multiply where we currently were by our constant, so 0.75. That's now where we think we are. We then want to say, build into our system, where, if we move just a little teeny tiny bit, our predictions probably pretty accurate. But, if we move a whole lot, our predictions not as accurate. We're going to multiply our motion by our prediction error. The reason we do this twice is that prediction error is actually represented as sigma squared, so it's error squared. You don't really need to know that, just multiply it twice.

That's the prediction phase. Then, after we predicted we have to update it with our measurement. I'm going to skip this gain line and instead go straight to the actual update. So, we have our guess of where we currently are. Then, we add it with a mysterious gain number times the current measurement, minus the previous guess. The way that we can think about this gain is, it's sort of the ratio of our last measurement and the prediction. If our prediction error is really low, like really, really low, then our gain is really, really low. If it's so low that it gets pretty close to zero, we can approximate zero. When that happens, we can actually eliminate out this entire term and that means that we should just ignore our noisy measurements all together. Our last prediction was so good, it was so good, we don't even need our new measurements. Either that, or our new measurements were so bad that it's not helping us in any way, shape, or form.

If the prediction error is high, then it means we have a really high gain. When that happens, we end up approaching one. When we do this, we have an X guess and then we also have a negative X guess. Those two terms cancel each other out. We end up just guessing whatever our measurement is. This means that, we throw out our previous prediction and just use our measurement. You might want to do this in a case where it turns out that your sensor is really, really accurate but your prediction model is not. A way to visualize that is if our prediction is less certain, or less accurate, it's kind of a little bit more flat and our robot would be leaning toward our measurement. Or, if our prediction is more certain, it's a little bit more peaky? Then, our robot is going to be leaning more towards the prediction.

You put all of this together and you recursively update your prediction error and you end up with a graph that kind of looks a little bit like this. The jagged line represents our very noisy measurements. The blue line represents the actual value of the plane. The little green squares are what we are predicting. Now, it's not dead on. Again, we're not, perfect at predicting the future but we're pretty close. We're a lot better than what we had previously. Given this, hopefully our plane won't crash into the ground repeatedly. That's pretty much the simplest case of a Kalman Filter. We can get a lot, a lot deeper. There's a lot more scenarios and situations.

One of the more common things is having a Kalman Filter in a matrix form. For example, in this case, we only had altitude but what if we also had engine speed and barometric pressure and the angle of our flaps, and the angle of the pilot is pulling back on the controls? If we put all of those together, if they are related, instead of individually writing Kalman Filter for each of them, we put them in one Kalman Filter. It actually ends up being much, much, much more accurate for the entire system. This looks pretty similar but it's, yeah, there's a little bit more going on that we don't necessarily have time to get into.

The other case where a Kalman Filter gets into trouble is in motion that isn't linear. So, previously yes, we had a nice gentle curve but each step itself was linear. Each step was just based on a constant multiplied by the previous step. There are cases where we have circular motion or logarithmic or just you know, not linear. When that happens, we end up having two different probability distributions. Then, when we put them together they, in order to add two probability distributions together, they have to be on the same plane.

Here we're kind of estimating and making a bad estimation. Granted, this is still, it's likely better than doing it without any kind of a filter, just taking the noisy measurements. But, I would recommend not doing this. Instead, there's other ways. There's an extended Kalman Filter, there's an Unscented Kalman Filter and this is kind of the way I think of extended Kalman Filter: it rotates the plane of our probability distribution so that it approximates a linear calculation. It still has to be on a line and it still has to, both of them have to be on the same plane, but we can approximate our curve by rotating our line.

That's it for Bayes Rule, or, sorry, that's it for Kalman Filter. I did want to go back a little bit to Bayes Rule and touch on the two most important parts. The prediction, if we never predict the future then we can't know if we're right or wrong. This is what scientists, this is why scientists start with a hypothesis. If the hypothesis is wrong, we're forced to revaluate our underlying assumption. When we, and then whenever we get new information, we have to update. We have to update our own set of beliefs. The interesting thing about this is we can never be too sure about ourselves. No matter how many times we get heads, we can never be a 100 percent sure that it is a trick coin unless we actually investigate it. That's why this is probability.

As soon as it dips to that, if you end up going all the way to zero, or if you just make that claim? If you say, "Oh, there's a zero percent chance this could ever happen." Bayes Rule will not help you, your system can never recover.

I already gave the answer previously of even if you get tails, it's like sorry, Bayes Rule tells you there's a zero percent chance. You cannot recover. No matter how sure of yourself that you are, you always need to remain a little bit skeptical. You might think that there's a 100 percent chance of the sun coming up tomorrow. That would be a pretty good bet. For most days, you'd be right, but if it turns out that tomorrow is the day that our sun turns into a red giant and consumes the earth, hopefully your millennia of prior experience with the sun coming up every day doesn't cause you to accidentally die.

On that note, it always pays to have good information, and good guesses. We don't have to wait until our sun explodes. We can actually take a look at other stars and see what happens to them. We can compare our situation to another, it's not exactly the same, but it'll give us a better prediction than we would have otherwise. The more data and the more predictions that we make, the better our outcomes will be. Let that sink in. I highly recommend a book called [Algorithms to Live By](http://amzn.to/2sgTuKV). I think it's a book every programmer should read. It's got a good narrative and it has an entire chapter on Bayes Rule. It's very easy to read, it doesn't get into the math, nitty gritty, like I did. I also have, oh, I see some people taking photos, I'm going to leave it up here and speak to delay the next slide. Okay, good, good.

I also highly recommend [The Signal and the Noise](http://amzn.to/2rjwaNs). This is a book written by Nate Silver, it's about probability. Nate Silver runs 538, he successfully predicted our 45th president had a one in five chance of winning and would likely lose the popular vote. He did not predict the magnitude by which he would lose the popular vote. Just saying.

The audio I got, it's Mozar's Requiem in D minor. Previously, the Kalman tutorial you saw, you can go to [bit.ly/kalman-tutorial](bit.ly/kalman-tutorial). This is Steven D. Levy's resource. Then, also, if you're really into Kalman Filters and you want to see a lot of that Kalman Filters, extended Kalman Filters, and other forms this is a great resource. It's just [bit.ly/kalman-notebook](bit.ly/kalman-notebook). Unfortunately all of this is also in Python but it's, I mean if you know Ruby it's pretty easy to read.

You can also check out [Udacity](https://www.udacity.com/) and Georgia Tech. And, if you didn't know, BAE is not short for baby. It's African American vernacular and it stands for "before anyone else". So, Copernicus built on top of Bayes theory and developed special cases of when we can truly have no prior estimate, what should we do? Well, Laplace took Bayes' work and actually much of what we know is Bayes Rule and Bayes Theorem to be the nice, pleasant polished thing that it is, actually comes from Laplace. So, before there was Copernicus, before there was Laplace, Bayes was BAE. Thank you very much.