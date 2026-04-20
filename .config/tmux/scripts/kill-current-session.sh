#!/bin/sh

current_session=$(tmux display-message -p '#{session_name}')
last_session=$(tmux display-message -p '#{client_last_session}')

if [ -n "$last_session" ] && [ "$last_session" != "$current_session" ] && tmux switch-client -t "$last_session" 2>/dev/null; then
  tmux kill-session -t "$current_session" 2>/dev/null
else
  tmux detach-client 2>/dev/null || true
  tmux kill-session -t "$current_session" 2>/dev/null
fi
