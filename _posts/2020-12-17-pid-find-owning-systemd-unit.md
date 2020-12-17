---
layout: post
title: Find the systemd Unit that Owns a Process
categories: [Blog]
tags: [linux,systemd]
---

Recently I had to do a little troubleshooting and I was able to pinpoint a particular process ID from `ps` that I was interested in. In particular, **I wanted to know which systemd unit was responsible for this particular process**.

It turns out that `systemctl` can give you this information! Here's an excerpt from `man systemctl`:

> status [PATTERN...|PID...]]
>
> Show terse runtime status information about one or more units, followed by most recent log data from the journal. If no units are specified, show system status. If combined
> with --all, also show the status of all units (subject to limitations specified with -t). **If a PID is passed, show information about the unit the process belongs to.**

*Note: Relevant section in bold.*

With the common `systemctl status` command, we can find which systemd unit a particular process ID belongs to.

Let's see a quick example with the `sshd` process. We can use `ps` to find the pid (or `pidof` as well) and then run `systemctl status <pid>`:

![systemctl status output](../images/systemctl-status.png)

Super easy and straightforward. Running `systemctl status` on the process ID tells us exactly what systemd unit owns this process!
