#!/usr/bin/env bash
set -euo pipefail

case "${1:-}" in
	"") dry_run=false ;;
	--dry-run) dry_run=true ;;
	*) echo "Usage: $0 [--dry-run]" >&2; exit 2 ;;
esac
if [[ $# -gt 1 ]]; then
	echo "Usage: $0 [--dry-run]" >&2
	exit 2
fi

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_root="$repo_root/.pi/agent"
target_root="$HOME/.pi/agent"
backup_root=""

# source:destination, both relative to their respective agent directories.
# Keep this explicit mapping in sync with .pi/README.md.
mappings=(
	"settings.json:settings.json"
	"models.json:models.json"
	"config/interactive-shell.json:interactive-shell.json"
	"config/subagents.json:subagents.json"
	"config/session-summary.json:session-summary.json"
	"config/pi-fff.json:extensions/pi-fff.json"
	"config/pi-tool-display.json:extensions/pi-tool-display/config.json"
)

# Local extension code and themes retain their relative paths.
for file in "$source_root"/extensions/*.ts "$source_root"/themes/*.json; do
	[[ -f "$file" ]] || continue
	relative="${file#"$source_root/"}"
	mappings+=("$relative:$relative")
done

# Validate every source before touching live configuration.
for mapping in "${mappings[@]}"; do
	if [[ ! -f "$source_root/${mapping%%:*}" ]]; then
		echo "Missing Pi config source: $source_root/${mapping%%:*}" >&2
		exit 1
	fi
done

for mapping in "${mappings[@]}"; do
	source="$source_root/${mapping%%:*}"
	relative="${mapping#*:}"
	target="$target_root/$relative"
	if [[ "$dry_run" == true ]]; then
		printf '%s -> %s\n' "$source" "$target"
		continue
	fi

	if [[ -e "$target" || -L "$target" ]]; then
		if [[ -z "$backup_root" ]]; then
			mkdir -p "$HOME/.dotfiles-backups"
			backup_root="$(mktemp -d "$HOME/.dotfiles-backups/pi-$(date +%Y%m%d-%H%M%S)-XXXXXX")"
		fi
		mkdir -p "$backup_root/$(dirname "$relative")"
		cp -a "$target" "$backup_root/$relative"
	fi

	mkdir -p "$(dirname "$target")"
	# Replace destination symlinks rather than modifying their external targets.
	temporary="$(mktemp "$(dirname "$target")/.dotfiles-XXXXXX")"
	cp -p "$source" "$temporary"
	mv -f "$temporary" "$target"
done

if [[ "$dry_run" == false ]]; then
	echo "Installed Pi config -> $target_root"
	[[ -z "$backup_root" ]] || echo "Backups: $backup_root"
fi
