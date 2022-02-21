---
layout: post
title: Analyze Current Goroutines in Go
categories: [Blog]
tags: [golang]
---

Debugging is a very important skill for any programmer. One of the really great features of Go is its approach to concurrency. A major component of that implementation is through the use of goroutines. Like many other complex things there may be times when we need to understand what is happening during the runtime.

This blog post is going to show a couple of ways to get and analyze the current goroutines in your software.

*Note: What a goroutine is and how it works is out of the scope of this blog post. For more information please refer to [A Tour of Go](https://go.dev/tour/concurrency/1).*

## Debugger

One way to see what goroutines there are currently are through the debugger. Let's use this code for our example:

```go
package main

import (
        "fmt"
        "time"
)

func doSomething() <-chan struct{} {
        done := make(chan struct{})

        go func() {
                timer := time.Tick(1 * time.Second)

                i := 0
                for {
                        select {
                        case <-timer:
                                fmt.Println("tick!")
                                i++
                                if i >= 5 {
                                        done <- struct{}{}
                                }
                        }
                }
        }()

        return done
}

func main() {
        done := doSomething()
        <-done
}
```

This does nothing more creates a timer that ticks every second for 5 seconds then completes. Let's say we are debugging our application and want to see which goroutines are available. Let's start the debugger:

```
$ dlv debug .
```

Once in the debugger let's break on the second line in `main` that waits on receiving from the `done` channel:

```
(dlv) b main.go:32
Breakpoint 1 set at 0x4cacee for main.main() ./main.go:32
(dlv) c
> main.main() ./main.go:32 (hits goroutine(1):1 total:1) (PC: 0x4cacee)
    27:         return done
    28: }
    29:
    30: func main() {
    31:         done := doSomething()
=>  32:         <-done
    33: }
```

This is great, the debugger stopped in our main goroutine but we know that there is another goroutine running with a timer. But how do we see that? You can use the Delve `goroutines` (or `grs` for short) command:

```
(dlv) grs
* Goroutine 1 - User: ./main.go:32 main.main (0x4cacee) (thread 19229)
  Goroutine 2 - User: /usr/local/go/src/runtime/proc.go:337 runtime.gopark (0x43c615) [force gc (idle)]
  Goroutine 3 - User: /usr/local/go/src/runtime/proc.go:337 runtime.gopark (0x43c615) [GC sweep wait]
  Goroutine 4 - User: /usr/local/go/src/runtime/proc.go:337 runtime.gopark (0x43c615) [GC scavenge wait]
  Goroutine 5 - User: /usr/local/go/src/runtime/proc.go:337 runtime.gopark (0x43c615) [finalizer wait]
  Goroutine 6 - User: ./main.go:11 main.doSomething.func1 (0x4cad20)
[6 goroutines]
```

Looking at this output we can see there are four runtime goroutines also listed here that we can ignore (primarily for garbage collection). But we can see that goroutine 1 is current, and the other user goroutine we started is goroutine 6.

Let's switch the debugger to our other goroutine:

```
(dlv) gr 6
Switched from 1 to 6 (thread 19229)
(dlv) l
> main.doSomething.func1() ./main.go:11 (PC: 0x4cad20)
     6: )
     7:
     8: func doSomething() <-chan struct{} {
     9:         done := make(chan struct{})
    10:
=>  11:         go func() {
    12:                 timer := time.Tick(1 * time.Second)
    13:
    14:                 i := 0
    15:                 for {
    16:                         select {
```

Now we are in the other goroutine and we can step through the code like any other debugging session.

## Programmatically

I'm typically not a fan of print debugging, but there are some valid cases where it can be really helpful. Let's say you're running your distributed application in a Kubernetes cluster and you want to see what current goroutines are (perhaps you're troubleshooting a goroutine leak). This is a quick way to get a dump of information without having to deal with remote debugging.

The way to accomplish this through your code is with `pprof`. Let's add that import and then inject this right before we wait on the `done` channel in `main`:

```go
func main() {
        done := doSomething()
        pprof.Lookup("goroutine").WriteTo(os.Stdout, 1)
        <-done
}
```

Now let's run the application and take a look at the output:

```
$ go run .
goroutine profile: total 2
1 @ 0x462d1d 0x4c0aee 0x4c08c5 0x4bd452 0x4cc357 0x4377d6 0x467861
#       0x462d1c        runtime/pprof.runtime_goroutineProfileWithLabels+0x5c   /usr/local/go/src/runtime/mprof.go:716
#       0x4c0aed        runtime/pprof.writeRuntimeProfile+0xcd                  /usr/local/go/src/runtime/pprof/pprof.go:724
#       0x4c08c4        runtime/pprof.writeGoroutine+0xa4                       /usr/local/go/src/runtime/pprof/pprof.go:684
#       0x4bd451        runtime/pprof.(*Profile).WriteTo+0x3f1                  /usr/local/go/src/runtime/pprof/pprof.go:331
#       0x4cc356        main.main+0x76                                          /home/trstringer/dev/go/test31/main.go:34
#       0x4377d5        runtime.main+0x255                                      /usr/local/go/src/runtime/proc.go:225

1 @ 0x4cc3a1 0x467861
#       0x4cc3a0        main.doSomething.func1+0x0      /home/trstringer/dev/go/test31/main.go:13

tick!
tick!
tick!
tick!
tick!
```

We can see that both goroutines print out with their stack. This is a super quick and easy way to get an idea of the current goroutines without having to break into a debugger.

## Summary

Hopefully this blog post has showed a couple of ways to see the current goroutines, both through the debugger and a data dump. Enjoy!
