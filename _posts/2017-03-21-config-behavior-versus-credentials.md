---
title: "Config: Behavior versus Credentials"
layout: post
published: true
date: 2017-03-21
permalink: /2017/03/21/config-behavior-versus-credentials/
categories:
    - Ruby
---

An application doesn't have one type of configuration, it has two. In Rails, it's confusing since we muddle these two together under a giant switch statement powered by `RAILS_ENV`. Let's start with some definitions.

## Behavior

Is caching enabled or disabled? What gems are loaded? What actions are safe to perform? When you have your app configured for "test" then it's perfectly normal and expected to drop your database or flush your Redis instance between test runs, even though that would be catastrophic in production. In development we want hot code reloading to decrease iteration time, while in production we want to cache all code so we can run with maximum speed and throughput.

This is what I mean by behavior. How does your app behave and what actions are acceptable? This is typically powered in Rails by setting `RAILS_ENV` environment variable to `development`, `production` or `test`. Different gems get loaded from the `Gemfile` depending on what behavior we want, and different behaviors are enabled or disabled via environment specific files such as `config/environments/production.rb`.

## Credentials

In addition to being able to flush a Redis instance or not, our app needs to know how to actually connect to the instance. Same goes for any external resources you use, database, email provider, payment service, APIs, etc. It makes sense that when your behavior changes your credentials should too. Just because it's okay to drop your database in "test" doesn't mean that you should do so while connected to your production database. Rails saw this issue early on and "fixed" it for the database side by requiring database connection information be present in the `database.yml` under different "environments".

```yml
test:
  name: schneems_test

production:
  url: postgres://username:password@host:port/name
```

Usually, any other credentials are inside of a file like `config/environments/production.rb` or in an initializer for example:

```ruby
# config/initializers/sidekiq.rb

if Rails.env.production?
  REDIS_URL = 'redis://redis.example.com:7372/12'
else
  REDIS_URL = 'redis://localhost:6379'
end

Sidekiq.configure_server do |config|
  config.redis = { url: REDIS_URL }
end
```

One good question I got from DHH on this dichotomy was "Where does a CDN config fit in?". Generally configuring a Rails app to use a CDN doesn't have any password or "secrets", instead it's a subdomain that is public information. I would still label this as "credentials" because naming is hard, and changing that value does not change the behavior of the application. It changes the resource that is being used to serve the application.

## Behavior Versus Credentials - Staging

In the case of Rails, there is no distinguishing between behavior or credentials. You are encouraged to use a giant switch `RAILS_ENV=production` to set both at the same time as they are coupled. This works for most cases but has some nasty side effects.

While you start with 3 environments shipped with Rails, you might one day decide that you want another one day. Maybe you want to be able to show stakeholders previews through something like [review apps](https://devcenter.heroku.com/articles/github-integration-review-apps). Maybe you have a QA team and you want them to have access to a staging environment where it's safe for them to exercise the full depth and breadth of your app without fear of emailing thousands of users or kicking off real debit card transactions.

In that case, most people add a `RAILS_ENV=staging`. The problem here is one of divergence. If you expect your QA to catch a bug before it hits production then your staging needs to behave EXACTLY like production. You can do things like have `config/environments/staging.rb` to load the config in `config/environments/production.rb`. If the app used that file to specify credentials then now your app is accidentally connected to production credentials, oops.

It's also common to configure behavior in other places in your app with if statements similar to how we did it with sidekiq credentials previously:

```

config.action_controller.perform_caching = Rails.env.production?
```

This one is a bit contrived, but things like this do happen. Then you'll see a bug in production that can't be reproduced in staging, it costs hours or days of your life. Now one option could be to make the `production?` method return true for `staging` environment, but this would mean that we are accidentally connected to our production sidekiq instance.

Another thing I see is apps that have admin features available in development for debugging but not in production for security reasons. Having these things exposed on a staging site could accidentally leak customer information and that would be bad.

This conflation between behavior and credentials is a bad one. When I started answering support tickets at Heroku for Ruby apps, most of the "impossible" behavior ended up being explained by a

```
$ heroku run bash
~$ echo $RAILS_ENV
staging
```

It became so common that I [wrote an article about it](https://devcenter.heroku.com/articles/deploying-to-a-custom-rails-environment) and even emit a warning while you're deploying. I mentioned this to the Rails mailing list and someone's reaction was "they must be new" and I will tell you that apps of all shapes and sizes with developers of all skill levels hit this problem. It's not an issue of "knowing what you're doing" it's an issue of your app behaving as expected and doing the right thing more often than not.

After the warning and the error, I still see an occasional ticket related to this but it's no longer where I spend the bulk of my debugging time.


## Imitating Behavior

In the previous example, a "staging" environment should act very close to a "production" environment. In that case, it makes sense to preserve the production behavior but only change the credentials. So "staging" isn't a behavior, it's a set of different credentials.

There's another case I see where people want to debug a production issue or do some performance benchmarking with production settings. If you're using the default behavior of hiding all your behavior and credentials behind `RAILS_ENV`, if you start running your app with `RAILS_ENV=production` locally you're in dangerous territory. Maybe the endpoint that you want to debug as slow is for sending out mass emails based on users in your database. If you boot with `RAILS_ENV=production` locally and hit that endpoint, now you've just sent off dozens or hundreds of emails, oops.

This is essentially another case of the "staging" problem. We want to reproduce or imitate behavior, but either we accidentally get the credentials too, or we have slightly different behavior based on an accidentally slightly different configuration with a custom `RAILS_ENV`.

## The Illusion of Safety

As I mentioned previously, I had a mailing list conversation about this topic recently. One of the things I heard was that the dev wanted to be able to use `RAILS_ENV=staging` as a safety net. If they use that then they __know__ they are not going to affect any production data. I disagree.

What if you're on your staging console and you're trying to reproduce a production bug, but you can't. You think "maybe there's a difference in behavior with production and try it out with `RAILS_ENV=production` without thinking that even though you're on your staging app it has credentials to ALL your environments. The next thing you know, your production app doesn't just have a bug, it's down.

While any instance of your running application should be able to __behave__ like any other instance (dev/prod/test), they shouldn't even have the credentials to connect to all the different services.

If you can ssh into your staging server and take down your production database, that's a problem. While you might say "I'll never do that" or "I'm a good programmer", we're all bad programmers when we're tired, or hungry, or upset. Since we're all bad programmers on some days, we have to always plan for that case. I don't know about you, but breaking my production app from within my staging environment sounds like a pretty bad time.

## Two measures of defence

One thing we can do is to safe guard against dangerous actions. I took this measure [in Rails to prevent dropping production databases by accident](https://github.com/rails/rails/pull/22967). Again, I know that __you__ will never need this code, because __you__ are a good programmer. This is a thing that does happen and if it ever happens to "bad programmer you" then you'll be glad there is an extra safeguard there.

This approach is extremely time intensive. It also requires enough people doing the "wrong" thing to find out what actions are the most dangerous or the most common to warrant protection. Also there's plenty of cases where you can't infer what is dangerous and what isn't. For example sending out emails or charging money to an account are common on a production app but shouldn't happen in staging or development. From the framework level it would be almost impossible to detect when this action is valid or not. That's why we need a separate line of defence.

Seperate the behavior of your application from the credentials. It's that simple. If your app CANNOT charge a creddit card because it has "development" api credentials instead of production credentials, then this action is inherently safe. You're free to `RAILS_ENV=production` all you want, on any machine that you want, and you'll only get in trouble if you're on your production instance.

This means not checking in any credentials into your repo. This has a few benefits, if a contractor or intern walks away with your codebase do they walk away with your customer data too? What if someone accidentally hits the "public" button on GitHub for your repo, so you have to roll all your credentials? By separating out your behavior from your credentials and not checking in your credentials, you are protected from a wide array of threats.

## Easier Said Than Done

On Heroku this means storing your credentials in environment variables. Heroku provides a secure way of setting these values per app via `heroku config`. Are there security implications to this method? Yes. Because env vars are global any clients or services such as an error reporting library has access to all your credentials. This is mitigated in that all the good ones only whitelist environment variables to record such as `RAILS_ENV` and ignore any others such as `DATABASE_URL`. If you are using a service that does otherwise, you need to switch. While this does mean that you need to be careful about what clients are running on your app, you need to do this anyway. Even without the ability to record your env vars, an unsecure client could run arbitrary code or tar up your app and send it somewhere. Based on that I don't think this is a large threat.

What about if you're not running on Heroku? If you're deploying via something like [dokku you can already use environment variables](https://dokku.viewdocs.io/dokku/configuration/environment-variables/). If you're using something else, you can roll your own environment variable support via a `.env` file and either the [dotenv-rails gem](https://github.com/bkeepers/dotenv) or [foreman gem](https://rubygems.org/gems/foreman). You might want to also back up the creds somewhere other than on your production disk, a password manager such as LastPass or 1Password with shared passwords across your admins is an option.

If you need a third level of lockdown protection for the services you rely on, consider isolating them via the network. You can roll your own or use [Heroku Private Spaces](https://www.heroku.com/private-spaces).

At the end of the day, I'm advocating for declarative configuration. I don't want my apps to connect to any services I didn't explicitly configure or do anything I didn't tell them to. The alternative is conditional configuration which is what Rails encourages by default. In that case we've not built one app but rather 3 separate apps that are wrapped in a giant conditional, switched by one environment variable.
