---
title: "Migrating a Ruby Library from TravisCI to CircleCI"
layout: post
published: true
date: 2021-01-13
permalink: /2021/01/13/migrating-a-ruby-library-from-travisci-to-circleci/
image_url: https://www.dropbox.com/s/hgsovros8uxyndw/Screen%20Shot%202021-01-13%20at%208.58.40%20AM.png?raw=1
categories:
    - ruby
    - ci
    - testing
---

TravisCI.org is dead. Long live the new CI! TravisCI.org was THE way to run CI for an open source Ruby library. It was so easy that it was seemingly effortless. Even better, it was free. Since the slow-motion collapse of the product, developers have been pushed to other CI providers. I was recently tasked with transferring CI away from Travis for my library [derailed_benchmarks](github.com/schneems/derailed_benchmarks) and chose CircleCI. This post is a little about why I chose CircleCI, a little about how the transition worked, and a little about nostalgia.

## Nostalgia first

I vividly remember when I was working for Gowalla, we had no CI. I didn't even KNOW what CI was until we got a new employee [Brad Fults](https://twitter.com/h3h). Brad set up Jenkins on a mac mini, and slowly my world was transformed.

We didn't have a strong testing culture when I started at Gowalla. I printed out a sign that read "ask me about Rspec" and taped it above my desk. We did have tests though. One issue that I had with testing is that everyone was expected to run tests locally before pushing to GitHub (or prod). But people wouldn't, or they would forget. Sometimes it would work on their machine but break on someone else's. One of my first OSS libraries was attempting to fix this problem I named it [git_test](https://github.com/schneems/git_test). It would store the test results in git so you could see who was running tests and if they passed or failed.

After Brad set up the CI server, I didn't love it at first. The CI machine was always down, or tests would pass locally but fail on CI. It took me longer than I would like to admit to realize that my ambition around creating `git_test` was solved by having CI and that CI was a far superior solution.

About the time Brad was setting up Jenkins, waves were being made about a hot new startup called TravisCI. It had a slick interface and unbelievably was all open source. I don't remember if we ever transitioned over to using a CI provider at Gowalla. Still, I've come to rely on having a managed CI provider as an integral part of my software development practices over the years.

As Travis is shutting down their TravisCI.org, it feels like it's the marker of an end of an era. It felt a golden age filled with promise and hope for collaboration between open source and private companies. The "free" offering felt less like a marketing gimmick and more like a bold declaration, that a company could make money, open source it's own software, and support the community all at the same time. I mourn that.

## Why CircleCI?

I now work for Heroku, and we have our CI product [Heroku CI](https://www.heroku.com/continuous-integration). I love it for application development. Heroku CI is not a great fit for testing libraries, especially since there's no way to give global public access to the test output. In my day job, I use Heroku CI, and increasingly I've been using CircleCI for non-app testing. I like their tooling. You can use a local CLI for debugging and an easy "Run with SSH" option to debug in the cloud on their Hardware. That is a feature Travis never had. I've also interacted with their support several times and had great experiences.

> Note: This is 100% my opinion. No one from Heroku has reviewed this post. This message is not endorsed by anyone other than me.

While I know many people are transitioning over to GitHub Actions for CI, I changed my Twitter avatar to "GitHub drop ICE" to protest their contract with the (known human rights abusing) ICE agency. I try not to use GitHub actions when I don't have to. A less-political reason is performance.

I still use some actions like [this one that checks if a PR touched the CHANGELOG.md](https://github.com/zombocom/dead_end/blob/320dcfa4f314ed48e77d30e7b0151610205d8d8c/.github/workflows/check_changelog.yml). On this project, I also have CircleCI tests in Ruby, and frequently the CircleCI tests will boot, execute, and finish before the GitHub action even starts firing. While most of my test suites are dominated by the suite's length, those extra seconds can add up.

Debugability and tooling are also on my mind. I can run a CircleCI test locally via the CLI, but cannot with GitHub Actions.

I also feel like CircleCI is a CI company while Github Actions is a feature tacked on to a git hosting service. It's getting lots of love and resources now, but I don't know ten years from now if that will still be true.

## Transitioning from `.travis.yml` to `.circleci/config.yml`

Here's my original `.travis.yml` for `derailed_benchmarks`:

```yaml
language: ruby
rvm:
  - 2.2.10
  - 2.5.8
  - 2.7.1

gemfile:
  - gemfiles/rails_5_1.gemfile
  - gemfiles/rails_6_0.gemfile
  - gemfiles/rails_git.gemfile

jobs:
  allow_failures:
    - rvm: 2.2.10
      gemfile: gemfiles/rails_6_0.gemfile
    - rvm: 2.2.10
      gemfile: gemfiles/rails_git.gemfile
```

I love the compactness of this config. TravisCI was initially built with Ruby library maintainers in mind, and the compactness of the config in this case shows. It runs the tests (implicitly it knows to run `rake test`). It will run these tests against a "matrix" of Ruby versions (listed under `rvm`) and different gemfile contents (listed under `gemfile`). You can also see where I've configured it to skip some combinations that I know don't work (Ruby 2.2 does not work with Rails 6.0).

Now here's what I ended up with for a roughly equivalent CircleCI config (with some Ruby versions changed):

```yaml
version: 2.1
orbs:
  ruby: circleci/ruby@1.1.2
references:
  run_tests: &run_tests
    run:
      name: Run test suite
      command: bundle exec rake test
  # Needed because tests execute raw git commands
  set_git_config: &set_git_config
    run:
      name: Set Git config
      command: git config --global user.email "you@example.com"; git config --global user.name "Your Name"
  restore: &restore
    restore_cache:
      keys:
        - v1_bundler_deps-{{ .Environment.CIRCLE_JOB }}
  save: &save
    save_cache:
      paths:
        - ./vendor/bundle
      key: v1_bundler_deps-{{ .Environment.CIRCLE_JOB }} # CIRCLE_JOB e.g. "ruby-2.5"
  bundle: &bundle
    run:
      name: install dependencies
      command: |
        echo "export BUNDLE_JOBS=4" >> $BASH_ENV
        echo "export BUNDLE_RETRY=3" >> $BASH_ENV
        echo "export BUNDLE_PATH=$(pwd)/vendor/bundle" >> $BASH_ENV
        echo "export BUNDLE_GEMFILE=$(pwd)/gemfiles/$GEMFILE_NAME" >> $BASH_ENV
        source $BASH_ENV
        bundle install
        bundle update
        bundle clean

jobs:
  test:
    parameters:
      ruby_version:
        type: string
      gemfile:
        type: string
    docker:
      - image: "circleci/ruby:<< parameters.ruby_version >>"
    environment:
      GEMFILE_NAME: <<parameters.gemfile>>
    steps:
      - checkout
      - <<: *set_git_config
      - <<: *restore
      - <<: *bundle
      - <<: *run_tests
      - <<: *save

workflows:
  all-tests:
    jobs:
      - test:
          matrix:
            parameters:
              ruby_version: ["2.5", "2.7", "3.0"]
              gemfile: ["rails_5_2.gemfile", "rails_6_1.gemfile", "rails_git.gemfile"]
            exclude:
              - ruby_version: "3.0"
                gemfile: rails_5_2.gemfile
```

## Break it down, start at the end

The most important part of the CircleCI config file is at the bottom. This is where I'm telling it about how to run my tests:

```yaml
workflows:
  all-tests:
    jobs:
      - test:
          matrix:
            parameters:
              ruby_version: ["2.5", "2.7", "3.0"]
              gemfile: ["rails_5_2.gemfile", "rails_6_1.gemfile", "rails_git.gemfile"]
            exclude:
              - ruby_version: "3.0"
                gemfile: rails_5_2.gemfile
```

The `workflows` key is a special key, just like `jobs` and `version`. This last part says to define a workflow where it will run my job named `test` (defined above) with a test matrix that looks like this:


|          | rails_5_2.gemfile     | rails_6_1.gemfile     | rails_git.gemfile     |
|----------|-----------------------|-----------------------|-----------------------|
| Ruby 2.5 | rails_5_2.gemfile-2.5 | rails_6_1.gemfile-2.5 | rails_git.gemfile-2.5 |
| Ruby 2.7 | rails_5_2.gemfile-2.6 | rails_6_1.gemfile-2.6 | rails_git.gemfile-2.6 |
| Ruby 3.0 | skip                  | rails_6_1.gemfile-3.0 | rails_git.gemfile-3.0 |


Unlike TravisCI, Circle has no built-in understanding of Ruby or the gemfile, so we've got to define some lower-level primitives. In this case, we're creating a parameter named `ruby_version` and another named `gemfile`, then the permutations of these two parameters will be used to build the test matrix.

You can also see that there's a similar ability to "skip" combinations, though Circle uses the `exclude` keyword.

## Consuming parameters

Now let's look at the `test` job using the special keyword `jobs`:

```yaml
jobs:
  test:
    parameters:
      ruby_version:
        type: string
      gemfile:
        type: string
    docker:
      - image: "circleci/ruby:<< parameters.ruby_version >>"
    environment:
      GEMFILE_NAME: <<parameters.gemfile>>
    steps:
      - checkout
      - <<: *set_git_config
      - <<: *restore
      - <<: *bundle
      - <<: *run_tests
      - <<: *save
```

First, the job declares that it accepts two parameters and should both be treated as a "string".

```yaml
    parameters:
      ruby_version:
        type: string
      gemfile:
        type: string
```

Next is the docker/machine declaration:

```
    docker:
      - image: "circleci/ruby:<< parameters.ruby_version >>"
```

CircleCI has a large number of pre-built docker instances that can be used. It doesn't give me quite as much control as an `rvm install` via Travis, but since this is a library, I am mostly concerned with major and minor ruby versions. The parameters are substituted into this value using the `<< >>` syntax:

Next I set an environment variable via my `gemfile` parameter to be used in a script:

```yaml
    environment:
      GEMFILE_NAME: <<parameters.gemfile>>
```

The last thing in this section is the set of commands (or "steps") that will execute for each test:

```yaml
    steps:
      - checkout
      - <<: *set_git_config
      - <<: *restore
      - <<: *bundle
      - <<: *run_tests
      - <<: *save
```

Some steps are provided by CircleCI (like `checkout`), which checks out your source code, but you can either define yours inline like `- run: "echo 'lol'"` or you can use a reference as I've done here.

## References

Each reference is defined with a name and a command. The `restore` and `save` references use some other pre-defined keys like `restore_cache` and `save_cache`.

```yaml
references:
  run_tests: &run_tests
    run:
      name: Run test suite
      command: bundle exec rake test
  # Needed because tests execute raw git commands
  set_git_config: &set_git_config
    run:
      name: Set Git config
      command: git config --global user.email "you@example.com"; git config --global user.name "Your Name"
  restore: &restore
    restore_cache:
      keys:
        - v1_bundler_deps-{{ .Environment.CIRCLE_JOB }}
  save: &save
    save_cache:
      paths:
        - ./vendor/bundle
      key: v1_bundler_deps-{{ .Environment.CIRCLE_JOB }} # CIRCLE_JOB e.g. "ruby-2.5"
  bundle: &bundle
    run:
      name: install dependencies
      command: |
        echo "export BUNDLE_JOBS=4" >> $BASH_ENV
        echo "export BUNDLE_RETRY=3" >> $BASH_ENV
        echo "export BUNDLE_PATH=$(pwd)/vendor/bundle" >> $BASH_ENV
        echo "export BUNDLE_GEMFILE=$(pwd)/gemfiles/$GEMFILE_NAME" >> $BASH_ENV
        source $BASH_ENV
        bundle install
        bundle update
        bundle clean
```


Let's look at this in step order:

```yaml
    steps:
      - checkout
      - <<: *set_git_config
      - <<: *restore
      - <<: *bundle
      - <<: *run_tests
      - <<: *save
```

First is `set_git_config`:

```yaml
  # Needed because tests execute raw git commands
  set_git_config: &set_git_config
    run:
      name: Set Git config
      command: git config --global user.email "you@example.com"; git config --global user.name "Your Name"
```

As the comment states, I only need this because some derailed tests are using raw git commands. When it executes, it will run `git config --global user.email "you@example.com"; git config --global user.name "Your Name"` on the shell.

Next is restore:

```yaml
  restore: &restore
    restore_cache:
      keys:
        - v1_bundler_deps-{{ .Environment.CIRCLE_JOB }}
```

Here we're setting a cache key based on the name of the CircleCI job. I want to store Gem dependencies in the cache so that test runs are faster. Setting this cache key is how it knows which cache to restore.

Once the cache is loaded I can install dependencies:

```yaml
  bundle: &bundle
    run:
      name: install dependencies
      command: |
        echo "export BUNDLE_JOBS=4" >> $BASH_ENV
        echo "export BUNDLE_RETRY=3" >> $BASH_ENV
        echo "export BUNDLE_PATH=$(pwd)/vendor/bundle" >> $BASH_ENV
        echo "export BUNDLE_GEMFILE=$(pwd)/gemfiles/$GEMFILE_NAME" >> $BASH_ENV
        source $BASH_ENV

        bundle install
        bundle update
        bundle clean
```

A lot is going on here. I'm choosing to use bundler env vars instead of flags since some flags are deprecated. CircleCI needs to know about environment variable modifications between commands, so I'm writing to a file stored at $BASH_ENV that is sourced before every command.

Since derailed needs to test against many different Rails versions, it uses different Gemfile contents in the `gemfiles/` folder. To set the correct one based on the parameters I used before, I am reading from the GEMFILE_NAME env var:

```shell
        echo "export BUNDLE_GEMFILE=$(PWD)/gemfiles/$GEMFILE_NAME" >> $BASH_ENV
```

I needed this value to be an absolute path since the tests execute sub-shells in different directories, so the `$(PWD)` here gets expanded to be an absolute path.

When all that config is written, then I source the file:

```shell
        source $BASH_ENV
```

Then I install dependencies via `bundle install`. Perhaps surprisingly, I then run a `bundle update`. Since derailed is a library, I don't check in any Gemfile.lock since I don't control the specific library versions that apps will use. Instead, this `bundle update` is telling bundler to check for more recent dependencies. I also need this because I'm caching dependencies and don't want to get stuck on some ancient versions accidentally.

Finally, I execute `bundle clean`. That will remove any gem that's not currently in the recently generated Gemfile.lock, which prevents the cache from getting bloated with many gems that we no longer need.

CircleCI does provide a Ruby "orb," which is effectively some pre-packaged references that can be re-used. This concept is similar to GitHub action's "marketplace". The orb comes with some references to install a specific ruby version with RVM (which I don't need since the docker container already has it). The orb can also be used for installing dependencies via bundler. Unfortunately, the Ruby orb is mainly optimized around application development and doesn't expect things like the Gemfile to be in a different directory needed for library development. My method is verbose, but I feel pretty straightforward.

After dependencies are installed then they're cached:

```yaml
  save: &save
    save_cache:
      paths:
        - ./vendor/bundle
      key: v1_bundler_deps-{{ .Environment.CIRCLE_JOB }} # CIRCLE_JOB e.g. "ruby-2.5"
```

The last reference to mention is pretty self-explanatory:

```
  run_tests: &run_tests
    run:
      name: Run test suite
      command: bundle exec rake test
```

It runs my tests via `bundle exec rake test`. After all that, then my matrix of tests is up-and-running ship-shape.

## Version and orbs

The last thing to mention is the version and orb declaration:

```yaml
version: 2.1
orbs:
  ruby: circleci/ruby@1.1.2
```

The version, I believe, refers to the version of YAML API that you're using. You can validate your YAML using the CLI `$ circleci config validate`.

I previously mentioned orbs. I use them in other places to install dependencies, such as `pack` for [building Cloud Native docker images](https://github.com/heroku/heroku-buildpack-ruby/blob/ff7927dc5f93d89a45683895ac157d739bfbb2f1/.circleci/config.yml#L3). I initially thought that I might want to have more control over my specific Ruby version (such as Ruby 2.7.2 instead of whatever comes on `circleci/ruby:2.7`). However, I ended up not needing that flexibility. I kept the orb here to have an excuse to talk a bit more about orbs, though, because if you end up using CircleCI, you'll end up using orbs.

Here is an example of using the ruby orb via `ruby/install-deps` reference they provide in [their example Rails config](https://github.com/CircleCI-Public/circleci-demo-ruby-rails/blob/efc68981242c66aa8a6373029ae3f896eb19d778/.circleci/config.yml#L36).

## Retro

Honestly, this took a lot longer than I thought it would. I've not seen other people talk about using CircleCI for testing libraries, so I wanted to see what the result would look like. Overall I'm happy with the config results. Now that I've got the skeleton in place, making changes seems very easy, but it was a process to get here. I'm curious if anyone else uses CircleCI to test a library with multiple Ruby versions and multiple Gem files. If so, shoot me a link on Twitter [@schneems](https://twitter.com/schneems).

Here's some other examples of CircleCI test config for libraries:

- [valut-rails config.yml](https://github.com/hashicorp/vault-rails/blob/024ac42761a1e9491f4e502ad9c55c85f5c59d24/.circleci/config.yml)
- [apartment config.yml](https://github.com/rails-on-services/apartment/blob/30f08c4b41b448172b319a5c40a9ad69302359ef/.circleci/config.yml)

