---
layout: post
title: Monitor, Log, and Alert CPU Throttling from Overheating on Linux
categories: [Blog]
tags: [linux, fedora, gnome, python, systemd]
---

I've been recently dealing with an overheating issue on my Linux machine (Lenovo T420s). Completely perplexed on what was causing it (it wasn't constant and happened with many different variables at play) and really unsure of when exactly it was happening, I turned to code to paint the picture for me.

That was the tough part for me. I'd grep the systemd journal and notice that these CPU throttling events were happening throughout the day. I had no telemetry on what was happening during the time surrounding my CPU temps as well as what my system load was.

Not to mention, when these issues happened I was usually none-the-wiser and therefore couldn't do any troubleshooting during the CPU throttling events.

## Here's what I ended up with

I wrote a [Python script (GitHub)](https://github.com/trstringer/linux-core-temperature-monitor) that does a few things. First and foremost, I wanted to know every minute on the minute what my CPU core temps were regardless of whether I'm getting throttled or not so that I had the option to chart this (I haven't done this, as I think I've found the culprit but I wanted to keep my options open). I also wanted to know if my laptop fan was functioning as desired in relation to the CPU temps, so I needed to grab fan RPM.

Likewise, an obvious significant factor here is system load. And lastly, since I really care about my CPU being throttled I needed to not only monitor for these events in the systemd journal but I wanted to be alerted when they happened.

The script relies heavily on the `lm_sensors` package. On my Fedora 26 machine, that was as simple as `dnf install -y lm_sensors`.

For the notification part, I wanted a desktop notification. Because I'm a GNOME desktop environment user, I'd issue the `notify-send` command. Here's what the experience looks like:

![CPU throttled notification](/images/cpu-throttled.png)

Of course, I needed to run this script every minute to get the desired effect so I just added the following to my crontab: `* * * * * /home/trstringer/dev/python/temp-monitor/app.py`.

In the end, these notifications and metrics that were logged (CSV) allowed me to pinpoint exactly what was causing this (it ended up being related to my laptop be docked. Not great news, but obviously avoidable!).

Note, this script is very GNOME-specific. In the off-chance you, too, need to do this type of monitoring, fork the repo and refactor out the DE specific code!

Enjoy!
