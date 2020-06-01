---
layout: post
title: Get the History of an Installed Package with DNF
categories: [Blog]
tags: [linux, fedora]
---

DNF ("DaNdiFied Yum") is the next version of Yum, the package manager for RPM-based Linux distributions (RHEL, CentOS, and Fedora). For those of us that are Fedora users, DNF is probably nothing new.

Like most package managers, there is a lot of functionality built into the tooling. DNF is no different. But one thing that I really like about Fedora, after having done my fair share of distro-hopping, is DNF. Especially if you are familiar with Yum, DNF has very little cognitive overhead.

Recently I found myself needing to troubleshoot where a package came from. It was not something I particularly remembered installing, and after an upgrade I wanted to get to the bottom of it.

## Where did this package come from?

The way to find out the history of a particular package is use DNF's history command to first list out all of the relevant history events by package name. In my case, I was curious how and when `dnfdragora` was installed on my machine.

```
# dnf history list <package_name>
```

Using dnfdragora as my package name, my output is the following list of DNF history events:

![DNF history](/images/dnf-history-1.png)

From that, I know that this package was installed with the package group kde-desktop, on August 20th. It was also upgraded on January 6th.

But let's find out some more information about that installation from August 20th:

```
# dnf history info <history_id>
```

On my machine, my history ID is going to be 78 if I want to get details about the installation:

![DNF history](/images/dnf-history-2.png)

The output of this is cut off for brevity, as there are a lot of packages that are installed with KDE (indicated by the kde-desktop package group). But if I grep this output for dnfdragora, I can verify what dnf history list told me already:

```
# dnf history info 78 | grep dnfdragora
```

![DNF history](/images/dnf-history-3.png)

## Summary

This was a quick one, but it is a common exercise for Linux users to be able to do fast discovery on how software got onto their machine. DNF makes this easy and approachable, and I hope this blog post has illustrated that!
