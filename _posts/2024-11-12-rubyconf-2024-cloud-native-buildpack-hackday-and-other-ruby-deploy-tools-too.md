---
title: "RubyConf 2024: Cloud Native Buildpack Hackday (and other Ruby deploy tools, too!) "
layout: post
published: true
date: 2024-11-11
permalink: /rubyconf-2024-hackday/
categories:
    - ruby
image_url: https://www.dropbox.com/s/e4id8bgvhn8n9s5/Screenshot%202024-11-12%20at%2012.02.52%E2%80%AFPM.png?raw=1
---

I've spent the last decade+ working on Ruby deploy tooling, including (but not limited to) the Heroku classic and upcoming Cloud Native Buildpack. If you want to contribute to a Ruby deployment or packaging tool (even if it's not one I maintain), I can help. If you want to learn more about Cloud Native Buildpacks (CNBs) and maybe get a green square on GitHub (or TWO!), keep reading for more resources.

> Note: This post is for an in-person hackday event at RubyConf 2024 happening on Thursday, November 14th. If you found this but are away from the event, you can still follow along, but I won't be available for in-person collaboration.

## What is a buildpack?

If you're new to Cloud Native Buildpacks, it's a way to generate OCI images (like docker) without a Dockerfile. Buildpacks take your application code on disk as input and inspect it to determine that it's a Ruby app and needs to install gems with a bundler.

If you've never heard of a buildpack, here are some getting-started guides you can try if you find a bug or run into questions. I can help.

- What is a CNB?
    - Follow buildpacks.io tutorial https://buildpacks.io/docs/
- Using a CNB -
    - heroku/Ruby tutorial https://github.com/heroku/buildpacks/blob/main/docs/ruby/README.md
    - Paketo tutorial https://paketo.io/docs/howto/ruby/

## Hacking ideas

Once you've played with a buildpack, you're ready for prime-time. Below, you'll find some sample things to hack on. You can tackle one by yourself, if you're ready, or

### heroku/ruby-buildpack issues

- Anything on https://github.com/heroku/buildpacks-ruby/issues. Look for the "help wanted" tag.

### Deny unknown fields

A well-scoped-out task with a change example involves modifying code but requires minimal rust knowledge.

- Link: https://github.com/heroku/buildpacks-ruby/issues/272
- Effort: Low
- Impact: Medium
- Requires: Code editor, installing rust

### Test drive Hanami with a Ruby CNB

Test drive Hanami with a Ruby CNB, document the experience and suggest changes or fixes.

- Effort: low
- Impact: low
- Requires: Ruby

### Update error messages

https://github.com/heroku/buildpacks-ruby/issues/333

- Effort low
- Impact: low
- Requires: Code editor, installing rust

### Warn when no `bin/rails` file found

https://github.com/heroku/buildpacks-ruby/issues/298

- Effort: Medium
- Impact: Medium
- Requires: Writing Rust

### Build a CNB with Rust, bash, or Ruby

No link. Write a Cloud Native Buildpack.

- Effort: Medium
- Impact: Unknown

### Add `.ruby-version` support

- Link: https://github.com/heroku/buildpacks-ruby/issues/346
- Effort High
- Impact: High
- Requires: Rust proficiency

