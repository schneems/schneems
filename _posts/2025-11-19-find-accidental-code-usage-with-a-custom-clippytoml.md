---
title: "Disallow code usage with a custom `clippy.toml`"
layout: post
published: true
date: 2025-11-19
permalink: /2025/11/19/find-accidental-code-usage-with-a-custom-clippytoml/
image_url: https://www.dropbox.com/scl/fi/of3ftnwjv72p30n0g6nwb/Screenshot-2025-11-19-at-3.51.10-PM.png?rlkey=4hgvry025hjbh5pfz2gwy5web&raw=1
categories:
    - rust
---

I recently discovered that adding a `clippy.toml` file to the root of a Rust project gives the ability to disallow a method or a type when running `cargo clippy`. This has been really useful. I want to share two quick ways that I've used it: Enhancing `std::fs` calls via `fs_err` and protecting CWD threadsafety in tests.

> Update: you can also use this technique to [disallow unwrap()](https://blog.cloudflare.com/18-november-2025-outage/)!

## std lib enhancer

I use the [fs_err](https://github.com/andrewhickman/fs-err) crate in my projects, which provides the same filesystem API as `std::fs` but with one crucial difference: error messages it produces have the **name** of the file you're trying to modify. Recently, while I was skimming the issues, someone mentioned [using clippy.toml to deny `std::fs` usage](https://github.com/andrewhickman/fs-err/issues/71). I thought the idea was neat, so I tried it in my projects, and it worked like a charm. With this in the `clippy.toml` file:

```toml
disallowed-methods = [
    # Use fs_err functions, so the filename is available in the error message
    { path = "std::fs::canonicalize", replacement = "fs_err::canonicalize" },
    { path = "std::fs::copy", replacement = "fs_err::copy" },
    { path = "std::fs::create_dir", replacement = "fs_err::create_dir" },
    # ...
]
```

Someone running `cargo clippy` will get an error:

```term
$ cargo clippy
    Checking jruby_executable v0.0.0 (/Users/rschneeman/Documents/projects/work/docker-heroku-ruby-builder/jruby_executable)
    Checking shared v0.0.0 (/Users/rschneeman/Documents/projects/work/docker-heroku-ruby-builder/shared)
warning: use of a disallowed method `std::fs::canonicalize`
   --> ruby_executable/src/bin/ruby_build.rs:169:9
    |
169 |         std::fs::canonicalize(Path::new("."))?;
    |         ^^^^^^^^^^^^^^^^^^^^^ help: use: `fs_err::canonicalize`
    |
    = help: for further information visit https://rust-lang.github.io/rust-clippy/rust-1.91.0/index.html#disallowed_methods
    = note: `#[warn(clippy::disallowed_methods)]` on by default
```

Running `cargo clippy --fix` will now automatically update the code. Neat!

## CWD protector

Why was I skimming issues in the first place? I [suggested adding a feature to allow enhancing errors with debugging information](https://github.com/andrewhickman/fs-err/issues/55), so instead of:

```
failed to open file `file.txt`: The system cannot find the file specified. (os error 2)
```

The message could contain a lot more info:

```
failed to open file `file.txt`: The system cannot find the file specified. (os error 2)

Path does not exist `file.txt`
- Absolute path `/path/to/dir/file.txt`
- Missing `file.txt` from parent directory:
  `/path/to/dir`
    └── `file.md`
    └── `different.txt`
```

To implement that functionality, I wrote [path_facts](https://github.com/schneems/path_facts), a library that provides facts about your filesystem (for debugging purposes). And since the core value of the library is around producing good-looking output, I wanted snapshot tests that covered all my main branches. This includes content from both relative and absolute paths. A naive implementation might look like this:

```rust
let temp = tempfile::tempdir().unwrap();
std::env::set_current_dir(temp.path()).unwrap(); // <= Not thread safe

std::fs::write(Path::new("exists.txt"), "").unwrap();

insta::assert_snapshot!(
    PathFacts::new(path)
        .to_string()
        .replace(&temp.path().canonicalize().unwrap().display().to_string(), "/path/to/directory"),
    @r"
    exists `exists.txt`
     - Absolute: `/path/to/directory/exists.txt`
     - `/path/to/directory`
         └── `exists.txt` file [✅ read, ✅ write, ❌ execute]
    ")
```

In the above code, the test changes the current working directory to a temp dir where it is then free to make modifications on disk. But, since Rust uses a multi-threaded test runner and `std::env::set_current_dir` affects the whole process, this approach is not safe ☠️.

There are a lot of different ways to approach the fix, like using [cargo-nextest](https://nexte.st/), which executes all tests in their own process (where changing the CWD is safe). Though this doesn't prevent someone from running `cargo test` accidentally. There are other crates that use macros to force non-concurrent test execution, but they require you to [remember to tag the appropriate tests](https://crates.io/crates/serial_test). I wanted something lightweight that was hard to mess up, so I turned to `clippy.toml` to fail if anyone used `std::env::set_current_dir` for any reason:

```toml
disallowed-methods = [
    {
        path = "std::env::set_current_dir",
        reason = "Use `crate::test_help::SetCurrentDirTempSafe` to safely set the current directory for tests"
    },
]
```

Then I wrote a custom type that used a mutex to guarantee that only one test body was executing at a time:

```rust
impl<'a> SetCurrentDirTempSafe<'a> {
    pub(crate) fn new() -> Self {
        // let global_lock = ...
        // ...

        #[allow(clippy::disallowed_methods)]
        std::env::set_current_dir(tempdir.path()).unwrap();
```

You might call my end solution hacky (this hedge statement brought to you by too many years of being ONLINE), but it prevents anyone (including future-me) from writing an accidentally thread-unsafe test:

```term
$ cargo clippy --all-targets --all-features -- --deny warnings
    Checking path_facts v0.2.1 (/Users/rschneeman/Documents/projects/path_facts)
error: use of a disallowed method `std::env::set_current_dir`
   --> src/path_facts.rs:395:9
    |
395 |         std::env::set_current_dir(temp.path()).unwrap();
    |         ^^^^^^^^^^^^^^^^^^^^^^^^^
    |
    = note: Use `crate::test_help::SetCurrentDirTempSafe` to safely set the current directory for tests
    = help: for further information visit https://rust-lang.github.io/rust-clippy/rust-1.91.0/index.html#disallowed_methods
    = note: `-D clippy::disallowed-methods` implied by `-D warnings`
    = help: to override `-D warnings` add `#[allow(clippy::disallowed_methods)]`
```

## clippy.toml

Those are only two quick examples showing how to use [clippy.toml](https://doc.rust-lang.org/clippy/lint_configuration.html#lint-configuration-options) to enhance a common API, and how to safeguard against incorrect usage. There's plenty more you can do with that file, including:

- `disallowed-macros`
- `disallowed-methods`
- `disallowed-names`
- `disallowed-types`

You wouldn't want to use this technique of annotating your project with `clippy.toml` if the thing you're trying to prevent would be actively malicious for the system if it executes, since `clippy.toml` rules won't block your `cargo build`. You'll also need to make sure to run `cargo clippy --all-targets` in your CI so some usage doesn't accidentally slip through.

And that clippy lint work has paid off, [my latest PR to `fs_err`](https://github.com/andrewhickman/fs-err/pull/81) was merged and deployed in version `3.2.0`, and you can use it to speed up your development debugging by turning on the `debug` feature:

```toml
[dev-dependencies]
fs-err = { features = ["debug"] }
```

Clip cautiously, my friends.
