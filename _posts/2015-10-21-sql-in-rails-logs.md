---
layout: post
title: "SQL statements in Rails logs"
date: 2015-10-27
published: true
author_name: Richard Schneeman
author_url: https://ruby.social/@Schneems
---

Sometimes in programming, the smallest things are the most helpful. I remember wowing a co-worker when I hit CTRL+A and my cursor jumped to the beginning of a long terminal command. Since then, I've vowed that no tip is too small to share. Today, my tip is for getting Rails SQL statements and Cache behavior in production logs locally. It's pretty simple. If you're using `rails_12factor` gem to output your logs to standard out, then all you need to do is boot up your server with `LOG_LEVEL=debug`, like this:

```
$ RAILS_ENV=production LOG_LEVEL=debug rails s
```

Now you'll get all your SQL statements in the output:

```
[729e4a51-f83c-4862-bc68-a1842e806696] Started GET "/repotag/rjgit" for ::1 at 2015-10-21 11:47:34 -0500
[729e4a51-f83c-4862-bc68-a1842e806696] Processing by ReposController#show as HTML
[729e4a51-f83c-4862-bc68-a1842e806696]   Parameters: {"full_name"=>"repotag/rjgit"}
[729e4a51-f83c-4862-bc68-a1842e806696]   Repo Load (1.0ms)  SELECT  "repos".* FROM "repos" WHERE "repos"."full_name" = $1 LIMIT 1  [["full_name", "repotag/rjgit"]]
[729e4a51-f83c-4862-bc68-a1842e806696]   Issue Load (83.2ms)  SELECT "issues".* FROM "issues" WHERE "issues"."repo_id" IN (988)
[729e4a51-f83c-4862-bc68-a1842e806696]    (2.0ms)  SELECT COUNT(*) FROM "users" INNER JOIN "repo_subscriptions" ON "users"."id" = "repo_subscriptions"."user_id" WHERE "repo_subscriptions"."repo_id" = $1  [["repo_id", 988]]
[729e4a51-f83c-4862-bc68-a1842e806696]   User Load (1.7ms)  SELECT  "users".* FROM "users" INNER JOIN "repo_subscriptions" ON "users"."id" = "repo_subscriptions"."user_id" WHERE "repo_subscriptions"."repo_id" = $1 AND ("users"."private" != 't') LIMIT 27  [["repo_id", 988]]
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered subscribers/_avatars.html.slim (7.4ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   CACHE (0.0ms)  SELECT COUNT(*) FROM "users" INNER JOIN "repo_subscriptions" ON "users"."id" = "repo_subscriptions"."user_id" WHERE "repo_subscriptions"."repo_id" = $1  [["repo_id", 988]]
[729e4a51-f83c-4862-bc68-a1842e806696]    (1.6ms)  SELECT COUNT(count_column) FROM (SELECT  1 AS count_column FROM "users" INNER JOIN "repo_subscriptions" ON "users"."id" = "repo_subscriptions"."user_id" WHERE "repo_subscriptions"."repo_id" = $1 AND ("users"."private" != 't') LIMIT 27) subquery_for_count  [["repo_id", 988]]
[729e4a51-f83c-4862-bc68-a1842e806696]   Issue Load (80.4ms)  SELECT  "issues".* FROM "issues" WHERE "issues"."repo_id" = $1 AND "issues"."state" = $2  ORDER BY created_at DESC LIMIT 20 OFFSET 0  [["repo_id", 988], ["state", "open"]]
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered repos/show.html.slim within layouts/application (132.3ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_head.html.slim (6.5ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_flashes.html.slim (3.5ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_logo.html.slim (9.4ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_nav.html.slim (21.1ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_thoughtbot.html.slim (3.2ms)
[729e4a51-f83c-4862-bc68-a1842e806696]   Rendered application/_footer.html.slim (13.3ms)
[729e4a51-f83c-4862-bc68-a1842e806696] Completed 200 OK in 375ms (Views: 121.2ms | ActiveRecord: 178.6ms)
```

So, what can you do with that? You get the timing information with each SQL call and each partial render, isolate one that is slow and dig in. You can use `EXPLAIN ANALYZE` on sql queries to see if you're missing indexes (though, note that the syntax at the end isn't valid SQL, you'll need to manually substitute values). You can use noisey SQL calls to find N+1 queries. There's a wealth of speed info right there in your logs.

You'll even get cache hit information:

```
[94ff47da-4ce1-4635-a351-1933801e340c] Started GET "/" for ::1 at 2015-10-21 14:10:16 -0500
[94ff47da-4ce1-4635-a351-1933801e340c] Processing by PagesController#index as HTML
[94ff47da-4ce1-4635-a351-1933801e340c]    (2.4ms)  SELECT COUNT(*) FROM "users"
[94ff47da-4ce1-4635-a351-1933801e340c]    (0.9ms)  SELECT COUNT(*) FROM "repos"
[94ff47da-4ce1-4635-a351-1933801e340c]   Rendered application/_github.html.slim (1.9ms)
[94ff47da-4ce1-4635-a351-1933801e340c]   Rendered application/_down.html.slim (3.0ms)
[94ff47da-4ce1-4635-a351-1933801e340c]   Repo Load (1.1ms)  SELECT DISTINCT language FROM "repos"
[94ff47da-4ce1-4635-a351-1933801e340c]   Repo Load (1.3ms)  SELECT  "repos".* FROM "repos" WHERE (issues_count > 0)  ORDER BY issues_count DESC LIMIT 10 OFFSET 0
[94ff47da-4ce1-4635-a351-1933801e340c]    (0.6ms)  SELECT COUNT(*) FROM "repos" WHERE (issues_count > 0)
[94ff47da-4ce1-4635-a351-1933801e340c]   Cache digest for app/views/repos/_repo.html.slim: aa8c513a57bfdcd94630b4f9de18efe2
[94ff47da-4ce1-4635-a351-1933801e340c]   Cache digest for app/views/pages/_repos_with_pagination.html.slim: c5aef60bba7aa653b57beb58f58905ef
[94ff47da-4ce1-4635-a351-1933801e340c] Cache read_multi: ["views/repos/696-20150302152054739843000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/1224-20150302161524469739000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/297-20150302144607625400000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/987-20150302155234667489000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/186-20150302143211298695000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/839-20150302153126399409000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/845-20150302153500118622000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/1240-20150302161400575160000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/28-20150302140547910840000/c5aef60bba7aa653b57beb58f58905ef", "views/repos/47-20150302141042221265000/c5aef60bba7aa653b57beb58f58905ef"]
```

Remember, if you're debugging speed issues, you should be running in `production` mode so that all of your caching is enabled. Otherwise you might spend a good amount of time "fixing" something that is already cached. Oh, and while you're at it, add the [bullet gem](https://github.com/flyerhzm/bullet) to your project. You'll be glad you did. That's all. Short and sweet.
