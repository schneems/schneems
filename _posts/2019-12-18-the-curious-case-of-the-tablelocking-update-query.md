---
title: "The Curious Case of the Table-Locking UPDATE Query"
layout: post
published: true
date: 2019-12-18
permalink: /2019/12/18/the-curious-case-of-the-tablelocking-update-query/
categories:
    - ruby
    - database
    - performance

image_url: https://www.dropbox.com/s/8712hijlmtzvxwz/Screenshot%202019-12-18%2013.21.06.png?raw=1
---

I maintain an internal-facing service at Heroku that does metadata processing. It's not real-time, so there's plenty of slack for when things go wrong. Recently I discovered that the system was getting bogged down to the point where no jobs were being executed at all. After hours of debugging, I found the problem was an `UPDATE` on a single row on a single table was causing the entire table to lock, which caused a lock queue and ground the whole process to a halt. This post is a story about how the problem was debugged and fixed and why such a seemingly simple query caused so much harm.

>This post originaly published on the [Heroku blog](https://blog.heroku.com/curious-case-table-locking-update-query)

## No jobs processing

I started debugging when the backlog on our system began to grow, and the number of jobs being processed fell to nearly zero. The system has been running in production for years, and while there have been occasional performance issues, nothing stood out as a huge problem. I checked our datastores, and they were well under their limits, I checked our error tracker and didn't see any smoking guns. My best guess was the database where the results were being stored was having problems.

The first thing I did was run `heroku pg:diagnose`, which shows "red" (critical) and "yellow" (important but less critical) issues. It showed that I had queries that had been running for DAYS:


```
68698   5 days 18:01:26.446979 \
  UPDATE "table" \
  SET <values> \
  WHERE ("uuid" = '<uuid>') \
```

Which seemed odd. The query in question was a simple update, and it's not even on the most massive table in the DB. When I checked `heroku pg:outliers` from the [pg extras CLI plugin](https://github.com/heroku/heroku-pg-extras) I was surprised to see this update taking up 80%+ of the time even though it is smaller than the largest table in the database by a factor of 200. So what gives?

Running the update statement manually didn't reproduce the issue, so I was fresh out of ideas. If it had, then I could have run with `EXPLAIN ANALYZE` to see why it was so slow. Luckily I work with some pretty fantastic database engineers, and I pinged them for possible ideas. They mentioned that there might be a locking issue with the database. The idea was strange to me since it had been running relatively unchanged for an extremely long time and only now started to see problems, but I decided to look into it.


```language-sql
SELECT
  S.pid,
  age(clock_timestamp(), query_start),
  query,
  L.mode,
  L.locktype,
  L.granted
FROM pg_stat_activity S
inner join pg_locks L on S.pid = L.pid
order by L.granted, L.pid DESC;
-----------------------------------
pid      | 127624
age      | 2 days 01:45:00.416267
query    | UPDATE "table" SET <values> WHERE ("uuid" = '<uuid>')
mode     | AccessExclusiveLock
locktype | tuple
granted  | f
```

I saw a ton of queries that were hung for quite some time, and most of them pointed to my seemingly teeny `UPDATE` statement.

## All about locks

Up until this point, I basically knew nothing about how PostgreSQL uses locking other than in an explicit advisory lock, which can be used via a gem like [pg_lock](https://github.com/heroku/pg_lock) (That I maintain). Luckily Postgres has excellent docs around locks, but it's a bit much if you're new to the field: [Postgresql Lock documentation](https://www.postgresql.org/docs/11/explicit-locking.html#LOCKING-TABLES)

Looking up the name of the lock from before `Access Exclusive Lock` I saw that it locks the whole table:

>ACCESS EXCLUSIVE
>Conflicts with locks of all modes (ACCESS SHARE, ROW SHARE, ROW EXCLUSIVE, SHARE UPDATE EXCLUSIVE, SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, and ACCESS EXCLUSIVE). This mode guarantees that the holder is the only transaction accessing the table in any way.
>Acquired by the DROP TABLE, TRUNCATE, REINDEX, CLUSTER, VACUUM FULL, and REFRESH MATERIALIZED VIEW (without CONCURRENTLY) commands. Many forms of ALTER TABLE also acquire a lock at this level (see ALTER TABLE). This is also the default lock mode for LOCK TABLE statements that do not specify a mode explicitly.

From the docs, this lock is not typically triggered by an `UPDATE`, so what gives? Grepping through the docs showed me that an `UPDATE` should trigger a `ROW SHARE` lock:

```
ROW EXCLUSIVE
Conflicts with the SHARE, SHARE ROW EXCLUSIVE, EXCLUSIVE, and ACCESS EXCLUSIVE lock modes.

The commands UPDATE, DELETE, and INSERT acquire this lock mode on the target table (in addition to ACCESS SHARE locks on any other referenced tables). In general, this lock mode will be acquired by any command that modifies data in a table.
```

> A database engineer directly told me what kind of lock an `UPDATE` should use, but you could find it in the docs if you don't have access to some excellent database professionals.

Mostly what happens when you try to `UPDATE` is that Postgres will acquire a lock on the row that you want to change. If you have two update statements running at the same time on the same row, then the second must wait for the first to process. So why on earth, if an `UPDATE` is supposed only to take out a row lock, was my query taking out a lock against the whole table?

## Unmasking a locking mystery

I would love to tell you that I have a really great debugging tool to tell you about here, but I mostly duck-duck-go-ed (searched) a ton and eventually found [this forum post](https://grokbase.com/t/postgresql/pgsql-general/124s02j3jy/updates-sharelocks-rowexclusivelocks-and-deadlocks). In the post someone is complaining about a similar behavior, they're using an update but are seeing more aggressive lock being used sometimes.

Based on the responses to the forum it sounded like if there is more than a few `UPDATE` queries that are trying to modify the same row at the same time what happens is that one of the queries will try to acquire the lock, see it is taken then it will instead acquire a larger lock on the table. Postgres queues locks, so if this happens for multiple rows with similar contention, then multiple queries would be taking out locks on the whole table, which somewhat could explain the behavior I was seeing. It seemed plausible, but why was there such a problem?

I combed over my codebase and couldn't find anything. Then as I was laying down to go to bed that evening, I had a moment of inspiration where I remembered that we were updating the database in parallel for the same UUID using threads:

```language-ruby
@things.map do |thing|
  Concurrent::Promise.execute(executor: :fast) do
    store_results!(thing)
  end
end.each(&:value!)
```

In every loop, we were creating a promise that would concurrently update values (using a thread pool). Due to a design decision from years ago, each loop causes an `UPDATE` to the same row in the database for each job being run. This programming pattern was never a problem before because, as I mentioned earlier, there's another table with more than 200x the number of records, so we've never had any issues with this scheme until recently.

With this new theory, I removed the concurrency, which meant that each `UPDATE` call would be sequential instead of in parallel:

```language-ruby
@things.map do |thing|
  store_results!(thing)
end
```

While the code is less efficiently in the use of IO on the Ruby program, it means that the chance that the same row will try to be updated at the same time is drastically decreased.

I manually killed the long-running locked queries using `SELECT pg_cancel_backend(<pid>);` and I deployed this change (in the morning after a code review).

Once the old stuck queries were aborted, and the new code was in place, then the system promptly got back up and running, churning through plenty of backlog.

## Locks and stuff

While this somewhat obscure debugging story might not be directly relevant to your database, here are some things you can take away from this article. Your database has locks (think mutexes but with varying scope), and those locks can mess up your day if they're doing something different than you're expecting. You can see the locks that your database is currently using by running the `heroku pg:locks` command (may need to install the `pg:extras` plugin). You can also see which queries are taking out which locks using the SQL query I posted earlier.

The next thing I want to cover is documentation. If it weren't for several very experienced Postgres experts and a seemingly random forum post about how multiple `UPDATE` statements can trigger a more aggressive lock type, then I never would have figured this out. If you're familiar with the Postgres documentation, is this behavior written down anywhere? If so, then could we make it easier to find or understand somehow? If it's not written down, can you help me document it? I don't mind writing documentation, but I'm not totally sure what the expected behavior is. For instance, why does a lock queue for a row that goes above a specific threshold trigger a table lock? And what exactly is that threshold? I'm sure this behavior makes total sense from an implementation point of view, but as an end-user, I would like it to be spelled out and officially documented.

I hope you either learned a thing or two or at least got a kick out of my misery. This issue was a pain to debug, but in hindsight, a quirky bug to blog about. Thanks for reading!

And to learn about another potential database issue, check out this other blog post by Heroku Engineer Ben Fritsch, [Know Your Database Types](https://blog.heroku.com/know-your-database-types).

Special thanks to [Matthew Blewitt](https://github.com/mble) and [Andy Cooper](https://github.com/andscoop) for helping me debug this!
