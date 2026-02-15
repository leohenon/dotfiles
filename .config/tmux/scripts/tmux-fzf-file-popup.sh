#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 1 ]; then
	echo "Usage: $0 <target-pane>" >&2
	exit 1
fi

target_pane=$1
session_path=$(tmux display-message -p -t "$target_pane" "#{session_path}")
cd "$session_path"

cache_file="/tmp/tmux-fzf-cache-$(printf "%s" "$session_path" | tr '/' '_')"
cache_age=300

is_git_repo() {
	git -C "$session_path" rev-parse --is-inside-work-tree >/dev/null 2>&1
}

generate_file_list() {
	if is_git_repo; then
		git -C "$session_path" -c core.quotepath=off ls-files --cached --others --exclude-standard 2>/dev/null
		return
	fi

	if command -v fd >/dev/null 2>&1; then
		fd --type f \
			--exclude .git \
			--exclude node_modules \
			--exclude target \
			--exclude build \
			--exclude dist \
			--exclude .next \
			--exclude out \
			--exclude coverage \
			--exclude .cache \
			--max-depth 15 \
			2>/dev/null
		return
	fi

	find . -type f \
		-not -path '*/\.*' \
		-not -path '*/node_modules/*' \
		-not -path '*/target/*' \
		-not -path '*/build/*' \
		-not -path '*/dist/*' \
		-not -path '*/.next/*' \
		-not -path '*/out/*' \
		-not -path '*/coverage/*' \
		-not -path '*/.cache/*' \
		-maxdepth 15 \
		2>/dev/null | sed 's|^\./||'
}

refresh_cache_async() {
	(
		local tmp
		tmp="${cache_file}.tmp.$$"
		generate_file_list >"$tmp"
		mv "$tmp" "$cache_file"
	) >/dev/null 2>&1 &
}

cache_is_fresh=false
if [ -f "$cache_file" ]; then
	now=$(date +%s)
	mtime=$(stat -f %m "$cache_file" 2>/dev/null || stat -c %Y "$cache_file" 2>/dev/null || printf "")
	if [ -n "$mtime" ] && [ $((now - mtime)) -lt "$cache_age" ]; then
		cache_is_fresh=true
	fi
fi

if [ "$cache_is_fresh" = true ]; then
	refresh_cache_async
	selected_file=$(fzf --prompt='file> ' --height=100% --layout=default --border <"$cache_file")
else
	selected_file=$(generate_file_list | tee "$cache_file" | fzf --prompt='file> ' --height=100% --layout=default --border)
fi

[ -z "${selected_file:-}" ] && exit 0

full_path="$session_path/$selected_file"
pane_proc=$(tmux display-message -p -t "$target_pane" "#{pane_current_command}")

if [[ "$pane_proc" == *nvim* ]]; then
	tmux send-keys -t "$target_pane" Escape ":e $selected_file" Enter
else
	tmux new-window -n "$(basename "$selected_file")" "nvim '$full_path'"
fi
