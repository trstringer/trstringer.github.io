---
layout: post
title: Errors and Error Wrapping in Go
categories: [Blog]
tags: [golang]
---

Errors are a core part of almost every programming language, and how we handle them is a critical part of software development. One of the things that I really enjoy about programming in Go is the implementation of errors and how they are treated: Effective without having unnecessary complexity. This blog post will dive into what errors are and how they can be wrapped (and unwrapped).

## What are errors?

Let's start from the beginning. It's common to see an `error` getting returned and handled from a function:

```go
func myFunction() error {
    // ...
}
```

But what exactly *is* an `error`? It is one of the simplest interfaces defined in Go ([source code reference](https://github.com/golang/go/blob/b357b05b70d2b8c4988ac2a27f2af176e7a09e1b/src/builtin/builtin.go#L270-L272)):

```go
type error interface {
	Error() string
}
```

It has a single function `Error` that takes no parameters and returns a string. That's it! That's all there is to implementing the `error` interface. We'll see later on how we can implement `error` to create our own custom error types.

## Creating errors

Most of the time you'll rely on creating errors through one of two ways:

```go
fmt.Errorf("error doing something")
```

Or:

```go
errors.New("error doing something")
```

The former is used when you want to use formatting with the typical fmt verbs. If you aren't wrapping an error (more on this below) then `fmt.Errorf` effectively makes a call to `errors.New` ([source code reference](https://github.com/golang/go/blob/b357b05b70d2b8c4988ac2a27f2af176e7a09e1b/src/fmt/errors.go#L17-L30)). So if you're not wrapping an error or using any additional formatting then it's a personal preference.

What do these non-wrapped errors look like? Breaking into the debugger we can analyze them:

```
(dlv) p err1
error(*errors.errorString) *{
        s: "error doing something",}
```

The concrete type is `*errors.errorString`. Let's take a look at this Go struct in the `errors` package ([source code reference](https://github.com/golang/go/blob/b357b05b70d2b8c4988ac2a27f2af176e7a09e1b/src/errors/errors.go#L63-L69)):

```go
type errorString struct {
	s string
}

func (e *errorString) Error() string {
	return e.s
}
```

`errorString` is a simple implementation having a single `string` field and because this implements the `error` interface it defines the `Error` function, which just returns the struct's string.

## Creating custom error types

What if we want to create custom errors with certain pieces of information? Now that we understand what an error actually is (by implementing the `error` interface) we can define our own:

```go
type myCustomError struct {
    errorMessage    string
    someRandomValue int
}

func (e *myCustomError) Error() string {
    return fmt.Sprintf("Message: %s - Random value: %d", e.errorMessage, e.someRandomValue)
}
```

And we can use them just like any other `error` in Go:

```go
func someFunction() error {
    return &myCustomError{
        errorMessage:    "hello world",
        someRandomValue: 13,
    }
}

func main() {
    err := someFunction()
    fmt.Printf("%v", err)
}
```

The output of running this code is expected:

```
Message: hello world - Random value: 13
```

## Error wrapping

In Go it is common to return errors and then keep bubbling that up until it is handled properly (exiting, logging, etc.). Consider this example:

```go
func doAnotherThing() error {
    return errors.New("error doing another thing")
}

func doSomething() error {
    err := doAnotherThing()
    return fmt.Errorf("error doing something: %v", err)
}

func main() {
    err := doSomething()
    fmt.Println(err)
}
```

`main` makes a call to `doSomething`, which calls `doAnotherThing` and takes its error.

*Note: It's common to have error handling with `if err != nil ...` but I wanted to keep this example as small as possible.*

Typically you want to preserve the context of your inner errors (in this case "error doing another thing") so you might try to do a superficial wrap with `fmt.Errorf` and the `%v` verb. In fact, the output seems reasonable:

```
error doing something: error doing another thing
```

But outside of wrapping the error messages, we've lost the inner errors themselves effectively. If we were to analyze `err` in `main`, we'd see this:

```
(dlv) p err
error(*errors.errorString) *{
        s: "error doing something: error doing another thing",}
```

Most of the time that is typically fine. A superficially wrapper error is ok for logging and troubleshooting. But what happens if you need to programmatically test for a particular error or treat an error as a custom one? With the above approach, that is extremely complicated and error-prone.

The solution to that challenge is by wrapping your errors. To wrap your errors you would use `fmt.Errorf` with the `%w` verb. Let's modify the single line of code in the above example:

```go
return fmt.Errorf("error doing something: %w", err)
```

Now let's inspect the returned error in main:


```
(dlv) p err
error(*fmt.wrapError) *{
        msg: "error doing something: error doing another thing",
        err: error(*errors.errorString) *{
                s: "error doing another thing",},}
```

We're no longer getting the type `*errors.errorString`. Now we have the type `*fmt.wrapError`. Let's take a look at how Go defines `wrapError` ([source code reference](https://github.com/golang/go/blob/b357b05b70d2b8c4988ac2a27f2af176e7a09e1b/src/fmt/errors.go#L32-L43)):

```go
type wrapError struct {
	msg string
	err error
}

func (e *wrapError) Error() string {
	return e.msg
}

func (e *wrapError) Unwrap() error {
	return e.err
}
```

This adds a couple of new things:

1. `err` field with the type `error` (this will be the inner/wrapped error)
1. `Unwrap` method that gives us access to the inner/wrapped error

This extra wiring gives us a lot of powerful capabilities when dealing with wrapped errors.

### Error equality

One of the scenarios that error wrapping unlocks is a really elegant way to test if an error *or any inner/wrapped errors* are a particular error. We can do that with the `errors.Is` function:

```go
var errAnotherThing = errors.New("error doing another thing")

func doAnotherThing() error {
    return errAnotherThing
}

func doSomething() error {
    err := doAnotherThing()
    return fmt.Errorf("error doing something: %w", err)
}

func main() {
    err := doSomething()

    if errors.Is(err, errAnotherThing) {
        fmt.Println("Found error!")
    }

    fmt.Println(err)
}
```

I changed the code of `doAnotherThing` to return a particular error (`errAnotherThing`). Even though this error gets wrapped in `doSomething`, we're still able to concisely test if the returned error is or wraps `errAnotherThing` with `errors.Is`.

`errors.Is` essentially just loops through the different layers of the error and unwraps, testing to see if it is equal to the target error ([source code reference](https://github.com/golang/go/blob/b357b05b70d2b8c4988ac2a27f2af176e7a09e1b/src/errors/wrap.go#L40-L60)).

### Specific error handling

Another scenario is if you have a particular type of error that you want to handle, even if it is wrapped. Using a variation of an earlier example:

```go
type myCustomError struct {
    errorMessage    string
    someRandomValue int
}

func (e *myCustomError) Error() string {
    return fmt.Sprintf("Message: %s - Random value: %d", e.errorMessage, e.someRandomValue)
}

func doAnotherThing() error {
    return &myCustomError{
        errorMessage:    "hello world",
        someRandomValue: 13,
    }
}

func doSomething() error {
    err := doAnotherThing()
    return fmt.Errorf("error doing something: %w", err)
}

func main() {
    err := doSomething()

    var customError *myCustomError
    if errors.As(err, &customError) {
        fmt.Printf("Custom error random value: %d\n", customError.someRandomValue)
    }

    fmt.Println(err)
}
```

This allows us to handle `err` in main if it (or any wrapped errors) have a concrete type of `*myCustomError`. The output of running this code:

```
Custom error random value: 13
error doing something: Message: hello world - Random value: 13
```

## Summary

Understanding how errors and error wrapping in Go can go a really long way in implementing them in the best possible way. Using them "the Go way" can lead to code that is easier to maintain and troubleshoot. Enjoy!
