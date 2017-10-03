---
title: "Lifelong Rubyist makes some Python code 5x Faster"
layout: post
published: true
date: 2017-10-02
image: og/ruby-python-fast.png
permalink: /2017/10/02/lifelong-rubyist-makes-some-python-code-5x-faster/
categories:
    - ruby
---

I've been writing Ruby code for the past 10+ years, and recently due to my masters courses, I've been writing a lot of Python. While there are many differences, one area of similarity is their performance characteristics and how code can be optimized. In this post I'm going to look at a bit of Python code I optimized recently, and then compare the process of making this code faster to the process of how I make Ruby code faster.

> Several people have mentioned they thought the post was about me making the Python interpreter faster. That would have been pretty dang cool, but is not the case. This article is about how to write faster code using an interpreted language. The lessons learned are applied equally to both Python and Ruby.

Before we get to the code in question let's take a look at some of my qualifications. If you don't know, performance in Ruby is one of my favorite hobbies. I'm the maintainer of [derailed benchmarks](https://github.com/schneems/derailed_benchmarks) for benchmarking Rails applications, and I've made a ton of performance pull requests to various projects. I was somewhat accidentally responsible for fanning the "freeze all strings" fad after I had a [PR to Rails that made end to end requests nearly 12% faster](https://github.com/rails/rails/pull/21057). Though in truth most of the performance came from reducing hash (dict for the python folks) and array (list) allocations.

> Word of warning, I tend to use list and array interchangeably. I do the same thing with method/function. I know they're different and it will make some of your eyes bleed, I'm sorry. Get over it.

When it comes to making things faster, this isn't exactly my first rodeo.

Before we can make something fast, we have to understand what it does. Here's the problem setup.

> If you don't care about what the code does, you can skip to the "Don't Repeat Your (logic)" part that goes through what optimizations are possible.

The code I'm optimizing is used for playing a game that requires determining all possible moves for a Queen piece on a chess-like board. For this case we are using a variable board height and width (i.e. it's not an actual chess board). It also has a representation of the board state as list of lists (array of arrays for Ruby peeps) that contain the board "state".

Open spaces are represented by a `0`. The board state might look like this:

```
height = 7
width  = 7
board_spaces_occupied = [
    [  1,  0,  1,  1,  1,  0,  0],
    [  1,  1,  0,  1,  1,  0,  1],
    [  1,  1,  1,  1,  0,  0,  1],
    [  1,  0,  1,  0,  1,  1,  1],
    [  1,  0,  0,  1,  1,  1,  1],
    [  0,  0,  1,  0,  0,  1,  1],
    [  0,  1,  1,  0,  1,  1,  1],
]
```

The details are more complex but utterly irrelevant so that's all you need to know. Also since I know you're going to ask "why didn't you use numpy?" on Reddit. It was against the rules of this specific assignment.

To accomplish the task of figuring out where the valid moves are, I was given a variant on this Python code:

```python
BLANK = 0

def get_legal_moves_slow(move):
    r, c = move

    directions = [ (-1, -1), (-1, 0), (-1, 1),
                    (0, -1),          (0,  1),
                    (1, -1), (1,  0), (1,  1)]

    fringe = [((r+dr,c+dc), (dr,dc)) for dr, dc in directions
            if move_is_legal(r+dr, c+dc)]

    valid_moves = []
    while fringe:
        move, delta = fringe.pop()

        r, c = move
        dr, dc = delta

        if move_is_legal(r,c):
            new_move = ((r+dr, c+dc), (dr,dc))
            fringe.append(new_move)
            valid_moves.append(move)

    return valid_moves

def move_is_legal(row, col):
    return 0 <= row < height and \
           0 <= col < width and \
           board_spaces_occupied[row][col] == BLANK
```

> This code was originally in a class but this form is a bit easier for the purposes of the blog post. Here `height` and `width` and `board_spaces_occupied` will be globally accessible variables.

You can see that it works fine, if we pass in a "move" of `(5, 4)` our program correctly tells us there's only two places a queen could move from there:

```python
print get_legal_moves_slow((5,4))
# => [(6, 3), (5, 3)]
```

> To any Rubyists the parens means that this is a "tuple", think of it as in immutable array. If this were Ruby it would be `[[6, 3], [5, 3]]`.

To understand how to make a faster version of this we need to understand what it's doing, I'll walk you through the logic.

A queen can move either up and down or diagonally. It can move as far as it wants as long as all spaces it moves through are open. To represent this, first we want to find all of the positions immediately around the queen that are open. We can represent this as a change in row and a change in column.

```python
directions = [ (-1, -1), (-1, 0), (-1, 1),
                (0, -1),          (0,  1),
                (1, -1), (1,  0), (1,  1)]
```

Next we iterate over each of these variants and see if the queen could legally make that move.

To do this we loop through each direction, combine it with our current row and column and then check to see if it's valid.

When a direction is valid then we store not only the position of the valid square, but also how we got there (i.e. the direction). We use that "direction" to continually expand outwards to find other valid moves.

```python
fringe = [((r+dr,c+dc), (dr,dc)) for dr, dc in directions
        if move_is_legal(r+dr, c+dc)]
```

> Note: The `r` stands for row, `c` stands for column. The `dr` stands for delta row and `dc` stands for delta column. I didn't pick the variable names. Btw Rubyists, this format of iterating over a list is called list comprehension if you want to google the syntax.

Now we have a "fringe" list that we can keep expanding. To help visualize let's go through an example.

On a totally empty board if we are at position `(3, 3)` then moving one space to the upper left corner would put us at `(2, 2)`. We used the first element in the "direction" array `(-1, -1)` to get there. Now in our "fringe" we would have this:

```python
# [((row, column), (delta_row, delta_column))]
  [((2,   2),      (-1,        -1))]
```

If we wanted to keep "expanding" it we can apply the same direction `(-1, -1)` again to our position and end up at `(1, 1)`.

Now that we have the positions immediately around a space we need to "expand" each one until it hits a non-occupy-able space.

This code does the full expansion:

```python
valid_moves = []
while fringe:
    move, delta = fringe.pop()

    r, c = move
    dr, dc = delta

    if move_is_legal(r,c):
        new_move = ((r+dr, c+dc), (dr,dc))
        fringe.append(new_move)
        valid_moves.append(move)
```

We iterate over each element in our "fringe" list, remove it, check to make sure it's a valid move, and then apply our delta row and delta column to make a new position. We add that position onto our "fringe" list to be checked as well as add the original to a `valid_moves` list that will be what we return.

Hopefully you're still with me. In my case this code was being called inside of loops for the same board again and again. So every millisecond counted.

Now that we understand how code works how do we optimize it?

In the next few sections I'll go over the tenets of optimizing scripting languages that I've found apply to both Ruby and Python. If you can understand how to make Python code faster, you can make code in any scripting language faster. At the end I'll show you the final result and give some benchmarks.

## Don't Repeat Your (logic)

One of the most basic of optimizations is to not duplicate work. When we put an element onto the `fringe` list it's already checked if it's a valid in the list comprehension, then when we're popping elements off of the list we're checking if the same element is valid again. That means if all 8 spaces are valid, we've had to check each of them twice.

We can go faster by only doing this check once.

## Prefer Logic over Objects

In scripting languages object creation takes memory and CPU cycles. That memory then takes more CPU cycles to later be cleaned up in GC.

Some objects are cheaper to create than others. Complex objects take longer to create and copy. Lists (arrays for Ruby) and dicts (hashes) are much more expensive to make than strings. Likewise integers are cheaper than strings.

It's hard to demonstrate so here's a contrived example. We're given a value that may or may not be `None` (nil for Rubyists). We then add it to a list and process it later. For example:

```python
my_list = [value] # <== List allocated here
if None in my_list:
    return

# ...
```

That example will allocate a list even if we're going to do nothing with it. Instead it's much faster to check the value first before allocating the array:

```python
if value is None:
  return
my_list = [value]
# ...
```

> Yes, I realize you would never write code like the first example, but you get the point.

Objects are slow, logic is fast. This is true in Ruby and Python.

## Careful how you Serialize

There are two parts to think about when reducing object creation. The actual overhead of the object being created and how are we referencing and using the object. How is that object being manipulated after it has been allocated?

In this case we want to watch how we serialize and move around our data, pulling values from a tuple isn't free. In our example we're expanding a tuple to points

```python
move = (1, 0)
# ...
r, c = move
```

Pulling out `r` and `c` isn't free. For example if we have two similar functions:

```python
def function_one(move):
    r, c = move
    return r + c

def function_two(r, c):
    return r + c
```

It is MUCH faster to pass in the decomposed values (using `function_two`) instead of the tuple. I benchmarked this using `kernprof`, and the serialization in `function_one` takes double the compute Time longer since it has to move data around before it can use it.

Ideally we want to manipulate our data as little as possible to get maximum performance improvement.

## Careful with literals in loops

In a scripting language that doesn't have a JIT every time this code gets called:

```python
valid_moves = []
```

A very expensive array gets allocated. In our code example we're not explicitly putting literals into loops, but sometimes you also have to consider how the code is being run. In my case this function `get_legal_moves_slow()` is called over and over repeatedly. Just because it doesn't have a `for` or a `while` right above it, doesn't mean that it's not inside of a loop.

In this case `valid_moves` is actually needed every time the function is called as it gets mutated, do you see any static values that don't change?

How about this one:

```python
directions = [ (-1, -1), (-1, 0), (-1, 1),
                (0, -1),          (0,  1),
                (1, -1), (1,  0), (1,  1)]
```

This tiny bit of relatively readable code is allocating one list, 8 tuples, and 16 references to integers EVERY time it's called. This list is never mutated, we can save a lot of allocations by moving it out of the function and into a global constant that is only created once at boot time.

## Don't look, just leap

I already mentioned we don't want to repeat the same check twice. There is no code faster than "no code". The optimal number of times to perform a check is exactly zero.

I'm not telling you to write unsafe code, but if you KNOW for a fact that a certain scenario can never happen, then you don't need to check for it.

Where could we apply this? Right here:

```python
def move_is_legal(row, col):
    return 0 <= row < height and \
           0 <= col < width and \
           board_spaces_occupied[row][col] == BLANK
```

Before we see if the board space is open, we check to make sure that the piece didn't fall off of the board.

How could we remove this check? One option would be to put a border around our board, so that as it expands it sees that the space isn't free. This however makes some of our other math more difficult.

There's a way to do it without contorting our logic, I'll get to that later. The point though is to think about where we can possibly remove logic checks.

## No Methods no Problem

Method calls (function calls in Python) are not free. When you call a method the interpreter has to look up where that method exists and then call the code.

I say this with hesitancy because methods make code cleaner and more understandable, and 99% of the time your bottleneck isn't calling methods. This is an extreme micro optimization, but it's still relatively true.

Think also about how many times a lookup is being performed. I don't know how list index lookup in Python is implemented but in Ruby it's as a method. So this code:

```python
board_spaces_occupied[row][col] == BLANK
```

Will perform not one, but two lookups. First as we access the `board_spaces_occupied[row]`. Another list is returned and we access our second element (via the `col`).

If we can remove methods or remove the number of operations we must perform against a data structure then we will go faster.

The good news is that method call time and things like array lookup by index are optimized by core developers so they will typically be extremely fast and therefore not worth optimizing.

I.e. don't contort your program just to have fewer lookups or method calls. On the other hand if you can reduce a lookup easily, why not?

## Bench your code

A word of warning, Performance Padawan: when it comes to any performance code you must ALWAYS benchmark. Before, and after and in-between. While most of my advice is generally true, it might not be true for your specific use case. So always benchmark. How to benchmark well is a whole other thing that I'll save for another time.

## Sometimes break all the rules

Sometimes more objects are better. We can trade CPU for memory by caching. We already talked about moving the direction array to a constant, this is a micro form of this lesson. We're forcing that code to live in memory forever. On the flip side we never have to burn CPU cycles to re-build it. Cached!

What can we cache here? We know that the height and width are fixed. We know the rules of movement won't change. Positions on the board may change. With this in mind we can pre-compute a list of ALL valid moves for each position.

We have to be careful though since the state of the board can change, to account for this we can make a list for each direction of expansion. For example from `(3, 3)` moving to the right would be:

```python
[(3, 4), (3, 5), (3, 6)]
```

Now what happens if there's something at position `(3, 5)`? We can check if the space is empty and remove it, but that also means that `(3, 6)` is not reachable either. Since we have a list for each direction we can break iteration on the first occupied space we find.

## Let's put it all together

First we'll pull out our direction array:

```python
STAR_DIRECTIONS = [  (-1, 0), (1,  0), # up down
                     (0, -1), (0,  1), # left right
                     (1, -1), (1,  1), (-1, -1), (-1, 1)] # diagonals
```

> The order of the directions don't matter, you can see I changed them here.

Next up I want to be able to lookup if a space is empty with only one call instead of two, I also want to look up based off of a tuple and not individual row/column combo. So I built a dict (hash in Ruby) with the position as an index:

```python
def build_blank_space_dict():
    blank_space_dict = {}
    for c in range(0, height):
        for r in range(0, width):
            blank_space_dict[(c, r)] = (board_spaces_occupied[c][r] == BLANK)
    return blank_space_dict
```

You can see how I use it here:

```python
def move_is_legal_from_dict(move):
    return 0 <= move[0] < height and \
           0 <= move[1] < width and \
           blank_space_dict[move]
```

Now here's the most expensive meat and potatoes. We want to precompute ALL valid moves for the board and cache them. While it's expensive, we only do it once at boot, so it doesn't need to be recalculated:

```python
def calculate_first_move_guess_dict():
    first_move_guess_dict = {}
    for r in range(0, height):
        for c in range(0, width):
            rc_tuple = (r, c)
            first_move_guess_dict[rc_tuple] = []
            for delta_r, delta_c in STAR_DIRECTIONS:
                valid_guesses = []
                dr = delta_r
                dc = delta_c
                move = (r + dr, c + dc)
                while move_is_legal_from_dict(move):
                    valid_guesses.append(move)
                    dr += delta_r
                    dc += delta_c
                    move = (r + dr, c + dc)

                first_move_guess_dict[rc_tuple].append(valid_guesses)
    return first_move_guess_dict
```

That's a giant chunk of code. It's basically the exact same code that was previously in `get_legal_moves_slow()`. The main difference is that theirs is inside of two loops to build each row and column possibility.

Notice something important here, we're checking for the validity of a move with `move_is_legal_from_dict()` before adding it to our list. This checks for positions outside of the board, and will remove them. That means later when we check for board states we don't have to perform that check again (I told you I would get back to it, didn't I).

Finally the method we've all been waiting for:

```python
def get_legal_moves_fast(move):
    valid_moves = []
    for direction_list in first_move_guess_dict[move]:
        for move in direction_list:
            if blank_space_dict[move]:
                valid_moves.append(move)
            else:
                break # rest of moves in this direction are invalid

    return valid_moves
```

We look up an array of valid moves with `first_move_guess_dict[move]`. On a 3 by 3 board, for position (1, 1) it would return:

```python
[[(0, 1)], [(2, 1)], [(1, 0)], [(1, 2)], [(2, 0)], [(2, 2)], [(0, 0)], [(0, 2)]]
```

It then loops through each element in those sub arrays and checks them with `blank_space_dict[move]` if it's valid it gets added onto our possible moves, otherwise we break the inner loop because no other points from that direction are valid (queen move rules).

Finally we return a list of valid move tuples.

How does it compare? I used kernprof to see:

```term
$ kernprof -l -v perf.py
Wrote profile results to perf.py.lprof
Timer unit: 1e-06 s

Total time: 1.17439 s
File: perf.py
Function: get_legal_moves_fast at line 53

Line #      Hits         Time  Per Hit   % Time  Line Contents
==============================================================
    53                                           @profile
    54                                           def get_legal_moves_fast(move):
    55    100000        41991      0.4      3.6      valid_moves = []
    56    900000       378690      0.4     32.2      for direction_list in first_move_guess_dict[move]:
    57   1000000       491422      0.5     41.8          for move in direction_list:
    58    200000       106333      0.5      9.1              if blank_space_dict[move]:
    59    200000       116717      0.6      9.9                  valid_moves.append(move)
    60                                                       else:
    61                                                           break # rest of direction is invalid
    62
    63    100000        39242      0.4      3.3      return valid_moves

Total time: 5.80368 s
File: perf.py
Function: get_legal_moves_slow at line 69

Line #      Hits         Time  Per Hit   % Time  Line Contents
==============================================================
    69                                           @profile
    70                                           def get_legal_moves_slow(move):
    71    100000        79230      0.8      1.4      r, c = move
    72
    73    100000        78106      0.8      1.3      directions = [ (-1, -1), (-1, 0), (-1, 1),
    74    100000        75957      0.8      1.3                      (0, -1),          (0,  1),
    75    100000        94609      0.9      1.6                      (1, -1), (1,  0), (1,  1)]
    76
    77    900000       739500      0.8     12.7      fringe = [((r+dr,c+dc), (dr,dc)) for dr, dc in directions
    78    800000      1704089      2.1     29.4              if move_is_legal(r+dr, c+dc)]
    79
    80    100000        79558      0.8      1.4      valid_moves = []
    81
    82    500000       406481      0.8      7.0      while fringe:
    83    400000       471503      1.2      8.1          move, delta = fringe.pop()
    84
    85    400000       323095      0.8      5.6          r, c = move
    86    400000       321289      0.8      5.5          dr, dc = delta
    87
    88    400000       736811      1.8     12.7          if move_is_legal(r,c):
    89    200000       214678      1.1      3.7              new_move = ((r+dr, c+dc), (dr,dc))
    90    200000       215883      1.1      3.7              fringe.append(new_move)
    91    200000       189134      0.9      3.3              valid_moves.append(move)
    92
    93    100000        73752      0.7      1.3      return valid_moves
```

If you're on mobile this is the important part:

```
Total time: 1.17439 s
File: perf.py
Function: get_legal_moves_fast at line 53

Total time: 5.80368 s
File: perf.py
Function: get_legal_moves_slow at line 69
```

The original method took 5.80368 seconds and our new and improved method took 1.17439. That's about a 5x performance boost.

Could we get even faster?

One thing I didn't mention is that some operations can be expensive. I've read that `append()` to a list in python is not heavily optimized. Instead of constantly appending to the same list we could perhaps initialize an array of a fixed size add elements to indexes and then resize it once we remove any `None` (nil) elements. But again, benchmark everything to see if it's true.

If you have access to numpy there's probably a way to do some of this faster. If you're on a platform that does not have a GVL (i.e. not Ruby and not Python) then you could loop through each direction in parallel possibly. Though the scheduling time of putting that on other thread probably isn't worth it.

Also there might be some python minutiae that I missed, or some language feature I'm not aware of that makes everything way faster. I've been told to look into itertools, functools, and operator modules.

I'll also point out that my code is gnarly, it's way more complicated than the original code. It does much more, and it preserves more state and uses more memory. That being said, the only thing that matters to me is the call time of that last "get legal moves" function. It is short, almost unreadable succinct, it also requires lots of knowledge about how each of those pieces fit together.

Most of the time I am coding, I write so that it is easily read by humans. While a 5x perf improvement might sound good, it's only good if it doesn't cause your co-workers to take 10x as long maintaining the code. While we think of perf work in terms of CPU and RAM, also consider human costs as well. I generally write slow code, and then profile and only optimize the extreme hot spots. In my case this was a hotspot.

Thanks for reading.
