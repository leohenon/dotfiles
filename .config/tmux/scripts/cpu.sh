#!/bin/sh

cpu="$(top -l 1 -n 0 2>/dev/null | awk -F'[:%]' '/CPU usage/ { printf "%.0f", $2 + $4 }')"
if [ -z "${cpu:-}" ]; then
	cpu="0"
fi
printf "%s%%" "$cpu"
