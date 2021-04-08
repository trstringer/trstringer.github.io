---
layout: post
title: systemd Inhibitor Locks Deep Dive
categories: [Blog]
tags: [linux,systemd,golang]
---

systemd inhibitor locks are a really great way to have some control over the system state changes (shutdown, reboot, idle, suspend, etc.). The common use case for this is if you need to ensure that some pre-shutdown/suspend handling takes place before the state change.

Another component that is a large part of this topic is the systemd D-Bus. This is the mechanism that allows for communication between different processes. In our case of inhibitor locks, we are going to be talking to [`systemd-logind`](https://www.freedesktop.org/software/systemd/man/systemd-logind.service.html) through D-Bus. There are parts of this implementation where we will make D-Bus method calls to `systemd-logind`, and another component where we will be listening on the system bus for a signal.

The rest of this blog post goes through the detail of the workflow (creating an inhibitor lock as well as listening for the signal). Like most things, it is best explained with an example. The implementation I created is in Go in the section below: [Inhibitor lock in Go](#inhibitor-lock-in-go). If you don't necessarily care about the code and are just interested in the technical details, you can ignore that section.

## Creating an inhibitor lock

The inhibitor lock is created by making a method call on logind's Manager interface: `org.freedesktop.login1.Manager.Inhibit`. This takes four parameters:

- **What** - this is the event (e.g. "shutdown")
- **Who** - a short description of the process taking the lock
- **Why** - a short sentence describing why the process needs the lock
- **Mode** - either "delay" or "block"

Most of the above parameters are self-explanatory, but the mode is an interesting one. If **block** is specified, it will block the state change indefinitely. Because of this, it should be used with great caution and care. The more common mode is **delay**. This will temporarily pause the state change until either the inhibitor lock file descriptor (more information on that below) is closed *or* the `InhibitDelayMaxSec` elapses. This configuration option is defined in logind config and defaults to **5 seconds**. 

If the inhibitor lock is successfully taken, logind will provide a file descriptor back to the caller. This is the way that your process can release the inhibitor lock, allowing the event to continue (e.g. shutdown). Because of this, it is typically necessary to store the file descriptor for future use.

You can list all locks that are currently taken with the `systemd-inhibit` utility:

```
$ systemd-inhibit --list
     Who: Inhibitor Test (UID 0/root, PID 5899/inhibit)
    What: shutdown
     Why: Testing systemd inhibitors from Go
    Mode: delay

     Who: Unattended Upgrades Shutdown (UID 0/root, PID 1126/unattended-upgr)
    What: shutdown
     Why: Stop ongoing upgrades or perform upgrades before shutdown
    Mode: delay

2 inhibitors listed.
```

In my example, there are two locks currently. The first one is my custom process's lock (`inhibit`) and the second one is a separate lock from `unattended-upgr`. Judging by the `Why`, it allows some pre-shutdown handling for upgrades.

One really useful tool when working with D-Bus is being able to trace and monitor different messages on the bus. This post will frequently use `dbus-monitor` to watch for activity. For instance, when my process makes the call to `Inhibit`, I can see this on the system bus (`sudo dbus-monitor --system`):

```
method call time=1617656172.801601 sender=:1.74 -> destination=org.freedesktop.login1 serial=2 path=/org/freedesktop/login1; interface=org.freedesktop.login1.Manager; member=Inhibit
   string "shutdown"
   string "Inhibitor Test"
   string "Testing systemd inhibitors from Go"
   string "delay"
```

You can see the interface is `org.freedesktop.login1.Manager` and the member is `Inhibit`. The first part of the message is that it is a `method call`. And then we can see that we get a `method return`:

```
method return time=1617656172.801667 sender=:1.5 -> destination=:1.74 serial=368 reply_serial=2
   file descriptor
         inode: 660
         type: fifo
```

As it was mentioned above, the return of `Inhibit` is a file descriptor, which we can see by monitoring the system bus. So at this point, our process has successfully retrieved the inhibitor lock. But that's not it!

## Watching for the event signal

The inhibitor lock is only half the story. It is what allows us to tell systemd to wait a little bit on an event (e.g. shutdown) so that we can do something. But now we need to *listen* for the event. This is done by calling `org.freedesktop.DBus.AddMatch`. The parameter is the match rule to watch for. When my process makes the `AddMatch` call, we can see from `dbus-monitor` what is happening:

```
$ sudo dbus-monitor --system "type='signal',interface='org.freedesktop.login1.Manager'"
...
method call time=1617656172.802230 sender=:1.74 -> destination=org.freedesktop.DBus serial=3 path=/org/freedesktop/DBus; interface=org.freedesktop.DBus; member=AddMatch
   string "type='signal',interface='org.freedesktop.login1.Manager',path='/org/freedesktop/login1',member='PrepareForShutdown'"
```

We can see that it is a `method call` on the interface `org.freedesktop.DBus` and the member/method is `AddMatch`. The second line is the parameter that is passed to `AddMatch`, which is the rule that we are looking to match on. The rule is of type `signal` and it is the **`PrepareForShutdown`** signal from `org.freedesktop.login1.Manager` (systemd-logind). Once this match is added, we know our process is now subscribed to any signals that match the rule.

Once we make a call to shutdown the machine (e.g. `sudo shutdown --reboot +1`), we can see this signal on the system bus:

```
signal time=1617656515.646325 sender=:1.5 -> destination=(null destination) serial=381 path=/org/freedesktop/login1; interface=org.freedesktop.login1.Manager; member=PrepareForShutdown
   boolean true
```

This trace message shows us that we get the `PrepareForShutdown` signal from the `org.freedesktop.login1.Manager` interface. `dbus-monitor` got this signal, but our custom process also got the signal as well and handled it accordingly. Here are the journal logs from the process:

```
systemd[1]: Started Inhibitor test.
inhibit[5899]: Starting dbus example
inhibit[5899]: Inhibitor file descriptor: 7
inhibit[5899]: Waiting for shutdown signal
inhibit[5899]: Signal: &{:1.5 /org/freedesktop/login1 org.freedesktop.login1.Manager.PrepareForShutdown [true] 5}
inhibit[5899]: Closing file descriptor
systemd[1]: Stopping Inhibitor test...
systemd[1]: Stopped Inhibitor test.
```

## Inhibitor lock in Go

We've talked about how inhibitor locks and AddMatch signal handlers work with D-Bus, so now I wanted to show an implementation in Go.

```golang
package main

import (
	"fmt"
	"os"
	"syscall"

	"github.com/godbus/dbus/v5"
)

func main() {
	fmt.Println("Starting dbus example")

	// Get a handle on the system bus. There are two types
	// of buses: system and session. The system bus is for
	// handling system-wide operations (like in this case,
	// shutdown). The session bus is a per-user bus.
	conn, err := dbus.SystemBus()
	if err != nil {
		fmt.Printf("error getting system bus: %v\n", err)
		os.Exit(1)
	}
	defer conn.Close()

	// Call the Inhibit method so that this process register
	// an inhibitor lock. This returns a file descriptor so
	// that after a shutdown signal this process can signal
	// back to systemd that it is complete by closing the
	// file descriptor.
	//
	// The parameters that are passed to Inhibit dictate the
	// state change. In this case, that is "shutdown". The
	// mode can either be "delay" or "block". Delay will halt
	// the state change for the InhibitDelayMaxSec setting,
	// which defaults to 5 seconds. Block will indefinitely
	// block the operation and should be used with caution.
	var fd int
	err = conn.Object(
		"org.freedesktop.login1",
		dbus.ObjectPath("/org/freedesktop/login1"),
	).Call(
		"org.freedesktop.login1.Manager.Inhibit", // Method
		0,                                        // Flags
		"shutdown",                               // What
		"Inhibitor Test",                         // Who
		"Testing systemd inhibitors from Go",     // Why
		"delay",                                  // Mode
	).Store(&fd)
	if err != nil {
		fmt.Printf("error storing file descriptor: %v\n", err)
		os.Exit(1)
	}
	fmt.Printf("Inhibitor file descriptor: %d\n", fd)

	// Call AddMatch so that this process will be notified for
	// the PrepareForShutdown signal. This will allow us to do
	// custom logic when the machine is getting ready to shutdown.
	err = conn.AddMatchSignal(
		dbus.WithMatchInterface("org.freedesktop.login1.Manager"),
		dbus.WithMatchObjectPath("/org/freedesktop/login1"),
		dbus.WithMatchMember("PrepareForShutdown"),
	)
	if err != nil {
		fmt.Printf("error adding match signal: %v\n", err)
		os.Exit(1)
	}

	fmt.Println("Waiting for shutdown signal")

	// AddMatch is already called, but we need to setup a signal
	// handler, which is just a channel.
	shutdownSignal := make(chan *dbus.Signal, 1)
	conn.Signal(shutdownSignal)
	for signal := range shutdownSignal {
		fmt.Printf("Signal: %v\n", signal)

		// Once we have completed whatever pre-shutdown tasks
		// that need to be done, we should close the file
		// descriptor that was created when we called Inhibit.
		// This tells systemd (logind) that it can continue with
		// the shutdown.
		fmt.Println("Closing file descriptor")
		err = syscall.Close(fd)
		if err != nil {
			fmt.Printf("error closing file description: %v\n", err)
			os.Exit(1)
		}
	}

	fmt.Println("Completed")
}
```

And the systemd service unit:

```
[Unit]
Description=Inhibitor test

[Service]
ExecStart=/opt/inhibit
```

## Summary

systemd is full of really amazing features. Inhibitor locks are a great way that you can have some control over a major event (such as shutdown) to be able to handle tasks to prepare for that state change. Hopefully this blog post has showed how this works and how you can view and troubleshoot inhibitor locks and match signals!

## References

- [systemd Inhibitor Locks](https://www.freedesktop.org/wiki/Software/systemd/inhibit/)
- [systemd-logind D-Bus interface](https://www.freedesktop.org/software/systemd/man/org.freedesktop.login1.html)
- [systemd-inhibit](https://www.freedesktop.org/software/systemd/man/systemd-inhibit.html)
- [D-Bus specification - Match Rules](https://dbus.freedesktop.org/doc/dbus-specification.html#message-bus-routing-match-rules)
- [dbus-monitor](https://dbus.freedesktop.org/doc/dbus-monitor.1.html)
- [Go dbus client](https://github.com/godbus/dbus)
