---
layout: post
title: Using Neovim as my PostgreSQL Client
categories: [Blog]
tags: [postgresql,vim,linux]
---

I've been a Vim user for a _very_ long time. And I'm also an avid PostgreSQL user, both personally and professionally. In fact, I finally got around to blogging about how I [use Vim as my postgres client](https://trstringer.com/postgres-client-vim/) a little over a half year ago.

A couple of months ago I did something that I didn't really think I would ever do: I gave Neovim a try. And whoa... almost overnight it became obvious to me that I've been missing out. One of the quickest realizations was just how easy it is to extend Neovim with Lua. As long as I've been using Vim, I was never a big fan of Vimscript and because of that, I had avoided writing my own plugins.

Move over Vimscript, hello Lua. What a breath of fresh air.

With my editor modernization, I decided to write my first plugin: A PostgreSQL client plugin to work with a postgres database directly from within Neovim. I ended up creating [psql.nvim](https://github.com/trstringer/psql.nvim).

`psql.nvim` allows you to run queries directly in Neovim, and it provides helper commands to get things like a list of tables, functions, and databases. It also allows you to quickly format your SQL code, using `pg_format` (provided by `pgformatter`).

Some tooling that I had to make was a local connection manager. I created [psqlcm](https://github.com/trstringer/psqlcm) for this. Inside Neovim, the plugin will look at the first line and see which connection it should use for the queries. And there's a sliding window `current` label to change which current connection you are using.

Here's a little demo to show a some of the functionality:

![psql.nvim demo](../images/psqlnvim-psqlcm2.gif)

I can quickly connect to a database and run queries, either full script files or just with visual selection (sometimes you don't want to run _all_ the queries in your ad hoc SQL script).

It was a really great experience writing this first Neovim plugin, and I'm sure I'll have many more in the future! This plugin and tooling was written for me and my workflow, but perhaps others may find it useful!
