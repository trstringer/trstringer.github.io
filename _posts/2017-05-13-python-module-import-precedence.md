---
layout: post
title: Module Import Precedence in Python
categories: [Blog]
tags: [python]
---

I was recently troubleshooting a module import issue that was causing me to wonder how exactly Python determines which module to import. The background story there is I had pip install'd a module into site-packages. A module with the same name was in the directory of current module I was developing (not a great scenario out of the gate, but understand I had no control over that local module name conflict in this case).

In order to reverse engineer what Python is doing, I setup the following environment:

```
$ cd ~/dev/python
$ mkdir module_import_test
$ cd module_import_test
$ python3 -m venv venv
$ . venv/bin/activate
$ touch app.py
```

All I did there was create a test directory, a virtual environment (and activated it), and a test module file app.py.

Another important part to consider is the `PYTHONPATH` environment variable. On my machine, this is set to `/home/trstringer/dev/python`. This is important to remember!

Now, I wanted to reproduce with a module from PyPI. For this, I'm choosing the ever-so-popular requests module.

```
$ pip install requests
```

The following are the contents of app.py:

```python
import sys
import requests

for idx, path in enumerate(sys.path, 1):
    print(f'{idx} - {path}')

print(f'\nrequests module location - {requests.__file__}')
```

All I'm doing here is the following (effectively):

1. Importing the requests module (wherever it may be living)
1. Printing out the contents of sys.path (more on this later)
1. Displaying the __file__ attribute of the requests module (again, more on this later)

In my environment, take a look at this output:

```
1 - /home/trstringer/dev/python/module_import_test
2 - /home/trstringer/dev/python
3 - /usr/lib/python36.zip
4 - /usr/lib/python3.6
5 - /usr/lib/python3.6/lib-dynload
6 - /home/trstringer/dev/python/module_import_test/venv/lib/python3.6/site-packages

requests module location - /home/trstringer/dev/python/module_import_test/venv/lib/python3.6/site-packages/requests/__init__.py
```

Lots of information here. Let's disect this, working backwards. As you can see, the requests module was imported from my `<project_dir>/venv/.../site-packages` directory. That's expected. But the listing of directories from `sys.path` shows really great information about where Python looks when attempting to import a module.

## Breaking it all down

The first element of sys.path will be the current directory of the module that is running the import. In my case, that directory is ./module_import_test/.

If Python doesn't find the module in the local directory, it'll then move onto the paths specified in `$PYTHONPATH`. In my case, I only have the single directory which is item #2 listed above there.

And then Python will subsequently look through a handful of installation-specific directories, lastly looking in site-packages (my virtual environment).

What this means is that if I have a requests.py file in my module_import_test directory, that will throw everything off (which is what I was originally dealing with). Let's prove that:

```
# currently in the module_import_test directory
$ touch requests.py
$ python app.py
1 - /home/trstringer/dev/python/test4
2 - /home/trstringer/dev/python
3 - /usr/lib/python36.zip
4 - /usr/lib/python3.6
5 - /usr/lib/python3.6/lib-dynload
6 - /home/trstringer/dev/python/test4/venv/lib/python3.6/site-packages

requests module location - /home/trstringer/dev/python/test4/requests.py
```

Perfect! Now Python has found requests.py in the first directory it looked in, and it appears to have stopped there, no longer walking sys.path to find any other occurrences of another requests module. The original requests module that I pip install'd is no longer being imported.

Likewise, if I had a file requests.py living in my $PYTHONPATH then Python would import that and short-circuit the search, never looking in my site-packages folder where the real requests module lives.

## TL;DR the main takeaway

* Be familiar with how Python searches for a module when importing it by analyzing sys.path
* Understand and troubleshoot with module.__file__ to prove which path Python used to import a particular module
