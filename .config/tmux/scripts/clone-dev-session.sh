#!/usr/bin/env bash
set -euo pipefail

root="$HOME/dev"
input="${1:-}"

if [ -z "${input// }" ]; then
  exit 0
fi

# GitHub shorthand: user/repo -> full https URL
if [[ "$input" =~ ^[A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+$ ]]; then
  url="https://github.com/$input.git"
else
  url="$input"
fi

# Derive repo dir name: strip trailing .git, take basename, trim trailing slash
name="${url%/}"
name="${name##*/}"
name="${name%.git}"

if [ -z "$name" ]; then
  tmux display-message "clone: could not derive repo name from: $url"
  exit 1
fi

target="$root/$name"
mkdir -p "$root"

if [ ! -d "$target" ]; then
  tmux display-message "Cloning $url ..."
  if ! git clone "$url" "$target" >/tmp/tmux-clone-dev.log 2>&1; then
    tmux display-message "clone failed (see /tmp/tmux-clone-dev.log)"
    exit 1
  fi
fi

exec "$HOME/.config/tmux/scripts/new-dev-session.sh" "$name"
