function ff --description "fzf directory picker — cd into selected directory"
    set selected (find $HOME -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar)

    test -z "$selected" && return 0

    cd "$selected"
end
