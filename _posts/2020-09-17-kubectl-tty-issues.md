---
layout: post
title: Beware of kubectl's -t (--tty) Option
categories: [Blog]
tags: [kubernetes, devops]
---

I see this all over the place in documentation, blog posts, scripts, articles, etc:

```
kubectl exec -it my-pod -- do_something_here
```

These type options have the following help text:

```
  -i, --stdin=false: Pass stdin to the container
  -t, --tty=false: Stdin is a TTY
```

Using these options in a script can cause a tricky bug, though. Take a look at this example that just does a common `kubectl exec` to get some data from a pod:

```bash
#!/bin/bash

EXPECTED_OUTPUT="hello world"
ACTUAL_OUTPUT=$(kubectl exec -it my-pod -- echo hello world)

echo "  Actual output: $ACTUAL_OUTPUT"
echo "Expected output: $EXPECTED_OUTPUT"

if [[ "$ACTUAL_OUTPUT" == "$EXPECTED_OUTPUT" ]]; then
    echo "Yes! $ACTUAL_OUTPUT matches $EXPECTED_OUTPUT"
else
    echo "No... $ACTUAL_OUTPUT does not match $EXPECTED_OUTPUT"
fi
```

Read the code and try to predict the output. The first two lines are expected (sort of):

```
  Actual output: hello world
Expected output: hello world
```

These two strings are obviously the same. Right? Wrong! The third echo from the script starts to give us hints of that:

```
 does not match hello world
```

That is shocking! Not only did `[[ "$ACTUAL_OUTPUT" == "$EXPECTED_OUTPUT" ]]` evaluate to false (we know that by the "does not match" part of the output), but the echo looks strange. It appears to be missing the *"No... hello world"* part of the output string.

So what is going on here? There is a subtle bug that you wouldn't expect.

Let's see what the byte output is when you use `-t`:

```bash
 $ kubectl exec -it my-pod -- echo hello world | od -c -
0000000   h   e   l   l   o       w   o   r   l   d  \r  \n
0000015
```

There's our problem! Because of the TTY, we have an additional carriage return (`\r`) added. Let's remove `-t` (and naturally remove `-i`, because we don't want an interactive session either):

```bash
 $ kubectl exec my-pod -- echo hello world | od -c -
0000000   h   e   l   l   o       w   o   r   l   d  \n
0000014
```

This is what we would expect and desire: Just a `\n` and not `\r\n` in the output.

After you fix your script you should see the expected behavior:

```bash
#!/bin/bash

EXPECTED_OUTPUT="hello world"
ACTUAL_OUTPUT=$(kubectl exec my-pod -- echo hello world)

echo "  Actual output: $ACTUAL_OUTPUT"
echo "Expected output: $EXPECTED_OUTPUT"

if [[ "$ACTUAL_OUTPUT" == "$EXPECTED_OUTPUT" ]]; then
    echo "Yes! $ACTUAL_OUTPUT matches $EXPECTED_OUTPUT"
else
    echo "No... $ACTUAL_OUTPUT does not match $EXPECTED_OUTPUT"
fi
```

Output:

```
  Actual output: hello world
Expected output: hello world
Yes! hello world matches hello world
```

In summary, be mindful when you're writing your `kubectl exec` commands, especially in a script! You should not be using `-it` in a script, or any other time that you don't actually need an interactive session.
