---
layout: post
title: Creating and Using Go Project Templates
categories: [Blog]
tags: [golang]
---

I love writing software in Go. It is by far what I've been using for the better part of many years now. Most of us developers (Go or otherwise) fall under one of two categories, or somewhere in between:

1. Work on a single codebase forever
1. Write many applications in a short amount of time

If you're the former, you are not really all too concerned with creating new software, or greenfield development as a whole. But for those of us that lean more towards the latter, getting boilerplate code out is annoying and can even be error prone. When I need to create a new CLI, I go to my GitHub account and find a recent CLI I created. Then it's lots of copy/pasting. I know I'm not the only one that does this.

Thankfully, though, the Go team has been [working on tooling to make project templates a real thing](https://go.dev/blog/gonew). This blog post goes in depth on [using](#using-a-go-template) and [creating](#creating-a-go-template) Go templates!

## Using a Go template

Before you can start to use a Go project template, you need to first get the `gonew` bin:

```
$ go install golang.org/x/tools/cmd/gonew@latest
```

To run `gonew`, you pass it a few parameters:

```
gonew <template_package> <destination_module>
```

That's it! Now it's time to start consuming templates. For this example, I want to create a new simple CLI from a template that I've already created (more on that below).

```
$ gonew github.com/trstringer/go-template-cli-simple github.com/trstringer/hello-world-cli
gonew: initialized github.com/trstringer/hello-world-cli in ./hello-world-cli
```

`gonew` creates the directory for you, and uses the last part of the module name. In this case, that's `hello-world-cli`. Let's navigate to the new project and see what files live there now:

```
$ cd ./hello-world-cli
$ ls -la
drwxrwxr-x  2 trstringer trstringer 4096 Oct 19 23:55 .
drwxrwxr-x 63 trstringer trstringer 4096 Oct 19 23:55 ..
-rw-rw-r--  1 trstringer trstringer    6 Oct 19 23:55 .gitignore
-rw-rw-r--  1 trstringer trstringer  291 Oct 19 23:55 go.mod
-rw-rw-r--  1 trstringer trstringer  764 Oct 19 23:55 go.sum
-rw-rw-r--  1 trstringer trstringer  768 Oct 19 23:55 main.go
-rw-rw-r--  1 trstringer trstringer  336 Oct 19 23:55 Makefile
-rw-rw-r--  1 trstringer trstringer  399 Oct 19 23:55 README.md
-rw-rw-r--  1 trstringer trstringer  327 Oct 19 23:55 setup.sh
```

`gonew` brought down the whole template (including the `README.md`!). As you would've guessed, `go.mod` reflects the _destination_ module:

```
module github.com/trstringer/hello-world-cli

go 1.21

require github.com/urfave/cli/v2 v2.25.7

require (
        github.com/cpuguy83/go-md2man/v2 v2.0.2 // indirect
        github.com/russross/blackfriday/v2 v2.1.0 // indirect
        github.com/xrash/smetrics v0.0.0-20201216005158-039620a65673 // indirect
)
```

Because this module still has some more template remnants, we need to run a quick setup:

```
$ make setup
Running initial setup...
Setup complete!
```

More on this setup down below. And that's it! You can now run this with `go run`:

```
$ go run . --message "hello from Thomas' blog"
hello from Thomas' blog
```

Or build the bin and run that directly:

```
$ make build
$ ./dist/hello-world-cli --message "hello from bin" --exclamation
hello from bin!
```

Now what? Well, the boilerplate is there so now is the perfect time to modify it for your own application requirements!

## Creating a Go template

This blog post kind of put the proverbial cart before the horse. Before you can use a Go project template, you _may_ need to create one. That's a "maybe" because you might instead use one of the [Go team's templates](https://pkg.go.dev/golang.org/x/example), or an entirely different template such as the [simple CLI template](https://github.com/trstringer/go-template-cli-simple) that I used above.

A Go project template is nothing more that an existing Go module that is readily available for consumption. My `go-template-cli-simple` is a fully functioning Go module that can just be directly cloned and run by itself. So when creating your own Go templates, keep that in mind: There is nothing special about a template project as far as `gonew` is concerned.

But also as you can see in `go-template-cli-simple`, I've added some wiring here. Because I wanted the consumer (me) to be able to quickly get up and running, I added a `Makefile` with two different targets. The first is `build`, to build the binary:

```
.PHONY: build
build:
	mkdir -p ./dist
	go build -o ./dist/$(PROJECT_NAME)
```

The second is slightly more complicated. It is the `setup` target we ran above:

```
.PHONY: setup
setup:
	@if [[ ! -f ./setup.sh ]]; then \
		echo "Setup is already complete. You can delete this setup make target."; \
	else \
		chmod 755 ./setup.sh && ./setup.sh && rm ./setup.sh; \
	fi
```

This essentially runs a one-time `setup.sh` script which really only replaces the template name with the current project ("destination") name, and also resets the `README.md`, which only applies to the template.

```bash
#!/bin/bash

echo "Running initial setup..."

NEW_BASENAME=$(basename $(pwd))

# Replace the old project name with the new one in all files.
find . -type f | xargs -rn 1 sed -i -e "s/go-template-cli-simple/$NEW_BASENAME/g"

# Reset the README, as it currently contains template instructions.
echo "# $NEW_BASENAME" > README.md

echo "Setup complete!"
```

Once `make setup` runs successfully, the `setup.sh` script is automatically deleted. Running `make setup` a second time gives a helpful message:

> Setup is already complete. You can delete this setup make target.

So you can even go as far as just deleting this `setup` target altogether.

And that's essentially all there is in making smart Go project templates! Feel free to create a library of these templates for your (and your team's) uses. And the great thing about these project templates is that they are Go modules, so all of the great things (such as versioning and releases) are already there.

## Summary

I really love the direction that Go project templates are going in. They save a lot of time and headache. I find myself writing mostly CLIs and web servers, and being able to save time by reusing a version-controlled template that I am comfortable with is such a great approach!
