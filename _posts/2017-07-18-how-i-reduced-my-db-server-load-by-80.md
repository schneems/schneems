---
title: "How I Reduced my DB Server Load by 80%"
layout: post
published: true
date: 2017-07-18
permalink: /2017/07/18/how-i-reduced-my-db-server-load-by-80/
categories:
    - ruby
---

Database load can be a silent performance killer. I've been optimizing the query performance of a [web app I run designed to get people involved in open source](https://www.codetriage.com), but was seeing random spikes of query times to 15 seconds or more. While I had been seeing this behavior for some time, I only recently began tuning my database queries. You can read about my efforts to  [First I sped up my home page with some indexes](https://schneems.com/2017/06/22/a-tale-of-slow-pagination/) (and Rack Mini Profiler). Then I [tracked down and killed some expensive queries](https://blog.heroku.com/expensive-query-speed-up-app). After these major improvements the average response time was around 50ms and my perc95 was under 1 second. Yet, I had this annoying issue where in a 24 hour period, my perc95 response times would shoot up to maybe 15 seconds or 30 seconds and start timing out for a short period of time. This post is about me finding and fixing that issue which resulted in a net 80% decrease in my database load.

> This article also [translated into Japanese](https://frasco.io/how-i-reduced-my-db-server-load-by-80-7902699be42c).

For some context, this is what my response time dashboard looked like when I would get one of those spikes:

![](https://www.dropbox.com/s/ny7olvdtm9mupej/Screenshot%202017-06-29%2012.54.30.png?raw=1)

To understand why that request (or series of requests) was so slow I reached for a metrics tool. In this case, I'm using [the Scout add-on on Heroku](https://elements.heroku.com/addons/scout) to capture production metrics. I changed the scale to show the last 12 hours of requests (default is 3 hours). And then narrowed in on the huge spike. When I did that here's the page that I saw:

![scout page of slow request](https://www.dropbox.com/s/fywluxpofp41bfh/Screenshot%202017-06-29%2009.34.26.png?raw=1)

Yikes!

There must have been something odd about the app or the database. In the output from scout can see that one query took about 38 seconds to complete. I tried visiting the same page manually and it loaded quickly. So it wasn't something off or weird about that specific page causing the slowness.

Luckily enough I work for Heroku, so I popped into the Slack room for our database engineers and asked what might cause that kind of performance degradation. They asked what kind of average load my DB was under. I'm using a [standard-0 DB](https://devcenter.heroku.com/articles/heroku-postgres-production-tier-technical-characterization#burstable-performance) and Heroku lists it as being able to sustain a [load of 0.2](https://devcenter.heroku.com/articles/heroku-postgres-production-tier-technical-characterization#burstable-performance). I opened up [my logs in papertrail](https://elements.heroku.com/addons/papertrail) and searched for `load-avg` and I found this entry right around the time of my slow request:

```term
Jun 29 01:01:01 issuetriage app/heroku-postgres: source=DATABASE sample#current_transaction=271694354
sample#db_size=4469950648bytes sample#tables=14 sample#active-connections=35
sample#waiting-connections=0 sample#index-cache-hit-rate=0.87073  sample#table-cache-hit-rate=0.47657
sample#load-avg-1m=2.15 sample#load-avg-5m=1.635 sample#load-avg-15m=0.915
sample#read-iops=16.325 sample#write-iops=0 sample#memory-total=15664468kB
sample#memory-free=255628kB sample#memory-cached=14213308kB sample#memory-postgres=549408kB
```

While a normal load average of 0.2 or lower is fine, my app was spiking up to `2.15`, yowza!

I already spent some time optimizing my query times, so this was a bit of a surprise for me. One of the database engineers suggested [the pg:outliers command which comes from this Heroku a `pg:extras` CLI extension](https://github.com/heroku/heroku-pg-extras).

> If you're not running on Heroku, you get access to the same data via the `pg_stat_statements` table.

When I installed the extension and ran the command I found that one query accounted for a whopping (you guessed it) 80% of total execution time.

```term
$ heroku pg:outliers
total_exec_time  | prop_exec_time |   ncalls    |   sync_io_time   |                                                                                       query
------------------+----------------+-------------+------------------+------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
3790:50:52.62102 | 80.2%          | 100,727,265 | 727:08:40.969477 | SELECT  ? AS one FROM "repos" WHERE LOWER("repos"."name") = LOWER($1) AND ("repos"."id" != $2) AND "repos"."user_name" = $3 LIMIT $4
493:04:18.903353 | 10.4%          | 101,625,003 | 52:09:48.599802  | SELECT COUNT(*) FROM "issues" WHERE "issues"."repo_id" = $1 AND "issues"."state" = $2
```

Here's the query if you are on a smaller screen:

```term
SELECT ?
AS one
FROM "repos"
WHERE LOWER("repos"."name") = LOWER($1) AND
("repos"."id" != $2) AND
"repos"."user_name" = $3
LIMIT $4
```

Now this was strange to me, because I don't remember writing any queries like this. I grepped my codebase for any `LOWER` SQL calls and couldn't find any. I then turned to Papertrail to see where in production this was being called. The first one I found was in a create action:

```term
Started POST "/repos" for 131.228.216.131 at 2017-06-29 09:34:59
Processing by ReposController#create as HTML
  Parameters: {"utf8"=>"✓", "authenticity_token"=>lIR3ayNog==", "url"=>"https://github.com/styleguidist/react-
  User Load (0.9ms)  SELECT  "users".* FROM "users" WHERE "users".
  Repo Load (1.1ms)  SELECT  "repos".* FROM "repos" WHERE "repos".
   (0.9ms)  BEGIN
  Repo Exists (1.9ms)  SELECT  1 AS one FROM "repos" WHERE LOWER( $3 LIMIT $4
   (0.5ms)  COMMIT
   (0.8ms)  BEGIN
  RepoSubscription Exists (4.3ms)  SELECT  1 AS one FROM "repo_ns"."user_id" = $2 LIMIT $3
  SQL (5.6ms)  INSERT INTO "repo_subscriptions" ("created_at",
   (6.1ms)  COMMIT
[ActiveJob] Enqueued SendSingleTriageEmailJob (Job ID: cbe2b04a-d271
Redirected to https://www.codetriage.com/styleguidist/react-
Completed 302 Found in 39ms (ActiveRecord: 21.9ms)
Jun 29 02:35:00 issuetriage heroku/router:  at=info method=POST path="/repos" host=www.codetriage.com request_id=5e706722-7668-4980-ab5e-9a9853feffc9 fwd="131.228.216.131" dyno=web.3 connect=1ms service=542ms status=302 bytes=1224 protocol=https
```

> Log tags removed for clarity


It's a bit much to read through, but you can see the query right next to `Repo Exists`. I checked that endpoint (`ReposController#create`) and did have some suspect methods but they all checked out fine (i.e. not making any SQL calls with `LOWER`). So what gives? Where was the query coming from?

It turns out it was coming from [this line](https://github.com/codetriage/codetriage/commit/d96cf446d6d35b74ace5a68b652d3eb0a1f8ce57#diff-0fa2d88e0cbaacf18f6096a7304430a1L5) in my model. This innocuous little line was responsible for 80% of my total database load. This `validates` call is Rails attempting to ensure that no two `Repo` records get created with the same username and name. Instead of enforcing the consistency in the database, it put a before commit hook onto the object and it's querying the database before we create a new repo to make sure there aren't any duplicates.

When I added that validation behavior I didn't think much of it. Even looking at the validation it was hard to believe it was responsible for so much load. After all, I only had around 2,000 total repos. So theoretically that call should only have happened about 2,000 times, right?

To answer this question I went back to the logs and found another site where the same SQL call was invoked.

```term
Jun 29 07:00:32 issuetriage app/scheduler.8183:  [ActiveJob] Enqueued PopulateIssuesJob (Job ID: 9e04e63f-a515-4dcd-947f-0f777e56dd1b) to Sidekiq(default) with arguments: #<GlobalID:0x00000004f98a68 @uri=#<URI::GID gid://code-triage/Repo/1008>>
Performing PopulateIssuesJob (uri=#<URI::GID gid://code-
  User Load (10.4ms)  SELECT
   (35.4ms)  BEGIN
  Repo Exists (352.9ms)  SELECT  $3 LIMIT $4
  SQL (3.7ms)  UPDATE "repos"
   (4.5ms)  COMMIT
Performed PopulateIssuesJob (Job ID: 9e04e63f-a515-4dcd-947f-0f777e56dd1b) from Sidekiq(default) in 629.22ms
```

> Log tags removed for clarity

This time the query was coming not from a web action, but a background job. When I looked it up I realized that the validation wasn't being performed on only create, it was being performed on ANY updates to the record. Even if the username or name columns weren't touched it would still query the database, just to be sure.

I have a nightly task that loops through all repos and sometimes updates their records. It turns out that my background task was happening almost exactly the same time as the really long web request. In essence, I was being my own noisy neighbor. My own workers were spiking the load of my database way above normal operating capacity and then regular time-sensitive web requests were being starved of database CPU time.

I promptly deleted the validation and instead replaced it with a unique index that adds a constraint to the database.

```ruby
class AddUniqueIndexToRepos < ActiveRecord::Migration[5.1]
  def change
    add_index :repos, [:name, :user_name], :unique => true
  end
end
```

> Note: the fix is not a drop in replacement it just so happens that [I was already handling the case of a non-unique entry being created](https://github.com/codetriage/codetriage/pull/573#issuecomment-312045401) and I didn't have to make any changes to my codebase. Otherwise I would have to go around rescuing postgres errors all over the place.

Now we are guaranteed that no two records can have the same username/name combination at the database level and Rails does not have to make a query every time we update a record.

> Not to mention that the Rails validation has a race condition and can't actually guarantee consistency, it's better to enforce these types of things at the database level anyway.

You might have noticed that the`LOWER` part of the SQL query isn't represented in my unique index. In my case, I was already normalizing the data stored, so that bit of logic was redundant.

Since removing that validation and adding in a unique index my app no longer has any 30 second + request spikes. Its database is humming along at or under the 0.2 load-avg.

![photo of current response time](https://www.dropbox.com/s/k1yxr2aylgitod9/Screenshot%202017-07-12%2014.56.01.png?raw=1)

When we think of slow databases we tend to think in terms of how quickly an individual query performs. Rarely do we consider how one query or a series of queries could interact to slow down the whole site.

After finding about `pg:outliers` I was also able to find some other good places to add indexes to reduce the load. For example:

```sql
issuetriage::DATABASE=> EXPLAIN ANALYZE SELECT  "repos".* FROM "repos" WHERE "repos"."full_name" = 'schneems/wicked' LIMIT 1;
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
Limit  (cost=0.00..39297.60 rows=1 width=1585) (actual time=57.885..57.885 rows=1 loops=1)
   ->  Seq Scan on repos  (cost=0.00..39297.60 rows=1 width=1585) (actual time=57.884..57.884 rows=1 loops=1)
         Filter: ((full_name)::text = 'schneems/wicked'::text)
         Rows Removed by Filter: 823
Total runtime: 57.912 ms
(5 rows)
```

While the overall execution time here isn't in the multi-second realm it's not great. That sequential scan is pretty fast, but it's not free. I added an index to `full_name` and now it flies. The same query comes back in under 1ms. The index on calls like this helped me reduce DB load as well.

To recap:

- A high `load-avg` in your database can slow down ALL queries, not just the already slow ones.
- Use `pg:outliers` to find queries taking up more than their share of CPU time if you're running on Heroku, you can use `pg_stat_statements` if you're running somewhere else.
- Use logs to find where queries are happening and `EXPLAIN ANALYZE` if needed to understand why a query is costly.
- The inputs to your query matter and can give you drastically different query performance.
- Add indexes, change how your data is stored, or change programming logic to avoid outlier queries.
- Use databases to enforce data consistency when possible instead of application code.

In hindsight this was a fairly easy bug to find and fix, it just took a little bit of time and the right tools. I've been seeing that stray 30s+ spike in request time daily for months, maybe years. I never bothered to dig in because I thought it would be too much trouble to track down. It also only happened once a day, so the impact to users was pretty minimal. With the right tools and a little bit of insight from our database engineers, I got rid of it in no time. I don't think I'm done with DB optimizations, but for now, I'm hitting all my self-imposed goals. Thanks for reading my database load journey.

