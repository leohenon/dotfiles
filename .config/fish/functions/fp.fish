function fp --description "fzf directory picker — opens selection in a new tmux window or session"
    set selected (find $HOME -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar)

    test -z "$selected" && return 0

    set session_name (basename $selected | tr '.' '_' | tr ' ' '_')

    set base_name $session_name
    set counter 2

    while tmux has-session -t "$session_name" 2>/dev/null
        set session_name "$base_name"_"$counter"
        set counter (math $counter + 1)
    end

    tmux new-session -d -s "$session_name" -c "$selected"

    if set -q TMUX
        tmux switch-client -t "$session_name"
    else
        tmux attach-session -t "$session_name"
    end
end
