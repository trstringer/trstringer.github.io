---
layout: post
title: SSH Through a Jumpbox to a Protected Server
categories: [Blog]
tags: [linux]
---

This is a common pattern: You have a protected server (or servers) that aren’t publicly accessible. Typically, you may have what is commonly referred to as a “jumpbox”, which is accessible from a public network (sometimes this jumpbox would be in a [DMZ](https://en.wikipedia.org/wiki/DMZ_(computing))).

## TL;DR

To SSH to a server through a jumpbox, you can use `ssh -J myuser@jumpbox myuser@securebox`.

## The longer version

When provisioning or setting up your Linux servers in your data center, your favorite cloud service provider, or under your desk it is a common practice to add your SSH public key to authorized keys on the destination server.

That’s all fine and well, but typically if you’re connecting through the public internet you wouldn’t have access to your protected server(s).

This is where the jumpbox would come into play. You would have access to your jumpbox, and your jumpbox would have access to your secure network. This greatly reduces the surface attack area for your secure network (and servers).

A couple of weeks ago, I was getting frustrated with what I thought was the de facto way to connect through a jumpbox. And like us Linux users sometimes do, I decided to ask the community what the easiest way to do this is, so I hopped on the ##linux (freenode) IRC channel.

That was where it was recommended for me to use the `-J` option, in the format of `ssh -J <jumpbox> <destination>`. Sure enough, it worked like a charm.

Manpages for SSH(1) explain the following:

> -J [user@]host[:port]
> Connect to the target host by first making a ssh connection to the jump host and then establishing a TCP forwarding to the ultimate destina‐
> tion from there. Multiple jump hops may be specified separated by comma characters. This is a shortcut to specify a ProxyJump configuration
> directive.

I hope this shortcut helps other Linux users often doing the same thing! This has made my life a lot easier.

Enjoy!
