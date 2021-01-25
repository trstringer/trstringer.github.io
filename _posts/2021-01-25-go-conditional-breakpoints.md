---
layout: post
title: Setting Conditional Breakpoints in Go
categories: [Blog]
tags: [golang]
---

Being able to debug your code is a necessary skill for any programmer. Setting conditional breakpoints allows you to efficiently and effectively inspect your code workflow. Take this simple (but contrived) code:

**app.go**

```golang
package main

import (
    "fmt"
    "math/rand"
)

func main() {
    for {
        first := rand.Intn(10)
        second := rand.Intn(10)
        result := first + second

        fmt.Printf("The result is %d\n", result)
    }
}
```

This code just adds a couple of numbers, but let's say there is a condition that you want to inspect, such as when `second` is set to `7`. You could just set a normal breakpoint on `app.go:12` and if the value of `second` is not set to `7` then you could just `continue` until you reach that condition. But that's really long and painful.

Let's see a couple of ways to do this more efficiently.

## The Delve way

There is a built-in capability to handle conditional breakpoints. You can see this through the Delve documentation:

```text
(dlv) help cond
Set breakpoint condition.

        condition <breakpoint name or id> <boolean expression>.

Specifies that the breakpoint or tracepoint should break only if the boolean expression is true.
```

So in our example above, if we wanted to break into the debugger when `second` is set to `7`, we could do the following in our debugging session:

```text
 $ dlv debug app.go
Type 'help' for list of commands.
(dlv) b app.go:12
Breakpoint 1 set at 0x4bb7c6 for main.main() ./app.go:12
(dlv) cond 1 second == 7
(dlv) c
> main.main() ./app.go:12 (hits goroutine(1):1 total:1) (PC: 0x4bb7c6)
     7:
     8: func main() {
     9:         for {
    10:                 first := rand.Intn(10)
    11:                 second := rand.Intn(10)
=>  12:                 result := first + second
    13:
    14:                 fmt.Printf("The result is %d\n", result)
    15:         }
    16: }
(dlv) p second
7
```

By setting the condition `cond 1 second == 7` we are instructing Delve to break on breakpoint 1 *only* if `second` is set to `7`.

We can also validate the condition by running `bp`:

```text
(dlv) bp
Breakpoint runtime-fatal-throw at 0x438e20 for runtime.fatalthrow() /usr/local/go/src/runtime/panic.go:1162 (0)
Breakpoint unrecovered-panic at 0x438ea0 for runtime.fatalpanic() /usr/local/go/src/runtime/panic.go:1189 (0)
        print runtime.curg._panic.arg
Breakpoint 1 at 0x4bb7c6 for main.main() ./app.go:12 (1)
        cond second == 7
```

You can change the condition for the breakpoint by running the `cond` statement against with a new boolean expression.

## The code way

The above shows the way you can do this with Delve, but your conditional breakpoint expression might be a little more complex. You can add a conditional check to your code and then set a nonconditional (unconditional?) breakpoint on that line of code. Let's see this addition to the above code:

**app.go**

```golang
package main

import (
    "fmt"
    "math/rand"
)

func main() {
    for {
        first := rand.Intn(10)
        second := rand.Intn(10)

        if first == 3 && second == 7 {
            fmt.Println("Set breakpoint here")
        }

        result := first + second

        fmt.Printf("The result is %d\n", result)
    }
}
```

Adding lines 13-15, this effectively acts as the code path for a conditional breakpoint. Now all I have to do is set the breakpoint on line 14:

```text
 $ dlv debug app.go
Type 'help' for list of commands.
(dlv) b app.go:14
Breakpoint 1 set at 0x4bbbd3 for main.main() ./app.go:14
(dlv) c
> main.main() ./app.go:14 (hits goroutine(1):1 total:1) (PC: 0x4bbbd3)
     9:         for {
    10:                 first := rand.Intn(10)
    11:                 second := rand.Intn(10)
    12:
    13:                 if first == 3 && second == 7 {
=>  14:                         fmt.Println("Set breakpoint here")
    15:                 }
    16:
    17:                 result := first + second
    18:
    19:                 fmt.Printf("The result is %d\n", result)
(dlv) p first
3
(dlv) p second
7
```

And there it is! When you hit your breakpoint it will be under the conditions of the code. The nice thing about this approach is that it persists between debugging sessions, so you don't have to deal with typing the same things over and over in the debugger to get this same conditional breakpoint.

## Summary

This blog post showed a couple of ways to work with conditional breakpoints in your Go code. This allows you to get to the execution conditions as quickly as possible to start debugging your code!
