---
layout: post
title: Be Good at Referencing, Not Remembering
categories: [Blog]
tags: [software-development]
---

My memory is awful. In all aspects of life. But as a software engineer, I don't rely on my memory. In fact, it's the opposite. I rely on my lack of memory. We live in a world where there is too much... too many commands, too much syntax, too many docs, etc. etc. etc.

It's impossible to remember it all. So don't remember any of it! As a software engineer/programmer/developer, your power is not in remembering: It is in **referencing**.

Here's a *small* sample of me:

- I can't remember where to put my systemd unit files, but I can reference it in `man systemd.unit`
- I can't remember Go's `copy` order if source or destination comes first, but I can reference it in `go doc builtin copy`
- I can't remember the parameters for `tar`, but I can reference it in `man tar`
- I can't remember the parameters to create an Azure VM, but I can reference it in `az vm create --help`
- I can't remember Kubernetes `apiVersion`s, but I can [look them up with a few commands](https://trstringer.com/kubernetes-apiversion/)
- I can't remember Kubernetes pod spec, but I can reference it with `kubectl explain pods.spec`
- I can't remember how to get a Bash shell script's location, but I can reference it quickly [in my own documentation](#create-your-own-documentation)
- *...this list is endless...*

## Be good at finding documentation

Documentation is everywhere. Memory is more error-prone than documentation (usually). **Choose documentation over memory, every time**.

Documentation also comes in many forms: In the *terminal* and in the *browser*. I live in the terminal, so my first choice (by far) is to be able to view the reference on the command-line. If you are a Linux user, leverage the man pages. For most command-line interfaces, you can usually have `--help` or `help` to dump out the command documentation.

## The easier the documentation is to consume...

...the less discomfort to finding the knowledge. If it's hard to find the text that tells you how something works, it will be mentally and emotionally painful. Use (or create) documentation that is easy to digest.

## Create your own documentation

Not everything can be found in `--help`, or `man`, or product docs. Some things are created by you, the individual programmer: Software that you write, issues that you troubleshoot, guides on how you set something up. **Create your own documentation** that is easy to consume.

A good example: I was developing an entirely different product in Azure 6 months ago. With every feature I developed I was documenting everything. Now 6 months later when somebody asks me about something, my memory is blank as if it was a different developer. But I look back in my notes, and I remember. My memory is in my notes.

## Summary

A great engineer is not great because they remember things, they are great because they can figure things out. If it's already been done, then it is through documentation and referencing they figure it out. Forget about your memory, get proficient at referencing.
