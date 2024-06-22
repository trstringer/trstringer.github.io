---
layout: post
title: Neovim Git Branch Aware Automatic Session Persistence
categories: [Blog]
tags: [vim]
---

A few weeks ago I blogged about how to implement [automatic session persistence](https://trstringer.com/neovim-auto-reopen-files/). This quickly became a really great user experience for me.

But something was wrong... The problem was when I would create a separate branch for entirely separate development and my previous session was reopened. It might sound like no big deal, but there was a bit of unnecessary cognitive overhead in being presented with a different branch's Vim session and having to close those files and open a different set that was relevant to the new development task.

So I made a few changes to my solution. In my `~/.bashrc`, my `vim` function now looks like this:

```bash
vim () {
    if [[ -z "$@" ]]; then
	SESSION_FILE="Session.vim"
	GIT_BRANCH=""
	if [[ -d ".git" ]]; then
	    GIT_BRANCH=$(git branch --show-current)
	    SESSION_FILE="Session-${GIT_BRANCH}.vim"
	fi
	if [[ -f "$SESSION_FILE" ]]; then
	    nvim -S "$SESSION_FILE" -c "lua vim.g.savesession = true ; vim.g.sessionfile = \"${SESSION_FILE}\""
	else
	    nvim -c "lua vim.g.savesession = true ; vim.g.sessionfile = \"${SESSION_FILE}\""
	fi
    else
    	nvim "$@"
    fi
}
```

This is just some logic to see _if_ I'm the root of a git repo. If so, I use a session state file in the format of `Session-<branch>.vim`.

But I couldn't stop there. I had to make Neovim aware of this. In the above shell function I cache the session filename globally. Now my `VimPreLeave` Neovim autocommand takes that branch-specific session file to save session state:

```lua
vim.api.nvim_create_autocmd("VimLeavePre", {
  pattern = "*",
  callback = function()
    if vim.g.savesession then
      for _, k in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.getbufinfo(k)[1].hidden == 1 then
          vim.api.nvim_buf_delete(k, {})
        end
      end
      local session_file = "Session.vim"
      if vim.g.sessionfile ~= "" then
        session_file = vim.g.sessionfile
      end
      vim.api.nvim_command(string.format("mks! %s", session_file))
    end
  end
})
```

And then upon reopening Neovim, the bash function is smart enough to look for the current branch's session file and, if it exists, uses it!

This seems like a small change, but it's a big leap in UX for me!
