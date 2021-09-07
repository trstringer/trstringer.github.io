---
layout: post
title: Common Scenarios with Bash Parameter Expansion
categories: [Blog]
tags: [linux]
---

When creating bash shell scripts, sometimes one of the toughest things to accomplish is basic parameter and string operations. Or conversely, when *reading* a shell script this notation can be quite confusing! This blog post will highlight and illustrate some of the more common expansion tricks, but reference the [bash manual on Shell Parameter Expansion for the full documentation](https://www.gnu.org/software/bash/manual/html_node/Shell-Parameter-Expansion.html).

## Parameters and defaults

One of the most common uses of parameter expansion is to have a default value for a variable.

```bash
MY_VAR=${OPTIONAL_VAR:-my default value}
echo "$MY_VAR"

OPTIONAL_VAR="not default"
MY_VAR=${OPTIONAL_VAR:-my default value}
echo "$MY_VAR"
```

The output is:

```
my default value
not default
```

This can also be an expression!

```bash
DISTRO=${OPTIONAL_DISTRO:-$(lsb_release -i)}
```

In certain situations, something that is less code is to just set the value of the variable itself and then return it with `=`. This is a single variable approach to a similar problem:

```bash
echo "${OPTIONAL_VAR:=hello world}"
echo "Optional variable is $OPTIONAL_VAR"
```

The output is:

```
hello world
Optional variable is hello world
```

I would argue that this is harder on the reader, though. I prefer the more verbose approach with `-`.

What if you need to require a variable to run your script? The common approach is to do something like:

```bash
if [[ -z "$REQUIRED_VAR" ]]; then
    echo "You must set REQUIRED_VAR"
    exit 1
fi
echo "Required variable is $REQUIRED_VAR"
```

This same thing can be accomplished with parameter expansion:

```bash
echo "Required variable is ${REQUIRED_VAR:?}"
```

If `REQUIRED_VAR` isn't set, you would get an error message:

> REQUIRED_VAR: parameter null or not set

You could customize that message as well:

```bash
echo "Required variable is ${REQUIRED_VAR:?You must set REQUIRED_VAR to some required data}"
```

Now the error message (if `REQUIRED_VAR` is still unset) is:

> REQUIRED_VAR: You must set REQUIRED_VAR to some required data

## Substrings

If you have spent any time programming in other languages (Python, Java, C++, etc) getting substrings is usually easy and effortless. Bash provides this functionality through parameter expansion, but it might seem slightly less obvious than you are used to.

Let's work with this string:

```bash
MY_STRING="hello world"
```

If you want to get the leading characters, you would use `${MY_STRING:0:2}`. The first number `0` is the offset (so the beginning of th string) and the second number `2` is the length.

Need to get the trailing characters? This is a little trickier, but you would do `${MY_STRING: -3}` to get the three trailing characters. Note that you need to have a space after the `:` so it doesn't interpret it as a different parameter expansion!

## Other scenarios

One of the more common tasks is to change a string to all upper-case or all lower-case.

```bash
MY_STRING="Hello World"

echo "${MY_STRING@U}"
echo "${MY_STRING@L}"
```

The output is:

```
HELLO WORLD
hello world
```

## Summary

Bash is a really powerful platform, and there are a lot of things you can do when writing your shell scripts. Hopefully this blog post has showed how you can use parameter expansion to accomplish some of these tasks!
