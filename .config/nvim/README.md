# Neovim

A fast, streamlined nvim config ([init.lua](init.lua), [Plugins](lua/plugins/)).

## Install

```sh
git clone --depth 1 https://github.com/leohenon/dotfiles.git
bash dotfiles/scripts/install-nvim.sh
nvim
```

Requires Neovim, Git, a C compiler, make, tree-sitter CLI, fd, and ripgrep. tmux/Pi features need this repo’s configs.

## Core

- lazy.nvim
- Telescope + telescope-fzf-native.nvim
- nvim-lspconfig + Mason
- nvim-cmp + LuaSnip
- copilot.lua
- nvim-treesitter
- conform.nvim
- gitsigns.nvim
- vim-fugitive
- codediff.nvim
- Trouble
