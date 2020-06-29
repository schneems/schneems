---
title: "Rate Limiting, Rate Throttling, and how they work Together"
layout: post
published: true
date: 2020-06-25
permalink: /2020/06/25/rate-limiting-rate-throttling-and-how-they-work-together/
image_url: https://www.dropbox.com/s/i7wpjvyxgjih14a/Screenshot%202020-06-25%2012.47.25.png?raw=1
categories:
    - ruby
    - rate throttling
    - rate limiting
---

In the beginning, there were API requests, and they were good. But then some jerk went and made too many requests too fast and brought the server crashing to its knees. Enter: Rate limiting.

Rate limiting is a server-side concept. If you're hosting a service or an API, you want people who are consuming your service to spread the load predictably. This strategy helps with capacity planning and also helps to mitigate certain types of abuse. If you have an API, then you most likely should protect it by rate-limiting requests.

In the beginning, there was an API server, and it was good. But then some jerk went and added rate-limiting code to it, which made the script you wrote crash. Enter: Rate throttling.

Rate throttling is a client-side concept. Imagine you're consuming some API endpoints. You can make 1000 requests an hour. You write your code to iterate over the 10_000 things you need, run it, and since each request takes a fraction of a second, after a few seconds, you start getting API errors, and your code stops working. What happened? Your requests are being rate-limited by the server. This behavior is bad news since you still need the other 9_000 entries. How can you get them? You can avoid errors by slowing down the rate of your requests by throttling your client. This strategy is known as rate throttling.

While rate limiting works to reduce the load on a server, rate throttling reduces errors on a client. If you're talking to a server that uses rate-limiting, then without some rate throttling logic, you'll eventually hit errors.

## Rate limiting strategies

There are lots of [rate limiting strategies](https://cloud.google.com/solutions/rate-limiting-strategies-techniques#techniques-enforcing-rate-limits), for instance:

- Leaky bucket
- Sliding window
- Genetic Cell Rate Algorithm (GCRA)

There are lots more, but these are the common ones.

Usually, you'll need people who want to access your API to register for some account, and you will provide them back with a secret token they can use for authorization. The rate-limiting is typically done on a per-token basis.

## Rate throttling strategies

The type of rate-limiting that is happening on the server will dictate your client's rate-throttling strategy. A typical high-level strategy is to allow a client to make as many requests as fast as possible and check each response to see if it was limited by the server (usually via a 429 status response code). If the response was limited, wait a bit, and then try again. Depending on the rate-limiting strategy being used, the logic to determine how much to wait will change.

For example, in the GitHub API (which uses a leaky bucket), they tell you how many requests you have left in your "bucket," and the next time, it will be refilled. When your client hits a 429, you can sleep until the refill time (and add in some jitter) and then retry.

On Heroku, which uses a GCRA algorithm that encourages requests to be more evenly spread out over time, clients can exponentially backoff.

> To get specific on optimizing for a GCRA strategy, I wrote a [gem called rate_throttle_client that explains more](https://github.com/zombocom/rate_throttle_client)

While sleeping is an easy way to pass the time as your client waits for more capacity to begin making new API requests, it's not the only option. For example, when you hit a rate throttle event, your system could store the request for later and switch to another workload. For instance, if the code runs on some background worker that handles multiple job types. In this scenario, if API requests start getting rate limited in one job type, the system could throw them in the back of the job queue to work on other tasks, such as sending emails. This tactic could be described as "work saving" though there might be a better term. While this sounds like a "free lunch," it's much more complicated in practice and has some business decisions that affect how you might want to implement such a system.

## Rate limiting without rate throttling

As a server owner, if clients hitting your service aren't throttling themselves, they might be hammering your infrastructure even if all they're getting is 429 responses, this isn't good. As a client, we already saw that your responses would start failing, and then either you'll end up getting errors, or maybe your system will be stuck in infinite retry loops. This isn't good either.

## Rate throttling without rate limiting

As a server owner, if you're relying on a client to limit itself, it will not. No matter how sure you are that people will only use a given client, there's nothing stopping someone malicious from sniffing your API endpoints and hitting them manually as fast as they want. If you don't have rate limiting on your server, someone will eventually figure it out, and you'll likely wake up one day to a massive server bill or a pager notification telling you that some resource has gone down.

## Rate limiting and throttling combined

When rate limiting is implemented on the server, and a client is provided with rate throttling, then everyone mostly gets what they want. People making requests aren't getting a ton of errors, and the admins wearing pagers on the server-side can sleep better at night. If you maintain an API, consider documenting how to rate throttle requests effectively. Or even better, release a client that includes native support for rate throttling.

----
> Teaser image "superbikes 06" by gbsngrhm is licensed under CC BY-SA 2.0
