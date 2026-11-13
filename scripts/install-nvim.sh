#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_dir="$repo_root/.config/nvim"
config_home="${XDG_CONFIG_HOME:-$HOME/.config}"
target="$config_home/nvim"

if [[ ! -f "$source_dir/init.lua" ]]; then
	echo "Missing Neovim config: $source_dir/init.lua" >&2
	exit 1
fi

mkdir -p "$config_home"
if [[ -d "$target" ]]; then
	source_path="$(cd "$source_dir" && pwd -P)"
	target_path="$(cd "$target" && pwd -P)"
	if [[ "$source_path" == "$target_path" ]]; then
		echo "Neovim already uses this config: $target"
		exit 0
	fi
	if [[ "$source_path" == "$target_path/"* ]]; then
		echo "Move this checkout outside $target before installing." >&2
		exit 1
	fi
fi

# Finish copying before moving the existing config out of the way.
staging="$(mktemp -d "$config_home/.nvim-install-XXXXXX")"
trap 'rm -rf "$staging"' EXIT
cp -R "$source_dir" "$staging/nvim"

if [[ -e "$target" || -L "$target" ]]; then
	backup="$(mktemp -d "$config_home/nvim.backup-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
	mv "$target" "$backup/nvim"
	echo "Backed up existing config -> $backup/nvim"
fi

mv "$staging/nvim" "$target"
echo "Installed Neovim config -> $target"
