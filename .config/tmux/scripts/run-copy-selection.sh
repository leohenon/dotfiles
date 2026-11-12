#!/bin/sh
set -eu

# copy-pipe supplies the selected text on stdin. Never evaluate it here.
command=$(cat)
[ -n "$command" ] || exit 0
# Fish -C executes after shell initialization and preserves command newlines.
# Pass separate argv to tmux so the selection is not reparsed by /bin/sh.
tmux split-window -h -t "$1" -c "$2" /opt/homebrew/bin/fish -i -C "$command"
