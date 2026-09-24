---
title: "A Type Stronger than the Sum of its Components"
layout: post
published: true
date: 2026-09-24
permalink: /2026/09/24/a-type-stronger-than-the-sum-of-its-components/
image_url: https://www.dropbox.com/scl/fi/e1twqezq77ga6ejbkxeqs/Screenshot-2026-09-24-at-3.09.22-PM.png?rlkey=evyikbm74s2ntz85sjs47ijpp&raw=1
categories:
    - rust
---

Have you ever written a type that you appreciated so much you still think about it? Like eating a really good meal, where if you try hard enough, you can still recall the taste in your mouth. I had a mini moment of Rust joy the other day and wanted to share the experience.

TLDR: I turned an enum with N variants into N types. Nothing earth-shattering, but it made my life better.

Specifically, [`std::path::Component`](https://doc.rust-lang.org/std/path/enum.Component.html) is an enum that you can get from any [std::path::Path](https://doc.rust-lang.org/std/path/struct.Path.html) reference. Where a path can be viewed as an iterator of components. To give you an example `/tmp/hello` is `[Component::RootDir, Component::Normal("tmp"), Component::Normal("hello")]`.  This enum is very handy for decomposing and working with paths, but an interface that takes one component that could be any of those variants is overly broad and not terribly useful.

In a [library where I work with paths a lot](https://github.com/schneems/path_facts) I made owned structs for each of those component types so that I could write a function signature like this:

```rust
impl AbsPath {
    // ...
    pub(crate) fn join_normal(&self, path: &NormalComponent) -> AbsPath {
        AbsPath(self.as_ref().join(path.as_ref()))
    }
}
```

Where `NormalComponent` is a `struct NormalComponent(OsString)` that is guaranteed to come from a `Component::Normal` variant. In the example above, I'm using properties of this type to guarantee that joining it to a path that is already absolute will produce a path that is also absolute.

It might not sound earth-shattering, but prior to that, the alternative was something like:

```rust
pub(crate) fn join_normal(&self, path: &OsStr) -> AbsPath
```

But an `OsStr` could be anything. It could contain `..` or be an absolute path (in which case, the [join API replaces the target](https://doc.rust-lang.org/std/path/struct.Path.html#method.join)). Another use case is using it to [represent the entries inside a directory](https://github.com/schneems/path_facts/pull/27/changes/8a1bc039fdd5b1e7186afa38485fb2bf42a5aa54#diff-c34cb87be68214956fa84ca439e1a52f71ace0cae10c5f8e5e15d072aace9ed8R49-R50).

In hindsight, it's such an obvious move: Take an existing, well-designed enum and make a type for each of the variants it can hold. If it's useful to know you have 1 of N possible things (an enum), it's probably also useful to know you have 1 very specific thing that can also fit into that enum. An enum is also known as a "sum type." So another way to think of this is if it's useful to have a sum type, it's also useful to have the individual components of that type.

Prior to this abstraction, I produced a range of other types:

- AbsPath - A path that is `absolute`-ized.
- RelativePath - You guessed it, a path that is relative.
- CanonicalPath - A path that has been `canonicalize`-d.

I found these useful, but still overly broad. A weird thing with working with paths is that they represent a lexical value and a physical location, and the two can be different. A path that is lexically relative might be a symlink on disk with an absolute target. And trying to normalize or transform paths can have weird consequences. Like if you try to get metadata from a file at `/path/to/location/skipped/..` it will fail if `skipped` does not exist or is not a directory. However, if you canonicalize the path first, that will succeed and produce `/path/to/location`, which will not fail when you try to get metadata from it.

An absolute path is not normalized, so it can have `..` (`ParentDir`) and `.` (`CurDir`) in it. But if you don't know how the path will be used (in my library, I don't know why someone is asking for facts about that given path). You cannot safely normalize those values unless you've resolved their physical parent. That's because `/path/to/location/skipped` from above could also be a symlink to a completely different absolute path, which needs to be resolved before the "apply `..` to fold parent directory" happens. And to make matters worse, Windows has special paths that change the behavior of lookups. So paths that start with `\\?\` like `\\?\C:\windows` treat `.` and `..` as literal values.

That means, when you run a path through `std::path::canonicalize` it returns a path with this syntax. Which also means that it is unsafe to call `canonicalize(canonicalize(&path).join(&other))` on Windows. If `&other` contains a `..`, it will produce a verbatim lookup that will likely fail. Thankfully, the `Component` parsing is consistent here, so it always returns a `Component::ParentDir` for a `..` rather than a `Component::Normal("..")`.

Join safety is probably the biggest benefit I got out of this new type, but it's also fun that I can do things like this:

```rust
fn up(position: Reached, name: ParentDirComponent) -> (Step, Reached)
```

Here, the `up` function is walking/tracing a path on disk one component at a time. Previously, this was taking an `OsString`, which required the programmer to be careful. This type signature forces the developer to prove to the compiler that they hold a `..` component in hand before they can call this logic. Not earth-shattering either, but this level of pedantic confidence is just so...delightful here.

Not everyone's taste in food or types is the same. It's fine if you don't like the examples I'm serving here, but I thought this was satisfying and wanted to give you some food for thought.  I would love to hear about other satisfying type patterns you're still savoring.

An AI disclaimer: Gen AI coding tools, I also code a lot of stuff by hand, and advocate for something like a "manually coded Monday." This `src/component.rs` is exclusively my meat brain child. I actually coded it while I was in a car with no internet, waiting for my kids' soccer practice to be over. I use Grammarly (non-gen-ai mode) to help me edit my prose.
