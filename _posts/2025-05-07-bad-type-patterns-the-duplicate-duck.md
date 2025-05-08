---
title: "Bad Type Patterns - The Duplicate duck"
layout: post
published: true
date: 2025-05-07
permalink: /2025/05/07/bad-type-patterns-the-duplicate-duck/
image_url: https://www.dropbox.com/scl/fi/187wkh8owgxh47ooab6aj/Screenshot-2025-05-07-at-8.47.13-PM.png?rlkey=d654rdnjv7du24nyo4h8js3xh&dl&raw=1
categories:
    - rust
    - types
---

Why aren't people [writing more types](https://lobste.rs/s/qmmfje/don_t_be_afraid_types)? Perhaps it's because the intermediate and expert developers deleted the patterns that didn't work and left no trace for beginners to learn from. This post details some code I recently deleted that has a pattern I call the "duplicate duck." You can learn the process I used to develop the type, and why I deleted it. Further, I advocate for Rust developers to document and share their mistakes in the hope that we can all learn from them.

## TLDR: What's a duplicate duck?

A "duplicate duck" is a type that implements a subset of traits of a popular type with the same results. In my case I wrote a type, `MultiError`, that I later realized was identically [duck typed](https://en.wikipedia.org/wiki/Duck_typing)  to [`syn::Error`](https://docs.rs/syn/latest/syn/struct.Error.html) and that my struct added nothing. I deleted my type with no loss in functionality and the world was better for it.

I saved my code before throwing it away. The following is the story of my design process and eventual epiphany.

> Quick `whoami`: I write Rust for Heroku where I [maintain the Ruby Cloud Native Buildpack](https://github.com/heroku/buildpacks/blob/main/docs/ruby/README.md). I also maintain a free service [CodeTriage](https://www.codetriage.com) and wrote a book, [How to Open Source](https://howtoopensource.dev), for turning coders into contributors.

## Story version - Context

I've been hacking on proc macros recently, you can read about a recent investigation ["A Daft proc-macro trick: How to Emit Partial-Code + Errors"](https://www.schneems.com/2025/03/26/a-daft-procmacro-trick-how-to-emit-partialcode-errors/). I want proc macro authors to emit as many accumulated errors as possible (versus stopping on the first one), I'm also a fan of unit testing. I wanted to add a return type from my functions that said, "I return many accumulated errors," and I wanted that return type to be unit-testable.

In my code, I've been accumulating errors with `VecDeque<syn::Error>`. This makes it easy to combine them into a single `syn::Error` :

```rust
if let Some(mut error) = errors.pop_front() {
    for e in errors {
        error.combine(e);
    }
    Some(error)
} else {
    None
}
```

However, I don't want to return a result of `Result<T, VecDeque<syn::Error>>` from my functions as the error state isn't guaranteed to be non-empty. A good type should make invalid state impossible to represent.
## Start with the data

To guarantee my type always had at least one error, I separated out the first error from the rest of the collection. Even if this container is empty, the type definition guarantees we can always turn this into a `syn::Error`

```rust

/// Guaranteed to hold at least one [`syn::Error`]
///
/// The [`syn::Error`] can hold multiple errors
/// through [`syn::Error::combine()`], however it
/// does not allow the receiver to distinguish
/// between the two cases, which makes testing
/// less precise. Using this type is a stronger
/// hint that the function accumulates errors.
///
#[derive(Debug, Clone)]
pub(crate) struct MultiError {
    first: syn::Error,
    rest: VecDeque<syn::Error>,
}

impl MultiError {
    pub(crate) fn from(mut errors: VecDeque<syn::Error>) -> Option<Self> {
        if let Some(first) = errors.pop_front() {
            let rest = errors;
            Some(Self { first, rest })
        } else {
            None
        }
    }
}
```

> Warning: Just because the docs state something, doesn't mean it's true.

> Note the visibility, by default I use `pub(crate)` for the struct and associated functions but not for the fields (`first` and `rest`). When I'm unsure of my design, it's easier to change them later if all access goes through functions.

This type allowed me to introduce helper functions like this:

```rust
pub(crate) fn parse_attrs<T>(
        attrs: &[syn::Attribute]
    ) -> Result<Vec<T>, MultiError>
where
    T: syn::parse::Parse,
{
    let mut errors = VecDeque::new();
    // ...
    if let Some(error) = MultiError::from(errors) { // <== HERE
        Err(error)
    } else {
        Ok(
        // ...
        )
    }
}
```

This code says "I take in any slice of `syn::Attribute` and then parse that attribute into a vector of `T` or return one or more syn errors". So far, so good.

But my macro needs a `syn::Error` to generate error tokens and my function returns a `MultiError`. So I needed a way to convert my type into a `syn::Error`.

## Add into behavior

Based on the properties of the type, we know we can always convert into a `syn::Error` infallibly, so I can expose that via implementing `Into<syn::Error>`:

```rust
impl From<MultiError> for syn::Error {
    fn from(value: MultiError) -> Self {
        let MultiError { mut first, rest } = value;
        for e in rest {
            first.combine(e);
        }
        first
    }
}
```

As a bonus, the try operator (`?`) will implicitly call `into()` which allows us to do things like this:

```rust
fn check_logic(...) -> Result<(), syn::Error> {
  // ...
  let result: Result<(), MultiError> = logic();
  let _ = result?; // <=== Convert MultiError to syn::Error implicitly
  // ...
}
```

With that added, I needed a way to test my logic to ensure I was capturing multiple errors.

## Add Display

To render the error on failure it needs to implement `std::fmt::Display`:

```rust
impl std::fmt::Display for MultiError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        Into::<syn::Error>::into(self.clone()).fmt(f)
    }
}
```

It's not pretty, but it worked and was easy. This code path is only ever called under test.
## Add iteration

To expose multiple errors for testing, I chose to implement the `IntoIterator` trait:

```rust
impl IntoIterator for MultiError {
    type Item = syn::Error;
    type IntoIter = <VecDeque<syn::Error> as IntoIterator>::IntoIter;

    fn into_iter(self) -> Self::IntoIter {
        let MultiError { first, mut rest } = self;
        rest.push_front(first);
        rest.into_iter()
    }
}
```

This code says that we can now convert our struct into something that produces a series of `syn::Error`-s. Since we've already got a `VecDeque` lying around, and I knew that it implemented the same trait, I piggybacked my logic on top. This allowed me to do things like this test:

```rust
    #[test]
    fn test_captures_many_field_errors() {
        let field: syn::Field = syn::parse_quote! {
            #[cache_diff(unknown)]
            #[cache_diff(unknown)]
            version: String,
        };
        let result: Result<Vec<ParseAttribute>, MultiError> =
            crate::shared::parse_attrs::<ParseAttribute>(&field.attrs);

        assert!(
            result.is_err(),
            "Expected {result:?} to be err but it is not"
        );
        let error = result.err().unwrap();
        assert_eq!(2, error.into_iter().count()); // <== into_iter() HERE
    }

    enum ParseAttribute {
        //...
    }
    impl syn::parse::Parse for ParseAttribute {
        // ...
    }
```

This code parses a single field with multiple `syn::Attribute`-s on it. In this case, `cache_diff(unknown)` is an invalid attribute, and I want to assert that it does not stop after the first one it sees. The code converts my result into an iterator and then asserts that there are two elements. Great!

## Iter Oops

While the above code example worked fine, I kept applying this pattern, bubbling up errors until I hit a failure in my code:

```rust
    #[test]
    fn test_captures_many_field_errors() {
        let result = ParseContainer::from_derive_input(&syn::parse_quote! {
            struct Metadata {
                #[cache_diff(unknown)]
                #[cache_diff(unknown)]
                version: String,

                #[cache_diff(unknown)]
                #[cache_diff(unknown)]
                name: String
            }
        });

        assert!(
            result.is_err(),
            "Expected {result:?} to be err but it is not"
        );
        let error = result.err().unwrap();
        assert_eq!(4, error.into_iter().count()); // <== FAILED here
    }
```

The error said that I was returning only two errors instead of 4. Which was confusing. I moved the code into a `trybuild` integration test and saw 4 errors. At this point it dawned on me, that at some time I was storing multiple errors into a single `syn::Error` and then placing that combined error in my `MultiError`. Basically I had a multi `MultiError`.

If that was hard to follow, here's some pseudo code:

```rust
let mut errors: VecDeque<syn::Error> = VecDeque::new();

match call_fun() { // Returns a MultiError
    Ok(_) => todo!(),
    // Combines it into a single `syn::Error`
    Error(error) => errors.push_back(error.into())
}
// ...

if let Some(error) = MultiError::from(errors) {
    Err(error)
} else {
    Ok(
    // ...
    )
}
```

Essentially, my `MultiError` type allowed for what I **thought** was uninspectable-state. Each `syn::Error` could hold N errors.

## A Fowl Epiphany

As I went through the stages of grief for my beautiful type that had a fundamental flaw, I hit on the idea that perhaps I could upstream a change to expose the internal combined errors from `syn::Error`. I thought that the `IntoIterator` interface was a good candidate to add. But to my shock, when I opened the docs the [ `impl IntoIterator` for `syn::Error` was right there this whole time](https://docs.rs/syn/2.0.100/syn/struct.Error.html#impl-IntoIterator-for-Error). I just missed it.

When I realized that `syn::Error` already implemented every trait that I needed, I was able to change every `MultiError` into `syn::Error` and replace every `MultiError::from_error` with a function that returns `Option<syn::Error>`. Then, with zero other logic changes, my code compiled. That confirmed my suspicions that I had written a duck-typed duplicate of a commonly available struct.

The only value my `MultiError` type brought was that it hinted that the function was written with error accumulation in mind, but could not guarantee that the accumulation logic was correct. It didn't seem like this minor social hint was enough to justify the extra code. I could achieve similar goals with a type alias.
## Bad duck

If a type doesn't introduce new capabilities or constraints and can be replaced by an existing, stable type, it should probably be deleted in favor of the more common type.

## Good duck

Just because a type starts to smell a little foul (or rather "fowl") does that mean you need to get rid of it? Producing a new type guarantees that there are no mix-up between your type and the common type. New typing could also allow you to restrict operations to a subset of the common type. Both of these things are about adding constraints.

A third reason to keep a duck around would be the stability of the interface. If you're going to expose your type via a library and you're worried it might change, then it could be helpful to wrap the type so your downstream user don't have to change their code even if the underlying logic or implementation changes.

## Duck documentation

When in doubt, consider documenting your duck and explaining what constraints the new type adds over the original. After writing them down, search for an already existing type that has the same behaviors. Perhaps go so far as to document why those types don't meet your needs. If you cannot enumerate those differences well, then perhaps it's a sign you should ditch your duck.

In my case I had explicitly called out `syn::Error` and even went as far as implementing `Into<syn::Error>`. Those are two strong signs that I should have investigated my claims and looked for features provided by trait implementations.

## Practice your duck calls

One of the reasons I missed that `syn::Error` already met my needs that I didn't stop to consider why certain traits were implemented on the struct or think about how they might be used to expose the data that I needed. Over time I've been better at internalizing and mentally mapping trait names to the behaviors they provide. Still, I've got some more work to do. Hopefully after this experience, with strong hints that I'm re-implementing an existing type as a duck, I won't forget to check trait implementations for what I need.

Beyond "trying harder" and "writing a blog post as penitence so I don't do it again," I thought that it would be nice if this behavior was also shown via an example, so I [sent a PR to syn to add some examples to syn::Error::combine](https://github.com/dtolnay/syn/pull/1855).  I don't think we need to clutter all code with documenting every possible use case of every possible trait, but this very useful iteration functionality its in nicely in demonstrating how the combine behavior works. Hopefully, the addition of these docs will bre received well and not as an [albatross](https://en.wikipedia.org/wiki/Albatross_(metaphor))

I would like to encourage everyone to pay attention to your types and the pain you're feeling around them. If you find you've written a type that you later refactored away, consider pausing and capturing why it was written and why the world is better off without it. What other "bad type" patterns are out there and how can we make it easier for newcomers to spot and avoid them?

