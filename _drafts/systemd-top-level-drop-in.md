---
layout: post
title: Top-Level Drop-In to Apply Settings to All Units of a Certain Type
categories: [Blog]
tags: [linux,systemd]
---

One of the great ways that systemd allows you to modify a unit definition, without necessarily having to change the original unit file definition, is with drop-ins. Drop-ins are super powerful, and it is typical to create them for an individual unit. Let's take this service unit for example:

**svc1.service**

```
[Unit]
Description=Service 1

[Service]
ExecStart=/bin/echo hello world
```

The easiest way to create a drop-in for `svc1.service` is by running `systemctl edit svc1.service`. In my example, I add this as a drop-in when prompted by the editor (*Note: specify the `EDITOR` variable to change the default editor. For instance, I like to edit text with Vim so I have to do `sudo EDITOR=vim systemctl edit svc1.service`*):

```
[Service]
ExecStartPre=/bin/echo running this first
```

But, once you exit the editor how can you validate that you actually created a drop-in? Run `systemctl cat` on the unit:

```
$ systemctl cat svc1.service
# /etc/systemd/system/svc1.service
[Unit]
Description=Service 1

[Service]
ExecStart=/bin/echo hello world

# /etc/systemd/system/svc1.service.d/override.conf
[Service]
ExecStartPre=/bin/echo running this first
```

This is a *really* helpful command. Each of the commented lines (starting with `#`) show the path of the part of unit that is applied. You can see that our drop-in is below the original unit file with the `ExecStartPre` directive.

This is great if you just want to add a drop-in for a single unit. But what if you want to add a drop-in for all service units?

This can be accomplished with a top-level drop-in, which is created in a unit dir with the name of `<service_type>.d`. So if I wanted to create a top-level drop-in for all service units, I would create a dir `/etc/systemd/system/service.d` and then create my drop-in file there:

**10-execstartpre.conf**

```
[Service]
ExecStartPre=/bin/echo top-level exec start pre
```

Let's see what `svc1.service` looks like now:

```
$ systemctl cat svc1.service
# /etc/systemd/system/svc1.service
[Unit]
Description=Service 1

[Service]
ExecStart=/bin/echo hello world

# /etc/systemd/system/service.d/10-execstartpre.conf
[Service]
ExecStartPre=/bin/echo top-level exec start pre

# /etc/systemd/system/svc1.service.d/override.conf
[Service]
ExecStartPre=/bin/echo running this first
```

You can see now that the top-level drop-in is included in the effective unit definition. Now let's create a new service:

**svc2.service**

```
[Unit]
Description=Service 2

[Service]
ExecStart=/bin/echo hello world
```

And without doing anything more for this new service unit, we can see that our top-level drop-in applies:

```
$ systemctl cat svc2.service
# /etc/systemd/system/svc2.service
[Unit]
Description=Service 2

[Service]
ExecStart=/bin/echo hello world

# /etc/systemd/system/service.d/10-execstartpre.conf
[Service]
ExecStartPre=/bin/echo top-level exec start pre
```

Another thing to note, though, is that unit drop-ins *can* override each other if they have the same name. Let's create a drop-in for `svc2.service` that has the same name (`10-execstartpre.conf`) as the top-level drop-in:

**/etc/systemd/system/svc2.service.d/10-execstartpre.conf**

```
[Service]
ExecStartPre=/bin/echo svc2 exec start pre
```

Because the drop-in file has the same name, it will override previous drop-ins, including the top-level drop-in:

```
$ systemctl cat svc2.service
# /etc/systemd/system/svc2.service
[Unit]
Description=Service 2

[Service]
ExecStart=/bin/echo hello world

# /etc/systemd/system/svc2.service.d/10-execstartpre.conf
[Service]
ExecStartPre=/bin/echo svc2 exec start pre
```

Hopefully this blog post has showed how to define top-level drop-ins to add or modify configuration for all units of a particular type!
