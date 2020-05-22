---
layout: post
title: Searching Through All systemd Unit Files for a String
categories: [Blog]
tags: [linux, systemd]
---

I was recently working on an issue where I had a systemd service that I didn’t want to run anymore (but I didn’t want to remove the service itself, and I also didn’t want to mask it). The obvious attempt was to disable it, to remove any symlinks that would tie this unit to another unit. But I noticed that on reboot this service was still started! And I needed to find out what was starting the service.

I realized that there was a good chance this was because of a dependency directive (After, Requires, etc.) in another unit that was causing this service to start. With this in mind, I knew I would want to grep through all of the units. My first attempt was to run `systemctl cat *`. Unfortunately I ran into an error early on in this attempt: “No files found for <unit_name>”. [I'm trying to find out if this is normal behavior, or not](https://github.com/systemd/systemd/issues/14082) but in this case `systemctl cat` was not going to be my solution.

I came up with a one-liner alternative. Although quite a bit more verbose than a single `systemctl cat`, it proved to be more effective:

```bash
$ systemctl list-units --all --no-legend | 
    awk '{print $1}' | 
    xargs -n1 -i sh -c 'systemctl cat "{}" 2> /dev/null | grep cloud-init | xargs -n1 -iJJ echo !!!{}!!! JJ'
```

In my case, I was looking for the string "cloud-init" (that was the unit name that I was searching for) in other units.

I had to add a `... | grep -v '!!!cloud'` hide any of the corresponding cloud-init services to reduce the noise in the output. Here is what I found:

![systemd search output for units](/images/systemd-unit-search.png)

And there it is! I can see that the `mnt.mount` unit has a `Requires=cloud-init.service` dependency directive. This is the offending unit that was causing my unit to run (when I didn't want it to).

Piping together a few commands, and nested xargs (yikes!), we are able to grep through all units on the system quickly. If you ever have the requirement to search through all unit files on a machine, then hopefully this post will be useful!
