function gc --wraps='git -c core.editor=nvim commit' --description 'alias gc git -c core.editor=nvim commit'
    git -c core.editor=nvim commit $argv
end
