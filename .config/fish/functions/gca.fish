function gca --wraps='git -c core.editor=nvim commit --amend' --description 'alias gca git -c core.editor=nvim commit --amend'
    git -c core.editor=nvim commit --amend $argv
end
