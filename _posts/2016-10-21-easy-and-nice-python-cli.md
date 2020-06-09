---
layout: post
title: The easy (and nice) way to do CLI apps in Python
categories: [Blog]
tags: [python]
---

There are a few ways to do the command-line app thing in Python. I've done these few ways, and some of them have their pain-points and annoyances. So I reached out to the community to find what the better way is (I hate to say "best", as possibly there is something that is better than this).

## What is a CLI?

"CLI" stands for "command line interface". It's a type of application that is invoked through the command-line/terminal/shell/whatever. As a developer, power user, and a generally "more keyboard, less mouse" type of person, I use CLI apps all the time. And when I need write some custom software for myself, oftentimes the CLI fits my needs. And Python is a great language to churn out a quick CLI app.

## Filesystem structure

Here is my basic filesystem structure:

```
pycli/
├── README.md
├── install.sh
├── pycli
  ├── __init__.py
  ├── __main__.py
  ├── classmodule.py
  └── funcmodule.py
└── setup.py
```

As you can see above, I name the root directory of the CLI project to be whatever I want the CLI to be called (in this example case, the CLI is called and invoked by pycli).

## CLI sub directory

As you can see, there is only a single sub directory in the root CLI folder. I name it the same as the CLI app, but in more complex CLIs you may have multiple packages. Each of the sub directories would be the containers of each package. In my simple case (and for most of my CLIs) there is only a single package, which translates to a single sub directory. In this example, it is also named pycli/.

## __init__.py

This file (empty) is there to tell Python that directory contains a package. That's it. It could be empty just to have the simple indication, or it could have actual code that will run during initialization of the package itself.

## __main__.py

This is an important one. It's our entry point for the CLI, which will be indicated by our setup configuration in setup.py in the root directory. I have just some simple code here to show that "it works".

```python
import sys
from .classmodule import MyClass
from .funcmodule import my_function

def main():
    print('in main')
    args = sys.argv[1:]
    print('count of args :: {}'.format(len(args)))
    for arg in args:
        print('passed argument :: {}'.format(arg))

    my_function('hello world')

    my_object = MyClass('Thomas')
    my_object.say_name()

if __name__ == '__main__':
    main()
```

All this does is import a few other modules (see below), parse args passed to the CLI, and implements those imported module members (a simple function and a simple class).

## classmodule.py

An extremely simple (useless) class that is imported into __main__.py and instantiated there. Again, this is just to show the how of importing a class from a module in the same package.

```python
class MyClass():
    def __init__(self, name):
        self.name = name

    def say_name(self):
        print('name is {}'.format(self.name))
```

## funcmodule.py

Whereas `classmodule.py` shows how to define a class for `__main__.py` to import, `funcmodule.py` shows how to define a simple (useless) function that `__main__.py` can import and invoke.

```python
def my_function(text_to_display):
    print('text from my_function :: {}'.format(text_to_display))
```

## setup.py

Now back out to the root directory of the CLI source code. The `setup.py` file is what ties it all together and tells Python how to handle it.

```python
from setuptools import setup
setup(
    name = 'pycli',
    version = '0.1.0',
    packages = ['pycli'],
    entry_points = {
        'console_scripts': [
            'pycli = pycli.__main__:main'
        ]
    })
```

At first glance, this may look complicated. But all we're doing here is importing the `setup` function from the `setuptools` package and calling it with a few parameters. Most of those will be self-explanatory. The `packages` argument is just a list that indicates all of the include packages. If you recall from above, this CLI has a single package also named `pycli`.

`entry_points` is the important part here. It's what indicates (with a string) what the runnable application will be called, and when run what exactly should be invoked. Here it says `pycli = pycli.__main__:main`. That might look really confusing, but here's how this translates: "the runnable will be called `pycli`, and when executed it will run the `main` function in the `__main__` module which is part of the `pycli` package. That's it!

## install.sh

The best way to install (and uninstall) your Python CLI app is to use pip (`pip3` for Python 3). In the root directory of the CLI source code, running `pip3 install .` will install this app using setup.py as "instructions". Likewise, running `pip3 uninstall pycli` will remove the app.

I decided to put this logic in a shell script so that I didn't have to always manually type out these commands (which gets very tedious when you are actively developing a CLI app). So I dump it all in a shell script.

```
pip3 install -e .
```

Now all I have to do is run `install.sh` to "recycle" the CLI on my machine with current source code.

*Note: Thanks for all the suggestions on making this a better install script with the -e switch!*

## Summary

For me, CLI apps are absolutely crucial. And Python makes it a breeze to write the code for them. With this approach I've found an easy way to write these types of apps… quickly. For reference source code on a simple CLI app in Python check out [the accompanying repository on GitHub](https://github.com/trstringer/pycli).
