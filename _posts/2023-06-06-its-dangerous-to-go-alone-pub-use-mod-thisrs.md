---
title: "It's dangerous to go alone, `pub` `mod` `use` this.rs"
layout: post
published: true
date: 2023-06-14
permalink: /2023/06/14/its-dangerous-to-go-alone-pub-mod-use-thisrs/
image_url: https://capture.dropbox.com/QjSoZWiDtYvz4WoH?raw=1
categories:
    - rust
    - tutorial
---
What exactly does `use` and `mod` do in Rust? And how exactly do I "require" that other file I just made? This article is what I wish I could have given a younger me.

This post starts with a fast IDE-centric tutorial requiring little prior knowledge. Good if you have a Rust project and want to figure out how to split up files. Afterward, I'll dig into details so you can understand how to reason about file loading and modules in Rust.

> Tip: If you enjoy this article, check out my book [How to Open Source](https://howtoopensource.dev/) to help you transform from a coder to an open source contributor.

## Tutorial: Naievely require/load-ing files in Rust

> Skip this if: You're the type of person who likes to see all the ingredients before you see the cake.

For this tutorial, I'll be using VS Code and the [rust analyzer extension](https://marketplace.visualstudio.com/items?itemName=rust-lang.rust-analyzer).

With that software installed, create a new Rust project via the `cargo new` command:

```
$ cargo new file-practice
     Created binary (application) `file-practice` package
$ cd file-practice
$ exa --tree --git-ignore ./src
./src
└── main.rs
```

> Note: The `exa` command isn't required. I'm using it to show file hierarchy. You can install it on Mac via `brew install exa`.

In the `src` directory, there's only one file, `main.rs`. Since some people think tutorial apps are a joke, let's make an app that tells jokes.

Create a new file named `joke.rs` by running:

```
$ touch src/joke.rs
$ exa --tree --git-ignore ./src
./src
├── joke.rs
└── main.rs
```

Add a function to the file:

```rust
// src/joke.rs
fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
}
```

Then modify your `src/main.rs` file to use this code:

```rust
// src/main.rs
fn main() {
    println!("Hello, world!");
    want_to_hear_a_joke();
}
```

This code fails with an error:

```
$ cargo test
error[E0425]: cannot find function `want_to_hear_a_joke` in this scope
 --> src/main.rs:4:5
  |
4 |     want_to_hear_a_joke();
  |     ^^^^^^^^^^^^^^^^^^^ not found in this scope

For more information about this error, try `rustc --explain E0425`.
```

You cannot use the code in `src/joke.rs` code as `src/main.rs` cannot find it.

When you create a file in a Rust project and get an error that it cannot be found, navigate to the `src/joke.rs` file in your VS Code editor and hit `CMD+.` (command key and period on Mac, or control period on Windows). You'll get a "quick fix" prompt asking if you want:

- "insert `mod joke;`"
- "insert `pub mod joke;`"

Your editor may look different than mine, but note the quick-fix menu right under my cursor:

![](https://capture.dropbox.com/cDaZUgrZP3IiRIOK?raw=1)

If you hit enter, then your `src/main.rs` should now look like this:

```rust
// src/main.rs
mod joke;

fn main() {
    println!("Hello, world!");
    want_to_hear_a_joke();
}
```

## Watch for changes with cargo-watch

> Skip if: You already know how to use cargo-watch in the VS Code terminal

Run your tests on save in the vscode terminal with cargo watch. You can open a terminal by pressing `CMD+SHIFT+P` (command shift "p" on Mac or control shift p on Windows). Then type in "toggle terminal" and hit enter. This will bring up the terminal. Then, install [cargo watch](https://crates.io/crates/cargo-watch)

```
$ cargo install cargo-watch
```

Now run the watch command in your terminal:

```
$ cargo watch -c -x test
```

This command tells `cargo` to `watch` the file system for changes on disk, then clear (`-c`) the window and execute tests (`-x test`). This will make iteration faster:

![Screenshot](https://capture.dropbox.com/2FFU2XzxKe9AaAIC?raw=1)

## Back to the tutorial

Make sure cargo watch is running and save the `src/main.rs` file. Note that tests are failing since the program still cannot compile:

```
   Compiling file-practice v0.1.0 (/private/tmp/file-practice)
error[E0425]: cannot find function `want_to_hear_a_joke` in this scope
 --> src/main.rs:6:5
  |
6 |     want_to_hear_a_joke();
  |     ^^^^^^^^^^^^^^^^^^^ not found in this scope
  |
note: function `crate::joke::want_to_hear_a_joke` exists but is inaccessible
 --> src/joke.rs:2:1
  |
2 | fn want_to_hear_a_joke() {
  | ^^^^^^^^^^^^^^^^^^^^^^^^ not accessible

For more information about this error, try `rustc --explain E0425`.
error: could not compile `file-practice` due to previous error
[Finished running. Exit status: 101]
```

The error "exists but is inaccessible" is similar to what we saw before but with additional information. If you run that `rustc` command, it suggests:

```
$ rustc --explain E0425
...
If the item you are importing is not defined in some super-module of the current module must also be declared as public (e.g., `pub fn`).
```

The very last line gives us a great clue. We need to update the function to be public. Edit your `src/joke.rs` file to make the function public:

```rust
// src/joke.rs
pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
}
```

On save, it still fails, but we've got a different message (always a good thing):

```
error[E0425]: cannot find function `want_to_hear_a_joke` in this scope
 --> src/main.rs:6:5
  |
6 |     want_to_hear_a_joke();
  |     ^^^^^^^^^^^^^^^^^^^ not found in this scope
  |
help: consider importing this function
  |
2 | use crate::joke::want_to_hear_a_joke;
  |

For more information about this error, try `rustc --explain E0425`.
error: could not compile `file-practice` due to previous error
[Finished running. Exit status: 101]
```

It suggests "consider importing this function" by adding `use crate::joke::want_to_hear_a_joke;` to `src/main.rs`. Use the quick-fix menu `CMD+.` on the function in `src/main.rs`:

![screenshot](https://capture.dropbox.com/puwGvtCE2IjXSaC5?raw=1)

After accepting that option, `src/main.rs` now looks like this:

```rust
// src/main.rs
mod joke;
use crate::joke::want_to_hear_a_joke;

fn main() {
    println!("Hello, world!");
    want_to_hear_a_joke();
}
```

When I save the file, it compiles!

```
   Compiling file-practice v0.1.0 (/private/tmp/file-practice)
    Finished test [unoptimized + debuginfo] target(s) in 1.34s
     Running unittests src/main.rs (target/debug/deps/file_practice-22ac5cd70121e9ea)

running 0 tests

test result: ok. 0 passed; 0 failed; 0 ignored; 0 measured; 0 filtered out; finished in 0.00s

[Finished running. Exit status: 0]
```

To recap what happened here:

- We created a new file, `src/joke.rs`.
- To make it visible to `src/main.rs`, we needed to add a `mod` statement. We used VS Code `CMD+.` to generate the mod statement.
- We then updated the function in `src/joke.rs` to be public (added a `pub` based on the compiler detail error message)
- Finally, we needed to add a `use` into `src/main.rs` so our code could call it. This was suggested both by the compiler and VS Code.

You don't have to memorize EVERYTHING required. All in all, our tools either did the work or gave us a strong hint as to what to do next. Start mapping if-this-error to then-that-fix behavior while learning `use`, `mod`, and file loading.

## Tutorial: Importing nested files

To import code from a file in the `src/` directory into `src/main.rs`, you must add a `mod` declaration to `src/main.rs`.

How do you add files in a different directory?

Let's say we want to tell several kinds of jokes, so we split them into a directory and different files. Use the results of the first tutorial and add to it:

```
$ mkdir src/joke
$ touch src/joke/knock_knock.rs
$ touch src/joke/word_play.rs
$ exa --tree --git-ignore ./src
./src
├── joke
│  ├── knock_knock.rs
│  └── word_play.rs
├── joke.rs
└── main.rs
```

Now add some code that we can import. Write a joke into `src/joke/knock_knock.rs`:

```rust
// src/joke/knock_knock.rs
pub fn tank_knocks() {
    println!("Knock knock.");
    println!("Who's there?");
    println!("Tank");
    println!("Tank who?");
    println!("You're welcome!");
}
```

And another into `src/joke/word_play.rs`:

```rust
// src/joke/word_play.rs
pub fn cow_date() {
    println!("Where do cows go on a date");
    println!("To the Moooooo-vies");
}
```

With these files saved, use the `CMD+.` quick-fix menu, which will prompt you to insert a `mod`. Select the first option on both files and save both.

You might be surprised it didn't modify `src/main.rs` like our first tutorial. Instead, the extension modified the file `src/joke.rs` with these additions:

```rust
// src/joke.rs
mod word_play;   // <== New mod
mod knock_knock; // <== New mod

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
}
```

Notice:

- When you use `mod` in your crate root (`src/main.rs`), it references a file in the same directory (i.e., `src/<name>.rs`).
- When you use `mod` in a non-root file (like `src/joke.rs`), it references a file in a directory with that name (i.e., `src/joke/<name>.rs`).

Modify `src/joke.rs` to use the contents of those modules now:

```rust
// src/joke.rs
mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  word_play::cow_date();      // <== Here
  knock_knock::tank_knocks(); // <== Here
}
```

These two lines implicitly use the module imported above to its own namespace. You can also make this explicit using the `self` keyword:

```rust
// src/joke.rs
mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  self::word_play::cow_date();      // <== Here
  self::knock_knock::tank_knocks(); // <== Here
}
```

You can save and run this code. Make sure you're sitting down so you don't end up rolling on the floor laughing.

To recap what happened here:

- We created two files in the `src/joke/` directory. Each file has one public function.
- We added two mod statements to `src/joke.rs` (via `CTRL+.`).
- We used those two new namespaces inside of `src/joke.rs` to call the two new functions.

## Calling `cow_date` from main

The `want_to_hear_a_joke` function will output two jokes. Sometimes my kids think a joke is so funny that they want to hear it again. Let's add `cow_date` again. This time put it directly in the `main() {}` function:

```rust
// src/main.rs
mod joke;
use crate::joke::want_to_hear_a_joke;

fn main() {
    println!("Hello, world!");
    want_to_hear_a_joke();
    cow_date(); // <== Here
}
```

When you save, you'll get an error:

```
   Compiling file-practice v0.1.0 (/private/tmp/file-practice)
error[E0425]: cannot find function `cow_date` in this scope
 --> src/main.rs:8:5
  |
8 |     cow_date();
  |     ^^^^^^^^ not found in this scope
  |
note: function `crate::joke::word_play::cow_date` exists but is inaccessible
 --> src/joke/word_play.rs:2:1
  |
2 | pub fn cow_date() {
  | ^^^^^^^^^^^^^^^^^ not accessible

For more information about this error, try `rustc --explain E0425`.
error: could not compile `file-practice` due to previous error
[Finished running. Exit status: 101]
```

We've seen this error before "cannot find function `<name>` in this scope". The help ends with this line:

> "If the item you are importing is not defined in some super-module of the current module, then it must also be declared as public (e.g., `pub fn`)."

That's not super helpful since the `cow_date` function is already public:

```rust
// src/joke/word_play.rs
pub fn cow_date() { // <== Note the `pub` here
    println!("Where do cows go on a date");
    println!("To the Moooooo-vies");
}
```

Before we saw that these two invocations are basically the same thing:

```rust
// src/joke.rs

self::word_play::cow_date(); // <== Explicit self
      word_play::cow_date(); // <== Implicit self
```

So you might guess that calling `cow_date()` inside of `src/main.rs` is the same as calling `self::cow_date()`, which makes it a bit more explicit. You might also notice that `cow_date` is nowhere in `src/main.rs`. Where did it come from?

That function came from `src/joke/word_play.rs`, but Rust cannot find it. The first time we called the function, we started with `self` and traversed the path. Let's try that same technique:

```rust
// src/main.rs
mod joke;
use crate::joke::want_to_hear_a_joke;

fn main() {
    println!("Hello, world!");
    want_to_hear_a_joke();
    self::joke::word_play::cow_date(); // <== HERE
}
```

Did that work?

```
error[E0603]: module `word_play` is private
 --> src/main.rs:8:17
  |
8 |     self::joke::word_play::cow_date();
  |                 ^^^^^^^^^ private module
  |
note: the module `word_play` is defined here
 --> src/joke.rs:2:1
  |
2 | mod word_play;
  | ^^^^^^^^^^^^^^

For more information about this error, try `rustc --explain E0603`.
error: could not compile `file-practice` due to previous error
[Finished running. Exit status: 101]
```

No. But, our message changed again (always worth celebrating). Before, the error said that `cow_date` was "inaccessible." Now it's saying that `word_play` is a private module.

It points at a line in `src/joke.rs`, where `word_play` is defined for `self::joke::word_play`.

Hover over `word_play` in `src/main.rs` and press `CMD+.`. It asks if you want to change the visibility of the module:

![Screenshot](https://capture.dropbox.com/i00cCJhE7iP3SDAb?raw=1)

Accept that change and save. Then the file compiles!

To recap what happened here:

- We added a function call to `cow_date()` in `src/main.rs`
- Main.rs couldn't find our code, so we used the full path `self::joke::word_play::cow_date()`
- That gave us an error hinting the problem was privacy related.
- We changed `mod word_play;` to `pub(crate) mod word_play;` in `src/joke.rs` (by using the quick fix menu `CMD+.`)
- Now the program works

You might wonder, "What's `pub(crate)` and how is it different from `pub`?

The `pub(crate)` declaration sets visibility to public but is limited to the crate's scope. This is less privileged than `pub`. The `pub` declaration allows a different crate with access to your code (via FFI or a library) to use that code. By setting `pub(crate)`, you indicate a semi-private state. Changing that code might affect code in other files of your project, but it won't break other people's code.

I prefer using `pub(crate)` by default and only elevating to `pub` as needed. However, the core part of this exercise was seeing how far we could get by letting our tools figure out the problem for us.

## How can I load that file?

If all you want to do is put code in a file and load it from another file, you're good to go. This is the high-level cheatsheet for what we did above:

Reference Rust code in a file fast by:

- Starting from the bottom of your file tree in the project, use `CMD+.` and insert mod statements.
- Continue the first step until you've reached the root of your crate (`src/main.rs` or `src/lib.rs`).
- Try to use the code where you want while making the best guess for the correct path (i.e., `self::joke::word_play::cow_date`)
- Use compiler errors and the quick-fix tool (`CMD+.`) to insert `use` statements or adjust visibility with `pub` or `pub(crate)`.

## What is that `mod.rs` file?

If you use the above methodology, that rust analyzer will create files. There are two ways to load files from a directory. Before, I used the convention that `src/joke.rs` loaded all the files in the `src/joke` directory. That's [technically the preferred way](https://doc.rust-lang.org/reference/items/modules.html) of loading files in a directory, but there's one other method which is: putting a `mod.rs` file in the directory you want to expose.

In short, `src/joke/mod.rs` would do the same thing as `src/joke.rs`. Please don't take my word for it. Try it out:

Here's the current file structure:

```
$ exa --tree --git-ignore ./src
./src
├── joke
│  ├── knock_knock.rs
│  └── word_play.rs
├── joke.rs
└── main.rs
```

Now move the joke file to `src/joke/mod.rs`:

```
$ mv src/joke.rs src/joke/mod.rs
```

Now here's what our directory looks like

```
$ exa --tree --git-ignore ./src
./src
├── joke
│  ├── knock_knock.rs
│  ├── mod.rs
│  └── word_play.rs
└── main.rs
```

If you re-run tests. They still pass! As far as Rust is concerned, this code is identical to what we had before.

## Information dump

Now that you've tasted our lovely IDE productivity cake. It's time to learn about each of the ingredients. Here's what we'll cover:

- Code paths in Rust
  - `self` and (unqualified)
  - Differences between `self` and (unqualified)
  - `crate`
  - `super`
- Using `use`
  - Renaming paths with `use`
  - Glob imports with `use`
  - Import an extension trait with `use`
- A file state cheatsheet with `pub`, `mod`, `use` cheatsheet
- Modules != files

## Code paths in Rust

In the above example, we saw that we can reference code via a path starting with `self` like `self::joke::word_play::cow_date`. Here's what you can start a code path within Rust:

- `self`
- (unqualified)
- `crate`
- `super`

### Code paths starting with `self` and (unqualified)

Starting a path with `self` indicates that the code path is relative to the current module. Before we saw this code:

```rust
// src/joke.rs
mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  self::word_play::cow_date();      // <== Here
  self::knock_knock::tank_knocks(); // <== Here
}
```

In this case, `self` is inside the `src/joke.rs` module. This keyword is optional in this case. You can remove it, and the code will behave exactly the same. Most published libraries do not use ' self ' because it's less typing to omit the word altogether. Most would write that code like this:

```rust
// src/joke.rs
mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  word_play::cow_date();      // <== Here
  knock_knock::tank_knocks(); // <== Here
}
```

In this code, `self` is implied because we're not using `crate` or `super`.

Using `self` can be helpful as a reminder that you're using a relative path when you're starting. If you're struggling to correct a path, try mentally substituting the module's name (in this case, `joke`) for the `self` keyword as a litmus test to see if it still makes sense.

### Differences between `self` and (unqualified)

While it might seem that `self` and unqualified are interchangeable, they are not. This code will compile without self:

```rust
// Compiles fine
fn main() {
    println!("Hello, world!");
}
```

However, this code will not:

```rust
// Fails to compile

fn main() {
    self::println!("Hello, world!");
}
```

With error:

```
error[E0433]: failed to resolve: could not find `println` in the crate root
 --> src/main.rs:6:11
  |
6 |     self::println!("Hello, world!");
  |           ^^^^^^^ could not find `println` in the crate root
```

In addition to being an implicit reference to `self`, using an unqualified path also allows you access to elements that ship with Rust, like the `println!` macro or `std` namespace:

```rust
fn main() {
    let _out = std::fs::read_to_string("Cargo.toml").unwrap();
}
```

If you put `self::` in front of `std::fs` above, it would fail to compile.

Using an unqualified path also gives you access to any crates you import via `Cargo.toml`. For example, the `regex` crate:

```
$ cargo add regex
```

```rust
fn main() {
    let _re = regex::Regex::new("lol").unwrap();
}
```

If you put `self::` in front of `regex` above, it would fail to compile.

### Code paths starting with `crate`

A code path that starts with `crate` is like an absolute file path. This keyword maps to the crate root (`src/main.rs` or `src/lib.rs`).

In our above example, `self` was also `crate` since we were in the `src/main.rs`, so we could have written this code like this:

```rust
// src/main.rs
self::joke::word_play::cow_date();
```

As this:

```rust
// src/main.rs
crate::joke::word_play::cow_date();
```

Because `self` refers to `src/main.rs`, these two lines of code are identical. However, if you try to copy and paste them to another file, only the one that starts from `crate` will continue to work.

You can use an absolute path in any code module as long as all the parts of that path are visible to the current module. For example, here's the `src/joke.rs` file using a mix of absolute and relative paths:

```rust
// src/joke.rs
pub(crate) mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  crate::joke::word_play::cow_date(); // <== Absolute
  self::knock_knock::tank_knocks();   // <== Relative
}
```

This code calls `cow_date` via its absolute `cargo` path and `tank_knocks` from a relative path.

### Code paths starting with `super`

The `super` path references the path of a parent. In this case, the `super` of `src/joke.rs` is `src/` (otherwise known as the crate root). You can re-write the above code using `super` then as a replacement for `crate` like this:

```rust
// src/joke.rs
pub(crate) mod word_play;
mod knock_knock;

pub fn want_to_hear_a_joke() {
  println!("Want to hear a joke?");
  super::joke::word_play::cow_date(); // <== HERE
  self::knock_knock::tank_knocks();
}
```

### Code path recap

- `self` - A relative path from the current module
- (unqualified) - Same as `self` but allows for `std`, crate calls, and more
- `crate` - An absolute path from crate root (`src/main.rs` or `src/lib.rs).
- `super` - Relative path to the parent of the current module.

## Using `use`

- Renaming paths with `use`
- Glob imports with `use`
- Import an extension trait with `use`

### Renaming paths with `use`

> Skip this if: You know how to use `use` to rename modules.

In Rust, there is a filesystem module `std::fs`, but you don't have to `use` it to well...use it. You can type out the full path:

```rust
fn main() {
    let path = std::path::PathBuf::from("/tmp/lol.txt");
    let out = std::fs::read_to_string(path).unwrap(); // <== HERE
    println!("{out}")
}
```

Instead of writing out `std::path::PathBuf` and `std::fs` everywhere, you could tell Rust that you want to map a shorthand and rename it:

```rust
use std::path::PathBuf as PathBuf; // <== Here
use std::fs as fs;                 // <== Here

fn main() {
    let path = PathBuf::from("/tmp/lol.txt");
    let out = fs::read_to_string(path).unwrap();
    println!("{out}")
}
```

This code says, "Anytime you see `PathBuf` in this file, know what I mean is `std::path::PathBuf`". This pattern is so common you don't need the repetition of `as` at the end. Since you're `use`-ing it as the same name, you can write this code:

```rust
use std::path::PathBuf; // <== Note there's no `as`
use std::fs;            // <== Note there's no `as`

fn main() {
    let path = PathBuf::from("/tmp/lol.txt");
    let out = fs::read_to_string(path).unwrap();
    println!("{out}")
}
```

All three programs are exactly the same. The `use` does not __do__ anything. It simply renames things, usually for convenience.

### Glob imports with `use`

Beyond importing a namespace or a single item (such as an enum, struct, or function), you can import ALL the items in a namespace using a glob import.

For example:

```rust
use std::path::*; // <== Note glob import
use std::fs::*;   // <== Note glob import

fn main() {
    let path = PathBuf::from("/tmp/lol.txt");
    let out = read_to_string(path).unwrap();
    println!("{out}")
}
```

In this code, we can call the `read_to_string` function without naming it above. That's because `read_to_string` exists at `std::fs::read_to_string`, so when we import `std::fs::*`, it gets imported along with all of its `std::fs::*` friends.

This is generally discouraged because two imports may conflict. If one-day `std::path` introduces a new function named `std::path::read_to_string`, then there would be a conflict, and your code would fail to compile.

While glob imports might save time typing, they increase the mental load while reading. They're not currently considered "idiomatic." The exception would be for a [prelude file](https://stackoverflow.com/questions/36384840/what-is-the-prelude) within a crate.

### Import an extension trait with `use`

Beyond renaming imports, `use` can change your code's behavior!

In Rust, you can define a [trait](https://doc.rust-lang.org/stable/book/ch10-02-traits.html) on a struct that wasn't defined in the same library through something known as an ["extension trait"](https://rauljordan.com/rust-concepts-i-wish-i-learned-earlier/#understand-the-concept-of-extension-traits-when-developing-rust-libraries). This might sound exotic and weird, but it's common. Even Rust core code uses this feature.

For example, this code will not compile:

```rust
fn main() {
    let number = u64::from_str("99").unwrap();
    println!("{number}")
}
```

You'll get this compile error:

```
   Compiling demo v0.1.0 (/private/tmp/demo)
error[E0599]: no function or associated item named `from_str` found for type `u64` in the current scope
 --> src/main.rs:2:23
  |
2 |     let number = u64::from_str("99").unwrap();
  |                       ^^^^^^^^ function or associated item not found in `u64`
  |
  = help: items from traits can only be used if the trait is in scope
help: the following trait is implemented but not in scope; perhaps add a `use` for it:
  |
1 | use std::str::FromStr;
  |
help: there is an associated function with a similar name
  |
2 |     let number = u64::from_str_radix("99").unwrap();
  |                       ~~~~~~~~~~~~~~

For more information about this error, try `rustc --explain E0599`.
error: could not compile `demo` due to previous error
[Finished running. Exit status: 101]
```

But if you add a trait via `use`, now this code will compile:

```rust
use std::str::FromStr; // <== Here

fn main() {
    let number = u64::from_str("99").unwrap();
    println!("{number}")
}
```

Why did that work? In this case, the `use` statement on the first line changes the code by bringing the [`FromStr` trait](https://doc.rust-lang.org/std/str/trait.FromStr.html) into scope. Also, Rust was clever enough to realize that it __could__ compile if we added a `std::str::FromStr` onto the code. It's right there in the suggestion. Neat!

This behavior change confused me for the longest time as most `use` documentation and tutorials just beat the "Rust does not have imports, only renaming" drum to the point that it's not helpful information. Confusingly enough, if you define the `FromStr` trait on your own struct, you'll have to also `use std::str::FromStr` everywhere you want to use that behavior too.

## File/State permutations

The various permutations of `pub`, `mod`, and `use` can be confusing, to say the least. I wrote this out as an exercise in understanding them. It's more useful as a reference:

- Adding the code `mod <name>;`
  - Inside of `<filename>.rs` will:
    - Allow access to contents of `<filename>/<name>.rs` via `<name>::<component>`.
    - Allow access to `<filename>/<name>/mod.rs` via `<name>::<component>`.
    - Allow access of submodules of `<filename>` to access `<filename>::<name>`.
  - Inside of a module root (i.e., `<dirname>/mod.rs`)
    - Allow access to `<dirname>/<name>.rs` via `<name>::<component>`.
    - Allow access to `<dirname>/<name>/mod.rs.rs` via `<name>::<component>`.
    - Allow access of submodules of `<dirname>` to access `<dirname>::<name>`.
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Allow access to `src/<name>.rs` via `<name>::<component>`.
    - Allow access to `src/<name>/mod.rs.rs` via `<name>::<component>`.
    - Allow access to submodules of `crate` to access `crate::<name>`.
- Adding the code  `pub(crate) mod <name>;`
  - Inside of `<filename>.rs` will:
    - Same as `mod <name>` plus.
    - Allow super to access `<filename>::<name>`.
  - Inside of a module root (i.e. `<dirname>/mod.rs`).
    - Same as `mod <name>` plus.
    - Allow super to access `<filename>::<name>`>
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Same as `mod <name>`.
    - No additional effect.
- Adding the code `use <module>::<name>;` (relative path)
  - Inside of `<filename>.rs` will:
    - Add an alias from `<module>::<name>` as `<name>`.
    - Bring an extention trait into scope (if `<module>::<name>` is an extension trait).
    - Allow sub modules to access `<filename>::<name>` without using `<module>`.
  - Inside of a module root (i.e., `<dirname>/mod.rs`)
    - Add an alias from `<module>::<name>` as `<name>`.
    - Bring an extention trait into scope (if `<module>::<name>` is an extension trait).
    - Allow sub modules to access `<dirname>::<name>` without using `<module>`.
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Add an alias from `<module>::<name>` as `<name>`.
    - Bring an extention trait into scope (if `<module>::<name>` is an extension trait).
    - Allow all modules to access `crate::<name>` without using `<module>`.
- Adding the code  `pub(crate) use <module>::<name>;` (relative path) will do everything as `use <module>::<name>;` plus:
  - Inside of `<filename>.rs`
    - Same as `use <module>::<name>;` plus.
    - Allow super to access `<module>::<name>;` as `<filename>::<name>` without using `<module>`.
  - Inside of a module root (i.e., `<dirname>/mod.rs`)
    - Same as `use <module>::<name>;` plus.
    - Allow super to access `<module>::<name>;` as `<dirname>::<name>` without using `<module>`.
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Same as `use <module>::<name>;`.
- Adding the code  `use crate::<module-path>::<name>` (absolute path)
  - All modules in the path must be reachable with public visibility to crate root or
  there will be an error.
  - Inside of `<filename>.rs`
    - Same as `use <module>::<name>;` but the full path must be reachable from crate root.
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Same as `use <module>::<name>;` but the full path must be reachable from crate root.
  - Inside of a module root (i.e., `<dirname>/mod.rs`)
    - Same as `use <module>::<name>;` but the full path must be reachable from crate root.
- Adding the code  `pub(crate) use crate::<module-path>::<name>` (absolute path)
  - Inside of `<filename>.rs`
    - Same as `use crate::<module-path>::<name>;`
    - Allow all modules to access `crate::<path-to-filename>::<name>` without referencing `<module-path>`.
  - Inside of a module root (i.e., `<dirname>/mod.rs`)
    - Same as `use crate::<module-path>::<name>;`.
    - Allow all modules to access `crate::<path-to-dirname>::<name>` without referencing `<module-path>`.
  - Inside of a crate root (i.e., `main.rs`, `lib.rs`)
    - Same as `use crate::<module-path>::<name>;`.

## Modules != files

I've focused on mapping modules and files, but you can use modules without files. [Rust by example modules](https://doc.rust-lang.org/rust-by-example/mod.html) gives some examples. You'll likely find modules used without filenames as you go through various docs on `use` or the module system. Aside from `mod.rs` and `<dirname>/<modulename>.rs`, most features map 1:1 whether or not your modules are backed by a file system.

I really wanted to call this a "comprehensive" guide, but there's more to this rabbit hole. If you want a depth-first kind of learner, you can dive into some further reading:

- The Rust Reference (not THE book) - Talks about this stuff in detail
  - [Modules](https://doc.rust-lang.org/reference/items/modules.html)
  - [Use declarations](https://doc.rust-lang.org/reference/items/use-declarations.html)
- [Rust edition guide](https://doc.rust-lang.org/edition-guide/rust-2018/path-changes.html) talks about changes to the module system.
