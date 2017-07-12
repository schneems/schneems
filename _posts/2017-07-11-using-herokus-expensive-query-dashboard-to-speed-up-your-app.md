---
title: "Using Heroku's Expensive Query Dashboard to Speed up your App"
layout: post
published: true
date: 2017-07-11
permalink: /2017/07/11/using-herokus-expensive-query-dashboard-to-speed-up-your-app/
categories:
    - ruby
---

I recently [demonstrated how you can use Rack Mini Profiler to find and fix slow queries](https://schneems.com/2017/06/22/a-tale-of-slow-pagination/). It’s a valuable tool for well-trafficked pages, but sometimes the slowdown is happening on a page you don't visit often, or in a worker task that isn't visible via Rack Mini Profiler. How can you find and fix those slow queries?

> This is a repost of a blog I [wrote for Heroku](https://blog.heroku.com/expensive-query-speed-up-app).

Heroku has a feature called [expensive queries](https://devcenter.heroku.com/articles/expensive-queries) that can help you out.  It shows historical performance data about the queries running on your database: most time consuming, most frequently invoked, slowest execution time, and slowest I/O.

![expensive_queries](https://heroku-blog-files.s3.amazonaws.com/posts/1499377005-expensive_queries.png)

Recently, I used this feature to identify and address some slow queries for a site I run on Heroku named [CodeTriage](https://www.codetriage.com) (the best way to get started contributing to open source). Looking at the expensive queries data for CodeTriage, I saw this:

![Code Triage Project Expensive Query Screenshot](https://heroku-blog-files.s3.amazonaws.com/posts/1499374279-Screenshot%202017-06-22%2015.16.40.png)

On the right is the query, on the left are two graphs; one graph showing the number of times the query was called, and another beneath that showing the average time it took to execute the query. You can see from the bottom graph that the average execution time can be up to 8 seconds, yikes! Ideally, I want my response time averages to be around 50 ms and perc 95 to be sub-second time, so waiting 8 seconds for a single query to finish isn't good.

To find this on your own apps you can follow directions on the [expensive queries documentation](https://devcenter.heroku.com/articles/expensive-queries). The documentation will direct you to [your database list page] (https://data.heroku.com/) where you can select the database you’d like to optimize. From there, scroll down and find the expensive queries near the bottom.

Once you've chosen a slow query, you’ll need to determine why it's slow. To accomplish this use `EXPLAIN ANALYZE`:

```sql
issuetriage::DATABASE=> EXPLAIN ANALYZE
issuetriage::DATABASE-> SELECT "issues".*
issuetriage::DATABASE-> FROM "issues"
issuetriage::DATABASE-> WHERE "issues"."repo_id" = 2151
issuetriage::DATABASE->         AND "issues"."state" = 'open'
issuetriage::DATABASE-> ORDER BY  created_at DESC LIMIT 20 OFFSET 0;
                                                                       QUERY PLAN
---------------------------------------------------------------------------------------------------------------------------------------------------------
Limit  (cost=27359.98..27359.99 rows=20 width=1232) (actual time=82.800..82.802 rows=20 loops=1)
   ->  Sort  (cost=27359.98..27362.20 rows=4437 width=1232) (actual time=82.800..82.801 rows=20 loops=1)
         Sort Key: created_at
         Sort Method: top-N heapsort  Memory: 31kB
         ->  Bitmap Heap Scan on issues  (cost=3319.34..27336.37 rows=4437 width=1232) (actual time=27.725..81.220 rows=5067 loops=1)
               Recheck Cond: (repo_id = 2151)
               Filter: ((state)::text = 'open'::text)
               Rows Removed by Filter: 13817
               ->  Bitmap Index Scan on index_issues_on_repo_id  (cost=0.00..3319.12 rows=20674 width=0) (actual time=24.293..24.293 rows=21945 loops=1)
                     Index Cond: (repo_id = 2151)
Total runtime: 82.885 ms
```

In this case, I'm using [Kubernetes](https://www.codetriage.com/kubernetes/kubernetes) because they currently have the highest issue count, so querying on that page will likely give me the worst performance.

We see the total time spent was 82 ms, which isn't bad for one of the "slowest" queries, but we've seen that some can be way worse. Most single queries should be aiming for around a 1 ms query time.

We see that before the query can be made it has to sort the data, this is because we are using an `order` on an `offset` clause. Sorting is a very expensive operation, you can see that it says the "actual time" can take between `27.725` ms and `81.220` ms just to sort the data, which is pretty tough. If we can get rid of this sort then we can drastically improve our query.

One way to do this is... you guessed it, add an index. Unlike [last week](https://schneems.com/2017/06/22/a-tale-of-slow-pagination/) though, the issues table is HUGE. While the table we indexed last week only had around 2K entries, each of those entries can have a virtually unbounded number of issues. In the case of Kubernetes there are 5K+ issues, and that's only the `state=open` ones. The closed issue count is much larger than that, and it will only grow over time. We want to be mindful of taking up too much database size, so instead of indexing ALL the data, we can instead apply a partial index. I'm almost never querying for `state=closed` when it comes to issues, so we can ignore those while building our index. Here's the migration I used to add a partial index:

```ruby
class AddCreatedAtIndexToIssues < ActiveRecord::Migration[5.1]
  def change
    add_index :issues, :created_at, where: "state = 'open'"
  end
end
```

What's the result of adding this index? Let's look at that same query we analyzed before:

```sql

issuetriage::DATABASE=> EXPLAIN ANALYZE
issuetriage::DATABASE-> SELECT "issues".*
issuetriage::DATABASE-> FROM "issues"
issuetriage::DATABASE-> WHERE "issues"."repo_id" = 2151
issuetriage::DATABASE->         AND "issues"."state" = 'open'
issuetriage::DATABASE-> ORDER BY  created_at DESC LIMIT 20 OFFSET 0;
                                                                         QUERY PLAN
-------------------------------------------------------------------------------------------------------------------------------------------------------------
Limit  (cost=0.08..316.09 rows=20 width=1232) (actual time=0.169..0.242 rows=20 loops=1)
   ->  Index Scan Backward using index_issues_on_created_at on issues  (cost=0.08..70152.26 rows=4440 width=1232) (actual time=0.167..0.239 rows=20 loops=1)
         Filter: (repo_id = 2151)
         Rows Removed by Filter: 217
Total runtime: 0.273 ms
```

Wow, from 80+ ms to less than half a millisecond. That's some improvement. The index keeps our data already sorted, so we don't have to re-sort it on every query. All elements in the index are guaranteed to be `state=open` so the database doesn't have to do more work there. The database can simply scan the index removing elements where `repo_id` is not matching our target.

For this case it is EXTREMELY fast, but can you imagine a case where it isn't so fast?

Perhaps you noticed that we still have to iterate over issues until we're able to find ones matching a given Repo ID. I'm guessing that since this repo has the most issues, it's able to easily find 20 issues with `state=open`. What if we pick a different repo?

I looked up the oldest open issue and found it in [Journey](https://www.codetriage.com/rails/journey). Journey has an ID of 10 in the database. If we do the same query and look at Journey:

```sql
issuetriage::DATABASE=> EXPLAIN ANALYZE
issuetriage::DATABASE-> SELECT "issues".*
issuetriage::DATABASE-> FROM "issues"
issuetriage::DATABASE-> WHERE "issues"."repo_id" = 10
issuetriage::DATABASE->         AND "issues"."state" = 'open'
issuetriage::DATABASE-> ORDER BY  created_at DESC LIMIT 20 OFFSET 0;
                                                                     QUERY PLAN
----------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=757.18..757.19 rows=20 width=1232) (actual time=21.109..21.110 rows=6 loops=1)
   ->  Sort  (cost=757.18..757.20 rows=50 width=1232) (actual time=21.108..21.109 rows=6 loops=1)
         Sort Key: created_at
         Sort Method: quicksort  Memory: 26kB
         ->  Index Scan using index_issues_on_repo_id on issues  (cost=0.11..756.91 rows=50 width=1232) (actual time=11.221..21.088 rows=6 loops=1)
               Index Cond: (repo_id = 10)
               Filter: ((state)::text = 'open'::text)
               Rows Removed by Filter: 14
 Total runtime: 21.140 ms
 ```

Yikes. Previously we're only using 0.27 ms, now we're back up to 21 ms. This might not have been the "8 second" query we were seeing before, but it's definitely slower than the first query we profiled.

Even though we've got an index on `created_at` Postgres has decided not to use it. It's reverting back to a sorting algorithm and using an index on `repo_id` to pull the data. Once it has issues then it iterates over each to remove where the state is not open.

In this case, there are only 20 total issues for Journey, so grabbing all the issues and iterating and sorting manually was deemed to be faster. Does this mean our index is worthless? Well considering this repo only has 1 subscriber, it's not the case we need to be optimizing for. Also if lots of people visit that page (maybe because of this article), then Postgres will speed up the query by using the cache. The second time I ran the exact same explain query, it was much faster:

```
 Total runtime: 0.092 ms
```

Postgres already had everything it needed in the cache. Does this mean we're totally out of the woods then? Going back to my expensive queries page after a few days, I saw that my 8 second worst case is gone, but I still have a 2 second query every now and then.

![Expensive Queries Screenshot 2](https://heroku-blog-files.s3.amazonaws.com/posts/1499377612-Screenshot%202017-06-26%2010.47.20.png)

This is still a 75% performance increase (in worst case performance) so the index is still useful. One really useful feature of Postgres is the ability to [combine multiple indexes](https://www.postgresql.org/docs/8.3/static/indexes-bitmap-scans.html). In this case, even though we have an index on `created_at` and an index on `repo_id`, Postgres does not seem to think it's faster to combine the two and use that result. To fix this issue we can add an index that has both `created_at` and `repo_id`, which maybe I'll explore in the future.

Before we go, I want to circle back to how we found our slow query test case. I had to know a bit about the data and make some assumptions about the worst case scenarios. I had to guess that [Kubernetes](https://www.codetriage.com/kubernetes/kubernetes) was our worst offender, which ended up not being true. Is there a better way than guess and check?

It turns out that Heroku will [output slow queries into your app's logs](https://devcenter.heroku.com/articles/postgres-logs-errors#log-duration-3-565-s). Unlike the expensive queries, these logs also contain the parameters used in the query, and not just the query. If you have a logging addon such as [Papertrail](https://elements.heroku.com/addons/papertrail), you can search your logs for `duration` and get a result like this:

```
Jun 26 06:36:54 issuetriage app/postgres.29339:  [DATABASE] [39-1] LOG:  duration: 3040.545 ms  execute <unnamed>: SELECT COUNT(*) FROM "issues" WHERE "issues"."repo_id" = $1 AND "issues"."state" = $2
Jun 26 06:36:54 issuetriage app/postgres.29339:  [DATABASE] [39-2] DETAIL:  parameters: $1 = '696', $2 = 'open'
Jun 26 08:26:25 issuetriage app/postgres.29339:  [DATABASE] [40-1] LOG:  duration: 9087.165 ms  execute <unnamed>: SELECT COUNT(*) FROM "issues" WHERE "issues"."repo_id" = $1 AND "issues"."state" = $2
Jun 26 08:26:25 issuetriage app/postgres.29339:  [DATABASE] [40-2] DETAIL:  parameters: $1 = '1245', $2 = 'open'
Jun 26 08:49:40 issuetriage app/postgres.29339:  [DATABASE] [41-1] LOG:  duration: 2406.615 ms  execute <unnamed>: SELECT  "issues".* FROM "issues" WHERE "issues"."repo_id" = $1 AND "issues"."state" = $2 ORDER BY created_at DESC LIMIT $3 OFFSET $4
Jun 26 08:49:40 issuetriage app/postgres.29339:  [DATABASE] [41-2] DETAIL:  parameters: $1 = '1348', $2 = 'open', $3 = '20', $4 = '760'
```

In this case, we can see that our 2.4 second query (the last query in the logs above) is using a repo id of `1348` and an offset of `760`, which brings up another important point. As the offset goes up, the cost of scanning our index will also go up, so it turns out that we had a worse case than my initial guess (Kubernetes) and my second guess (Journey). It is likely that this repo has lots of issues that are old, and this query isn't made often, so that the data is not in cache. By using the logs we can find the exact worst case scenario without all the guessing.

Before you start writing that comment message, yes, I know that offset pagination is broken and [there are other ways to paginate](https://www.citusdata.com/blog/2016/03/30/five-ways-to-paginate/). I may start to look at alternative pagination options, or even getting rid of some of the pagination on the site altogether.

I did go back and [add an index to both the `created_at` and `repo_id` columns](https://github.com/codetriage/codetriage/commit/ce3ac6a59f92891e4a42b85927c852f074a0be3f). With the addition of those two indexes my "worst case" of 2.4 seconds is now down to 14 ms:

```sql
issuetriage::DATABASE=> EXPLAIN ANALYZE SELECT  "issues".*
issuetriage::DATABASE-> FROM "issues"
issuetriage::DATABASE-> WHERE "issues"."repo_id" = 1348
issuetriage::DATABASE-> AND "issues"."state" = 'open'
issuetriage::DATABASE-> ORDER BY created_at DESC
issuetriage::DATABASE-> LIMIT 20 OFFSET 760;
                                                                                QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1380.73..1417.06 rows=20 width=1232) (actual time=14.515..14.614 rows=20 loops=1)
   ->  Index Scan Backward using index_issues_on_repo_id_and_created_at on issues  (cost=0.08..2329.02 rows=1282 width=1232) (actual time=0.061..14.564 rows=780 loops=1)
         Index Cond: (repo_id = 1348)
 Total runtime: 14.659 ms
(4 rows)
```

Here you can see that we're able to use our new index directly and find only the issues that are open and belonging to a specific repo id.

What did I learn from this experiment?

- You can find [slow queries using Heroku's expensive queries](https://devcenter.heroku.com/articles/expensive-queries) feature.
- The exact arguments matter a lot when profiling queries. Don't assume that you know the most expensive thing your database is doing use metrics.
- You can find the exact parameters that go with those expensive queries by [grepping your logs for the exact parameters of those queries](https://devcenter.heroku.com/articles/postgres-logs-errors#log-duration-3-565-s).
- Indexes help a ton, but you have to understand the different ways your application will use them. It's not enough to profile with 1 query before and after, you need to profile a few different queries with different performance characteristics. In my case not only did I add an index, I went back to the expensive index page which let me know that my queries were still taking a long time (~2 seconds).
- Performance tuning isn't about magic fixes, it's about finding a toolchain you understand, and iterating on a process until you get the results you want.

*Richard Schneeman is an Engineer for Heroku who also [writes posts on his own blog](https://www.schneems.com). If you liked this post, you can [subscribe to his mailing list to get more like it for free](https://schneems.com/mailinglist).*

