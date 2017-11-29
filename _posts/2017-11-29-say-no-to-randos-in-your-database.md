---
title: "Say No to Randos (in Your Database)"
layout: post
published: true
date: 2017-11-29
image: og/randos.png
permalink: /2017/11/29/say-no-to-randos-in-your-database/
categories:
    - ruby
    - sql
    - random()
    - performance
    - query
    - postgres
    - postgresql
---

When I used my first ORM, I wondered "why didn't they include a `random()` method?" It seemed like such an easy thing to add, and I used it all the time. While there are many reasons you may want to pull a record out of your database at random, you shouldn't be using SQL's `RANDOM()` function unless you'll only be randomizing a limited number of records. In this post, we'll examine how such a simple looking SQL operator can cause a lot of pain, and a few different techniques we can use to fix it.

As you might know, I run [CodeTriage, the best way to get started helping open source](https://www.codetriage.com) and I've written about improving the database performance on that site:

- [Finding Slow queries with Rack Mini Profiler](https://schneems.com/2017/06/22/a-tale-of-slow-pagination/)
- [Finding Slow Queries with Heroku's Expensive Query Dashboard](https://www.schneems.com/2017/07/11/using-herokus-expensive-query-dashboard-to-speed-up-your-app/)
- [How I Reduced my DB server load by 80%](https://www.schneems.com/2017/07/18/how-i-reduced-my-db-server-load-by-80/)

Recently, I was running the `heroku pg:outliers` command to see what it looked like after some of those optimizations, and I was surprised to find I was spending 32% of database time in two queries with a `RANDOM()` in them.

```term
$ heroku pg:outliers
14:52:35.890252 | 19.9%          | 186,846    | 02:38:39.448613 | SELECT  "repos".* FROM "repos" WHERE (repos.id not in (?,?)) ORDER BY random() LIMIT $1
08:59:35.017667 | 12.1%          | 2,532,339  | 00:01:13.506894 | SELECT  "users".* FROM "users" WHERE ("users"."github_access_token" IS NOT NULL) ORDER BY RANDOM() LIMIT $1
 ```

Let's take a look at the first query to understand why it's slow.

```sql
SELECT
  "repos".*
FROM "repos"
WHERE
  (repos.id not in (?,?))
ORDER BY
  random()
LIMIT $1
```

This query is used once a week to encourage users to sign up to "triage" issues on an open source repo if they have an account, but aren't subscribed to help out. We send an email with 3 repo suggestions including a [random repo](https://github.com/codetriage/codetriage/blob/49b243f1a295ecb19b4e2efa75aa38bd6ec5e2bf/app/mailers/user_mailer.rb#L42). That seems like a good use of `RANDOM()` after all, we literally want a random result. Why is this bad?

While we're telling Postgres to only give us 1 record, the `ORDER BY random() LIMIT 1` doesn't only do that. It orders ALL the records before returning one.

While you might think it's doing something like `Array#sample` it's really doing `Array#shuffle.first`. When I wrote this code, it was pretty dang fast. But now there are 2,761 repos and growing. And EVERY time this query executes, the database must load rows for each of those repos and spend CPU power to shuffle them.

You can see another query that was doing the same thing with the user table:

```sql
=> EXPLAIN ANALYZE SELECT  "users".* FROM "users" WHERE ("users"."github_access_token" IS NOT NULL) ORDER BY RANDOM() LIMIT 1;

                                                      QUERY PLAN
-----------------------------------------------------------------------------------------------------------------------
 Limit  (cost=1471.00..1471.01 rows=1 width=2098) (actual time=12.747..12.748 rows=1 loops=1)
   ->  Sort  (cost=1471.00..1475.24 rows=8464 width=2098) (actual time=12.745..12.745 rows=1 loops=1)
         Sort Key: (random())
         Sort Method: top-N heapsort  Memory: 26kB
         ->  Seq Scan on users  (cost=0.00..1462.54 rows=8464 width=2098) (actual time=0.013..7.327 rows=8726 loops=1)
               Filter: (github_access_token IS NOT NULL)
               Rows Removed by Filter: 13510
 Total runtime: 12.811 ms
(8 rows)
```

It takes almost 13ms for each execution of a relatively small query.

So if `RANDOM()` is bad, what do we fix it with? This is a surprisingly difficult question. It largely depends on your application and how you're accessing the data.

In my case, [I fixed the issue by generating a Random ID and then pulling that record](https://github.com/codetriage/codetriage/pull/647). In this instance, I know that the IDs are relatively contiguous, so I pull the highest ID, pick a random number between 1 and `@@max_id`, then perform a query where I'm grabbing a record `>=` that id.

Is it faster? Oh yeah. Here's the same query as before with the `RANDOM()` replaced:

```sql
=> EXPLAIN ANALYZE SELECT  "users".* FROM "users" WHERE ("users"."github_access_token" IS NOT NULL) AND id >= 55 LIMIT 1;
                                                  QUERY PLAN
--------------------------------------------------------------------------------------------------------------
 Limit  (cost=0.00..0.17 rows=1 width=2098) (actual time=0.009..0.009 rows=1 loops=1)
   ->  Seq Scan on users  (cost=0.00..1469.36 rows=8459 width=2098) (actual time=0.009..0.009 rows=1 loops=1)
         Filter: ((github_access_token IS NOT NULL) AND (id >= 55))
 Total runtime: 0.039 ms
```

We went from ~13ms to sub 1ms query execution time.

There are are some pretty severe caveats here to watch out for. My implementation caches the max id, which is fine for my use cases, but it might not be for yours. It's possible to do this entirely in SQL using something like:

```sql
WHERE
  /* ... */
  AND id IN (
    SELECT
    FLOOR(
      RANDOM() * (SELECT MAX(id) FROM issues)
    ) + 1
  )
```

As always, benchmark your SQL queries before and after an optimization. This implementation doesn't handle sparsely populated ID values very well, and doesn't account for randomly selecting a max id that is greater than one available based on `WHERE` conditions. Essentially, if you were to do it "right", you would need to apply the same `WHERE` conditions to the subquery for `MAX(id)` as to your main query.

For my cases, it's fine if I get some failures, and I know that I'm only applying the most basic of `WHERE` conditions. Your needs might not be so flexible.

If you're thinking "is there no built-in way to do this?", there is `TABLESAMPLE`, which was introduced in [Postgres 9.5](https://www.postgresql.org/docs/9.5/static/tablesample-method.html). Thanks to [@HotFusionMan](https://twitter.com/HotFusionMan) for introducing it to me.

Here's the [best blog I've found on using TABLESAMPLE](https://blog.2ndquadrant.com/tablesample-in-postgresql-9-5-2/). The downside is that it's not "truly random" (if that matters to your application), and you cannot use it to only retrieve 1 result. I was able to hack it by doing a query that the only table sampled 1%. Then I used that 1% to get ids and then limited to the first record. Something like:

```sql
SELECT
  *
FROM repos
WHERE
  id IN (
    SELECT
      id
    FROM repos
    TABLESAMPLE SYSTEM(1) /* 1 percent */
  )
LIMIT 1
```

While this works and is much faster for queries returning LOTS of data (thousands or tens of thousands of rows), it's very slow for queries that have very little data. I have another query that uses `RANDOM()` to find open source issues for a specific repo. While some repos have thousands of issues, 50% have 27 or fewer issues. When I used the `TABLESAMPLE` technique for this query, it made my small queries really slow, and my previously slow queries fast. Since my numbers skew towards the small side for that query, it wasn't a net gain, so I stuck to the original `RANDOM()` method.

Have you replaced `RANDOM()` with another more efficient technique? Let me know about it to Twitter [@schneems](https://twitter.com/schneems).


