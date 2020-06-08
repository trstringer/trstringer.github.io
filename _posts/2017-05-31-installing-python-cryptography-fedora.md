---
layout: post
title: Installing Python's cryptography package on Fedora Linux
categories: [Blog]
tags: [python, fedora, linux]
---

I was recently wrestling with `pip install cryptography` on Fedora 25. I had followed the cryptography documentations and [installed the referenced dependencies](https://cryptography.io/en/latest/installation/#building-cryptography-on-linux). But even so, I was still receiving a gcc error when attempting to install the cryptography package (both with Python 2 and Python 3).

It turns out the resolution is to *also* install the `redhat-rpm-config` package:

```
$ sudo dnf install redhat-rpm-config -y
```

Once I did this, I was able to successfully installed the cryptography package for Python. This blog post is more of a documentation exercise for myself, but perhaps it'll help somebody else out in the future!
