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

for app in fish ghostty nvim tmux zsh; do
	backup_if_exists "$HOME/.config/$app"
	rm -rf "$HOME/.config/$app"
	cp -a "$repo_root/.config/$app" "$HOME/.config/$app"
done

backup_if_exists "$HOME/.zshrc"
cp -a "$repo_root/.config/zsh/.zshrc" "$HOME/.zshrc"

if [[ ! -d "$HOME/.config/tmux/plugins/tpm" ]]; then
	echo "Installing tmux plugin manager (tpm)..."
	git clone https://github.com/tmux-plugins/tpm "$HOME/.config/tmux/plugins/tpm"
fi

echo "Bootstrap complete."
echo "Backups: $backup_dir"
