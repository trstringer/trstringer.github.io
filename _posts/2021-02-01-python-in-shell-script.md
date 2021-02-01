---
layout: post
title: Run Python Code in a Shell Script
categories: [Blog]
tags: [linux,python,devops]
---

I'm a **big** fan of "the right tool for the right job". For some things, the right tool is a shell script. For others, it is Python. But sometimes... it is both.

A lot of times I find myself writing a shell script and wanting a *little* extra complexity than I care for in a shell script. Sometimes, it is easier to write a few lines in Python than trying to figure it out in a shell script. But... sometimes it is also convenient not to maintain (or transfer) an entire Python file (.py) to contain this logic.

## Ad hoc Python in a shell script

So what can you do? Put your Python directly in your shell scripts! How can you do this? Construct your multiline Python string and then pass the ad hoc Python code in with the `-c` parameter. An example:

**days_remaining.sh**

```bash
#!/bin/bash

PYCMD=$(cat <<EOF
from datetime import datetime

first_day_of_new_year = datetime(2022, 1, 1)

days_remaining = (first_day_of_new_year - datetime.now()).days
print('{} days remaining in this year'.format(days_remaining))
EOF
)

python3 -c "$PYCMD"
```

And now for the sake of completeness:

```
$ ./days_remaining.sh
335 days remaining in this year
```

## Indentation

There are a couple of ways to do multiline strings in a shell script, and this one of using here-documents (`<<`) for string redirection is the cleanest looking one and easiest to remember. Since I use spaces and not tabs, I'm not able to take advantage of `<<-` removing leading tabs, so I need to be careful with my indentation.

Let's say we had our Python code indented in the shell script. Maybe it's in a loop, or a function like this:

```bash
#!/bin/bash

get_remaining_days () {
    PYCMD=$(cat <<EOF
    from datetime import datetime
    
    first_day_of_new_year = datetime(2022, 1, 1)
    
    days_remaining = (first_day_of_new_year - datetime.now()).days
    print('{} days remaining in this year'.format(days_remaining))
    EOF
    )

    python3 -c "$PYCMD"
}

get_remaining_days
```

This might look ok, but it isn't correct syntax:

```
$ ./days_remaining.sh
./days_remaining.sh: line 4: unexpected EOF while looking for matching `)'
./days_remaining.sh: line 18: syntax error: unexpected end of file
```

For both the here-document and the Python code, we need to keep the code unindented. Here is the correct form:

```bash
#!/bin/bash

get_remaining_days () {
    PYCMD=$(cat <<EOF
from datetime import datetime

first_day_of_new_year = datetime(2022, 1, 1)

days_remaining = (first_day_of_new_year - datetime.now()).days
print('{} days remaining in this year'.format(days_remaining))
EOF
    )

    python3 -c "$PYCMD"
}

get_remaining_days
```

## Debugging Python inside a shell script

Code doesn't work the way we think it should all the time. Debugging is a necessary part of any software development, and you might need to debug that Python code that is directly in your shell scripts too.

As a Python programmer, we're quite familiar with setting a breakpoint in code with `import pdb; pdb.set_trace()`. So let's put that breakpoint in our shell script and see what happens:

```bash
#!/bin/bash

PYCMD=$(cat <<EOF
from datetime import datetime

first_day_of_new_year = datetime(2022, 1, 1)

import pdb; pdb.set_trace()

days_remaining = (first_day_of_new_year - datetime.now()).days
print('{} days remaining in this year'.format(days_remaining))
EOF
)

python3 -c "$PYCMD"
```

```
$ ./days_remaining.sh
> <string>(7)<module>()
(Pdb) l .
[EOF]
(Pdb) first_day_of_new_year
datetime.datetime(2022, 1, 1, 0, 0)
(Pdb) datetime.now()
datetime.datetime(2021, 1, 30, 14, 41, 13, 475833)
(Pdb)
```

Hmmm we have a partial debugging experience (because we passed in ad hoc code to Python with `-c`). We can analyze the code, but it's hard to know where we are, especially when we are stepping through the code, because it can't show any lines of code. Typically when you do `l .` in the debugger, it'll list the current line of code that the debugger is on and some surrounding lines of code. Very useful and almost necessary for proper debugging.

How can we get around this? Create a temporary file and dump the Python code directly to it and then pass the file directly to Python for a full debugging experience:

```bash
#!/bin/bash

PYCMD=$(cat <<EOF
from datetime import datetime

first_day_of_new_year = datetime(2022, 1, 1)

import pdb; pdb.set_trace()

days_remaining = (first_day_of_new_year - datetime.now()).days
print('{} days remaining in this year'.format(days_remaining))
EOF
)

TEMP_SCRIPT=$(mktemp)
echo "$PYCMD" > "$TEMP_SCRIPT"
python3 "$TEMP_SCRIPT"

# python3 -c "$PYCMD"
```

```
$ ./days_remaining.sh
> /tmp/tmp.ZDdkh5A4me(7)<module>()
-> days_remaining = (first_day_of_new_year - datetime.now()).days
(Pdb) l .
  2
  3     first_day_of_new_year = datetime(2022, 1, 1)
  4
  5     import pdb; pdb.set_trace()
  6
  7  -> days_remaining = (first_day_of_new_year - datetime.now()).days
  8     print('{} days remaining in this year'.format(days_remaining))
[EOF]
(Pdb) first_day_of_new_year
datetime.datetime(2022, 1, 1, 0, 0)
(Pdb) n
> /tmp/tmp.ZDdkh5A4me(8)<module>()
-> print('{} days remaining in this year'.format(days_remaining))
(Pdb) days_remaining
335
(Pdb)
```

Great! Now we can debug the Python code with all of the features and comfort of pdb.

## Warnings and final thoughts

If you do find your embedded ad hoc Python code getting long, it's probably a good idea to move that to a separate file so that it can be properly tested and maintained. Or perhaps even just write the whole utility in Python and forget about the shell script approach!

Hopefully this blog post has illustrated the flexibility of embedding Python code directly in your shell scripts to make the development experience a bit better than having to solve *all* problems just in shell scripting!
