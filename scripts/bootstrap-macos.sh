#!/usr/bin/env bash
set -euo pipefail

if [[ "$(uname -s)" != "Darwin" ]]; then
	echo "This bootstrap script supports macOS only."
	exit 1
fi

if ! command -v brew >/dev/null 2>&1; then
	echo "Homebrew is required: https://brew.sh"
	exit 1
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
backup_dir="$HOME/.dotfiles-backups/$(date +%Y%m%d-%H%M%S)"

backup_if_exists() {
	local path="$1"
	if [[ -e "$path" || -L "$path" ]]; then
		mkdir -p "$backup_dir"
		cp -a "$path" "$backup_dir/"
		echo "Backed up $path -> $backup_dir"
	fi
}

echo "Installing Homebrew dependencies from Brewfile..."
brew bundle --file "$repo_root/Brewfile"

mkdir -p "$HOME/.config"

for app in bat fish ghostty hunk karabiner nvim raycast shell tmux zsh; do
	backup_if_exists "$HOME/.config/$app"
	rm -rf "$HOME/.config/$app"
	cp -a "$repo_root/.config/$app" "$HOME/.config/$app"
done

if command -v bat >/dev/null 2>&1; then
	bat cache --build
fi

if command -v git >/dev/null 2>&1; then
	for old_include in "$HOME/.config/delta/gitconfig" "~/.config/delta/gitconfig"; do
		if git config --global --get-all include.path | grep -Fxq "$old_include"; then
			git config --global --fixed-value --unset-all include.path "$old_include"
		fi
	done
fi

backup_if_exists "$HOME/.config/theme.json"
cp -a "$repo_root/.config/theme.json" "$HOME/.config/theme.json"

for command_name in ai-usage ai-tokens ai-status; do
	command_path="$HOME/.config/shell/$command_name/$command_name.mjs"
	if [[ -f "$command_path" ]]; then
		chmod +x "$command_path"
		mkdir -p "$HOME/.local/bin"
		backup_if_exists "$HOME/.local/bin/$command_name"
		ln -sf "$command_path" "$HOME/.local/bin/$command_name"
	fi
done

backup_if_exists "$HOME/.zshrc"
cp -a "$repo_root/.config/zsh/.zshrc" "$HOME/.zshrc"

if ! command -v pi >/dev/null 2>&1; then
	echo "Installing pi..."
	npm install -g @mariozechner/pi-coding-agent
fi

if [[ -d "$repo_root/.pi/agent" ]]; then
	mkdir -p "$HOME/.pi/agent"
	rsync -a "$repo_root/.pi/agent/" "$HOME/.pi/agent/"
	echo "Synced pi config -> $HOME/.pi/agent"
fi

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
	echo "Installing tmux plugin manager (tpm)..."
	git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

if [[ -x "$repo_root/scripts/apply-cmux-keybinds.sh" ]]; then
	"$repo_root/scripts/apply-cmux-keybinds.sh"
fi

echo "Bootstrap complete."
echo "Backups: $backup_dir"
