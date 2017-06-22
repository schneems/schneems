---
title: "A Tale of Slow Pagination"
layout: post
published: true
date: 2017-06-22
permalink: /2017/06/22/a-tale-of-slow-pagination/
categories:
    - ruby
---

When I see a query in my logs without either a `limit` or a `count` clause, alarm bells go off because it is likely a hotspot. A pagination query has a`limit` so it usually flies under my radar:

```SQL
SELECT  "repos".* FROM "repos" WHERE (issues_count > 0) ORDER BY issues_count DESC LIMIT $1 OFFSET $2
```

> This query came from the main page of my app [CodeTriage.com](https://www.codetriage.com), the easiest way to get started contributing to Open Source.

As you can guess there's a problem here. It was pointed out to me by [Nate Berkopec](https://www.speedshop.co/) who writes a ton about Ruby performance problems. I had been staring the issue in the face for so long, I just accepted that slow query as a fact of life.

I'll take a moment to rewind and show you how I __should__ have found the problem.

## Always Benchmark Code

If you're not using [Rack Mini Profiler](https://github.com/MiniProfiler/rack-mini-profiler) in development, you really should be. Even better, you should be using it in production:

- https://github.com/codetriage/codetriage/commit/7cbe92bf7f9bd5cce3b726743b15a89a29e522ce
- https://github.com/codetriage/codetriage/commit/fce8322f2128b8bba531c9b2b329f22f34b89678

These two commits tell RMP that when someone is logged in and that person has an `admin` flag on their account to show them the rack-mini-profiler stats in the UI.

Here's what my index page looks like when I'm logged in.

![](https://www.dropbox.com/s/myl1360qa8lwk8e/Screenshot%202017-06-19%2010.47.05.png?dl=1)

When I click the tab in the top left, it expands and this is what I see:

![](https://www.dropbox.com/s/1rhci7acwm5rm1k/Screenshot%202017-06-19%2010.47.35.png?dl=1)

Of the 336ms page render time (on the server side), you can see that 281.6ms are being spent in:

```
Rendering: pages/_repos_with_pagination
```

You can also see that there's a link for `2 SQL` queries. When you click those this is what you see:

![](https://www.dropbox.com/s/i1nl2b6fuktq4vb/Screenshot%202017-06-19%2010.48.53.png?dl=1)

One SQL query takes 125ms and the other 118ms. Yikes!

Most of my other SQL queries take anywhere from 1-4ms so this is pretty bad. Over 70% of my time spent rendering my index page is spent in these two queries.

If you ever have a query that you don't know why it's slow, you can use EXPLAIN ANALYZE` with Postgres:

```SQL
$ heroku pg:psql
issuetriage::DATABASE=> EXPLAIN ANALYZE
SELECT COUNT(*)
FROM "repos"
WHERE (issues_count > 0);
                                                   QUERY PLAN
-----------------------------------------------------------------------------------------------------------------
Aggregate  (cost=39294.58..39294.58 rows=1 width=0) (actual time=115.217..115.217 rows=1 loops=1)
   ->  Seq Scan on repos  (cost=0.00..39293.48 rows=2198 width=0) (actual time=0.009..114.978 rows=2184 loops=1)
         Filter: (issues_count > 0)
         Rows Removed by Filter: 511
Total runtime: 115.253 ms
(5 rows)
```

This confirms the total time is pretty bad 115ms. I'm doing this in production so that I have production like data.

In this case, I'm doing a simple count, so why are things so slow? When you look at the output this line should jump out at you:

```SQL
->  Seq Scan on repos  (cost=0.00..39293.48 rows=2198 width=0) (actual time=0.009..114.978 rows=2184 loops=1)
```

The database has to loop over ALL records just to find the ones that have an issue count greater than zero.

The next query in our problem output has bind parameters in it:

```
SELECT
"repos".*
FROM "repos"
WHERE (issues_count > 0)
ORDER BY issues_count DESC
LIMIT $1
OFFSET $2;
```

We can replace these with some reasonable values, such as a limit of 20 and an offset of 0.

```SQL
issuetriage::DATABASE=> EXPLAIN ANALYZE
SELECT  "repos".* FROM "repos"
WHERE (issues_count > 0)
ORDER BY issues_count DESC
LIMIT 20
OFFSET 0;
                                                        QUERY PLAN
--------------------------------------------------------------------------------------------------------------------------
Limit  (cost=39305.18..39305.19 rows=20 width=1541) (actual time=150.109..150.113 rows=20 loops=1)
   ->  Sort  (cost=39305.18..39306.28 rows=2198 width=1541) (actual time=150.108..150.111 rows=20 loops=1)
         Sort Key: issues_count
         Sort Method: top-N heapsort  Memory: 65kB
         ->  Seq Scan on repos  (cost=0.00..39293.48 rows=2198 width=1541) (actual time=0.023..148.889 rows=2184 loops=1)
               Filter: (issues_count > 0)
               Rows Removed by Filter: 511
Total runtime: 150.160 ms
```

Even though we're using a limit, we have to order all the entries in our database by that value in the `order` clause before we can apply the limit. This means we have to sort all the values, which is why you're seeing that `sort` call. Later you're seeing the same sequential scan since we're also applying the same where clause (to not show `issues_count`-s of 0).

So what's the fix? In this case, it's pretty simple. We can give the database more information about the data that it needs to sort and filter by adding an index.

Indexes aren't magic remedies, there is a downside as they use memory in your database, which is not free. In this case, I only have about 2K repos in the DB so the index is well worth the cost. Alternatively, I could consider caching the view elements to not do those expensive lookups on the first page. I could even change the view to be a simple `next` button, and then I could have avoided having to count all the repos.

So there are multiple fixes possible, but in my case adding an index was the easiest. Again thanks to [Nate Berkopec](https://www.speedshop.co/) for pointing this out. I didn't figure this all out on my own, he did. He also has a book explaining how to debug and profile common performance issues like this that's worth picking up.

What's the end result? We can re-run our `EXPLAIN ANALYZE` and get some really good feedback:

```SQL
issuetriage::DATABASE=> EXPLAIN ANALYZE
SELECT  "repos".*
FROM "repos"
WHERE (issues_count > 0)
ORDER BY issues_count DESC
LIMIT 20
OFFSET 0;
                                                                         QUERY PLAN
------------------------------------------------------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.06..45.61 rows=20 width=1541) (actual time=0.019..0.050 rows=20 loops=1)
   ->  Index Scan Backward using index_repos_on_issues_count on repos  (cost=0.06..4980.92 rows=2187 width=1541) (actual time=0.017..0.047 rows=20 loops=1)
         Index Cond: (issues_count > 0)
 Total runtime: 0.084 ms
(4 rows)
```

From over 100ms to under 1ms not bad, what about the other?

```SQL
issuetriage::DATABASE=> EXPLAIN ANALYZE
SELECT COUNT(*) FROM "repos"
WHERE (issues_count > 0);
                                                                     QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------------------------------------
 Aggregate  (cost=75.33..75.33 rows=1 width=0) (actual time=1.713..1.713 rows=1 loops=1)
   ->  Index Only Scan using index_repos_on_issues_count on repos  (cost=0.06..74.23 rows=2187 width=0) (actual time=0.034..1.578 rows=2184 loops=1)
         Index Cond: (issues_count > 0)
         Heap Fetches: 618
 Total runtime: 1.757 ms
(5 rows)
```

Not too shabby either. The overall page render time went from 336ms to 169ms:

![](https://www.dropbox.com/s/jap4z2c4crhwyjl/Screenshot%202017-06-19%2011.05.47.png?dl=1)

That partial where we are calling these queries still accounts for 55ms, but it's much better than the previously 281.6ms. They say that a 200ms wait time is perceptible to a human, so in theory this just saved me a few "ugh why is this so slow"-s per day. Better than that, it also means that my index page can handle slightly more throughput as it won't be hanging around waiting for slow queries to finish.

Bottom line: Don't neglect your pagination queries when speeding up your app, and go by [Nate's book](https://www.railsspeed.com/).

