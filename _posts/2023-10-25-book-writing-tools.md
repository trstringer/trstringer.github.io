---
layout: post
title: Tools and Processes I Used For Writing My Book
categories: [Blog]
tags: [software-development,linux,vim]
---

This past year I [published my first book](https://trstringer.com/tabs/book/). While it was a rewarding experience, there were many challenges and obstacles along the way. But one thing I did in the beginning was figure out tooling so that writing and reviewing the book wasn't a painpoint. I'm a Linux user and it was on Linux that I wrote this book, but the tooling should work on MacOS or Windows as well.

The editor that I used is Vim. While many would consider Vim a barebones editor, I have used it for longer than I can remember for all editing, both for code and non-code requirements.

## Version control

I'll keep this section short, because my audience likely already uses version control for their code. There's no reason not to use this for writing a book, and many good reasons for doing so. In the event you want to see a past version of your book or revert parts of it, Git can help here. Not to mention, utilizing tags to handle book versions can be helpful if you expect to be releasing multiple versions of your book in the future.

## Directory structure

An important part of building the book (below) is the directory structure.

```
├── chapter_00_preface
│   └── README.md
├── chapter_01_intro_to_git
│   └── README.md
├── chapter_02_intro_to_github
│   └── README.md
├── chapter_03_issues_and_pull_requests
│   └── README.md
├── chapter_04_projects
│   └── README.md
├── chapter_05_actions_and_workflows
│   └── README.md
├── chapter_06_runners
│   └── README.md
├── chapter_07_artifacts_and_releases
│   └── README.md
├── dist
│   └── devops_with_github.pdf
├── front_cover_printed.pdf
├── images
│   ├── chapter_01_01.png
│   ├── chapter_01_02.png
│   ├── ...
│   ├── chapter_02_01.png
│   ├── chapter_02_02.png
│   └── ...
├── Makefile
└── README.md
```

### Chapter content

Each chapter gets its own directory named `chapter_<number>` where `number` is zero prefixed for single digits. This is important for building so that it is sorted correctly.

In each chapter directory there is a single file: `README.md`. This contains the actual chapter text. Each of these chapters starts out with the following text:

```
\pagebreak

# Chapter 1 - Introduction to Git
```

I needed `\pagebreak` to ensure that each chapter started on its own page, regarless of the previous text. And then, unsurprisingly, I wanted the chapter header to start off each chapter.

### dist

When I build the book, I want it to be sent to the `dist` directory. This is what I oftentimes do with code, and it seemed like a good place for the book the end up in as well.

### Front cover

The file `front_cover_printed.pdf` is the front cover of the book. This will be used when the book is built.

### Images

I put _all_ of the book's images into this directory. It made it easy within the chapters themselves to use this known directory, and when taking screenshots and making diagrams it meant I didn't have to think at all where to put the image.

### Makefile

I rely heavily on `make` as my book tooling "API". I have the following make targets:

* `build` - Build the book PDF
* `open` - Helper one-liner to open up the book PDF
* `info` - Display word and page count by chapter
* `todo` - Show all `TODO` comments in the book
* `deps` - Install all build and tooling dependencies

## Dependencies

In the event that I needed to reinstall dependencies to continue writing the book I wanted to make sure I had all the required dependencies recorded:

```bash
sudo apt install -y pandoc texlive-luatex texlive-full pdftk poppler-utils
```

Your dependencies may vary depending on your distribution or OS, but hopefully that's a good starting point to find package parity.

## Building the book

Here is my make target to build the book:

```
DIST_DIR=./dist
IMAGES_DIR=./images
BOOK_FILENAME=devops_with_github.pdf
BOOK_PATH_AND_FILENAME=$(DIST_DIR)/$(BOOK_FILENAME)
BOOK_PATH_AND_FILENAME_TMP=$(BOOK_PATH_AND_FILENAME).tmp
FRONT_COVER_FILENAME=front_cover_printed.pdf

.PHONY: build
build:
	mkdir -p $(DIST_DIR)
	time pandoc -s -o $(BOOK_PATH_AND_FILENAME) \
		--pdf-engine=lualatex \
		-V geometry:margin=1in \
		-V linestretch=1.4 \
		-V mainfont="DejaVu Sans" \
		--toc --toc-depth=3 \
		--highlight-style=zenburn \
		./chapter_*/README.md
	pdftk $(FRONT_COVER_FILENAME) $(BOOK_PATH_AND_FILENAME) cat output $(BOOK_PATH_AND_FILENAME_TMP)
	rm $(BOOK_PATH_AND_FILENAME)
	mv $(BOOK_PATH_AND_FILENAME_TMP) $(BOOK_PATH_AND_FILENAME)
```

This essentially uses `pandoc` to generate the book from all of the `./chapter_*/README.md` files. Then it adds the front cover image to the beginning of the boook for the final result.

## Getting book info

It was really important to me that I was able to keep track of progress for each chapter. And of course, I wanted to automate this so all I had to do was run `make info` to get some valuable book/chapter information:

```
.PHONY: info
info: build
	@echo
	@echo "Word count summary..."
	@wc -w ./chapter_*/README.md
	@echo
	@echo "Page count summary..."
	@pdfinfo $(BOOK_PATH_AND_FILENAME) | grep Pages
```

```
$ make info
Word count summary...
   260 ./chapter_00_preface/README.md
  4955 ./chapter_01_intro_to_git/README.md
  5349 ./chapter_02_intro_to_github/README.md
  5823 ./chapter_03_issues_and_pull_requests/README.md
  1261 ./chapter_04_projects/README.md
  9553 ./chapter_05_actions_and_workflows/README.md
  7478 ./chapter_06_runners/README.md
  1723 ./chapter_07_artifacts_and_releases/README.md
 36402 total

Page count summary...
Pages:           178
```

This helps me understand if a chapter is getting too long and how it compares to other chapters in the book as far as length goes.

## TODOs

Sometimes when writing the book I wanted to just make a quick note that I need to revisit this before considering it "done". I did this by using "TODO" comments throughout the chapter content files. I also wanted to make _discovering_ these TODO comments quick, so I added the `todo` target:

```
.PHONY: todo
todo:
	grep -rni todo **/*.md || true
```

## Diagrams

Writing a technical book means you're likely going to have diagrams (a _lot_ of diagrams). I love and use [Excalidraw](https://excalidraw.com/) all the time, for this book and for all my diagram needs.

One of the great things about Excalidraw is that when you export an image, you have the ability to embed the scene data in the image itself. What does that mean? That means if you need to make a modification you can just open that same image file and update it as you need! This is _extremely_ helpful.

## Vim code snippet

This is the only Vim-specific tip here. When writing code in the book, the line spacing was not great. I got tired of typing the `setstretch` and code formatting characters in, so I made an abbreviation and dumped this in my `.vimrc`. Now when I type `bookcode` it expands to this so I can add the code and not have to remember the syntax.

```
iab bookcode \setstretch{1.0}
            \<CR>```
            \<CR>```
            \<CR>\setstretch{1.4}
```

## Summary

Writing the book was a great exercise, and I really had a ton of benefits by automating (most of) the actual writing and building processes. For anybody wanting to do something similar, hopefully this helps and saves a bunch of time!
