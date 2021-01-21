---
layout: post
title: Using xargs to Construct Dynamic Commands
categories: [Blog]
tags: [linux]
---

Without a doubt, one of my most-used commands in the terminal is [xargs](https://man7.org/linux/man-pages/man1/xargs.1.html). This utility takes standard input and can dynamically build and execute commands. In this blog post I'll show common usages of xargs, as well as some tricks I've picked up along the way.

## Parameters you probably want

For the sake of demostration, we're going to use this input:

```
$ printf "line1\nline2\nline3\n"
line1
line2
line3
```

If you were to pipe this directly to xargs, you'd get this output:

```
$ printf "line1\nline2\nline3\n" | xargs echo hello
hello line1 line2 line3
```

By default, xargs will put *all* of the input in as arguments to the generated command. This might be default, but it is *probably not* what you're looking for. Typically you just want a single input as a single argument for xargs. We can force that by specifying `--max-args` (or `-n` for short) and setting that to 1:

```
$ printf "line1\nline2\nline3\n" | xargs -n 1 echo hello
hello line1
hello line2
hello line3
```

That's better! But what happens if we have no input into xargs?

```
$ echo | xargs -n 1 echo hello
hello
```

We get the xargs generated command run with *no* arguments. That's the default behavior, but again probably not what you want. This example might not illustrate why this could be bad, so let's try another example:

```
$ ls *.notreal | xargs -n 1 rm
ls: cannot access '*.notreal': No such file or directory
rm: missing operand
Try 'rm --help' for more information.
```

Even though there was no input to xargs (because there were no files that matched `*.notreal`), xargs still tried to run `rm` with no arguments (which is why we got the error `rm: missing operand`). To prevent xargs from running empty commands with no arguments, you should pass in `--no-run-if-empty` (or `-r` for short):

```
$ ls *.notreal | xargs -rn 1 rm
ls: cannot access '*.notreal': No such file or directory
```

Now you can see that xargs does not try to run `rm` with zero arguments. The above shows why I typically run xargs with `-rn` in 99% of my use-cases!

## Put elements in the middle (not append)

By default, xargs appends the input to the command:

```
$ printf "line1\nline2\nline3\n" | xargs -rn 1 echo hello world
hello world line1
hello world line2
hello world line3
```

But what if you wanted to insert the input into the middle of the command, instead of the end? You could use `-I` to specify a string that should be used as a placeholder for inserting:

```
$ printf "line1\nline2\nline3\n" | xargs -rn 1 -I{} echo hello {} world
hello line1 world
hello line2 world
hello line3 world
```

This allowed us to replace all occurrences with `{}` with the single argument input.

## Multiple commands from input

So xargs is good at running a single command with the input, but what if you want to run multiple commands? Use the same param from above for replacement, `-I`, and pass the commands as a string to `/bin/bash`:

```
$ ls *.txt | xargs -r -I{} /bin/bash -c "echo ... current file {}; grep search {}"
... current file file1
... current file file2
this is a search line
searching for stuff
... current file file3
... current file file4
more search here
... current file file5
```

This is one way you can grep files but also know which file the match came from (yes, I know `grep` can give you this information, but this is just used as an example when you might need multiple commands for a single argument input).

## Echo first, run later

Oftentimes xargs can be used to generate commands that change things (for instance, delete files). My recommendation is that, like most things with software, you validate before you make changes. With xargs that is as simple as putting an `echo` in front of the mutating command:

```
$ ls *.txt | xargs -rn 1 echo rm
rm file1
rm file2
rm file3
rm file4
rm file5
```

This just ran `echo rm` for all the input arguments, but it didn't actually do anything. After you inspect the commands that would run, you can just remove the `echo` from the xargs command to actually delete the files.

## Summary

I really love the flexibility and efficiency that xargs gives me in the terminal and my shell scripts. Being able to utilize it to its full capability can be powerful!
