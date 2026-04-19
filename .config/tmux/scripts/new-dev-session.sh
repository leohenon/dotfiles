#!/usr/bin/env bash
set -euo pipefail

root="$HOME/dev"
input="${1:-}"

if [ -z "$input" ]; then
  IFS= read -r input || exit 0
fi

if [ -z "${input// }" ]; then
  exit 0
fi

input="${input#~/dev/}"
input="${input#/}"

target="$root/$input"
mkdir -p "$target"
target="$(cd "$target" && pwd -P)"
root="$(cd "$root" && pwd -P)"

case "$target" in
  "$root"|"$root"/*) ;;
  *)
    echo 'path must stay inside ~/dev' >&2
    exit 1
    ;;
esac

sanitize() {
  local s
  s="$1"
  s="${s//\//_}"
  s="${s// /_}"
  s="${s//./_}"
  printf '%s\n' "$s"
}

base_name="$(sanitize "$(basename "$target")")"
rel_name="$(sanitize "${target#"$root"/}")"

if [ -z "$base_name" ]; then
  base_name="main"
fi

if tmux has-session -t "$base_name" 2>/dev/null; then
  session_name="$rel_name"
else
  session_name="$base_name"
fi

if [ -z "$session_name" ]; then
  session_name="$base_name"
fi

candidate="$session_name"
suffix=2
while tmux has-session -t "$candidate" 2>/dev/null; do
  if [ "$candidate" = "$session_name" ]; then
    break
  fi
  candidate="${session_name}_$suffix"
  suffix=$((suffix + 1))
done
session_name="$candidate"

if tmux has-session -t "$session_name" 2>/dev/null; then
  tmux switch-client -t "$session_name"
  exit 0
fi

tmux new-session -ds "$session_name" -c "$target"
tmux switch-client -t "$session_name"
