---
layout: post
title: Why I Prefer systemd Timers Over Cron
categories: [Blog]
tags: [linux, systemd]
---

systemd has become a mainstay for the Linux world, but one of the things that still seems to stick around is cron jobs. It's understandable, as cron is a tool that we have been using for a *long* time. Change is hard, but I think systemd Timers make the change well worth it. Here are a few reasons why...

## Dependency management

This is a common theme: Declarative vs imperative. Dependencies should be declarative, and should be kept separate from your imperative code. With systemd units (timer units being no different) these dependency directives are declared in unit files.

"But it takes so long to write unit files..."

I think writing unit files is one of those things that is way easier than you think. Want to have an equivalent of a cron job? A couple of small unit files...

### my_job.service

```
[Unit]
Description=Run my job

[Service]
ExecStart=/usr/local/my_job/my_job.sh
```

### my_job.timer

```
[Unit]
Description=My job timer

[Timer]
OnBootSec=0min
OnCalendar=*:*:0/30
Unit=my_job.service

[Install]
WantedBy=multi-user.target
```

Then run `systemctl enable my_job.timer` and done! The `my_job.service` unit describes *what* to do, and the `my_job.timer` unit describes *when* to do it.

## Calendar syntax

Crontab schedules are famous. Perhaps if you've been using cron for a long time you are quite familiar with them, but you can't disagree with the fact that they are very unapproachable, easy to forget, and definitely easy to make mistakes.

I think the systemd calendar events (timing) is much more intuitive (see `man systemd.time`). And what's even better, is there is a great native tool to actually check your timing...

```bash
$ systemd-analyze calendar *:*:0/30
  Original form: *:*:0/30
Normalized form: *-*-* *:*:00/30
    Next elapse: Thu 2020-04-23 10:04:00 EDT
       (in UTC): Thu 2020-04-23 14:04:00 UTC
       From now: 28s left
```

By passing your calendar event to `systemd-analyze calendar` you get a **very** helpful output; most notably the next time that the event will fire.

## Logging

On systemd distros we are already leveraging the systemd journal. Because our systemd timers are units themselves, their logging is natural and native for the systemd journal. What I mean by that is you can use the normal `journalctl` searching just like for any other unit's log messages. This beats the experience of grep'ing through syslog or having to make sense of `journalctl -u cron` output.

## Where processes *should* be managed

We are already using systemd to manage other processes that run on our Linux machines, why should we treat scheduled jobs any differently? By having a single management, logging, and maintenance interface (systemd), it greatly simplifies our lives.

So before you jump to cron the next time you need to schedule a task on a Linux machine, think twice about instead using a systemd timer.
