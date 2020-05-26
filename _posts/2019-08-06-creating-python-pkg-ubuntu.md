---
layout: post
title: Creating a Python package for Ubuntu... From code zero to apt install
categories: [Blog]
tags: [linux, python, ubuntu, debian]
---

Some of the work I am doing right now has me creating packages that should be distributed to Ubuntu Linux machines. For those of us that aren’t new to the Linux world, it is a normal thing to apt install <pkg_name>. But as a software developer and package creator/maintainer, building a package for distribution is not quite as straightforward as installing it.

This post is going to take us from the very beginning (code zero) all the way to publishing a package in a PPA (Personal Package Archive) for consumers to install and use.

*Note: the source code for the package can be found at [python3-random-quote (GitHub)](https://github.com/trstringer/python3-random-quote).*

## Creating the Python components

Before we even think about packaging this up, we need to have a working Python application. I went with something very simple (but a little bit more involved than just “Hello World” to the terminal). The package is going to be called python3-random-quote and it does just that: Gives the end user a random quote by making an HTTP request to a well-known quote-of-the-day endpoint. I chose to do this so that the package itself had a dependency that needed to be resolved (python3-requests).

Let’s first setup the directory for the Python application/library:

```bash
$ mkdir python3-random-quote
$ cd python3-random-quote
$ mkdir src
$ touch src/__init__.py
$ touch src/main.py
$ touch setup.py
```

The contents of src/main.py are:

```python
import requests

_QUOTE_URL = 'https://quotes.rest/qod'

def get_random_quote():
    """Get a random quote."""

    res = requests.get(_QUOTE_URL)
    return res.json()['contents']['quotes'][0]['quote']

def display_quote():
    """Display a random quote."""

    print(f'My random quote is: "{get_random_quote()}"')

if __name__ == '__main__':
    display_quote()
```

If you aren’t familiar with Python setuptools, I recommend you read and review the reference for building Python packages (don’t confuse this with building Debian packages). My setup.py contents are:

```python
from setuptools import setup, find_packages

setup(
    name='randomquote',
    version='0.1',
    description='Get a random quote',
    url='http://github.com/trstringer/python3-random-quote',
    author='Thomas Stringer',
    author_email='github@trstringer.com',
    license='MIT',
    install_requires=['requests'],
    packages=find_packages(),
    entry_points=dict(
        console_scripts=['rq=src.main:display_quote']
    )
)
```

*Note: I have completely breezed over the notion of local Python development best practices. I highly recommend that locally you develop in a virtual environment and maintain your dependencies in a requirements.txt file. More on this in PyPA docs for requirements files.*

Beyond the basics for the package in setup.py, there are a few items worth discussing briefly:

- **install_requires** — these are the required packages that my package needs. In my case, I have a dependency on requests, so I list it here.
- **packages** — this is a list of all packages that live in my library, and I make good use of a great setuptools helper, find_packages (to do just that: find all of the packages).
- **entry_points** / **console_scripts**— a little more tricky, but what I’m accomplishing here with a console script is I’m telling setuptools to create a bin for me (called rq) that calls display_quote in the src.main module. I wanted to make my Python package both a library that can be consume by other Python applications/libraries, but also a bin that can be directly invoked.

At this point we now have something that we should be able to pip install <package_dir>. If you are doing local development cycles on the package (for actual real software development that is more complicated than hello world) then I recommend you pip install -e <package_dir> so that you can make it an “editable” dependency.

## Launchpad and PPAs

Before we dive into creating the package and pushing it to a repository, we need to understand and work with Launchpad, which is Canonical’s platform for Open Source software with a bunch of capabilities. One of the main features of Launchpad is that it hosts Personal Package Archives (PPA). This allows us to push our deb source packages to Launchpad and have the platform build the software for distribution. One way to think of a PPA is as a hosted package repository.

Another nice feature of using a PPA to host your packages is that they are first-class citizens with much of the Ubuntu tooling. We’ll see a few examples of this shortly.

Besides the fact that you are not owning the infrastructure and the binary build process for your package repository, I personally don’t see a downside to using Launchpad PPAs for your package distribution. If you have any opinions to counter this though, I’d love to hear them in the comments!

In order to use your own PPA on Launchpad, there are a few things that you need to do to get this up and running:

1. Create a Launchpad account.
1. Create an OpenPGP key and upload it to your Launchpad account.
1. Create a new PPA.

The last two items are done in your Launchpad account page. There are other things you could do here as well. For instance, to work with git repositories hosted on Launchpad this is where you would upload your public SSH key(s). Ubuntu has a great guide on the specifics of setting up your environment, I highly recommend you read it for specifics.

## Creating the Debian package files

Now that we have our Python application/package all finished up, and Launchpad and a new PPA setup to receive our Debian package it’s time to create the necessary artifacts for making a deb. Start by creating a debian dir in the root of the repo.

*Note: For more information, see the official debian docs on required files.*

**debian/control** — the control file is what tells the packaging systems information about the package as well as what to do it with.

```
Source: python3-random-quote
Maintainer: Thomas Stringer <github@trstringer.com>
Build-Depends: debhelper,dh-python,python3-all,python3-setuptools
Section: devel
Priority: optional
Standards-Version: 3.9.6
X-Python3-Version: >= 3.6

Package: python3-random-quote
Architecture: all
Description: Get a random quote with Python.
Depends: ${python3:Depends},python3-requests
```

In my case, because I’m pushing up to a PPA the requirement is that it takes a source package (as opposed to a binary package). Because of this, my control file needs to include two paragraphs: one for the source, and one for the resultant binary package that my PPA will build for me.
The first (source) paragraph explains some information about the source package. A few very helpful references when writing your control file are:

- Debian documentation on control files and their fields (https://www.debian.org/doc/debian-policy/ch-controlfields.html#source-package-control-files-debian-control).
- Debian wiki article that explains the control file for Python projects (https://wiki.debian.org/Python/LibraryStyleGuide#debian.2Fcontrol).

The former link explains the mandatory (and optional) fields for the control file, and the latter link explains ones that are needed (and recommended) for Python applications. Used together, they should assist in making debian/control.

**debian/changelog** — this file explains what has changed since the last release. But of equal (more?) importance is that there is a standard with this file so that the packaging software can get the package and version information.

```
python3-random-quote (0.0.6) bionic; urgency=medium

  * Additional release.

 -- Thomas Stringer <thstring@microsoft.com>  Mon, 05 Aug 2019 14:47:24 -0400
```

You can see the format above is `<name> (<version>) <platform>; urgency=<urgency>`.

**debian/rules** — not much more than a Makefile (don’t forget tabs), this tells the build system what to do with the package. Thankfully there are many helpers here. Apparently you can use dh_make to generate this file (although I did not, but will in the future). But also using pybuild handles all of the typical build essentials for Python packages.

```
#! /usr/bin/make -f

#export DH_VERBOSE = 1
export PYBUILD_NAME = random-quote

%:
    dh $@ --with python3 --buildsystem=pybuild
```

**debian/compat** — as per the documentation, this is the debhelper compatibility level. Simply put, it should be a file with only the value 10 in it.

## Building and delivering the deb

Now that we have all of the deb files in place, it’s time to get it out to our PPA.

1. Locate the key ID that you pushed to Launchpad (this is so we can sign the package before we push it to our PPA): `$ gpg --list-keys`.
1. Build and sign the deb package from the repo root: `$ debuild -k"<key_id>" -S`.
1. Push the package to your PPA: `$ dput <ppa_uri> <source.changes>`. The **ppa_uri** can be found on your Launchpad PPA webpage (it’s in the format of `ppa:<username>/<ppa_name>`) and the source.changes file is what is generated from the debuild output.

A couple of things will happen now. After some time, Launchpad will email you and tell you whether your package was accepted or rejected. If rejected, it’ll give a reason why and you can fix the issue and re-upload.

If accepted, your PPA will then start building your package from source. The result of this is either a successful build or a failed build. In the event it fails, you can look at the package details in Launchpad and see what the build log says. But if it succeeds, then you are done! You have now published a deb to your own PPA.

## Installing the deb

This is most likely nothing new to most Linux users, but for completeness you can install the package by doing the following:

```bash
# apt-add-repository <ppa_uri>
# apt install <new_pkg_name>
```

And that’s it! If you want to see this in action from the package I deployed: `# apt-add-repository ppa:trstringer/ppa2 && apt install python3-random-quote`. After that (hopefully) succeeds, you should be able to run `rq` in your terminal and see the quote of the day.
