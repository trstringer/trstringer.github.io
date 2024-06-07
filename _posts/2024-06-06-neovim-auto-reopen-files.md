---
layout: post
title: Automatically Reopen Previous Files and Session in Neovim
categories: [Blog]
tags: [vim]
---

A common editor/IDE feature that most people probably don't think about twice is that when you close down your editor and reopen it, you _probably_ have the same files open, with the cursor at the same place, and mostly a duplicate experience of when you closed it.

Vim users know better though, and there's a little more manual effort to that. With Vim, we have the idea of a session that handles this logic. So if you're wanting to save the current session, you'd run `mks[!]`. This saves the session by default in a file named `Session.vim`. And then you reopen Vim you would have to run `vim -s Session.vim` to get back to where you were.

That's great, but it's very manual _and_ I can never remember to run `mks` before close and `-s` on reopen.

Thankfully, Neovim is _very_ approachable with configuring using Lua so I wanted to solve this since my recent migration from Vim to Neovim.

> Note: This is very possible with Vim as well, but personally speaking Lua has opened up a ton more doors and interest in customizing my Vim experience.

I already had a `vim` bash function in my `.bashrc`, so I expanded it handle conditional logic on whether or not to automatically open up an existing session:

```bash
vim () {
    if [[ -z "$@" ]]; then
	if [[ -f "./Session.vim" ]]; then
	    nvim -S Session.vim -c 'lua vim.g.savesession = true'
	else
	    nvim -c 'lua vim.g.savesession = true'
	fi
    else
    	nvim "$@"
    fi
}
```

When I open `vim` from the terminal, there is a bit of logic here that uses (or doesn't use) an existing session. I also set some global state that I will refer back to soon.

If there are other parameters passed to Vim, I _probably_ don't want to use an existing session or save this one. For instance, if I'm in a random dir and want to quickly edit my bashrc, I'd probably do `vim ~/.bashrc`. Well, I don't want that state to be saved, especially in that random dir. So I completely avoid state in that instance.

But if I just run `vim`, I _probably_ want to automatically restore state (and save it on next exit).

In my Neovim config I have the following autocommand:

```lua
vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    if vim.g.savesession then
      vim.api.nvim_command("mks!")
    end
  end
})
```

If `vim.g.savesession` is set then it runs `mks` before Vim exits. And that is set from my bash function when I don't pass any parameters to `vim`.

So now I have a pretty modern approach to automatic state saving in Neovim with just a few extra lines of code!
