---
layout: post
title: Running External Commands in Python (Shell or Otherwise)
categories: [Blog]
tags: [linux, python]
---

**TLDR**

You probably want:

```python
import subprocess
import sys

try:
    cp = subprocess.run(
        ["echo", "hello world"],
        capture_output=True,
        check=True,
        text=True,
    )
    print(cp.stdout)
except subprocess.CalledProcessError as cpe:
    print(cpe.stderr, end="")
    sys.exit(cpe.returncode)
```

If you _absolutely_ need a shell and/or have to run multiple commands, you can do this:

```python
import subprocess
import sys

cp = subprocess.run(
    "echo hello world",
    shell=True,
    text=True,
    # Send stderr to stdout and don't automatically throw an exception in order
    # to replicate checking the output of a shell command.
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
print(cp.stdout)
if cp.returncode != 0:
    print(f"Error! {cp.returncode}")
    # Maybe exit if you shouldn't continue on failure
    sys.exit(cp.returncode)
```

Ok, now for some detailed discussion.

## Intro

Python is used for a _lot_ of software. Maybe you're writing a web server, perhaps it's a data science application. In many cases, you never need to interact with the underlying system OS. Conversely there are many other software disciplines, like SRE and ops, where we are doing a lot of complex logic with the system. The typical tool to accomplish this is shell scripts, but it's common to have long and hard to maintain scripts.

Python is a much easier language to deal with. But that doesn't remove a typical requirement of having to run commands against the OS. In times past that has been a challenge, but Python 3.5 introduced [`subprocess.run`](https://docs.python.org/3/library/subprocess.html#subprocess.run), which is a _very_ helpful wrapper over some more complex subprocess logic that makes it a lot easier to use.

So for the large majority of requirements, `subprocess.run` is what you want to use. This entire blog post focuses on this single function.

## Shell or no shell?

This is probably one of the biggest questions that comes up. Do I set `shell` or not? The answer to the question is unfortunately redundant, straightforward, and not helpful at all: Set `shell` if you need a shell. For many programmers, they aren't really sure if a shell is needed. Oftentimes we just open up our terminal and type things in to run them, and now we want our Python code to do the same. The short answer is that you _only_ need a shell if you require shell syntax and/or are running multiple commands at once. For instance, if you want your Python code to run the executable `my_cool_bin` with a few arguments, you don't need a shell. But if you want to do something more elaborate like piping output into other binaries: `my_cool_bin`: `my_cool_bin | grep some_string | awk '{print $1}'`. Then you need to use the shell.

Here is my general guidance: **Do not use a shell if you can avoid it**. And if you find yourself needing a shell like in the example above, try to refactor your code so that you don't need a shell. In the example above I'm piping the output of `my_cool_bin` to search for some string with `grep`, and then piping that to `awk` to extract some of the text. That certainly requires a shell. But I could refactor this so that `grep` and `awk` functionality are handled in my Python code and I don't need to pipe anything. So now I'm back to running `my_cool_bin` without a shell. Just remember that string filtering and searching are pretty easy in Python, so you don't have to do _everything_ in a shell.

Let's take a step back. What exactly happens when you set `shell=True`? Let's see:

Without a shell...

```python
cp = subprocess.run(["sleep", "60"])
```

And then from another terminal if I use `ps` to see what this process is running I see it is just doing:

```
sleep 60
```

Makes sense. `sleep` is the binary and the list of arguments is just `60`.

Now let's use a shell:

```python
cp = subprocess.run("sleep 60", shell=True)
```

Using `ps` again, we can now see that our process is running a shell:

```
/bin/sh -c sleep 60
```

Which in turn starts _another_ process that runs `sleep 60`.

Note: Why did I use a string for the shell instead of a list of strings? More on that soon.

This example is a bit contrived (you could just sleep directly in Python), but it highlights that we don't need to, and therefore shouldn't, use a shell to run this code. We can cut out the middle shell process by just running the `sleep` process directly.

So what exactly happens when you specify `shell`?

```python
subprocess.run("echo hello world", shell=True)
```

This is just shorthand for:

```python
subprocess.run(["/bin/sh", "-c", "echo hello world"])
```

Nothing more, nothing less.

Another often-overlooked detail with the shell, let's say you _don't_ want to use `/bin/sh` for your shell. I run Debian and `/bin/sh` is symlink'd to `/usr/bin/dash`, which is a Debian bash-like shell. There's a good chance that I'd rather just use `/bin/bash` as my shell though. How can I control that with setting `shell=True`? I can't. I need to explicitly specify `bash`:

```python
subprocess.run(["/bin/bash", "-c", "echo hello world"])
```

You have to know what `/bin/sh` resolves to on your target machine if you want to know exactly what shell is being used with `shell=True`: `ls -la /bin/sh` should give you a good idea. Or more precisely, you can run:

```bash
/bin/sh -c 'readlink -f /proc/$$/exe'
```

On my Debian machine I get `/usr/bin/dash`. Not the ever so common `bash` shell.

## List of strings or one long string

The first parameter of `subprocess.run` is the args that you're running. It can either be a list of strings or a string. So... which one do you use?

TLDR:

- Using a shell? Use a string `str`: `"echo hello world"`
- Not using a shell? Use a list of strings `list[str]`: `["echo", "hello world"]`

Let's see some examples.

What happens if I'm not using a shell and try to use one long command string?

```python
subprocess.run("echo hello world")  # shell defaults to False
```

I get the error:

```
FileNotFoundError: [Errno 2] No such file or directory: 'echo hello world'
```

That's because the first string is supposed to be the bin. So if I put it all in a single string it will try to locate an executable named exactly that. In my case, there is no binary `echo hello world` anywhere in my path. The correct way would be:

```python
subprocess.run(["echo", "hello world"])
```

My binary is `echo` and my args are just a single string `"hello world"`. This works as intended.

It's a little of the opposite when you use a shell though. If I run this:

```python
subprocess.run(["sleep", "60"], shell=True)
```

I get an error:

```
sleep: missing operand
Try 'sleep --help' for more information.
```

Which might seem odd at first. After all, I _did_ pass an operand. Or at least I thought I did. Remember from above how this is expanded out:

```python
subprocess.run(["/bin/sh", "-c", "sleep", "60"])
```

Which is essentially running `/bin/sh -c sleep 60`. You're passing a single string `sleep` to the `-c` param of `/bin/sh` which causes the error. `60` is not contained in the command parameter. So we should instead do:

```python
subprocess.run(["/bin/sh", "-c", "sleep 60"])
```

Which can be abbreviated as:

```python
subprocess.run("sleep 60", shell=True)
```

One final note about string vs list of strings for the args. Let's say you aren't using a shell but for whatever reason you really want to do one long string. Python provides [`shlex.split`](https://docs.python.org/3/library/shlex.html#shlex.split) to split the string with "shell-like syntax". Our first example can be fixed if we do this instead:

```python
import shlex
import subprocess

subprocess.run(shlex.split("echo hello world"))
```

This is because `shlex.split` takes the string and does a pretty good job splitting it so that it can be run as a list of strings.

## Error handling

It's a common requirement to check the status code of a command you just ran in a shell script. It's not different when running these things in a Python script. This can be checked with `CompletedProcess.returncode`.

```python
cp = subprocess.run(["ls", "nonexistent"], capture_output=True)
print(f"Return code: {cp.returncode}")
```

I get the output: `Return code: 2` as expected.

If I wanted to replicate the behavior of `set -e` in a shell, specify `check=True`. This is great if you want to halt the script or explicitly catch a `CalledProcessError` exception:

```python
try:
    cp = subprocess.run(
        ["ls", "nonexistent"],
        check=True,
        capture_output=True,
        text=True,
    )
    print(cp.stdout)
except subprocess.CalledProcessError as cpe:
    print(cpe.stderr, end="")
    sys.exit(cpe.returncode)
```

Which results in:

```
ls: cannot access 'nonexistent': No such file or directory
```

`CompletedProcess` also provides a helper to raise an exception if it's a non-zero return code:

```python
cp = subprocess.run(["ls", "nonexistent"], capture_output=True)
cp.check_returncode()
```

If I don't handle this exception I get a familiar Python stack dump:

```
Traceback (most recent call last):
  File "/home/trstringer/dev/python/shelling-out/main.py", line 60, in <module>
    cp.check_returncode()
    ~~~~~~~~~~~~~~~~~~~^^
  File "/usr/lib/python3.13/subprocess.py", line 508, in check_returncode
    raise CalledProcessError(self.returncode, self.args, self.stdout,
                             self.stderr)
subprocess.CalledProcessError: Command '['ls', 'nonexistent']' returned non-zero exit status 2.
```

Maybe that's what you want. Or maybe you want to wrap this all in a try except block.

## Piping from stdin

If you wanted to pass-through stdin to your subprocess then you should just have to specfify `stdin=sys.stdin`:

```python
cp = subprocess.run(
    ["grep", "py"],
    stdin=sys.stdin,
    capture_output=True,
)
print(cp.stdout.decode(), end="")
```

Now when I run this from my terminal:

```bash
ls -la | python3 main.py
```

I see that my `ls` output was piped through stdin into my subprocess:

```
-rw-rw-r--  1 trstringer trstringer 1442 Apr  6 13:28 main.py
```

That's a fairly unusual case, though. It's typical to want to take stdin input from your Python code, but oftentimes you want to modify it before passing it into your subprocess:

```python
stdin_lines = "".join(
    [f"{line.rstrip('\n')} hello world\n" for line in sys.stdin.readlines()]
)

cp = subprocess.run(
    ["grep", "py"],
    input=stdin_lines.encode(),
    capture_output=True,
)
print(cp.stdout.decode(), end="")
```

This is a contrived example of me taking stdin and then appending a string "hello world" onto the end of each line. And then I pass that input into my subprocess.

```bash
ls -la | python3 main.py
```

Now outputs:

```
-rw-rw-r--  1 trstringer trstringer 1581 Apr  6 13:46 main.py hello world
```

## Combining stdout and stderr

If you want to combine stdout and stderr, which is really common, then you want to make a few changes. Before you understand the changes though, it's best to understand what exactly `capture_output` does. This invokes `Popen` to set both `stdout` and `stderr` to `subprocess.PIPE`. This is why their respective output is contained in the completed process's `stdout` and `stderr` properties. So if we want to combine them, we will not use `capture_output`, and instead be explicit about where we want to send `stdout` and `stderr`. In this case, if we want `stderr` to go to `stdout`, then we redirect it by setting it to `subprocess.STDOUT`. Because we don't have `capture_output` set, we need to explicitly set `stdout` to `subprocess.PIPE`.

```python
cp = subprocess.run(
    "echo hello ; ls nonexistent ; echo world",
    shell=True,
    stdout=subprocess.PIPE,
    stderr=subprocess.STDOUT,
)
print("Stdout:")
print(cp.stdout.decode(), end="")
```

Output:

```
Stdout:
hello
ls: cannot access 'nonexistent': No such file or directory
world
```

## Writing output to a file

This is not a typical scenario, but perhaps you want to write the output of your subprocess to a file. You can accomplish this by sending all output, stdout and stderr, to an open file:

```python
with open("my_output", "w") as outfile:
    subprocess.run(
        ["ls", "-la"],
        stderr=subprocess.STDOUT,
        stdout=outfile,
    )
```

After this runs, I can see that I now have a new file `my_output` with the contents of `ls -la`.

## Summary

A lot of us are writing Python to interact with the underlying OS. Instead of writing complex shell scripts, we can take all the benefits of Python and still make our system calls. Hopefully this blog post has showed a modern way to interact with the system from Python!
