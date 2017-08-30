---
title: "How I lost 17,000 GitHub Auth Tokens in One Night"
layout: post
published: true
date: 2017-08-30
permalink: /2017/08/30/how-i-lost-17000-github-auth-tokens-in-one-night/
image: og/auth-tokens.png
twurl: https://twitter.com/schneems/status/902973227974234114
categories:
    - ruby
---

How on earth does someone accidentally delete 85% of their users' GitHub tokens? I was suspicious that something might be wrong when I got an email from a service I run called CodeTriage, it's a free web app to help [find open source projects and issues to work on](https://www.codetriage.com). While I get plenty of emails from my service, I don't often get ones with the subject line "Code Triage auth failure". Before we can understand what happened, let's look into why this email even exists.

For CodeTriage to work it needs info from GitHub. Specifically, it needs to know about all the issues an open source library has open. To do that we need to make authenticated API requests. To make API requests, we need an API token. Now while an API token is good, even better is a VALID API token. Which unfortunately the system would lose from time to time.

When an invalid API token is in the system, it would cause random failures in the chain of pulling in issues, so I took steps to mitigate the issue. Once a week I have a script that cycles through all users, and use the [GitHub API to check a token](https://developer.github.com/v3/oauth_authorizations/#check-an-authorization). If the token is bad then I remove it from the database. I then email the user to let them know they need to re-authorize.

That's why my system deletes tokens, now let's look into the code, see if you can spot the problem that caused me to delete 85% of my users' tokens.

I use a home rolled GitHub API library that I wrote called `git_hub_bub` mostly because none of the existing libraries gave me enough control, and also I thought the name was funny. Mostly because I thought the name was funny. I implemented the logic to check a token on my User model:

```ruby
def auth_is_valid?
  GitHubBub.get("https://#{ENV['GITHUB_APP_ID']}:#{ENV['GITHUB_APP_SECRET']}@api.github.com/applications/#{ENV['GITHUB_APP_ID']}/tokens/#{self.token}", {}, token: nil)
  true
rescue GitHubBub::RequestError
  false
end
```

Then I hacked together a quick task to cycle through each user and check their token:

```ruby
task check_user_auth: :environment do
   User.find_each(conditions: "token is not null") do |user|
     if user.auth_is_valid?
       # Do nothing, auth is good
     else
       user.update_attributes(token: nil)
     end
   end
 end
```

When the token is not valid, I remove the token, because why would I want a bad token in my database?

Usually when someone's token is invalid it's because they made an update to their profile. Not that they revoked the token purposefully. So to fix the issue, we need a new token.

To get a new token, a user can log back into the system which will auto update their GitHub credentials. To let people know that their tokens are invalid and they need to be updated (along with sending them instructions), I wrote another task that sent out emails:

```ruby
task warn_invalid_token: :environment do
  User.find_each(conditions: "token is null") do |user|
    next unless Date.today.thursday?
    ::UserMailer.invalid_token(user).deliver
  end
end
```

We don't want to swamp you with emails, so we only send this once a week until they log back in to update their token.

> You win points if you guess what day the emails go out on.

I implemented this logic back in 2014 and for nearly 3 years it ran fine. Occasionally people would get bad tokens, but then they would re-auth and be on their way.

When I got that fateful email, I knew something was wrong because I hadn't deployed any code recently and I didn't modify my GitHub account. So what was up?

As soon as I could, I went to the console and did a token check. Yes my token was gone, so the email was correct. I then wondered if other people's were missing and sure enough, out of the roughly 20,000 users roughly 17,000 of them were missing tokens. My jaw just about dropped on the floor.

Turns out that there was a bug in my logic but not necessarily my code. After all, it did run flawlessly for a few years. So if my code was fine, where was the bug?

Looking at the update time of some of the records, I was able to place them roughly around the time of another event: A GitHub outage.

So while my code was correctly looping through and checking all the tokens, it was also dutifully deleting them when they came back as "bad" tokens. The thing was ALL requests were coming back without a success status code. Most all of the tokens on CodeTriage were deleted before the GitHub servers came back up.

For me it's not actually the end of the world. I don't need EVERY user to have a token, just that enough do. Once I realized how the failure happened I put some guards in place:

1) Make an API call to check that the API is up

```ruby
response          = Excon.get("https://status.github.com/api/status.json").body
github_api_status = JSON.parse(response)["status"]
next unless github_api_status == "good"
```

So now if the API is down, this should fail before we do any of our status checks. The API could always fail mid-way through the list but this would at least prevent running the checks in the middle of a known GitHub status downtime.

2) Duplicate token checks

Most of the tokens are valid, so when one comes back as "invalid" we can spend more time verifying that it's not a mistake. To do this we check the same token 3 times before deleting it.

3) Don't delete the tokens

This was a no-brainer. Instead of deleting the tokens I'm now moving them to a new field `old_token`. So if such a mass token event happens again, then I could recover much easier. I contacted GitHub support after my mass token deletion. The fist thing they asked me for was an example token, which I didn't have because I deleted all of them. So keeping a log of your really important values can be a good idea.

On this theme you might be tempted to use a gem like `acts_as_paranoid`. I would say, don't. I've heard a lot of things about this gem, mostly around sheer amount of data bloat.

## What if this was mission critical data?

If these tokens really were irreplaceable, how would I have recovered? I'm running on Heroku (I work there) and my "standard" Postgres instance includes point in time rollback for up to 4 days. This means that I'm able to pick an arbitrary day and time and generate a new database with the data available at that time. You can [read about how to do this on the documentation](https://devcenter.heroku.com/articles/heroku-postgres-rollback). It's also worth mentioning that "premium" databases have a point in time rollback of 10 days.

If this really had been a "stop the world" event, I could have rolled back in time, gotten all the tokens and been up and running fairly quickly.

> If you're not running on Heroku you should set up a continuous archive [such asthe WAL-E library](https://github.com/wal-e/wal-e) or WAL_G.


It's lucky for me that the impact wasn't so severe and the service was able to run just fine without this data. On the other-hand if the impact had been more severe then I would have had no other option but to rollback and I would have all the tokens again.

It's also worth mentioning that you can schedule periodic backups against your database using `heroku pg:backups:schedule` command, however this puts load on the database when you're taking the backup. It also prevents maintenance tasks from being able to run on the database.

I checked in with our database team and the consistent story seems to be don't use it unless you really need to. If I did have a `pg:backup` it would mean that there would be gap in time between when the backup was taken and the tokens were deleted (meaning that I might have only been able to recover most of the tokens instead of all of them). On the standard level I'm eligible to store 25 backups.

If your DB is under heavy load, you can also add a follower DB and take the backup from the follower DB. There's a [whole article on all the ways to backup your database if you're interested](https://devcenter.heroku.com/articles/heroku-postgres-data-safety-and-continuous-protection).

As the saying goes, you own your uptime, this includes service failures and data loss. It's important to think about how your service will be affected when sensitive data goes missing. The biggest mistake I made wasn't the code I wrote, it was not thinking about the edge case that someone else's API might go down.

Your service <strong>will</strong> fail. Instead of trying to prevent failure we can own <i>recovery</i> instead. Does everything go down or will failures be graceful? When you lose data, is it gone for good or can you recover?

I could make more patches to harden my API token checks, for example only delete an explicit 404 instead of ANY non 200 result. For now, that's less important than making sure that when my service falls down, that there's a way for it to get back up.
