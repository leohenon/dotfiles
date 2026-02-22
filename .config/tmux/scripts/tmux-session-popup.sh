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

base_name="${selected#$HOME/}"
base_name="${base_name//\//_}"
base_name="${base_name//./_}"
base_name="${base_name// /_}"
base_name="${base_name//-/_}"

if [ -z "$base_name" ] || [ "$base_name" = "$selected" ]; then
	base_name="main"
fi

session_name="$base_name"
suffix=2
while tmux has-session -t="$session_name" 2>/dev/null; do
	session_name="${base_name}_${suffix}"
	suffix=$((suffix + 1))
done

tmux new-session -ds "$session_name" -n nvim -c "$selected"

tmux switch-client -t "$session_name"
