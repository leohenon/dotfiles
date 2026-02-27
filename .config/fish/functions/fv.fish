function fv --description "fzf directory picker — opens selected dir in nvim in current terminal"
    set selected (find $HOME -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar)

    test -z "$selected" && return 0

    cd "$selected" && nvim .
end
