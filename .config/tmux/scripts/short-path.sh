#!/bin/sh

path=${1:-$PWD}
max=${2:-}
home=${HOME%/}

if [ "$path" = "$home" ]; then
  path="~"
elif [ -n "$home" ]; then
  case "$path" in
    "$home"/*) path="~/${path#"$home"/}" ;;
  esac
fi

# Drop trailing slashes, but keep the root path as "/".
while [ "$path" != "/" ] && [ "${path%/}" != "$path" ]; do
  path=${path%/}
done

short=$(
  awk -v path="$path" '
    function abbrev(part) {
      if (part == "~") return part
      if (part ~ /^\.[^.]../) return substr(part, 1, 2)
      return substr(part, 1, 1)
    }

    BEGIN {
      if (path == "") exit
      if (path == "/") {
        print "/"
        exit
      }

      n = split(path, parts, "/")
      start = 1
      out = ""

      if (substr(path, 1, 1) == "/") {
        out = "/"
        start = 2
      }

      last = n
      while (last >= start && parts[last] == "") last--

      for (i = start; i <= last; i++) {
        part = parts[i]
        if (part == "") continue
        if (i < last) part = abbrev(part)

        if (out == "" || out == "/") out = out part
        else out = out "/" part
      }

      print out
    }
  '
)

if [ -n "$max" ] && [ "$max" -gt 0 ] 2>/dev/null; then
  len=${#short}
  if [ "$len" -gt "$max" ]; then
    keep=$((max - 3))
    if [ "$keep" -gt 0 ]; then
      short="...$(printf '%s' "$short" | tail -c "$keep")"
    fi
  fi
fi

printf '%s' "$short"
