---
title: Vim and development tooling
# The development page
# v2.0
# https://github.com/cotes2020/jekyll-theme-chirpy
# © 2017-2019 Cotes Chung
# MIT License
---

Tooling that I use and is documented here for setup and maintenance:

- Neovim
  - [Setup](#neovim-setup)
  - [Usage](#neovim-usage)
- tmux
  - [Setup](#tmux-setup)
  - [Usage](#tmux-usage)

## Neovim

### Neovim Setup

```bash
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux64.tar.gz
sudo rm -rf /opt/nvim-linux64
sudo tar -C /opt -xzf nvim-linux64.tar.gz
```

Add this to `~/.bashrc`:

```bash
export PATH=$PATH:/opt/nvim-linux64/bin
export EDITOR=nvim

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

Install:

- Go
- pyright
- ruff
- prettierd

Add the following config file:

[**~/.config/nvim/init.lua**](https://github.com/trstringer/nvim-config/blob/main/init.lua)

### Neovim Usage

**LSP**

- (Normal) `g+r` - Goto references
- (Normal) `g+I` - Goto implementation
- (Normal) `g+D` - Goto declaration
- (Normal) `g+d` - Goto definition
- (Normal) `<SPACE>+r+n` - Rename

## tmux

### tmux Setup

```bash
# Debian.
sudo apt install -y tmux
```

```bash
# Setup tpm.
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Create the config file:

[**~/.tmux.conf**](https://github.com/trstringer/nvim-config/blob/main/.tmux.conf)

Run `tmux` and then install plugins with `CTRL-B + I`.

Install powerline fonts: `sudo apt install -y fonts-powerline`. A reboot or logout/login might be necessary.

### tmux Usage

- `CTRL-B + z`: Zoom in or out of a pane
