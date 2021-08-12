---
layout: post
title: Handling Errors from Deferred Functions in Go
categories: [Blog]
tags: [golang]
---

Being able to defer functions is a powerful feature. But with the Go error handling pattern, it can be easy to ignore errors. Take this for example:

```go
package main

import "fmt"

func cleanup() error {
        fmt.Println("Running cleanup...")
        return fmt.Errorf("error on cleanup")
}

func getMessage() (string, error) {
        defer cleanup()

        return "hello world", nil
}

func main() {
        message, err := getMessage()
        if err != nil {
                fmt.Printf("Error getting message: %v\n", err)
        } else {
                fmt.Printf("Success. Message: '%s'\n", message)
        }
}
```

The output of this application is:

```
Running cleanup...
Success. Message: 'hello world'
```

We've completely silenced the error that is returned from `cleanup`. That's not good! But how do we handle an error from a deferred function?

We can use a **function closure** to allow us to handle the error message. Let's change our `getMessage` function:

```go
func getMessage() (msg string, err error) {
        defer func() {
                err = cleanup()
        }()

        return "hello world", err
}
```

We define and then invoke the anonymous function as the deferred function itself so that we can encapsulate the error handling of `cleanup`. Our deferred function references `err`, which is the variable defined in the function definition (the other modification for this solution). Now we have the desired output:

```
Running cleanup...
Error getting message: error on cleanup
```

The error that `cleanup` returns is properly passed to the caller.

This is great! But... there's a small logic bug hiding in this. Let's expand on this example a little bit. Let's change `cleanup` so that it no longer returns an error:

```go
func cleanup() error {
        fmt.Println("Running cleanup...")
        return nil
}
```

And let's add a new function that does return an error:

```go
func doAnotherThing() error {
        return fmt.Errorf("error from another thing")
}
```

And adding a call to `doAnotherThing` from `getMessage`:

```go
func getMessage() (msg string, err error) {
        defer func() {
                err = cleanup()
        }()

        err = doAnotherThing()

        return "hello world", err
}
```

So we get our error from `doAnotherThing` and then we return that error to the caller of `getMessage`, right? Let's see:

```
Running cleanup...
Success. Message: 'hello world'
```

We expected the error handling in `main`, but we did not get an error back from `getMessage`. That's because our deferred function ran `cleanup` and overwrite the error that was returned from `doAnotherThing`. So we accidentally silenced that error in the normal flow of the function!

The fix is straightforward. In the deferred function, have a temporary error variable and test to see if `cleanup` returns an error. If yes, then set it. Otherwise do not alter the return error:

```go
func getMessage() (msg string, err error) {
        defer func() {
                if tempErr := cleanup(); tempErr != nil {
                        err = tempErr
                }
        }()

        err = doAnotherThing()

        return "hello world", err
}
```

Now we run this and get the expected error:

```
Running cleanup...
Error getting message: error from another thing
```

But we're not done yet! There's another consideration: If our deferred function (`cleanup` in this case) returns an error but other code in the function does too (`doAnotherThing` here), which error do we want to return? Well... it depends. I think there are a few right answers that the programmer will have to choose from:

1. Return the error from `doAnotherThing` and ignore the error from `cleanup`
1. Return the error from `cleanup` and ignore the error from `doAnotherThing`
1. Return all of the errors as `[]error`

The first option is usually the most natural. After all, it's commonly the main component of the function flow that you want to report the error for. The last option to deal with all of the errors is not typical error handling:

```go
func getMessage() (msg string, errs []error) {
        defer func() {
                if tempErr := cleanup(); tempErr != nil {
                        errs = append(errs, tempErr)
                }
        }()

        if tempErr := doAnotherThing(); tempErr != nil {
                errs = append(errs, tempErr)
                return "", errs
        }

        return "hello world", errs
}

func main() {
        message, errs := getMessage()
        if errs != nil {
                fmt.Printf("There are %d error(s)\n", len(errs))
                for _, err := range errs {
                        fmt.Printf("Error: %v\n", err)
                }
        } else {
                fmt.Printf("Success. Message: '%s'\n", message)
        }
}
```

But, these are the options! Different scenarios may require different choices for which errors you return.

Hopefully this blog post has showed how you can handle errors from deferred functions, but also make sure you don't accidentally cause a nasty bug by overwriting other errors!
