---
layout: post
title: systemd Time Spans in Go
categories: [Blog]
tags: [golang, linux, systemd]
---

One of the consistent features of systemd is how it deals with time spans. A common usage of systemd time spans is when you're getting journal log events. It's typical to invoke something similar to:

```
# journalctl --since "-5m"
```

This would give you the journal entries in the past 5 minutes. Focusing on the `-5m` part of that command, this is a *very* useful way to specify relative time adjustments (or "time spans", as referenced in the systemd.time man pages).

If you are interested in learning more about systemd time, I highly recommend you read the man pages: `man 7 systemd.time`.

# Why I like systemd.time

The above time span could've also been written `-5 m`, `-5minute`, `-5 minutes`, `-5min` ... and a few other variations (but you get the idea). That's the point, and the first (and primary) reason that I like systemd time spans: They make sense *and* they account for the typical "guesses" (for some people, `minutes` is what makes sense. For other, `min` is their initial default).

You want the date/time from 4 days, 8 hours, and 39 minutes from now? Easy and intuitive: `4d 8h 39m` (or `4days 8hours 39minutes`, etc. Again, reference the man pages `man 7 systemd.time` for more specifics on how to use systemd time spans).

The second reason I embrace `systemd.time` is **consistency**. This is a great standard to follow. We're already using systemd utilities often, so we should extend this consistency to our non-systemd utilities.

# Utilities and CLIs written in Go

I love Go. One of my main uses of Go is creating command line utilities. Oftentimes there is a requirement to work with time adjustments. I wanted to use systemd time spans, and I didn't want to always have to invent the wheel every time I needed time adjustments in a Go application I was writing.

This was the main reason behind creating the [go-systemd-time package (GitHub)](https://github.com/trstringer/go-systemd-time).

## go-systemd-time usage

I tried to make the package interface small and obvious. Most likely you are interested in a single function:

```
package systemdtime // import "github.com/trstringer/go-systemd-time/pkg/systemdtime"

func AdjustTime(original time.Time, adjustment string) (time.Time, error)
    AdjustTime takes a systemd time adjustment string and uses it to modify a
    time.Time
```

That's the Go doc on `AdjustTime`, where you just pass the original `time.Time` and the systemd time span as a string and you get back the adjusted `time.Time`.

## Example

```go
package main

import (
	"fmt"
	"os"
	"time"

	"github.com/trstringer/go-systemd-time/pkg/systemdtime"
)

func main() {
	now := time.Now()
	timeFormat := "3:04 PM on January 2, 2006"

	fmt.Printf("Now is %s\n", now.Format(timeFormat))

	adjustedTime, err := systemdtime.AdjustTime(now, "2d")
	if err != nil {
		fmt.Printf("error adjusting time: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Adjusted is %s\n", adjustedTime.Format(timeFormat))
	/*
	   Now is 8:38 PM on September 30, 2020
	   Adjusted is 8:38 PM on October 2, 2020
	*/
}
```

# Summary

I really like the user experience of systemd time spans and as a programmer that uses Go, it is nice to be able to use this notation for a common requirement in command line utilities. Give it a try!
