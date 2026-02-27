function fs --description "fzf session picker — switch to or attach to a tmux session"
    set selected (tmux list-sessions -F "#S" 2>/dev/null | fzf --prompt='session> ' --height=100% --layout=default --no-scrollbar)

    test -z "$selected" && return 0

    if set -q TMUX
        tmux switch-client -t "$selected"
    else
        tmux attach-session -t "$selected"
    end
end
