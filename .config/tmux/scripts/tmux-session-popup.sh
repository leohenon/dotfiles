#!/usr/bin/env bash

set -euo pipefail

if ! command -v tmux >/dev/null 2>&1; then
	echo "tmux is required" >&2
	exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
	echo "fzf is required" >&2
	exit 1
fi

selected="$({ find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null || true; } | sort -u | fzf --prompt='dirs> ' --height=100% --layout=default)"

if [ -z "${selected:-}" ]; then
	exit 0
fi

selected="$(cd "$selected" && pwd)"

session_name="$(basename "$selected")"
session_name="${session_name//./_}"
session_name="${session_name// /_}"
session_name="${session_name//-/_}"

if [ -z "$session_name" ]; then
	session_name="main"
fi

if ! tmux has-session -t="$session_name" 2>/dev/null; then
	tmux new-session -ds "$session_name" -n nvim -c "$selected"
fi

tmux switch-client -t "$session_name"
