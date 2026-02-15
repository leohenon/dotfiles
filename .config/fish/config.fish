if status is-interactive
    fish_add_path -g /opt/homebrew/bin /opt/homebrew/sbin
    set -gx PATH /usr/bin /bin /usr/sbin /sbin $PATH

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

    function _lh_load_theme_colors
        set -l theme_file ~/.config/shell/theme-colors
        if test -f $theme_file
            # Export syntax works in fish, but we need to make them global
            for line in (cat $theme_file | grep "^export" | string split '\n')
                set -l parts (string split -m 1 '=' -- (string replace 'export ' '' -- $line))
                if test (count $parts) -eq 2
                    set -gx $parts[1] $parts[2]
                end
            end
        end
    end

    function fish_mode_prompt
        _lh_load_theme_colors
        set -l c_fg "#FEFEFE"
        set -l c_muted "#A0A0A0"
        set -l c_mint "#99FFE4"
        set -l c_orange "#FFCFA8"
        set -l c_red "#FF8080"
        if set -q LH_COLOR_FG
            set c_fg $LH_COLOR_FG
        end
        if set -q LH_COLOR_MUTED
            set c_muted $LH_COLOR_MUTED
        end
        if set -q LH_COLOR_MINT
            set c_mint $LH_COLOR_MINT
        end
        if set -q LH_COLOR_ORANGE
            set c_orange $LH_COLOR_ORANGE
        end
        if set -q LH_COLOR_RED
            set c_red $LH_COLOR_RED
        end

        switch $fish_bind_mode
            case default
                set_color --bold $c_muted
                echo -n "  "
            case insert
                set_color --bold $c_muted
                echo -n "  "
            case visual
                set_color --bold $c_muted
                echo -n " 󰈈 "
            case replace_one replace
                set_color --bold $c_red
                echo -n " 󰛔 "
            case '*'
                set_color --bold $c_muted
                echo -n " ? "
        end
        set_color normal
    end

    function fish_prompt
        set -l st $status
        _lh_load_theme_colors
        set -l branch (prompt_git_branch)
        set -l c_fg "#FEFEFE"
        set -l c_muted "#A0A0A0"
        set -l c_mint "#99FFE4"
        set -l c_orange "#FFCFA8"
        set -l c_red "#FF8080"
        if set -q LH_COLOR_FG
            set c_fg $LH_COLOR_FG
        end
        if set -q LH_COLOR_MUTED
            set c_muted $LH_COLOR_MUTED
        end
        if set -q LH_COLOR_MINT
            set c_mint $LH_COLOR_MINT
        end
        if set -q LH_COLOR_ORANGE
            set c_orange $LH_COLOR_ORANGE
        end
        if set -q LH_COLOR_RED
            set c_red $LH_COLOR_RED
        end

        if test "$PWD" = "$HOME" -a -z "$branch"
            if test $st -eq 0
                set_color $c_muted; echo -n "~> "; set_color normal
                return
            else
                set_color $c_red; echo -n "✖"; set_color normal
                set_color $c_muted; echo -n " ~> "; set_color normal
                return
            end
        end

        set_color $c_muted; echo -n (basename $PWD); set_color normal

        if test -n "$branch"
            echo -n " "
            set_color $c_muted
            echo -n "git:("
            set_color $c_mint
            echo -n $branch
            set_color $c_muted
            echo -n ")"
            set_color normal
        end

        if test $st -ne 0
            echo -n " "
            set_color $c_red; echo -n "✖"; set_color normal
        end

        set_color $c_muted; echo -n " ~> "; set_color normal
    end

    fish_vi_key_bindings
    bind -M insert \cf accept-autosuggestion
    bind -M insert \t accept-autosuggestion
    bind -M insert \e\t complete

    function _lh_load_abbreviations
        set -l abbr_file ~/.config/shell/abbrs.tsv
        if not test -f $abbr_file
            return
        end

        while read -l line
            if test -z "$line"
                continue
            end
            if string match -qr '^\s*#' -- $line
                continue
            end

            set -l parts (string split -m 1 \t -- $line)
            if test (count $parts) -lt 2
                continue
            end

            set -l name $parts[1]
            set -l expansion $parts[2]
            abbr -a -- $name "$expansion"
        end < $abbr_file
    end

    _lh_load_abbreviations
    functions -e _lh_load_abbreviations

    abbr -a bunol 'bun run --cwd ~/dev/opencode/packages/opencode dev'
    abbr -a opl   '~/.config/run_opencode_dev.sh'

    set -gx VISUAL vim
    set -gx EDITOR vim
end

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

if test -f ~/.config/fish/local.fish
    source ~/.config/fish/local.fish
end
