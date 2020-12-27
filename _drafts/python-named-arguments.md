---
layout: post
title: Why You Should Typically Use Named Arguments in Python
categories: [Blog]
tags: [python]
---

When invoking functions in Python, you can usually pass your arguments either by **position** or **name**. There are advantages (and disadvantages) to each approach.

This blog post will discuss why you would want to choose **named arguments** *in most situations* over positional arguments. Conversely, there are a [handful of benefits for positional-only arguments (PEP 570)](https://www.python.org/dev/peps/pep-0570/#benefits-of-positional-only-parameters). I urge you to read the PEP to understand when positional arguments are preferred, but in most cases I think there are more benefits to using named arguments.

## Arguments

To ensure we are all the same page, let's say you have a function:

```python
def my_function(a, b):
    pass
```

To call this function with **positional arguments** you would do:

```python
my_function(1, 2)
```

Positionally, `a` would be set to `1` and `b` would be `2`.

To call this function with **named arguments**, you could do:

```python
my_function(a=1, b=2)
```

Or:

```python
my_function(b=2, a=1)
```

The second example highlights that order (position) doesn't matter when using named args.

Now let's see why named arguments are (usually) a better idea.

## Self-documenting code

Code that documents itself (without additional documents or comments) is a very powerful thing. When you're reading code, it should be obvious what it is doing. Named arguments help with that.

Take this function invocation that uses positional arguments:

```python
send_packet(buf, 30, intvl)
```

To understand what we're doing, you'd have to look at the function definition or some documentation (maybe a comment before the invocation?).

But with named arguments:

```python
send_packet(
    data=buf,
    timeout=30,
    interval=intvl
)
```

We don't have to look any further to have a pretty good idea of what we're trying to accomplish with this line of code.

## Future-proof your code

Say you have this function from above:

```python
def my_function(a, b):
    pass
```

If you call this function `my_function(1, 2)` with positional arguments, then `a` is `1` and `b` is `2`.

But what happens if the function changes:

```python
def my_function(a, c=3, b=5):
    pass
```

Now with the existing invocation `my_function(1, 2)`, `a` is still `1` but it's now `c` that is set to `2`. This is unlikely the desired transition from signature to invocation.

The function signature has changed, but if the function invocation doesn't know about that it could introduce undesired behavior.

If we had been calling this function with named parameters, then the signature change doesn't affect the args passed in.

```python
my_function(a=1, b=2)
```

Now our original code is resilient to the change, as `a` is still `1`, `b` is still `2`, and `c` defaults to `3`.

## Easier with kwargs

When working with arguments within a function, it's easier to reference the argument with the `kwargs` dictionary than it is with the positional args' tuple.

```python
def my_function(*args, **kwargs):
    pass

my_function(1, 2, b=3, c=4)
```

With this invocation, `args` is a tuple that is set to `(1, 2)` so you can reference the positional arguments.

`kwargs` is a dict with the value `{'b': 3, 'c': 4}` for named argument referencing.

If you needed to access the arguments in this manner, it is much easier (and less error-prone) to use `kwargs['b']` than to lookup positional args with `args(1)`. This includes both factors of self-documenting code and future-proofing yourself.

## You can force named arguments, but...

Python gives you the ability to allow *only* named arguments:

```python
def my_function(*, a, b):
    pass
```

If you were to attempt to invoke with position arguments:

```python
my_function(1, 2)
```

You would get errors:

```
Traceback (most recent call last):
  File "app.py", line 4, in <module>
    my_function(1, 2)
TypeError: my_function() takes 0 positional arguments but 2 were given
```

This is not my preference, I personally don't like the function definition with that notation. And sometimes when debugging in `pdb` it is easier and quicker to just ad-hoc call a function with positional arguments instead of having to use named args in that instance.

## Summary

There are no doubt going to be times and applications that you can and should use positional arguments (see the PEP above). But I think in most cases outside of that, it is better to use named arguments. Even if it is a few extra keystrokes, it will be a good investment in the future of the code.
