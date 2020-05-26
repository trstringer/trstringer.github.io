---
layout: post
title: Logging to systemd in Python
categories: [Blog]
tags: [linux, systemd, python]
---

One of the common themes in modern Linux is the adoption of systemd. Like it or hate it, it is here to stay.

The main component of logging in systemd is the Journal, controlled by journald. Linux users are undoubtedly familiar with invoking `journalctl` to view Journal logs. As Python developers that target Linux environments, it isn’t unusual to use systemd to manage our logged events.

I like this approach almost as much as I like logging to stdout, as it is consistent, expected (on Linux), and there is plenty of tooling around to support scraping the logs from systemd to push to central logging, aggregation, etc. (take a look at [fluentd](https://www.fluentd.org/) and [Fluent Bit](http://fluentbit.io/)!).

## Installing system dependencies

The Python package that we will rely on is appropriately named systemd. But before we can `pip install systemd`, we need to first grab system dependencies (specific to the distro we’re using).

On RPM-based distributions (RHEL, CentOS, Fedora) this should be as simple as installing `systemd-devel`. On my beloved CentOS machines, that would be:

```
# yum install -y systemd-devel
```

On Debian-based distributions, as per the [documentation](https://pypi.python.org/pypi/systemd/), the dependencies are `build-essential`, `libsystemd-journal-dev`, `libsystemd-daemon-dev`, and `libsystemd-dev`.

Once these dependencies are installed, you can then install our necessary Python package:

```
$ pip install systemd
```

*Note: I highly recommend you use a virtual environment for your Python development and deployments (unless containerized), to prevent Python package conflicts. More on this below.*

## Logging to systemd

Once we have the dependencies installed, logging to systemd is fairly straightforward. I think the best way to show this is with a simple snippet:

```python
import logging
import random
import time
from systemd.journal import JournaldLogHandler

# get an instance of the logger object this module will use
logger = logging.getLogger(__name__)

# instantiate the JournaldLogHandler to hook into systemd
journald_handler = JournaldLogHandler()

# set a formatter to include the level name
journald_handler.setFormatter(logging.Formatter(
    '[%(levelname)s] %(message)s'
))

# add the journald handler to the current logger
logger.addHandler(journald_handler)

# optionally set the logging level
logger.setLevel(logging.DEBUG)

if __name__ == '__main__':
    while True:
        # log a sample event
        logger.info(
            'test log event to systemd! Random number: %s',
            random.randint(0, 10)
        )

        # sleep for some time to not saturate the journal
        time.sleep(5)
```

The comments above should help explain, but from a higher level we just need to get an instance of a logger (I pass in the module name, but this could’ve been anything). The important part here is to wire up systemd’s Journal by adding a handler to our logger that is of type `JournaldLogHandler`. I personally like to include the level in my logging messages, so I define a custom formatter for my journald handler.

## Virtual environment

Because I rely heavily on virtual environments, I need to make sure systemd sources my virtual environment activation prior to running my Python script as a daemon. This allows me to reap the benefits of a virtual environment (dependency isolation), even while running my code as a daemon.

My usual approach to this is to just create an executable wrapper shell script:

```bash
#!/bin/bash

SCRIPT_PATH=$(dirname "$(realpath "$0")")
. "$SCRIPT_PATH/venv/bin/activate"
python "$SCRIPT_PATH/app.py"
```

I put this shell script in the same directory as my Python module.

## Setting up the systemd unit file and service

Before we can test this out, we need to create a **unit file** so that systemd knows how to setup and handle our daemon.

```
[Unit]
Description=Sample to show logging from a Python application to systemd
After=network.target

[Service]
Type=simple
ExecStart=/usr/local/bin/pysystemdlogging/run_app.sh
Restart=on-abort

[Install]
WantedBy=multi-user.target
```

Keep this unit file in whatever long term directory you like, typically with the Python source for this application. systemd works heavily off of convention regarding *what unit files exist where*. Without going into too much depth about systemd (there could be books written, and it is out of the scope of this blog post), we need to make sure our unit file is symlink'd and accessible in `/etc/systemd/system`:

```
# ln -s “$(pwd)/pylogtosystemd.service” /etc/systemd/system/pylogtosystemd.service
```

The next step is to reload systemd so that our new unit file is picked up.

```
# systemctl daemon-reload
```

Verify that the unit file is registered by attempting to get the status of our service.

```
$ systemctl status pysystemdlogging.service
```

You should see that the service is 'loaded' but 'inactive'. Let’s start our new daemon.

```
# systemctl start pysystemdlogging.service
```

## Viewing the log entries with journalctl

Now that our systemd daemon is up and running, let’s take a look at the entries that are (hopefully) waiting for us in the journal!

```
# journalctl -b -u pysystemdlogging.service
```

With the "-u" parameter we are able to filter based on a unit (in our case, we only want to see log entries from our daemon). "-b" tells journalctl to only give us entries since the last boot.

Hopefully your output looks similar to mine!

![Python and systemd logging output](/images/python-systemd-logging.png)

## Summary

I hope this post has illustrated how to easily log to systemd’s Journal from Python! If you’re interested in diving a little more into systemd and unit files, I highly recommend you check out [this entry in the Arch wiki](https://wiki.archlinux.org/index.php/Systemd). Enjoy!
