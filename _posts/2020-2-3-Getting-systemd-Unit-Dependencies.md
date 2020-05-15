---
layout: post
title: Getting systemd unit dependencies
categories: [Blog]
tags: [linux, systemd]
---

One of the difficult things of any init system is understanding how everything is all connected... what runs and when. One of the great things about systemd is that it makes it a fairly straightforward task to discover the dependency relationships for systemd units.

The main subcommand that will be used with `systemctl` for this is `list-dependencies`. During those times of wondering why this unit was started (or not started), this command will give you some clarity. Let's see an example.

Here are two systemd units of type service for a small demo.

### hello1.service

```
[Unit]
Description=Test hello service 1

[Service]
ExecStart=/usr/bin/echo hello from 1

[Install]
WantedBy=multi-user.target
```

### hello2.service

```
[Unit]
Description=Test hello service 2
Requires=hello1.service

[Service]
ExecStart=/usr/bin/echo hello from 2

[Install]
WantedBy=multi-user.target
```

The directive that indicates the relationship between these two units is `Requires` in `hello2.service`. This marks `hello1.service` as its dependency. This is a common pattern that you will see if you start digging through the units on your systemd machine. Another thing to note here is that in the `[Install]` section that we have a `WantedBy` directive with `multi-user.target`. This is another indicator of a dependency relationship, this time we are saying that both of these services are wanted by `multi-user.target`.

What does it look like to list out the dependencies?

```
$ systemctl list-dependencies hello2.service
hello2.service
● ├─hello1.service
● ├─system.slice
● └─sysinit.target
●   ├─apparmor.service
●   ├─dev-hugepages.mount
●   ├─dev-mqueue.mount
●   ├─keyboard-setup.service
... output omitted for brevity ...
```

Notice above that `hello1.service` is listed as a depedency of `hello2.service`. This is expected because of the `Requires` directive. Another common requirement is to go the other way: Find out which units have a particular unit as a dependency. We can get this information by adding the `--reverse` switch.

```
$ systemctl list-dependencies --reverse hello1.service
hello1.service
● ├─hello2.service
● └─multi-user.target
●   └─graphical.target
```

In this case we listed all of the units that have `hello1.service` as a dependency. This tells us what we already knew above, that `hello2.service` has it as a dependency.

Getting comfortable with quick and dynamic discovery of how systemd units work together is a key skill in developing and troubleshooting units.

Enjoy!
