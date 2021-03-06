---
layout: post
title: DefaultDependencies Can Cause a Unit Ordering Cycle
categories: [Blog]
tags: [linux,systemd]
---

Recently I ran into an issue that had me a little confused and troubleshooting for awhile, so I wanted to document it here. If you create a systemd unit that should be run before another unit, you could be surprised to find that in a certain circumstance you could have an ordering cycle:

> Mar 06 15:51:01 myhostname systemd[1]: cloud-init.service: Found ordering cycle on cloud-init-local.service/start

To cause this issue I created a systemd service unit that I wanted to run before another unit, `cloud-init-local.service`. Here was my new unit:

**svc1.service**

```
[Unit]
Description=Service 1
Before=cloud-init-local.service

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "echo begin && sleep 10 && echo end"

[Install]
RequiredBy=cloud-init-local.service
```

This is a very simplified version, but it illustrates the issue quite well. I created this unit to be `RequiredBy` the `cloud-init-local.service` unit, and also to have it start `Before` that unit as well. At first glance, this seems like a very single direction relationship. So you can imagine my surprise when I saw that the latter unit failed to start with the error message **Found ordering cycle**.

How could there be an ordering cycle in this case? The answer is in `DefaultDependencies` (`man systemd.service`). By leaving this option out of the definition of `svc1.service`, that defaults to `DefaultDependencies=yes`. But the service that we have the `RequiredBy` directive on does not have `DefaultDependencies` set:

```
$ systemctl show -p DefaultDependencies cloud-init-local.service
DefaultDependencies=no
```

So the ordering cycle is this: *svc1* -> *default dependencies* -> *cloud-init-local* -> *svc1* -> *...and so on*.

The fix is to add `DefaultDependencies=no` to the definition of `svc1.service`, which should resolve the ordering cycle.

Hopefully this blog post has provided a quick summary on how a seemingly single direction dependency can actually be an ordering cycle due to `DefaultDependencies`!
