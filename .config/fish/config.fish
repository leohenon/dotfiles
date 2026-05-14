set -g fish_greeting
set -g VIRTUAL_ENV_DISABLE_PROMPT 1

if status is-interactive
    fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
    set -gx PATH /usr/bin /bin /usr/sbin /sbin $PATH
    set -Ux fish_user_paths ~/go/bin $fish_user_paths
    fish_add_path -g --move --prepend /opt/homebrew/opt/python@3.10/bin

    function prompt_hostname
        echo -n mac
    end

    function prompt_arrow
        if test "$PWD" = "$HOME"
            echo -n ">"
        else
            echo -n "~>"
        end
    end

    function prompt_git_branch
        command git rev-parse --is-inside-work-tree >/dev/null 2>&1; or return

        set -l branch (command git symbolic-ref --quiet --short HEAD 2>/dev/null)
        if test -n "$branch"
            echo -n "$branch"
            return
        end

        set -l sha (command git rev-parse --short HEAD 2>/dev/null)
        if test -n "$sha"
            echo -n "detached:$sha"
        end
    end

    function fish_mode_prompt
    end

    function fish_prompt
        set -l st $status
        _lh_load_theme_colors
        set -l c_red "#FF8080"
        set -l c_muted "#A0A0A0"
        set -l c_orange "#FFCFA8"
        set -l c_yellow "#FFD84D"
        if set -q LH_COLOR_RED
            set c_red $LH_COLOR_RED
        end
        if set -q LH_COLOR_MUTED
            set c_muted $LH_COLOR_MUTED
        end
        if set -q LH_COLOR_ORANGE
            set c_orange $LH_COLOR_ORANGE
        end
        set -l branch (prompt_git_branch)

        if set -q VIRTUAL_ENV
            set_color blue
            echo -n "("(basename $VIRTUAL_ENV)") "
            set_color normal
        end

        if test "$PWD" != "$HOME" -o -n "$branch"
            set_color $c_muted
            echo -n (basename $PWD)
            set_color normal
        end

        if test -n "$branch"
            echo -n " "
            set_color blue; echo -n "git:("; set_color normal
            set_color $c_red; echo -n $branch; set_color normal
            set_color blue; echo -n ")"; set_color normal
        end

        if test $st -ne 0
            set_color $c_red
        else
            set_color $c_yellow
        end
        echo -n " ✘ "
        set_color normal
    end

    fish_vi_key_bindings
    bind -M insert \t accept-autosuggestion
    bind -M insert \e\t complete
    bind -M insert \cf 'fp; commandline -f repaint'
    bind -M insert \ce 'fe; commandline -f repaint'
    bind -M insert \cs 'fs; commandline -f repaint'
    bind -M insert \cg 'fv; commandline -f repaint'

    set -l abbr_file "$HOME/.config/shell/abbrs.tsv"
    if test -r $abbr_file
        set -l tab (printf '\t')
        while read -l line
            test -z "$line"; and continue
            string match -qr '^\s*#' -- $line; and continue
            set -l parts (string split -m1 $tab -- $line)
            test (count $parts) -lt 2; and continue
            abbr -a -- $parts[1] "$parts[2]"
        end < $abbr_file
    end

    function ds --description 'Delta side-by-side diff'
        command ~/.config/delta/delta-diff $argv
    end

    function dsa --description 'Delta side-by-side diff including untracked files'
        command ~/.config/delta/delta-diff --intent-to-add $argv
    end

    function dss --description 'Delta side-by-side staged diff'
        command ~/.config/delta/delta-diff --staged $argv
    end

    function g --description 'Google search in browser'
        if test (count $argv) -eq 0
            echo 'usage: g search terms'
            return 1
        end

        set -l query (python3 -c 'import urllib.parse, sys; print(urllib.parse.quote_plus(" ".join(sys.argv[1:])))' $argv)
        open "https://www.google.com/search?q=$query"
    end

    function u --description 'Open direct URL in browser'
        if test (count $argv) -eq 0
            echo 'usage: u url'
            return 1
        end

        set -l url $argv[1]
        if not string match -qr '^[a-zA-Z][a-zA-Z0-9+.-]*://' -- $url
            set url "https://$url"
        end

        open $url
    end

    set -gx VISUAL nvim
    set -gx EDITOR nvim

    function ng
        set -l repo_root (command git rev-parse --show-toplevel 2>/dev/null)
        if test -n "$repo_root"
            cd "$repo_root"
            command nvim -c Neogit
        else
            command nvim -c Neogit
        end
    end

    set -gx OPENCODE_ENABLE_EXA 1

end

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx PATH $PATH /Users/leohenon/.lmstudio/bin
set PATH $PATH /Users/leohenon/.local/bin
