# Embedded Neovim shells inherit the outer pane but must not register as its shell.
if status is-interactive; and set -q TMUX_PANE; and not set -q NVIM
    function _tmux_picker_ready --on-event fish_prompt
        command tmux set-option -p -t "$TMUX_PANE" @picker-shell-ready $fish_pid 2>/dev/null
    end

    function _tmux_picker_busy --on-event fish_preexec
        command tmux set-option -pu -t "$TMUX_PANE" @picker-shell-ready 2>/dev/null
    end

    function _tmux_picker_open
        set -l path (command tmux show-options -pqv -t "$TMUX_PANE" @picker-path)
        set -l kind (command tmux show-options -pqv -t "$TMUX_PANE" @picker-kind)
        command tmux set-option -pu -t "$TMUX_PANE" @picker-path
        command tmux set-option -pu -t "$TMUX_PANE" @picker-kind
        test -n "$path"; or return
        if begin; test "$kind" = dir; and test -d "$path"; end; or begin; test "$kind" = file; and test -f "$path"; end
            _tmux_picker_busy
            if test "$kind" = dir
                cd -- "$path"; and command nvim -- "$path"
            else
                command nvim -- "$path"
            end
            _tmux_picker_ready
        end
        commandline -f repaint
    end
end
