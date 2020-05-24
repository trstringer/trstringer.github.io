---
layout: post
title: Talking to systemd Through dbus with Python
categories: [Blog]
tags: [linux, systemd, python]
---

As users of systemd, it is a fairly common to use systemctl to interact with the system manager. But what if you’re writing code and you want to programmatically interact with units and services? One way is to `subprocess` out to `systemctl`, but there is overhead with that approach and other things to consider.

Another way is to communicate with systemd through **dbus**.

## What is dbus?

In Linux, dbus is a way for processes to speak with each other. It’s an implementation of interprocess communication. For much more information on what dbus is, take a look at the (freedesktop docs)[https://www.freedesktop.org/wiki/Software/dbus/].

Forgetting about Python for a minute, let’s dig around dbus. `gdbus` is a utility that we can use to look around. One of the operations you can do with dbus is to discover the object API. For instance, if I wanted to see what we can do with systemd through dbus, I can do the following:

```bash
$ gdbus introspect \
    --system \
    --dest org.freedesktop.systemd1 \
    --object-path /org/freedesktop/systemd1
```

The output will look something like this (collapsed for brevity):

```
node /org/freedesktop/systemd1 {
 interface org.freedesktop.DBus.Peer {
...
 };
 interface org.freedesktop.DBus.Introspectable {
...
 };
 interface org.freedesktop.DBus.Properties {
...
 };
 interface org.freedesktop.systemd1.Manager {
...
 };
 node job {
 };
 node unit {
 };
};
```

We will focus on the Manager interface to interact with the systemd service manager. This interface has the following sections (omitted for brevity):

```
interface org.freedesktop.systemd1.Manager {
 methods:
   GetUnit(in s arg_0,
           out o arg_1);
   GetUnitByPID(in u arg_0,
                out o arg_1);
 ...
 signals:
   UnitNew(s arg_0,
           o arg_1);
   UnitRemoved(s arg_0,
               o arg_1);
 ...
 properties:
   @org.freedesktop.DBus.Property.EmitsChangedSignal(“const”)
   readonly s Version = ‘237’;
   @org.freedesktop.DBus.Property.EmitsChangedSignal(“const”)
   readonly s Features = ‘+PAM +AUDIT +SELINUX …’;
 ...
 };
```

For the three sections in a dbus interface: **methods** are the ways we can interact with the dbus object, **signals** are how we can get notifications of certain events, and **properties** are just stored data. We will be focusing on **methods**, as that will be the most common functionality you’ll use.

## Communicating with systemd through dbus

The above section is important, because it allows us (dbus users) to figure out what exactly we can do and how we can interact with a particular process through dbus. To call a method with `gdbus` is not much more involved.

Let’s say we want to find out if the sshd.service unit is enabled. We would do the following (discovered from the above introspection):

```bash
$ gdbus call \
    --system \
    --dest org.freedesktop.systemd1 \
    --object-path /org/freedesktop/systemd1 \
    --method org.freedesktop.systemd1.Manager.GetUnitFileState \
    sshd.service
```

The output (on my machine) is an expected ('enabled',). Look through all the different methods from the introspection to see exactly what you can do through dbus.

## Using Python to make dbus requests

The above is a fancy (and painstaking) way to run systemctl status `sshd.service`. But this exercise is to allow us to use dbus through Python code.

```python
import dbus

unit_name = 'sshd.service'

bus = dbus.SystemBus()
systemd = bus.get_object(
    'org.freedesktop.systemd1',
    '/org/freedesktop/systemd1'
)

manager = dbus.Interface(
    systemd,
    'org.freedesktop.systemd1.Manager'
)

unit_state = manager.GetUnitFileState(unit_name)
```

I won’t speak through each of the individual lines, but by instantiating the bus and getting a handle on the Manager interface for systemd we are able to make the same **GetUnitFileState** method call.

*Note: I’ve breezed over an important part of interacting with dbus. There are two types of bus that we can talk through: system and user. The system is a single bus for the machine that most of the system services are on (which is why I’m using the system bus to get info about sshd.service). The user bus is unique to each login and is for communication of user applications. With gdbus you would either specify `--system` for the system bus or `--session` for the user bus. In the Python API, you would initialize the `SystemBus` for the system bus or `SessionBus` for the user bus.*
