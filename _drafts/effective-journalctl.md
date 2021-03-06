---
layout: post
title: Using journalctl Effectively
categories: [Blog]
tags: [linux,systemd]
---

If you have ever had the task of troubleshooting a modern Linux machine, you have undoubtedly used `journalctl` to display log messages. The journal is the logging mechanism for systemd machines, and `journalctl` is the tool that lets you read these messages.

If you run just `journalctl` (without parameters) from the terminal, you will no doubt have a display of useful (albeit verbose) information. What a lot of people don't know though is that `journalctl` is a very flexible tool, and being able to leverage this can give you more focused data in a shorter amount of time.

Over the years I've picked up a few tricks that I like to use with `journalctl` and I've compiled them here.

## Filter by units

Sometimes (rarely) you want to look through *all* of the journal entries, but usually you are focusing on a subset of systemd units. Thankfully you don't have to page through all of the entries to get to what you really care about. You can specify `-u` to filter by a systemd unit. The nice thing about this is that it can be used multiple times. So you can have a nicely tailored display of messages:

```
$ journalctl -u svc1.service -u svc2.service
-- Logs begin at Sat 2021-03-06 21:41:06 UTC, end at Sat 2021-03-06 22:06:42 UTC. --
Mar 06 21:51:46 myhostname systemd[1]: Started Service 2.
Mar 06 21:51:46 myhostname bash[948]: number: -c: line 1: syntax error: unexpected end of file
Mar 06 21:51:46 myhostname systemd[1]: Started Service 1.
Mar 06 21:51:46 myhostname bash[959]: number: -c: line 1: syntax error: unexpected end of file
Mar 06 21:51:46 myhostname systemd[1]: svc2.service: Main process exited, code=exited, status=1/FAILURE
Mar 06 21:51:46 myhostname systemd[1]: svc2.service: Failed with result 'exit-code'.
Mar 06 21:51:46 myhostname systemd[1]: svc1.service: Main process exited, code=exited, status=1/FAILURE
Mar 06 21:51:46 myhostname systemd[1]: svc1.service: Failed with result 'exit-code'.
-- Reboot --
Mar 06 21:55:01 myhostname systemd[1]: Started Service 1.
Mar 06 21:55:01 myhostname bash[985]: Random number from svc1 is 9372
Mar 06 21:55:02 myhostname systemd[1]: Started Service 2.
Mar 06 21:55:02 myhostname bash[1003]: Random number from svc2 is 6024
Mar 06 21:55:06 myhostname bash[985]: Random number from svc1 is 13347
Mar 06 21:55:07 myhostname bash[1003]: Random number from svc2 is 4633
Mar 06 21:55:11 myhostname bash[985]: Random number from svc1 is 4267
```

In this above example, if I'm troubleshooting just `svc1.service` and `svc2.service`, I can tailor my output to only include their messages which can greatly reduce the logging noise and let me focus on what really matters.

## Working with boots

As you can see in the above output, the journal is boot-aware. In certain cases, you might care about the different boots (usually that's just the current boot).

### List available boots

To list boots and their indexes (as well as their start and stop datetimes), you can run:

```
$ journalctl --list-boots
-3 ad80cea1580a4edbba655f840b3093a8 Sat 2021-03-06 21:41:06 UTC—Sat 2021-03-06 21:45:30 UTC
-2 512c07964c364feca8271d4faf8809b3 Sat 2021-03-06 21:45:43 UTC—Sat 2021-03-06 21:51:25 UTC
-1 f3cab66fcb8a4fa588e574b7ecce2724 Sat 2021-03-06 21:51:38 UTC—Sat 2021-03-06 21:54:41 UTC
 0 621f4c57ce0c41998fed45f491e6cb26 Sat 2021-03-06 21:54:53 UTC—Sat 2021-03-06 22:18:57 UTC
```

The other really valuable information that this tells you is how long the machine was up doing the different boot times!

### Filter by boot

In the above output of boot lists, the left-most number is the boot index that you might want to filter by. So, for instance, say I only wanted `svc1.service` output since the machine has rebooted, I can filter `-b` by `0`:

```
$ journalctl -u svc1.service -b 0
-- Logs begin at Sat 2021-03-06 21:41:06 UTC, end at Sat 2021-03-06 22:20:07 UTC. --
Mar 06 21:55:01 myhostname systemd[1]: Started Service 1.
Mar 06 21:55:01 myhostname bash[985]: Random number from svc1 is 9372
Mar 06 21:55:06 myhostname bash[985]: Random number from svc1 is 13347
Mar 06 21:55:11 myhostname bash[985]: Random number from svc1 is 4267
Mar 06 21:55:16 myhostname bash[985]: Random number from svc1 is 29344
Mar 06 21:55:21 myhostname bash[985]: Random number from svc1 is 30206
Mar 06 21:55:26 myhostname bash[985]: Random number from svc1 is 12201
```

## Search by time

A lot of times when troubleshooting something, you are only concerned about what has happened during a certain time range. `journalctl` allows you to filter by a particular time range (both absolute and relative). The format for the following parameters can be found in `man systemd.time`.

### Using since

Let's say you wanted to get the entries from the last 20 seconds:

```
$ journalctl -u svc1.service --since -20s
-- Logs begin at Sat 2021-03-06 21:41:06 UTC, end at Sat 2021-03-06 22:29:07 UTC. --
Mar 06 22:28:52 myhostname bash[985]: Random number from svc1 is 12249
Mar 06 22:28:57 myhostname bash[985]: Random number from svc1 is 5234
Mar 06 22:29:02 myhostname bash[985]: Random number from svc1 is 29407
Mar 06 22:29:07 myhostname bash[985]: Random number from svc1 is 26849
```

`--since` provides you a way of creating a start time (usually relative in this case) so that you don't have to page through entries that are too far in the past.

### Datetime ranges

Sometimes you are trying to focus on a certain datetime range though ("from then to then"). You can combine `--since`, which will be the start datetime, with `--until`, which will serve as the end time. Both of those are inclusive datetimes.

```
$ journalctl -u svc1.service --since "2021-03-06 22:20:00" --until "2021-03-06 22:21:00"
-- Logs begin at Sat 2021-03-06 21:41:06 UTC, end at Sat 2021-03-06 22:33:32 UTC. --
Mar 06 22:20:02 myhostname bash[985]: Random number from svc1 is 27922
Mar 06 22:20:07 myhostname bash[985]: Random number from svc1 is 25247
Mar 06 22:20:12 myhostname bash[985]: Random number from svc1 is 21920
Mar 06 22:20:17 myhostname bash[985]: Random number from svc1 is 22641
Mar 06 22:20:22 myhostname bash[985]: Random number from svc1 is 13974
Mar 06 22:20:27 myhostname bash[985]: Random number from svc1 is 1635
Mar 06 22:20:32 myhostname bash[985]: Random number from svc1 is 32234
Mar 06 22:20:37 myhostname bash[985]: Random number from svc1 is 18419
Mar 06 22:20:42 myhostname bash[985]: Random number from svc1 is 31735
Mar 06 22:20:47 myhostname bash[985]: Random number from svc1 is 16406
Mar 06 22:20:52 myhostname bash[985]: Random number from svc1 is 9543
Mar 06 22:20:57 myhostname bash[985]: Random number from svc1 is 9537
```

## Following the logs

In the situation when you are viewing or troubleshooting realtime journal log entries, you aren't forced to run `journalctl` over and over in your terminal. You can specify `-f` to follow the log dynamically:

```
$ journalctl -u svc1.service -f
```

Now when new entries come in for `svc1.service` they will appear in your terminal as a trailing log.

## Filtering by log level

This one is super helpful if you are troubleshooting any possible issues on the machine. Something is wrong, but what? Sometimes you don't care to see the informational messages, but you also don't have a subset of units to filter by. It's great feature to be able to filter by log level. Only want to see the errors (and worse)?

```
$ journalctl -p err
```

The log levels are `emerg`, `alert`, `crit`, `err`, `warning`, `notice`, `info`, and `debug`. The other really cool thing is that you can specify a range with the format `<start_log_level>..<end_log_level>`:

```
$ journalctl -p warning..err
```

## UTC

How many times are you troubleshooting and you're having to translate timezones with you log entries? It's the worst, doing mental/visual datetime math. I'm a fan of "everything is UTC". Thankfully you can specify that for your journal entries with `--utc`.

## grep'ing

Being able to `grep` anything in the terminal is a powerful ability. It is worth noting that `journalctl` can have the ability to specify a search pattern with `-g`, but it's also common to be on a machine that does *not* support this. If you try to specify this option you could have the error:

> Compiled without pattern matching support

At any rate, it's just as easy (easier?) to pipe `journalctl` output to `grep`:

```
$ journalctl -u svc1.service | grep "5753"
Mar 06 21:55:56 myhostname bash[985]: Random number from svc1 is 5753
```

## Summary

systemd journal log entries can be daunting: There are a lot of them and it can be an overload of information. But knowing how to effectively use `journalctl` and its many options can provide you with a lot of power and efficiency in troubleshooting and diagnosing!
