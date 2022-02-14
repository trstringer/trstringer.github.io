---
layout: post
title: Learning DevOps in 2022
categories: [Blog]
tags: [devops,linux,kubernetes,github]
---

I see this question asked all the time: "I want to get into DevOps, what should I learn?". It's a valid question! DevOps is a technical discipline that has such a wide breadth of responsibility that it's hard to know where to start.

*Note: Just to be clear, a "DevOps career" can look like many things including SRE (site reliability engineer), systems engineer, and the list goes on and on.*

I wanted to spend some time in compiling some *very* high-level guides on what I think are good focus areas for learning. This is broken down into the following categories:

- Platforms
- Languages
- Tooling
- Cloud

## Platforms

![DevOps platforms](../images/devops-2022-1.png)

### Linux

Hands down the biggest investment in DevOps is learning Linux. It is the absolute most fundamental skill that you can bring. Understanding Linux and being proficient in using it will, by itself, open a ton of doors. The world really does run on Linux. I would refuse to rank any of the skills in this blog post... except Linux. It's definitely the #1 skill here.

How can you learn Linux? Use it. I don't just mean using it as a server and writing some applications that run on Linux (that's great, and you should definitely do that). Fully committing to Linux is using it on your desktop. It's possible (and it's amazing). Do as much as you can through the terminal. Just like anything else, **immersion is the quickest way to practically learn**.

### Kubernetes

The other platform that I would recommend learning and focusing on is Kubernetes. We're seeing a lot of efforts being focused on here, and understanding containers and how Kubernetes works is a great skill that is very transferrable across the board. Read a book, and start experimenting. The easiest way is to create a Kubernetes cluster in your favorite cloud provider and deploy a simple application to it.

## Languages

![DevOps languages](../images/devops-2022-2.png)

### Bash shell scripting

Shell scripts are everywhere. They are often the first resort to automation. Need to do a thing and it can't be manual? Write a shell script. Even in my personal life, I typically refuse to do something more than once manually if I can write a script to do it. DevOps is no different. You would write a shell script to handle different parts of your CI/CD pipeline, all the way to writing a shell script to check the status of running services.

### Python

As useful as shell scripting is, there is definitely a ceiling with it where the requirement complexity and script maintainability become too much. **Many people (myself included) blaze straight past this limit and end up with a shell script that is way too long and complex and hard to maintain.** That's where Python can come in. Python is a fully-featured programming language with great libraries and tooling around it. A simple Python script can likely replace that massive complex shell script. An immediate benefit is being able to set a breakpoint and drop into the debugger.

### Go

Python is great but there are two requirements that might be an issue for Python:

- Performance
- Single binary

This is where Go can really shine. High performance and also one executable needed with dependencies bundled into it. The single artifact aspect of Go is a *really* nice advantage, especially when you're bundling your software into a container. Go is a great language that is a lot of fun to program in, and the syntax surface area is fairly small so learning it is more approachable than you might think (but Go can also get very complicated and there are many aspects to the language that can also be difficult!).

## Tooling

![DevOps tooling](../images/devops-2022-3.png)

### Git

Git is likely the most core tool that you would be using. We live in an everything-as-code world, and Git is the leading version control (by far). It's probably the binary that I use the most every single day. Getting familiar with what commits, branches, and remotes is super important. Having this core knowledge will help you figure out tricky situations (like merge conflicts) when the time comes up. I recommend that you use Git from the terminal instead of a GUI. The latter can definitely help and be a great workflow, but in my personal opinion it can hide some of the complexity of Git that is important to at least be familiar with.

### GitHub

While Git is a tool, GitHub is a DevOps service. GitHub allows you to store your Git repositories, but it also has great CI/CD capabilities. There are many other awesome services for this (such as GitLab) but most open source software is hosted on GitHub. Also, the platform itself has had great advancements making it a really modern approach to DevOps. The best way to learn GitHub is to start using it and contributing to projects. Learn how to use GitHub Actions to setup and run your CI/CD pipelines.

## Cloud

Learn one of the three main cloud providers: AWS, Azure, or GCP. You can't go wrong with either of them. Simply put, the cloud is where things happen. It's likely where you'll run your CI/CD pipelines as well as where you will end up deploying (and maintaining) your software. Getting familiar with a cloud provider is critical. Most cloud providers offer a free tier for certain services as well as a credit for learning.

## Summary

Hopefully this blog post has provided some guidance on what to learn this year for DevOps! Enjoy and happy computing!
