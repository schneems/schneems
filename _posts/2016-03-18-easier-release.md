---
layout: post
title: Easier Gem Releases with Bundler Release Tasks
subtitle:
date: 2016-03-18
published: true
author_name: Richard Schneeman
author_url: https://www.schneems.com
permalink: blogs/2016-03-18-bundler-release-tasks
---

If you maintain a gem and aren't using Bundler's release rake tasks you're missing out. If you have a well maintained gem, then the best practice is to tag a release every time you push a new gem version to RubyGems.org. This helps users to see differences between versions. For example you can compare releases on the Heroku Ruby Buildpack https://github.com/heroku/heroku-buildpack-ruby/compare/v142...v143. Bundler comes with a Rake task that simplifies tagging a release and pushing a version to RubyGems.

To use the rake tasks, you'll need a Rakefile in your project. In that Rakefile you'll need to add:

```
require 'bundler/gem_tasks'
```

You can see [this line in derailed_benchmarks](https://github.com/schneems/derailed_benchmarks/blob/b56fe251f6b07fcd5c787cc326bf3dabae72097e/Rakefile#L4). Now you can see available tasks by running:

```
$ bundle exec rake -T
rake build            # Build derailed-0.1.0.gem into the pkg directory
rake clean            # Remove any temporary products
rake clobber          # Remove any generated files
rake install          # Build and install derailed-0.1.0.gem into system gems
rake install:local    # Build and install derailed-0.1.0.gem into system gems without network access
rake release[remote]  # Create tag v0.1.0 and build and push derailed-0.1.0.gem to Rubygems
```

To cut a new release, you rev the version of your gem, commit to git and then run:

```
$ bundle exec rake release
```

That will create a tag, push to GitHub and push your latest version to Rubygems. It's that easy. Using the task also ensures that the latest code you have locally is on GitHub, I've been guilty before of fixing a problem and forgetting to push to master after I cut a RubyGems release. If you're not tagging your gem release versions on GitHub, you should start. If you already are tagging manually, you can save yourself a few commands with this simple trick. Go now, I `rake release` you.

