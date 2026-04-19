function fe --description "fzf file picker — opens selected file in nvim in the current terminal"
    fzf --walker file,hidden --bind 'enter:become(nvim {})' --prompt='file> ' --height=100% --layout=default --no-scrollbar
end
