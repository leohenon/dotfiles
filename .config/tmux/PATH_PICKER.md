# Path pickers

- `prefix Ctrl+D`: directories under `$HOME`, three levels deep.
- `prefix Ctrl+F`: files under the current directory, recursively.

Reuses idle shells/Neovim; otherwise opens a new tmux window. Directory selections change cwd. Hidden entries included; ignore files respected; `.git` and home app-data trees skipped.

Requires tmux, Python 3, fd, fzf and Neovim. Reload tmux, open new shells and restart Neovim after installation.

Source: `.config/tmux/scripts/path-picker.py`
