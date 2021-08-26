---
layout: post
title: Search All Files Including Dot Files and Dot Directories in Vim
categories: [Blog]
tags: [linux,vim]
---

Searching through files in your text editor is one of the most common and basic operations. But when you start mixing in dot files (`.example_file`) and dot dirs (`.example_dir/`) then it can get a little trickier than you would think in Vim. Let's take this example structure:

```
$ tree -a
.
├── .dot1
├── .dotdir1
│   ├── .dot3
│   └── normal3
├── normal1
└── normaldir1
    ├── .dot2
    └── normal2

2 directories, 6 files
```

You can see we have a mixture of all variations with dot and normal files and dirs. There are six files in total:

- `.dot1`
- `normal1`
- `normaldir1/.dot2`
- `normaldir1/normal2`
- `.dotdir1/.dot3`
- `.dotdir1/normal3`

Each of these files contains the text `hello world`. So now let's start searching with vimgrep (`:h vim`):

```
:vim /hello/ **/*

normal1|1 col 1| hello world
normaldir1/normal2|1 col 1| hello world
```

So that found our two normal files that do *not* live in dot directories. Of course we want to search more here:

```
:vim /hello/ **/* **/.*

normal1|1 col 1| hello world
normaldir1/normal2|1 col 1| hello world
.dot1|1 col 1| hello world
normaldir1/.dot2|1 col 1| hello world
```

Getting closer. Now we add our dot files to that list, but we are still missing some files: We didn't search through the dot directory `.dotdir1/`. That is where it gets a lot trickier. If we add the file search express `.**/*` then we will start searching through `../`, which is the parent directory of where Vim currently is. It is very unlikely that this is desired.

I recently learned about this really cool workaround to be able to search all files, including dot files and files in dot directories.

```
:args `find . -type f`
:vim /hello/ ##

./.dotdir1/.dot3|1 col 1| hello world
.dotdir1/normal3|1 col 1| hello world
.dot1|1 col 1| hello world
normaldir1/normal2|1 col 1| hello world
normaldir1/.dot2|1 col 1| hello world
normal1|1 col 1| hello world
```

Great! That found all six of our files, no matter what they are named and what directories they are in. How did it do that? The first command populates the arg list, which is the listing of files that are passed to Vim on startup. So we clear that arg list and populate it with the result of `find . -type f`, which is all files. Then we do our normal vimgrep search, but this time we reference the arg list with `##`.

This is a really neat trick that solves this problem!
