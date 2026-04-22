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

    abbr -a gs    'git status'
    abbr -a ga    'gstage'
    abbr -a gss   'git status --short'
    abbr -a gu    'gunstage'
    abbr -a gaa   'git add --all'
    abbr -a gb    'git branch'
    abbr -a gba   'git branch -a'
    abbr -a gbd   'git branch -d'
    abbr -a gcl   'git clone'
    abbr -a gc    'git commit'
    abbr -a gcm   'git commit -m'
    abbr -a gca   'git commit --amend'
    abbr -a gco   'git checkout'
    abbr -a gcb   'git checkout -b'
    abbr -a gl    'git log --oneline --graph --decorate'
    abbr -a gp    'git push'
    abbr -a gpsu  'git push --set-upstream origin main'
    abbr -a gpf   'git push --force-with-lease'
    abbr -a gpl   'git pull --rebase'
    abbr -a gd    'git diff'
    abbr -a gds   'git diff --staged'
    abbr -a gst   'git stash'
    abbr -a gsp   'git stash push --staged'
    abbr -a gsa   'git stash apply'
    abbr -a ghssh 'ssh -T git@github.com'
    abbr -a ghpub 'gh repo create --public --source=. --remote=origin --push'
    abbr -a ghpriv 'gh repo create --private --source=. --remote=origin --push'

    abbr -a dps   'docker ps'
    abbr -a dpa   'docker ps -a'
    abbr -a di    'docker images'
    abbr -a drm   'docker rm'
    abbr -a drmi  'docker rmi'
    abbr -a dex   'docker exec -it'
    abbr -a dlog  'docker logs -f'

    abbr -a dc    'docker compose'
    abbr -a dcu   'docker compose up'
    abbr -a dcud  'docker compose up -d'
    abbr -a dcd   'docker compose down'
    abbr -a dcb   'docker compose build'
    abbr -a dcr   'docker compose restart'
    abbr -a dcm   'docker compose -f docker compose.monitoring.yml'
    abbr -a dcp   'docker compose -f docker compose.prod.yml'
    abbr -a dcpn  'docker compose exec payload pnpm run'

    abbr -a ll    'ls -lah'
    abbr -a la    'ls -A'
    abbr -a ..    'cd ..'
    abbr -a ...   'cd ../..'
    abbr -a ....  'cd ../../..'
    abbr -a c     'clear'
    abbr -a md    'mkdir -p'
    abbr -a rd    'rmdir'

    abbr -a bunol 'bun run --cwd ~/dev/opencode/packages/opencode dev'
    abbr -a opl '~/.config/run_opencode_dev.sh'

    abbr -a f     'find . -name'
    abbr -a rg    'rg --hidden'
    abbr -a grep  'grep --color=auto'
    abbr -a h     'history'
    abbr -a psg   'ps aux | grep -v grep | grep'

    abbr -a ports 'lsof -i -P -n'
    abbr -a kill9 'kill -9'
    abbr -a myip  'curl ifconfig.me'

    set -gx VISUAL nvim
    set -gx EDITOR nvim
    abbr -a v     'nvim'
    abbr -a vi    'nvim'
    abbr -a py    'python3'
    abbr -a pip   'pip3'
    abbr -a serve 'python3 -m http.server'

    set -gx OPENCODE_ENABLE_EXA 1
    abbr -a o 'ocv'

    abbr -a t 'tmux'
    abbr -a tsc 'tmux switch-client -t'
    abbr -a ta 'tmux attach -t'
    abbr -a tn 'tmux new -s'
    abbr -a tk 'tmux kill-session -t '
    abbr -a tl 'tmux ls'
    abbr -a tlp 'tmux list-sessions -F "Session: #S | Root: #{session_path}"'
end

set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH
set -gx PATH $PATH /Users/leohenon/.lmstudio/bin
set PATH $PATH /Users/leohenon/.local/bin
