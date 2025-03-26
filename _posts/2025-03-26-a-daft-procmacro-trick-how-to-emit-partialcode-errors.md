---
title: "A Daft proc-macro trick: How to Emit Partial-Code + Errors"
layout: post
published: true
date: 2025-03-26
permalink: /2025/03/26/a-daft-procmacro-trick-how-to-emit-partialcode-errors/
image_url: https://www.dropbox.com/scl/fi/ef1bc0hyrc1c10ss1axyt/Screenshot-2025-03-26-at-12.50.22-PM.png?rlkey=nufmed7rszvxq20qonmm5o6py&raw=1
categories:
    - rust
    - proc-macro
---

A recent Oxide and Friends podcast episode, "A crate is born," detailed the creation of a proc macro for deriving "diffable" data structures with a trick I want to tell you about. To help rust-analyzer as much as possible, [@rain](https://hachyderm.io/@rain) explained that the macro should always emit as much valid source code as possible, even when an error is emitted. They didn't go into detail, so I looked into the internals that made this code + error emitting behavior possible and wanted to share.

> [Podcast link: A Crate is Born](https://oxide-and-friends.transistor.fm/episodes/a-crate-is-born)

This post covers:

- Why does macro output matter to `rust-analyzer `?
- What mechanics are used to emit code + errors?
- When does this macro emit code + errors versus when does it just emit code?
- How does this relate to best practices in future or existing Rust macros?
- What is error accumulation, and why should every proc macro use it?

> Who am I? I write Rust code for Heroku, mainly on the [Ruby Cloud Native Buildpack](https://github.com/heroku/buildpacks-ruby) (CNB). CNBs are an alternative to Dockerfile for building OCI images. You can learn more by [following a language-specific tutorial you can run locally](https://github.com/heroku/buildpacks/tree/main/docs#use). I also [wrote a book on Open Source contribution](https://howtoopensource.dev/) (paid) and I maintain [an Open Source contribution app - CodeTriage.com](https://www.codetriage.com/) (free).

## Why does macro output matter to `rust-analyzer`?

> Skip this if you already understand the problem statement

The Rust compiler will stop when it hits code that cannot compile. However, `rust-analyzer` (the Language Server Protocol implementation that powers IDEs like vscode) tries to resume after an error because it can't just stop rendering type hints.

Intuitively, it makes sense that if you have an invalid function in your code, it shouldn't break syntax highlighting (or other features) in your valid code:

```rust
fn invalid_wrong_return() -> String {
  ()
}

fn valid() -> String {
  "I am valid".to_string()
}
```

Daft (v0.1.2), emits trait implementations and sometimes generates new data structures. From the snapshot tests, an input of something like this:

```rust
#[derive(Debug, Eq, PartialEq, Diffable)]
struct Basic {
    a: i32,
    b: BTreeMap<Uuid, BTreeSet<usize>>,
}
```

Will generate code like this:

```rust
struct BasicDiff<'__daft> {
    a: <i32 as ::daft::Diffable>::Diff<'__daft>,
    b: <BTreeMap<Uuid, BTreeSet<usize>> as ::daft::Diffable>::Diff<'__daft>,
}
// ...
impl ::daft::Diffable for Basic {
    type Diff<'__daft> = BasicDiff<'__daft> where Self: '__daft;
    fn diff<'__daft>(&'__daft self, other: &'__daft Self) -> BasicDiff<'__daft> {
        Self::Diff {
            a: ::daft::Diffable::diff(&self.a, &other.a),
            b: ::daft::Diffable::diff(&self.b, &other.b),
        }
    }
}
```

If the macro does not emit this information (possibly due to some hypothetical error not present in this example), then rust-analyzer wouldn't know that the `BasicDiff` struct was expected to exist, what its fields were, or that `Basic::diff()` returned a `BasicDiff` struct. In short, the IDE would be generally less helpful.

Now that you understand the goal, how do we emit code when there's an error?

## What mechanics are used to emit code + errors?

The short version is that macros don't output code or errors; they emit tokens. The daft crate collects errors and continues when possible. If it can generate code, it will emit that generated code as tokens before turning the errors into tokens and then emitting both. An earlier version of the code looked like this:

```rust
let errors = error_store
    .into_inner()
    .into_iter()
    .map(|error| error.into_compile_error());

quote! {
    #out
    #(#errors)*
}
```

Where `quote!` produces tokens from both the code (`#out`) and the errors `#(#errors)*`.

But don't take my word for it, read the source: The entry point for the `Daft` derive macro is [`internal::derive_diffable`](https://github.com/oxidecomputer/daft/blob/5343fbb0d907ece8990d9d9b60e42669d35b7ece/daft-derive/src/lib.rs#L20). This function returns a [`DeriveDiffableOutput`]( https://github.com/oxidecomputer/daft/blob/5343fbb0d907ece8990d9d9b60e42669d35b7ece/daft-derive/src/internals/imp.rs#L11-L14). The `DeriveDiffableOutput` holds `Option<TokenStream>` for valid code that was generated and `Vec<syn::Error>` for errors

The `DeriveDiffableOutput` implements `quote::ToTokens` that emits the valid code followed by the errors (if they exist). [code](https://github.com/oxidecomputer/daft/blob/5343fbb0d907ece8990d9d9b60e42669d35b7ece/daft-derive/src/internals/imp.rs#L16-L21).

Put it all together, and you have a crate that emits partially generated code, even with errors. Neat.

## When to emit code + errors?

Now that I knew how Daft implemented this feature, I wanted to understand when they chose to apply this pattern. I [reviewed the snapshot tests](https://gist.github.com/schneems/6e27cc2e7fe8dea212f95ed9e154bbc7) and developed my own classifications.

There are three classes of failures in the snapshot tests:

- Emit code and errors (Warning error)
- Emit code only, no errors (Compile error)
- Emit errors only, no code (Error)

First, proc-macros cannot emit warnings. If the coder entered slightly off information that wouldn't affect compilation, the macro author must choose between letting it slide or raising an error. There's no in-between.

When there's a problem but daft can determine programmer intent, it will emit code and errors. I call this a "warning error." The primary example in snapshot testing is when the `#[daft(leaf)]`  attribute is used on an enum that is already a leaf by default (this is an internal concept to the crate).

> Note that the daft crate does not use "warning error" as terminology. I am making that distinction based on my [analysis of the snapshot test. Notes are here.](https://gist.github.com/schneems/6e27cc2e7fe8dea212f95ed9e154bbc7).

Second, the program can fail to compile even when code is emitted without error, for example, if a trait bound is not satisfied. The macro author cannot detect the problem because the reflection tools don't expose the necessary information. They must rely on the compiler errors to guide their user.

Finally, there are situations where the author cannot safely emit code because an input is ambiguous or wrong. With these "plain" errors, if the macro author tried to guess and got it incorrect, they're feeding rust-analyzer incorrect information, which might confuse the end user more. For example, if an attribute that doesn't exist, such as `#[daft(unknown)]`, is found, the macro author has no idea what was intended there and shouldn't guess.

While working on this classification exercise I found two snapshot tests where code isn't emitted but could be.

## Should all proc macros emit code + errors?

Obligatory: "It depends."

If you find your rust-analyzer horribly broken due to a proc-macro problem, then this is a great trick to suggest. However, it isn't a critical feature that every macro should have. Instead, libraries should focus on improving error accumulation (talked about later).

This code + error functionality requires a lot of plumbing, and ultimately, there's only one code path (or two if they like my suggestion) that generates code + errors. Looking at how this code path came to be, it seems more that it was added because the plumbing already existed and the opportunity presented itself. From that lens, it's easy to see why Daft goes this extra mile. The cost to implement was (comparatively) low:

- [Error store introduced in PR #41](https://github.com/oxidecomputer/daft/pull/41/files#diff-865f958fa8f3072cc4ef20a5f278d6165486225f009f28237cafd156c96ba946R23)
- [Emit Code + Errors added in PR #42](https://github.com/oxidecomputer/daft/pull/42)

While the lede: emitting code + errors is likely too much of an ask for most crates, every proc macro should accumulate errors. Let's look at that now.

## More `!` for your `$`: Accumulate proc macro errors

What do I mean by accumulated errors? In a Python (or Ruby) program that raises an error, you have to fix that to find out if there's another error lurking that also needs to be fixed. Rust programmers don't like playing that game. They want as many errors upfront as possible:

```
error: #[daft(leaf)] specified multiple times
 --> tests/fixtures/invalid/field-specified-multiple-times.rs:5:18
  |
5 |     #[daft(leaf, leaf, leaf)]
  |                  ^^^^

error: #[daft(leaf)] specified multiple times
 --> tests/fixtures/invalid/field-specified-multiple-times.rs:5:24
  |
5 |     #[daft(leaf, leaf, leaf)]
  |                        ^^^^

error: #[daft(ignore)] specified multiple times
 --> tests/fixtures/invalid/field-specified-multiple-times.rs:8:12
  |
8 |     #[daft(ignore)]
  |            ^^^^^^

error: #[daft(ignore)] specified multiple times
 --> tests/fixtures/invalid/field-specified-multiple-times.rs:9:12
  |
9 |     #[daft(ignore)]
  |            ^^^^^^
```

This daft output says there are two errors on line 5. One error on lines 8 and 9. This code generated the following errors:

```rust
use daft::Diffable;

#[derive(Diffable)]
struct MyStruct {
    #[daft(leaf, leaf, leaf)] // line 5
    a: i32,
    #[daft(ignore)]
    #[daft(ignore)] // line 8
    #[daft(ignore)] // line 9
    b: String,
}
```

Fields and their attributes are parsed iteratively, so it's common for a macro to stop iterating on the first problem (line 5) before returning. Instead, Daft stores the errors and continues parsing until it longer can.

I don't think it's the end of the world if a proc macro only emits a single error at a time, but it's a requirement if you're aiming for a "Michelin star proc-macro" experience.

## How does Daft implement error accumulation?

Instead of using a `Result<T, syn::Error>` return, daft passes an accumulator that holds a `Vec<syn::Error>` to every fallible function.  If there's an error, it's added to the accumulator.
This pattern also means that instead of having to choose between emitting `T` or `syn::Error` (via a `Result<T, syn::Error>`), the programmer can do both by returning a `T` while mutating the accumulator. That would indicate the problem is more of a "warning error" if the data structure can still be safely returned. Functions that return `Option<T>` indicate they're likely holding one or more plain errors that would prevent code generation when a `None` is returned.

Beyond affording the ability to return code + errors, not using a Result means that the try operator (`?`) cannot be used accidentally for an early/eager return. This property encourages the macro author to capture as many errors as possible and emit them all instead of only emitting the first error. It's a neat pattern, but it's not the only way to accumulate errors.

## Alternative pattern for `syn::Error` accumulation

The `syn::Error` struct has the capability of combining multiple errors without an accumulator by using [`syn::Error::combine`](https://docs.rs/syn/2.0.100/syn/struct.Error.html#method.combine). For example:

```rust
let mut errors = VecDeque::<syn::Error>::new();
// ...
if let Some(mut first) = errors.pop_front() {
    for e in errors.into_iter() {
        first.combine(e);
    }
    Err(first)
} else {
    Ok(
    // ...
    )
}
```

This pattern is useful when the function signature isn't changeable. For example, the [`syn::parse::Parse`](https://docs.rs/syn/2.0.100/syn/parse/trait.Parse.html) trait is commonly used by proc macros as a building block, and it has a fixed signature:

```rust
fn parse(input: syn::parse::ParseStream<'_>) -> Result<T, syn::Error>
```

With this pattern, the error behavior of the function is encoded in its return type:

- Errors that block code generation should return `Result<T, syn::Error>`
- Errors that do not block code generation should return `(T, Option<syn::Error>)`
- Errors that may or may not block code generation should return `Result<(T, Option<syn::Error>), syn::Error>`.
  - `Ok((T, None))` indicates no errors
  - `Ok((T, Some()))` indicates an error that did not block code generation.
  - `Err()` indicates that code could not be generated due to error

That last one is verbose, but it prevents representing an invalid state when `None` code and `None` errors are returned simultaneously.

The downside of this technique is that nothing prevents an early return on error with try (`?`).

I  was curious how this pattern would look implemented in place of the daft one, so I experimented with a [draft (not daft) PR](https://github.com/schneems/daft/pull/1).

> Note: The PR is to my own `main` branch, not theirs. I don't think any maintainer loves waking up to a giant PR with the "refactoring" in it.

## Wrap up

We learned why `rust-analyzer` is sensitive to macro output. We explored the mechanics that Daft uses to emit code + errors, and  accumulate errors. I introduced an alternative error accumulation method and I made some strong statements. Namely that emitting code + errors is a nice-to-have while accumulating and emitting all errors is an achievable best practice.

Coming from Ruby, proc macros are wonderful things that allow Rust developers to write powerful and expressive DSLs, and I love them. With the power to meta-program, there's also the possibility to meta-confuse your end user or toolchain (like rust-analyzer). I love that the Daft maintainers put as much work and care into the failure modes as the rest of their logic in addition to accumulating and presenting as many errors as possible.

I hoped you enjoyed learning about these patterns as much as I did.

> FYI I'm working on a proc-macro tutorial and would love to hear from readers on [Mastodon](https://ruby.social/@Schneems) or Reddit about what real-world patterns you've seen around improving the end-user experience, especially around errors.

