---
title: "Meditations on Writing a Queue"
layout: post
published: true
date: 2017-06-14
permalink: /2017/06/14/meditations-on-writing-a-queue/
categories:
    - ruby
---

What is a queue besides the line for the little teacups at Disney? In programming, a queue is a very useful data structure that can simplify our programs, especially when it comes to threading. In today's post, I'm going to walk you through building a queue in C, talk about how to effectively use a queue, and also compare to the `Queue` implementation that ships with Ruby.

## What is a Queue?

While there are different types of queues, the most common is a FIFO (first in first out). The first person in line to ride Space Mountain, is the first person who leaves the waiting area (and they also get the best seat).

Queues can have many different operations, but the most basic are `push`, this adds something to the queue, and `pop` which removes the most recent thing from the queue (assume all queues in this post are FIFO).

The next really important thing about a queue is that it's threadsafe. What do I mean by that? If you're trying to pop an element off of the queue in two different threads, you won't pop the same element off twice, and you won't cause a SEGV.

Because of this threadsafety, we can use a queue to safely transport data between a worker (consumer) and a boss (producer) thread. Because pushing and popping are atomic (more thread-safe jargon), we can use them without having to introduce locks at our top level code. This can simplify the design of our program and make it more readable. Readable code is maintainable code, so that's why I like using queues.

Queues are used all over in programming; a common one is in webservers like Nginx. As requests come in they will wait at the socket until a worker is available to pop it from the queue and begin processing. In industrial engineering speak a queue gives us the ability to "accumulate" work. This means that our system can have a burst capacity that is higher than it's actual capacity (as long as the average is at or below capacity, see [Little's Law](https://en.wikipedia.org/wiki/Little%27s_law)). We even see queues in our day-to-day life such as at the grocery store.

> Note: I'm using "capacity" in this paragraph to indicate "throughput".

## Why build a Queue?

The C programming language does not come with a queue structure out of the box like Ruby, but it provides all the primitives to build one. I'm learning C currently and I've been writing threading code, so having a queue structure helps simplify my end programs. If you know C, feel free to critique (but not criticize) my implementation: feedback is how we all get better.

## Build a Queue Data Structure

> I've got all the [code online](https://github.com/schneems/tiny_queue). If you want you can skip straight past the docs and [straight to this commit of the C code](https://github.com/schneems/tiny_queue/blob/316b4e6fab99b380c94e956c49bb18a935093cd1/tiny_queue.c). I recommend opening up that in another browser window to follow along as I explain what's going on. Note that while I might update the code on GitHub, it's a pain to keep a post in sync, so my explanations will always match an early version of this lib. For a more up-to-date version, you can check out the repo.

First up we'll need a way to store our queue. For this I introduce a struct called `tiny_queue_t`. In C there are no objects, instead we can build value objects using structs, here's the definition:

```c
typedef struct tiny_queue_t {
  struct tiny_linked_list_t* head;
  struct tiny_linked_list_t* tail;
  pthread_mutex_t mutex;
  pthread_cond_t wakeup;
} tiny_queue_t;
```

This struct has a pointer to a linked list (which I'll get to later) called `head`, and another called `tail`. It also has a mutex called `mutex` and a condition variable called `wakeup`.

> If you've not written any threadsafe codes before, a mutex is like a "talking stick" that only allows the current owner to run. Another example would be a stop light that only allows one car through at a time. Feel free to stop and google here if you need to. I'll talk more about the condition variable and mutex later.

Next up we need a linked list implementation.

```c
typedef struct tiny_linked_list_t {
  void *data;
  struct tiny_linked_list_t* next;
} tiny_linked_list_t;
```

The list is called `tiny_linked_list_t`. One thing to note is that I prefixed all my calls with `tiny_` since C does not have namespaces and I want to be able to use it with other code that has the same name. This struct has a generic pointer to `data`, this is where the elements in our queue will live. It then has a pointer to another `tin_linked_list_t` called `next`.

> In C a "pointer" means a "reference to". So "a pointer to a linked list" means "a reference to a linked list".

I wanted my queue to be able to grow to arbitrary length without putting any constraints on the system. I chose to use a linked list to do this. Each element in the list contains some data and a pointer to the next element in the list. When we have access to the first element in the list then we can iterate through all elements in the list. This is why our `tiny_queue_t` data type has a `head` pointer. It has a `tail` pointer so we can know when we're at the end of the list.

## Allocate a Queue

Next up we need to be able to allocate a queue instance. Here's the code


```c
tiny_queue_t* tiny_queue_create() {
  struct tiny_queue_t* queue = (struct tiny_queue_t*)malloc(sizeof(struct tiny_queue_t));
  queue->head = NULL;
  queue->tail = NULL;

  queue->mutex  = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
  queue->wakeup = (pthread_cond_t)PTHREAD_COND_INITIALIZER;
  return queue;
}
```

The function definition tells us that `tiny_queue_create()` takes no arguments and returns a pointer to a `tiny_queue_t` type. Next up we have to allocate the queue:

```c
struct tiny_queue_t* queue = (struct tiny_queue_t*)malloc(sizeof(struct tiny_queue_t));
```

Here our variable name is `queue`, it is of type `tiny_queue_t` and we are telling C to make it the size of a struct of `tiny_queue_t`. This will ask the OS for space in the heap to store our variable. Once allocated, our queue is empty so we set the head and tail to be `NULL`. We do this so then later we can explicitly check for the condition of having a `NULL` head.

The syntax, if you've not guessed it is that `queue->head` means that we want the `head` variable contained in the `queue` struct. This is similar to accessing an attribute from a value object in Ruby. We can read and write to values in structs like this

> In C `NULL` is like `nil` in Ruby, you can read more about [null pointers here](https://en.wikipedia.org/wiki/Null_pointer).

Next up we have to allocate our mutex and our condition variable. Honestly these lines are kinda like voodoo to me:

```c
queue->mutex  = (pthread_mutex_t)PTHREAD_MUTEX_INITIALIZER;
queue->wakeup = (pthread_cond_t)PTHREAD_COND_INITIALIZER;
```

I do know that `PTHREAD_MUTEX_INITIALIZER` and `PTHREAD_COND_INITIALIZER` are macros, which I don't entirely understand yet. I also know that the type casting is required, but I'm not sure why. Either way just know that we're setting these variables.

At this point we can allocate a queue instance

```c
tiny_queue_t *my_queue = tiny_queue_create()
```

But we can't use it, we don't have any way to push data onto the queue or to pop data off of it. It makes sense to look at the push first, since we can't pop what isn't there.

## Push to the Queue

```c
void tiny_queue_push(tiny_queue_t *queue, void *x) {
  pthread_mutex_lock(&queue->mutex);
    struct tiny_linked_list_t* new_node = (struct tiny_linked_list_t*)malloc(sizeof(struct tiny_linked_list_t));
    new_node->data = x;
    new_node->next = NULL;

    if(queue->head == NULL && queue->tail == NULL){
      queue->head = queue->tail = new_node;
    } else {
      queue->tail->next = new_node;
      queue->tail = new_node;
    }
  pthread_mutex_unlock(&queue->mutex);
  pthread_cond_signal(&queue->wakeup);
}
```


I know this looks intimidating, so I'll walk through it. Our method signature says that the first argument is a pointer to a `tiny_queue_t` instance, we access this in the `queue` variable. The second argument is a pointer to anything we want to store in the queue, this is passed in as the `x` variable. There is no return from this function.

Before we can push something to our queue we have to make sure that no one else is trying to also write to the queue, or take something off of the queue. This is where our mutexes come in. When we "lock" a mutex, no one else can acquire the mutex. This is similar to how in a discussion circle, only the person holding a "talking stick" can speak. In C you must manually lock and unlock the mutex. The code is indented to help visually identify this behavior

```c
pthread_mutex_lock(&queue->mutex);
  # ...
pthread_mutex_unlock(&queue->mutex);
```

Anything between this lock and unlock is "protected", meaning that we can modify things as long as all other code modifying the same values are also wrapped in a similar lock/unlock, then we are safe.

This is the first time we've seen `&` in code. The `&` is kinda like the companion of `*`. I think in this case that `queue->mutex` is the actual mutex, but the method signature of `pthread_mutex_lock` requires a pointer to a mutex. You can get this from:

```sh
$ man pthread_mutex_lock
PTHREAD_MUTEX_LOCK(3)    BSD Library Functions Manual    PTHREAD_MUTEX_LOCK(3)

NAME
     pthread_mutex_lock -- lock a mutex

SYNOPSIS
     #include <pthread.h>

     int
     pthread_mutex_lock(pthread_mutex_t *mutex);
# ...
```

On the last line notice it takes a pointer `pthread_mutex_t *mutex`.

Inside of the actual code we initialize a new linked list node of type `linked_list_t` and we put our pointer we passed in (x) on the node:

```c
struct tiny_linked_list_t* new_node = (struct tiny_linked_list_t*)malloc(sizeof(struct tiny_linked_list_t));
new_node->data = x;
new_node->next = NULL;
```

At this point we have a node, that is not linked to anything, and it points at nothing.

Next up we need to check for the case where our list is currently empty. This is when `head` and `tail` are both `NULL`

```c
queue->head == NULL && queue->tail == NULL
```

When this happens we can set both `head` and `tail` to the same element, because the list only has one item, the thing we just passed in:

```c
queue->head = queue->tail = new_node;
```

In this case `new_node->next` is still `NULL` because there is no second node to point at.

If the list was not empty then we must add our new node to the end of the list. We set the `next` value of our current last item in the list to this new node:

```c
queue->tail->next = new_node;
```

Then we make this node the new last item in the list:

```c
queue->tail = new_node;
```

That's all there is to it. We just pushed a node on to our list. The last thing we do after unlocking our mutex is to signal to our condition variable with `pthread_cond_signal`. You'll see what this does in the next section.


## Queue pop

Now we have data in our queue, we need a way to get data out of it. Introducing `tiny_queue_pop`

```c
void *tiny_queue_pop(tiny_queue_t *queue) {
  pthread_mutex_lock(&queue->mutex);
    while(queue->head == NULL) { // block if buffer is empty
      pthread_cond_wait(&queue->wakeup, &queue->mutex);
    }

    struct tiny_linked_list_t* current_head = queue->head;
    void *data = current_head->data;
    if(queue->head == queue->tail) {
      queue->head = queue->tail = NULL;
    }
    else {
      queue->head = queue->head->next;
    }
    free(current_head);
  pthread_mutex_unlock(&queue->mutex);

  return data;
}
```

This function takes a `tiny_queue_t` pointer as an argument and returns an untyped pointer (`void *`).

First thing we do is try to acquire a lock to the mutex. If an element is being added to the queue, this code will wait until the lock is released. The next thing that happens is interesting:

```c
while(queue->head == NULL) { // block if buffer is empty
  pthread_cond_wait(&queue->wakeup, &queue->mutex);
}
```

While the head of our queue is `NULL` it indicates that there is nothing in the queue. When this occurs we tell this code to go to sleep by calling `pthread_cond_wait` this will release the lock and wait until someone triggers the condition variable, in this case named `queue->wakeup`.

Remember when we pushed data to the queue we triggered `pthread_cond_signal`? That code sends a signal to tell anyone that is listening that they can wake up and start processing again. You can either wake up one listener or ALL listeners (via broadcast), in this case we're only waking up one at a time, since we've only enqueued one element into the queue.

What this does is it allows a thread that is trying to pop something off of the queue to go to sleep and not burn CPU time trying to pop things from an empty queue. Once we add something on to the queue, we signal to any sleeping threads that 1 element is in the queue and it can start processing.

One thing to note is that we are using a `while` and not an `if` clause when checking for an empty queue`. We do this on the off chance that between the time the signal was triggered and the code runs, the queue is empty again.

Let's say there was something in the queue, or our code was woken up via a `push`. The next thing we do is grab our `head` instance and pull our data pointer off of it:

```c
struct tiny_linked_list_t* current_head = queue->head;
void *data = current_head->data;
```

We're creating a variable called `current_head` that is a pointer to the linked list element currently at `head`. From there we pull out the pointer to whatever we pushed onto the queue in a variable named `data`.

When we push things on the queue, we add them to the end (or tail). When we pop them, they come off the top (or head). We need to check to see if we have a 1 element queue:

```c
queue->head == queue->tail
```

If that's the case then we set `head` and `tail` both to `NULL`, since after we pop 1 element off of a 1 element queue there will be nothing left.

If there is more than one element then we have to move the `head` pointer:

```c
queue->head = queue->head->next;
```

We are setting the current `head` pointer to the next element in the linked list. This means that the second element now becomes the first.

Finally, since we allocated a list element in the `push` via a `malloc` we have to deallocate it with a call to `free`:

```c
free(current_head);
```

We're only freeing our list element, not the data pointer on the list, which we will return. Last thing is to unlock the mutex so that other threads can push or pop. Note that we do not signal to our condition variable here because popping an element off of the queue does not indicate a change in state that is actionable by a reader or a writer (push or pop call).

Lastly we return the pointer to the thing we put in the queue:

```c
return data;
```

We're done! Told you that wasn't bad. What you're left with is a simple interface, the ability to create a queue, push, and pop. I wrote some examples of usage at https://github.com/schneems/tiny_queue. You can view the code

- [hello.c](https://github.com/schneems/tiny_queue/blob/master/hello.c) push strings on to a queue and pop them off
- [hello_struct.c](https://github.com/schneems/tiny_queue/blob/master/hello_struct.c) push arbitrary structs on to a queue and pop them off
- [hello_threads.c](https://github.com/schneems/tiny_queue/blob/master/hello_threads.c) push numbers on to a queue and have different threads perform work on the numbers.


## Ruby Queue Implementation

Ruby is written in C, and one goal of learning C for me is to possibly contribute to Ruby. I thought it would be interesting to compare my implementation of a Queue to how Ruby does these three operations.

First off I was surprised to find that as recently as Ruby 2.0, the Queue was written in Ruby (instead of C). Click on the [Queue docs for Ruby 2.0](http://ruby-doc.org/stdlib-2.0.0/libdoc/thread/rdoc/Queue.html) then "toggle source".

In [2.4.1](https://ruby-doc.org/core-2.4.1/Queue.html) it is written in C and points to [thread_sync.c](https://github.com/ruby/ruby/blob/b5b1a2131ec5cbde6adaf0d37953ff05c393218b/thread_sync.c). I'm actually going to look at the most recent implementation on `trunk` (Ruby uses `trunk` instead of `master` branch). Here's a [link to the code i'll be reviewing](https://github.com/ruby/ruby/blob/bacadbe9bfae2a9183934c08baaaefdec6d8dafe/thread_sync.c#L1074-L1105)

The C code looks a bit different than mine because the interface is intended to be consumed by Ruby and not another C code. a `VALUE` for example is not a C type but one that Ruby can understand.

Here is the code to push an element on to the queue:

```c
static VALUE
rb_szqueue_push(int argc, VALUE *argv, VALUE self)
{
    struct rb_szqueue *sq = szqueue_ptr(self);
    int should_block = szqueue_push_should_block(argc, argv);

    while (queue_length(self, &sq->q) >= sq->max) {
  if (!should_block) {
      rb_raise(rb_eThreadError, "queue full");
  }
  else if (queue_closed_p(self)) {
      goto closed;
  }
  else {
      struct queue_waiter qw;

      qw.w.th = GET_THREAD();
      qw.as.sq = sq;
      list_add_tail(&sq->pushq, &qw.w.node);
      sq->num_waiting_push++;

      rb_ensure(queue_sleep, Qfalse, szqueue_sleep_done, (VALUE)&qw);
  }
    }

    if (queue_closed_p(self)) {
      closed:
  raise_closed_queue_error(self);
    }

    return queue_do_push(self, &sq->q, argv[0]);
}
```

The pointer to the queue is not being passed in, instead it is being determined from `self` which is the execution context (since Ruby is object oriented):

```c
struct rb_szqueue *sq = szqueue_ptr(self);
```

You can see that their queue is bounded:

```c
while (queue_length(self, &sq->q) >= sq->max) {
```

There is a max value and while you're trying to push a value to the queue in a blocking fashion then an exception will be raised if you're past that limit.

Otherwise if you're pushing via non-block then it looks like the element will be added to the end of a waiting queue? I'm not totally sure what's going on here:


```c
struct queue_waiter qw;

qw.w.th = GET_THREAD();
qw.as.sq = sq;
list_add_tail(&sq->pushq, &qw.w.node);
sq->num_waiting_push++;

rb_ensure(queue_sleep, Qfalse, szqueue_sleep_done, (VALUE)&qw);
```

Then at the very end, there is a call to `queue_do_push`. If you look at that method:

```c
static VALUE
queue_do_push(VALUE self, struct rb_queue *q, VALUE obj)
{
    if (queue_closed_p(self)) {
  raise_closed_queue_error(self);
    }
    rb_ary_push(check_array(self, q->que), obj);
    wakeup_one(&q->waitq);
    return self;
}
```

This looks a lot like our code for push. They check to see if the queue is "closed", a behavior that's not implemented in my queue.

If it's not they add the element on to the end of an array. Functions inside of the Ruby source code are prefixed with `rb_` if they're exposed. So this function call `rb_ary_push` is the same as when you call `[].push("foo")` in your Ruby code.

Notice in this code they don't have to mess around with pointers and heads and tails, that's because they already have a list structure (implemented as an Array) that they can use.

Once the element is added to the array's tail then a condition variable signal is sent to wake up any blocked threads

```c
wakeup_one(&q->waitq);
```

One thing you might notice is that there's no mutexes in this code. There's no locking or unlocking. That is because instead of having a lock in each method, there is a global lock on the entire Ruby interpreter. This is called a GIL or a GVL and Python has a similar concept. This lock prevents two threads from running __Ruby__ code at the same time. This means that only one thread could be operating on the Array at a time.

A GIL will not totally protect you from threadsafety issues, as there are a number of operations that are not atomic, for instance `@foo ||= 2` or `@num += 1` can fail because they are expanded by the interpreter. Also Ruby does allow thread switching (and yes, it uses native threads) when IO is performed such as a disk read or a network call (such as a database query). So threading is still important.

I'm guessing that Ruby's C calls are atomic so by putting all that code within `queue_do_push` means that all those operations happen in one atomic chunk: check for closed, add element, signal to blocked threads.

This is one of the benefits of having a GIL, from an implementer's perspective it makes coding extremely easy because you don't have to worry about wrapping everything in a call to lock and unlock.


This is interesting to me because at my second RubyConf in Denver, I remember someone asking Matz if we could ever get rid of the GIL. His response was one of shock and horror. I think he basically said "no". After digging in I can understand a bit more now that it's not just some flag that needs to be unset, but rather the entire codebase would need to be re-written to be threadsafe, which would be an extremely hard effort for any organization.


This makes effort's like Koichi's work on "guilds" or another concurrency model even more interesting. Essentially the idea is that instead of getting rid of the GIL, we can have multiple GILs without having to spawn multiple processes. Each "guild" would essentially behave like a cross between a process and a thread. I've always thought of them as a process with a resource sharing model.


## Wrapup

If you've made it this far, congrats. This was some pretty dense stuff. I do have one tip which I want to leave readers if you're working with queues. This is a common "trick" that is not very intuitive if you've never worked with threads. The idea is that if you need to tell your workers when to shut down, but you also need to wake them up since they're blocked at the `pop` call. You can do this with a "poision" object. In Ruby it looks like this:

```ruby
require 'thread'

GLOBAL_QUEUE = Queue.new
POISON       = Object.new

threads = 10.times.map do
  Thread.new do
    loop do
      work = GLOBAL_QUEUE.pop
      break if work == POISON
      puts "Working on #{work}"
    end
  end
end

20.times do |i|
  GLOBAL_QUEUE.push(i)
end

10.times do
  GLOBAL_QUEUE.push(POISON)
end

threads.map {|t| t.join }
```

Here we create a unique object and assign it to a constant of `POISON` then when we pop an element from the queue we check to see if we have that special object and exit. If you know how many threads you have looping infinitely then you enqueue that same number of poison objects to stop all of them. Since the poison goes in the end of the queue, you can be sure that the queue is drained before the workers will shut down.

I also recommend [Working with Ruby Threads](https://pragprog.com/book/jsthreads/working-with-ruby-threads) if you're new to concepts like threads, queues, and mutexes.

I'm having a blast writing C code. While it does take me 20 hours to do something that would take 20 minutes in Ruby, it's a huge accomplishment when I get something to work. It's also neat not having the crutch of a huge standard library with pre-made data structures for me. The real pay-off though is that the more I learn about C, the less foreign and unapproachable the source code behind Ruby becomes. I'm not saying that everyone should learn C, but if you're looking for a challenge in a language that's extremely fast and used all over the world, it's not a bad language to be familiar with.

