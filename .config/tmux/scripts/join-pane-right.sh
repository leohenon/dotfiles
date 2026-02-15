#!/usr/bin/env bash
set -euo pipefail

if [ $# -ne 2 ]; then
	echo "Usage: $0 <target-pane> <source-pane>" >&2
	exit 1
fi

target=$1
source=$2

tmux join-pane -h -s "$source" -t "$target"
