---
title: "How to write a lock free Queue"
layout: post
published: true
date: 2017-06-28
permalink: /2017/06/28/how-to-write-a-lock-free-queue/
categories:
    - ruby
---

> Update: I did mention that lock free data structures are really hard to write, it looks like there might be some [issues that haven't been addressed in the implementation](https://www.reddit.com/r/C_Programming/comments/6k1ix6/how_to_write_a_lock_free_queue_in_c/) of this LF Queue that we're referencing. The rest of the analysis is still valid and hopefully useful to you, just know there's actually more that needs to be done, don't try to use that code for a mission critical application out of the box.

It's said that locks keep honest people honest. In programming locks keep multi-threaded programs honest by ensuring only one thread can access a resource at a time. Why would we want to get rid of locks then? In this post I'll revisit the [queue that I wrote in C](https://www.schneems.com/2017/06/14/meditations-on-writing-a-queue/), and instead look at a "lockless" queue implementation. We'll talk about atomicity and the tradeoffs when choosing one strategy or the other, and end with some ways to write "lock-free" Ruby code. Prepare to *unlock* your imagination!

First off, if you haven't read my [Mediations on Writing a Queue](https://www.schneems.com/2017/06/14/meditations-on-writing-a-queue/), go do that first. Now that you're up to speed, we'll look at someone else's code. Here is [a lock free queue written in C](https://github.com/darkautism/lfqueue).

> This post will be using examples from [this commit of lfqueue](https://github.com/darkautism/lfqueue/blob/master/lfq.c). Future versions of that lib may change.

Both libraries are very similar, they both have a constructor, a push method, and a pop method. They're both based on a linked list, but you'll notice that this one does not have any mutex or condition variable. How can it be threadsafe then?

Let's look back at a real world example of locks, an intersection. There is a space where cars going north and south need to intersect cars going east and west. If two cars try to use this resource at the same time, they will crash. We can put a stoplight at the intersection (our lock) and this will regulate who can use the resource and when.

A way to make a lockless intersection would require that we get rid of the stoplight, but also that we change the structure of the intersection. A good example might be a roundabout. We normalize all the behavior of the cars so they're turning the same direction, and then it is up to each individual car to ensure there's not another vehicle coming when they enter the roundabout.

Exact same problem, totally different solution.

In programming the way that we make lock free data structures is by first removing locks, and then re-designing the data flow to use atomic APIs.

In the case of `lfqueue`. The atomic API being used is `__sync_bool_compare_and_swap`. From the [docs](https://gcc.gnu.org/onlinedocs/gcc-4.4.5/gcc/Atomic-Builtins.html):

```
bool __sync_bool_compare_and_swap (type *ptr, type oldval type newval, ...)
type __sync_val_compare_and_swap (type *ptr, type oldval type newval, ...)

These builtins perform an atomic compare and swap. That is, if the current value of `*ptr` is `oldval`, then write `newval` into `*ptr`.

The “bool” version returns true if the comparison is successful and newval was written. The “val” version returns the contents of *ptr before the operation.
```

This method is atomic. That means anything this method does internally is completed in one operation. This method will first check to see if the pointer in the first argument is equal to the element passed into the second argument. If it is then it will replace (or swap) that value with a new value, which is the third argument. If the operation was able to succeed then it returns a boolean for true, otherwise false.

If this method was not atomic then after the check to see if the pointer matches the element we expect it to, another thread could modify the value, and then we would end up in an indeterminate state (a car crash). The atomic nature of the structure guarantees consistency even without a lock.

It's not enough to use an atomic API to remove locks, we also have to change our data flow to account for any memory setting failures. In the enqueue operation, we need to add a new node to the tail. This is done in lfqueue here:

```c
do {
  p = ctx->tail;

  if ( __sync_bool_compare_and_swap(&ctx->tail, p, tmpnode)) {
    p->next=tmpnode;
    break;
  }
} while(1);
```

First a temporary variable, `p`, is assigned the same value of the tail of our queue. In this case `ctx` is short for "queue context". Next we want to add our new node `tmpnode` to the end of our queue (make it the tail). If two threads are trying to do this at the same time, then one of them will succeed and one of them will fail. If the compare operation fails then the enqueue action will immediately loop again, trying to do another compare and swap operation, with the updated tail value. It will do this until it is successful, or until the heat death of the universe.

When the compare and set operation is successful, it means that we were able to change the value of the `tail`. The next line updates the previous tail's `next` pointer to point to our new node. We don't need to do this via a compare and set atomic operation, because if anyone else is trying to modify the the tail, they failed (or otherwise our compare would have failed). The `break` at the end exits the loop.

After you'll notice the `__sync_add_and_fetch`, and I think this is hilarious. If you look up the docs for it here's what it says:

> These builtins perform the operation suggested by the name, and return the new value.

Seriously? I get that the names are pretty intuitive, but that just comes across as user hostile. This is why I added [a documentation feature to CodeTriage to help find undocumented methods in Ruby libraries](https://www.codetriage.com/rails/rails). I believe that good documentation that respects users and their time helps all developers from all skill levels. If you're looking to help out a language community, docs is a great place to have a large amount of impact with a minimal amount of effort.

Back to the code. This call:

```c
__sync_add_and_fetch( &ctx->count, 1);
```

Will synchronize the value of `ctx->count` and then add one to it. It's not enough to do `ctx->count++` because this equates to:

```c
ctx->count = ctx->count + 1
```

Imagine that two threads are trying to do this same operation, one of them could context switch after the `ctx->count` but before the plus operator

```c
ctx->count = ctx->count + 1
//                     ^
//                     |___HERE
```

If that happened, then thread A tries to increment from 0 to 1, sees the value is zero, goes to add one. Then thread B context switches in, sees the value is 0, adds one so the value is now 1. Now thread C switches in and increments from 1 to 2 successfully. Thread A finaly gets to context switch in, but it sill thinks that the value is zero, so adding one to it will produce 1 instead of the correct result: 3. To avoid this race condition from happening we have to use an atomic function.

The dequeue function in lfqueue is pretty similar to enqueue, except in reverse. Instead of spinning trying to change the `tail`, it spins while trying to change the `head`. Instead of adding one to the count it subtracts one from the count.

So why would we ever use a lock when we can write with lock-free data structures? First is complexity. When we're locking a mutex, we know that we can access a shared state and do anything we want, we don't have to worry about how another thread might change that resource. With lockless programming, we have to always be asking ourselves if any new code needs to be atomic, and if so how can we enforce consistency.

When we learn to program, we don't generally think that an operation __might__ succeed. 1+1 is always 2 (or sometimes occasionally `2.0000001`). Having to convert everything to atomic operations requires a paradigm shift, and getting it right can be challenging. Writing multi-threaded code is hard enough, writing it with no locks is kinda like playing on ultra-hard mode.

Next reason why using lock free structures isn't such an easy win: performance. While it sucks to be stuck at a traffic light, when it turns green you go and don't look back. If you're at a really busy roundabout it can be very nerve racking to constantly burn cycles trying to figure out how fast each car is going, can you squeeze in, and should you go right now or wait. If you're suffering from a lot of contention and calls to your atomic structures are failing frequently, then there's a lot of extra work being done, when we could be sitting back grabbing a sip of our La Croix and listening to NPR.

In my [Operating Systems course](https://classroom.udacity.com/courses/ud923) I learned about another type of a lock, which is called a [spinlock](https://en.wikipedia.org/wiki/Spinlock). This is a lock that instead of blocking and yielding execution to another thread, keeps trying to acquire the lock until it succeeds. This again sounds like a waste of resources but it's not always. Context switching between threads isn't free, and if a task is very short lived then it's likely the mutex will be released and acquired faster than it would take to context switch in another thread.

Does that behavior sound similar to the structure that lfqueue coded? If the swap operation isn't successful, it will spin and keep trying until it succeeds. If you're using a queue that won't experience much contention, it seems reasonable that the lockless structure would be better, it will have fewer cases where it will have to spin. In cases where someone is constantly popping or pushing and the queue is the bottleneck, being able to tell threads to calm down and wait until they're ready to do work is a benefit of a lock based approach.

Ultimately if the performance bottleneck of your program ends up being your queueing library, hopefully you'll have some real world example data to profile with, and you won't have to take my best guess estimations.

## Lock Free Ruby

The key to lock-free code is in atomic data structures, this is also the key in Ruby. Some operations like `Queue#pop` are atomic, but others like:

```ruby
value ||= 0
```

Are not. In Ruby this expression will be expanded to be:

```ruby
value = value || 0
```

And we can have the same race condition we saw earlier with the count. The [concurrent ruby gem](https://github.com/ruby-concurrency/concurrent-ruby) has a number of thread safe data structures, some of them expose the ability to do a `compare_and_set` for example:

```ruby
require 'concurrent'

my_atomic = Concurrent::AtomicFixnum.new(0)
my_atomic.compare_and_set(0, 1)
# => true

puts my_atomic.value
# => 1
```

I will tell you a dirty secret though, which is this method is powered by a lock under the hood:

```ruby
# https://github.com/ruby-concurrency/concurrent-ruby/blob/041c1d10df225e6d3295c428aebb719931754562/lib/concurrent/atomic/mutex_atomic_fixnum.rb#L42-L51
def compare_and_set(expect, update)
  synchronize do
    if @value == expect.to_i
      @value = update.to_i
      true
    else
      false
    end
  end
end
```

The benefit of this style of "lock free" code is that the lock isn't exposed to the end consumer. Instead of having to pass around a value and a lock everywhere, you can instead pass only a value, that has a mutex associated with it. If you're using this library with JRuby,  actually get a lock free version of many of these methods. For the exact same top level code, you would get this implementation under the hood instead:

```java
# https://github.com/headius/ruby-atomic/blob/63107c09afca85df9136050185fdb1968da13bc9/ext/org/jruby/ext/atomic/AtomicReferenceLibrary.java#L105-L115
@JRubyMethod(name = {"compare_and_set", "compare_and_swap"})
public IRubyObject compare_and_set(ThreadContext context, IRubyObject expectedValue, IRubyObject newValue) {
    Ruby runtime = context.runtime;

    if (expectedValue instanceof RubyNumeric) {
        // numerics are not always idempotent in Ruby, so we need to do slower logic
        return compareAndSetNumeric(context, expectedValue, newValue);
    }

    return runtime.newBoolean(UNSAFE.compareAndSwapObject(this, referenceOffset, expectedValue, newValue));
}
```

So by using the libraries in `concurrent-ruby`, you're guaranteeing that they're threadsafe, and depending on the implementation and version you're using you may actually get a lock-free implementation.

While it would be nice if there were more atomic primitives such as compare and swap we could use in Ruby, we're able to get just about all the functionality we need via good ole-fashioned locks. If you find yourself in a patch of Ruby code where acquiring the mutex is the bottleneck, it might be time to drop down to the C interface.

That's it for today on atomic function calls, and lockless data structures. If you've made it this far, thanks for reading the whole *lock* stock and barrel.

