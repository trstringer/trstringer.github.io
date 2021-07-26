---
layout: post
title: Simple vs Oneshot - Choosing a systemd Service Type
categories: [Blog]
tags: [linux, systemd]
---

*This post is intentionally thorough, but if you're just looking for a summary and when to use which service type, [jump down below](#summary).*

When you are creating your systemd service, choosing a service type can be a little tricky and confusing. There are a handful of service types available, but this post will focus on the differences between oneshot and simple services. There can be a little confusion around which to use, and when to use it.

The man pages do a decent job at explaining this:

> If set to **simple** (the default if ExecStart= is specified but neither Type= nor BusName= are), the service manager will consider the unit started immediately after the main service process has
> been forked off. It is expected that the process configured with ExecStart= is the main process of the service. In this mode, if the process offers functionality to other processes on the
> system, its communication channels should be installed before the service is started up (e.g. sockets set up by systemd, via socket activation), as the service manager will immediately
> proceed starting follow-up units, right after creating the main service process, and before executing the service's binary. Note that this means systemctl start command lines for simple
> services will report success even if the service's binary cannot be invoked successfully (for example because the selected User= doesn't exist, or the service binary is missing).

> Behavior of **oneshot** is similar to simple; however, the service manager will consider the unit started after the main process exits. It will then start follow-up units.  RemainAfterExit= is
> particularly useful for this type of service.  Type=oneshot is the implied default if neither Type= nor ExecStart= are specified.

I've found this to be a good starting point to understanding, but it could still leave you wondering what to choose and when, especially if you don't have any follow-up units.

## Follow-up units timing

This is the biggest differentiatior between oneshot and simple services is when the follow-up units will start. As mentioned in the man pages, follow-up units of a simple service will immediately start. Here's an illustration to show this:

**Simple service and follow-up units timing**

![Simple service diagram](/images/oneshot-simple-1.png)

Whereas with a oneshot service, all follow-up units will wait until the completion of the service before they start:

**Oneshot service and follow-up units timing**

![Oneshot service diagram](/images/oneshot-simple-2.png)

There is an important reason behind this aspect though that drives other behavioral differences. This is all due to the differences in activation states for the services (more on activation states below).

Here is a quick example showing this. First, let's see a simple service and a follow-up unit:

**simple-test.service**

```
[Unit]
Description=Simple service test

[Service]
Type=simple
ExecStart=/bin/bash -c "echo Simple service - start && sleep 60 && echo Simple service - end"
```

And the dependent service:

**dep-simple-test.service**

```
[Unit]
Description=Dependent service
After=simple-test.service
Requires=simple-test.service

[Service]
ExecStart=/bin/bash -c "echo Dependent service - running"
```

Starting `dep-simple-test.service` will start `simple-test.service` first (because of the After/Requires directives), and the logging shows:

```
Jun 19 20:28:16 thstring20200619162314 systemd[1]: Started Simple service test.
Jun 19 20:28:16 thstring20200619162314 systemd[1]: Started Dependent service.
Jun 19 20:28:16 thstring20200619162314 bash[1238]: Simple service - start
Jun 19 20:28:16 thstring20200619162314 bash[1239]: Dependent service - running
Jun 19 20:28:16 thstring20200619162314 systemd[1]: dep-simple-test.service: Succeeded.
Jun 19 20:29:16 thstring20200619162314 bash[1238]: Simple service - end
Jun 19 20:29:16 thstring20200619162314 systemd[1]: simple-test.service: Succeeded.
```

The simple test (and many of these other ones below) just use a `sleep` to have a long pause to amplify the timing differences. Because `simple-test.service` is a simple service, its follow-up unit `dep-simple-test.service` will start immediately, and this can be seen by both services having been started at roughly the same time.

But if we do a similar thing with a oneshot service, let's see how different that looks.

**oneshot-test.service**

```
[Unit]
Description=Oneshot service test

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo Oneshot service - start && sleep 60 && echo Oneshot service - end"
```

**dep-oneshot-test.service**

```
[Unit]
Description=Dependent service
After=oneshot-test.service
Requires=oneshot-test.service

[Service]
ExecStart=/bin/bash -c "echo Dependent service - running"
```

The logging for these two units (after having started `dep-oneshot-test.service`) shows the difference:

```
Jun 19 20:31:46 thstring20200619162314 systemd[1]: Starting Oneshot service test...
Jun 19 20:31:46 thstring20200619162314 bash[1420]: Oneshot service - start
Jun 19 20:32:46 thstring20200619162314 bash[1420]: Oneshot service - end
Jun 19 20:32:46 thstring20200619162314 systemd[1]: oneshot-test.service: Succeeded.
Jun 19 20:32:46 thstring20200619162314 systemd[1]: Started Oneshot service test.
Jun 19 20:32:46 thstring20200619162314 systemd[1]: Started Dependent service.
Jun 19 20:32:46 thstring20200619162314 bash[1440]: Dependent service - running
Jun 19 20:32:46 thstring20200619162314 systemd[1]: dep-oneshot-test.service: Succeeded.
```

You can see that the `Dependent service` doesn't start until the `Oneshot service` has completed.

## Activation states

The activation states of the different service types controls a lot of the interaction with other units and is a major contributor to timing.

| Type | Before | During | After |
| ---- | ------ | ------ | ----- |
| Simple | inactive (dead) | active (running) | inactive (dead) |
| Oneshot | inactive (dead) | activating (start) | inactive (dead) |
| Oneshot (`RemainAfterExit`) | inactive (dead) | activating (start) | active (exited) |

Much more later on for oneshot with `RemainAfterExit`. The "during" activation state difference between simple and oneshot is the reason why follow-up units wait for a oneshot service to finish, and why they don't wait for a simple service to finish. It's because follow-up units will not start with an `activating` state.

## `RemainAfterExit` (oneshot)

Having hinted at it above, the directive `RemainAfterExit` changes the behavior of a oneshot service quite a bit. It's the way of telling systemd that after it exits it should still in an an `active` state. To expand more with an example:

**oneshot-remainafterexit.service**

```
[Unit]
Description=Oneshot service test with RemainAfterExit

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "echo Oneshot service - start && sleep 60 && echo Oneshot service - end"
```

Running `systemctl status` on this service at it has run, we can see the difference:

```
● oneshot-remainafterexit.service - Oneshot service test with RemainAfterExit
   Loaded: loaded (/etc/systemd/system/oneshot-remainafterexit.service; static; vendor preset: enabled)
   Active: active (exited) since Fri 2020-06-19 20:55:14 UTC; 7s ago
  Process: 1174 ExecStart=/bin/bash -c echo Oneshot service - start && sleep 60 && echo Oneshot service - end (code=exited, status=0/SUCCESS)
 Main PID: 1174 (code=exited, status=0/SUCCESS)

Jun 19 20:54:14 thstring20200619162314 systemd[1]: Starting Oneshot service test with RemainAfterExit...
Jun 19 20:54:14 thstring20200619162314 bash[1174]: Oneshot service - start
Jun 19 20:55:14 thstring20200619162314 bash[1174]: Oneshot service - end
Jun 19 20:55:14 thstring20200619162314 systemd[1]: Started Oneshot service test with RemainAfterExit.
```

Notice how the service is in an `active (exited)` state, instead of `inactive (dead)` (which would be the case if `RemainAfterExit` was off). But when would we want to keep this, and what does it *effectively* do? Let's see with an example that uses an `ExecStop` directive. `ExecStop` will run when a service is stopped.

**oneshot-execstop.service**

```
[Unit]
Description=Oneshot service test with ExecStop

[Service]
Type=oneshot
RemainAfterExit=no
ExecStart=/bin/bash -c "echo Oneshot service - start && sleep 60 && echo Oneshot service - end"
ExecStop=/bin/bash -c "echo Oneshot service - stop"
```

In this service `RemainAfterExit` is off (it's the default, but added for the sake of being explicit).

```
● oneshot-execstop.service - Oneshot service test with ExecStop
   Loaded: loaded (/etc/systemd/system/oneshot-execstop.service; static; vendor preset: enabled)
   Active: inactive (dead)

Jun 19 21:04:10 thstring20200619162314 systemd[1]: Starting Oneshot service test with ExecStop...
Jun 19 21:04:10 thstring20200619162314 bash[1480]: Oneshot service - start
Jun 19 21:05:10 thstring20200619162314 bash[1480]: Oneshot service - end
Jun 19 21:05:10 thstring20200619162314 bash[1604]: Oneshot service - stop
Jun 19 21:05:10 thstring20200619162314 systemd[1]: oneshot-execstop.service: Succeeded.
Jun 19 21:05:10 thstring20200619162314 systemd[1]: Started Oneshot service test with ExecStop.
```

We can see that the `ExecStop` ran *immediately* when the `ExecStart` was done, because the service transitioned into the `inactive (dead)` state. Now let's see what happens with `RemainAfterExit` set:

**oneshot-execstop-remainafterexit.service**

```
[Unit]
Description=Oneshot service test with ExecStop and RemainAfterExit

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "echo Oneshot service - start && sleep 60 && echo Oneshot service - end"
ExecStop=/bin/bash -c "echo Oneshot service - stop"
```

And the `systemctl status` output:

```
● oneshot-execstop-remainafterexit.service - Oneshot service test with ExecStop and RemainAfterExit
   Loaded: loaded (/etc/systemd/system/oneshot-execstop-remainafterexit.service; static; vendor preset: enabled)
   Active: active (exited) since Fri 2020-06-19 21:07:54 UTC; 8s ago
  Process: 1708 ExecStart=/bin/bash -c echo Oneshot service - start && sleep 60 && echo Oneshot service - end (code=exited, status=0/SUCCESS)
 Main PID: 1708 (code=exited, status=0/SUCCESS)

Jun 19 21:06:54 thstring20200619162314 systemd[1]: Starting Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:06:54 thstring20200619162314 bash[1708]: Oneshot service - start
Jun 19 21:07:54 thstring20200619162314 bash[1708]: Oneshot service - end
Jun 19 21:07:54 thstring20200619162314 systemd[1]: Started Oneshot service test with ExecStop and RemainAfterExit.
```

Notice here that because the service is still `active` (even though it has completed its `ExecStart`), the `ExecStop` still hasn't run  yet. Now if you were to run `systemctl stop oneshot-execstop-remainafterexit.service`, let's see what that looks like:

```
● oneshot-execstop-remainafterexit.service - Oneshot service test with ExecStop and RemainAfterExit
   Loaded: loaded (/etc/systemd/system/oneshot-execstop-remainafterexit.service; static; vendor preset: enabled)
   Active: inactive (dead)

Jun 19 21:06:54 thstring20200619162314 systemd[1]: Starting Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:06:54 thstring20200619162314 bash[1708]: Oneshot service - start
Jun 19 21:07:54 thstring20200619162314 bash[1708]: Oneshot service - end
Jun 19 21:07:54 thstring20200619162314 systemd[1]: Started Oneshot service test with ExecStop and RemainAfterExit.
Jun 19 21:08:58 thstring20200619162314 systemd[1]: Stopping Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:08:58 thstring20200619162314 bash[1900]: Oneshot service - stop
Jun 19 21:08:58 thstring20200619162314 systemd[1]: oneshot-execstop-remainafterexit.service: Succeeded.
Jun 19 21:08:58 thstring20200619162314 systemd[1]: Stopped Oneshot service test with ExecStop and RemainAfterExit.
```

Now we can see that the `ExecStop` has run because the service is now `inactive`. That's all interesting, but it isn't common to `systemctl stop` a service. So when would this be useful? See below...

## Run a service at shutdown

By creating a oneshot service with an `ExecStop` with `RemainAfterExit`, this is a great way to effectively run something at shutdown. Let's see what that looks like in practice:

**oneshot-execstop-remainafterexit-install.service**

```
[Unit]
Description=Oneshot service test with ExecStop and RemainAfterExit

[Service]
Type=oneshot
RemainAfterExit=yes
ExecStart=/bin/bash -c "echo Oneshot service - start && sleep 60 && echo Oneshot service - end"
ExecStop=/bin/bash -c "echo Oneshot service - stop"

[Install]
WantedBy=multi-user.target
```

Then running `systemctl enable` for this unit will install it. If you were to start the service (or reboot), you'd see this:

```
● oneshot-execstop-remainafterexit-install.service - Oneshot service test with ExecStop and RemainAfterExit
   Loaded: loaded (/etc/systemd/system/oneshot-execstop-remainafterexit-install.service; enabled; vendor preset: enabled)
   Active: active (exited) since Fri 2020-06-19 21:14:02 UTC; 5s ago
 Main PID: 366 (code=exited, status=0/SUCCESS)
    Tasks: 0 (limit: 4087)
   Memory: 0B
   CGroup: /system.slice/oneshot-execstop-remainafterexit-install.service

Jun 19 21:13:02 thstring20200619162314 systemd[1]: Starting Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:13:02 thstring20200619162314 bash[366]: Oneshot service - start
Jun 19 21:14:02 thstring20200619162314 bash[366]: Oneshot service - end
Jun 19 21:14:02 thstring20200619162314 systemd[1]: Started Oneshot service test with ExecStop and RemainAfterExit.
```

Just like above, our `ExecStop` hasn't run yet. Now do a reboot, and look at the logs:

```
-- Logs begin at Fri 2020-06-19 21:14:50 UTC, end at Fri 2020-06-19 21:18:47 UTC. --
Jun 19 21:14:51 thstring20200619162314 systemd[1]: Starting Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:14:51 thstring20200619162314 bash[337]: Oneshot service - start
Jun 19 21:15:51 thstring20200619162314 bash[337]: Oneshot service - end
Jun 19 21:15:51 thstring20200619162314 systemd[1]: Started Oneshot service test with ExecStop and RemainAfterExit.
Jun 19 21:17:48 thstring20200619162314 systemd[1]: Stopping Oneshot service test with ExecStop and RemainAfterExit...
Jun 19 21:17:48 thstring20200619162314 bash[681]: Oneshot service - stop
Jun 19 21:17:49 thstring20200619162314 systemd[1]: oneshot-execstop-remainafterexit-install.service: Succeeded.
Jun 19 21:17:49 thstring20200619162314 systemd[1]: Stopped Oneshot service test with ExecStop and RemainAfterExit.
```

What happens is that the machine was shutdown at around `21:17:48`, and this caused the service to stop which in turn runs `ExecStop`. This is a really simple and effective way to run something at shutdown (like a graceful cleanup process)! And what's even better is that you don't *have* to have an `ExecStart` with a oneshot service. More on that below.

## Multiple `ExecStart`s

A simple service can only have one `ExecStart` directive. But a oneshot service can have zero, one, or more than one `ExecStart`s. If you have no `ExecStart`, the requirement is that you would have to define `ExecStop` (as well as set `RemainAfterExit`). This would be a service that just runs on shutdown, and not any other time. It would resemble `oneshot-execstop-remainafterexit-install.service` but with the `ExecStart` removed.

As mentioned above, a oneshot service can have multiple `ExecStart`s as well. It could look like:

**oneshot-multiple-execstart.service**

```
[Unit]
Description=Oneshot service test with multiple ExecStart

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo First"
ExecStart=/bin/bash -c "echo Second"
ExecStart=/bin/bash -c "echo Third"
```

As expected, the logging output would be:

```
-- Logs begin at Mon 2020-06-22 13:24:01 UTC, end at Mon 2020-06-22 13:33:16 UTC. --
Jun 22 13:33:02 thstring20200622092223 systemd[1]: Starting Oneshot service test with multiple ExecStart...
Jun 22 13:33:02 thstring20200622092223 bash[1316]: First
Jun 22 13:33:02 thstring20200622092223 bash[1317]: Second
Jun 22 13:33:02 thstring20200622092223 bash[1318]: Third
Jun 22 13:33:02 thstring20200622092223 systemd[1]: oneshot-multiple-execstart.service: Succeeded.
Jun 22 13:33:02 thstring20200622092223 systemd[1]: Started Oneshot service test with multiple ExecStart.
```

By chaining together `ExecStart` actions, it allows you to create some powerful workflows right in a systemd unit. But what if one of your `ExecStart`s has a failure?

**oneshot-multiple-execstart-failure.service**

```
[Unit]
Description=Oneshot service test with multiple ExecStart and failure

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo First"
ExecStart=/bin/bash -c "false && echo Second"
ExecStart=/bin/bash -c "echo Third"
```

Trying to run this service, you would get the following output:

```
$ sudo systemctl start oneshot-multiple-execstart-failure.service
Job for oneshot-multiple-execstart-failure.service failed because the control process exited with error code.
See "systemctl status oneshot-multiple-execstart-failure.service" and "journalctl -xe" for details.

$ sudo journalctl -u oneshot-multiple-execstart-failure.service
-- Logs begin at Mon 2020-06-22 13:24:01 UTC, end at Mon 2020-06-22 13:37:16 UTC. --
Jun 22 13:36:53 thstring20200622092223 systemd[1]: Starting Oneshot service test with multiple ExecStart and failure...
Jun 22 13:36:53 thstring20200622092223 bash[1441]: First
Jun 22 13:36:53 thstring20200622092223 systemd[1]: oneshot-multiple-execstart-failure.service: Main process exited, code=exited, status=1/FAILURE
Jun 22 13:36:53 thstring20200622092223 systemd[1]: oneshot-multiple-execstart-failure.service: Failed with result 'exit-code'.
Jun 22 13:36:53 thstring20200622092223 systemd[1]: Failed to start Oneshot service test with multiple ExecStart and failure.
```

The service fails and halts execution. But what if you didn't want that failure to stop the service from continuing? You can simply add a `-` character in front of the executable.

**oneshot-multiple-execstart-failure-success.service**

```
[Unit]
Description=Oneshot service test with multiple ExecStart and failure

[Service]
Type=oneshot
ExecStart=/bin/bash -c "echo First"
ExecStart=-/bin/bash -c "false && echo Second"
ExecStart=/bin/bash -c "echo Third"
```

It isn't obvious, but notice in the second `ExecStart` that `/bin/bash` is prepended with a `-`. Now look at this output:

```
-- Logs begin at Mon 2020-06-22 13:24:01 UTC, end at Mon 2020-06-22 13:39:04 UTC. --
Jun 22 13:38:59 thstring20200622092223 systemd[1]: Starting Oneshot service test with multiple ExecStart and failure...
Jun 22 13:38:59 thstring20200622092223 bash[1553]: First
Jun 22 13:38:59 thstring20200622092223 bash[1555]: Third
Jun 22 13:38:59 thstring20200622092223 systemd[1]: oneshot-multiple-execstart-failure-success.service: Succeeded.
Jun 22 13:38:59 thstring20200622092223 systemd[1]: Started Oneshot service test with multiple ExecStart and failure.
```

The second `ExecStart` fails as expected, but it doesn't fail the service or stop execution and the third one does run.

## Summary

When you are deciding which service type to choose between simple and oneshot, here is some guidance:

* Does your service need to complete before any follow-up services run? Use **oneshot**.
* Do your follow-up services need to be running while this service does? Use **simple**.
* Is this a long-running service? Probably use **simple**.
* Do you need to run this service only at shutdown? Use **oneshot**.
* Do you need to have multiple separate commands to run? Use **oneshot**.

Hopefully this post has provided some insight on the underlying mechanics of these two systemd service types!
