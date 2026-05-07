export PATH="$HOME/go/bin:$PATH:/Users/leohenon/.lmstudio/bin"
export VIRTUAL_ENV_DISABLE_PROMPT=1

if [[ -o interactive ]]; then
  export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

  autoload -Uz compinit
  if [[ -n ${ZDOTDIR:-} ]]; then
    _lh_compdump="$ZDOTDIR/.zcompdump"
  else
    _lh_compdump="$HOME/.zcompdump"
  fi
  compinit -d "$_lh_compdump"
  zmodload zsh/complist
  setopt menu_complete auto_menu complete_in_word always_to_end no_beep

  if [[ -r /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh ]]; then
    source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
  fi

  KEYTIMEOUT=1
  bindkey -v
  bindkey -M vicmd 'v' visual-mode

  _lh_esc_visual() {
    if [[ ${REGION_ACTIVE:-0} -eq 1 ]]; then
      zle visual-mode
    else
      zle vi-cmd-mode
    fi
  }
  zle -N _lh_esc_visual
  bindkey -M vicmd '^[' _lh_esc_visual

  _lh_accept_suggestion_only() {
    if [[ -n ${POSTDISPLAY-} ]]; then
      BUFFER+="$POSTDISPLAY"
      POSTDISPLAY=""
      CURSOR=$#BUFFER
      zle redisplay
    fi
  }
  zle -N _lh_accept_suggestion_only
  bindkey -M viins '^I' _lh_accept_suggestion_only
  bindkey -M viins $'\e\t' expand-or-complete
  bindkey -M viins '^[[Z' expand-or-complete
  if [[ -n "${terminfo[kcbt]-}" ]]; then
    bindkey -M viins "${terminfo[kcbt]}" expand-or-complete
  fi

  ff() {
    local selected
    selected=$(find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar) || return 0
    [[ -n "$selected" ]] || return 0
    cd "$selected" || return 1
  }

  fp() {
    local selected session_name base_name counter
    selected=$(find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar) || return 0
    [[ -n "$selected" ]] || return 0

    session_name="${selected:t}"
    session_name=${session_name//./_}
    session_name=${session_name// /_}
    base_name="$session_name"
    counter=2

    while tmux has-session -t "$session_name" 2>/dev/null; do
      session_name="${base_name}_${counter}"
      counter=$((counter + 1))
    done

    tmux new-session -d -s "$session_name" -c "$selected"

    if [[ -n ${TMUX-} ]]; then
      tmux switch-client -t "$session_name"
    else
      tmux attach-session -t "$session_name"
    fi
  }

  fe() {
    fzf --walker file,hidden --bind 'enter:become(nvim {})' --prompt='file> ' --height=100% --layout=default --no-scrollbar
  }

  fs() {
    local selected
    selected=$(tmux list-sessions -F '#S' 2>/dev/null | fzf --prompt='session> ' --height=100% --layout=default --no-scrollbar) || return 0
    [[ -n "$selected" ]] || return 0

    if [[ -n ${TMUX-} ]]; then
      tmux switch-client -t "$selected"
    else
      tmux attach-session -t "$selected"
    fi
  }

  fv() {
    local selected
    selected=$(find "$HOME" -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u | fzf --prompt='dir> ' --height=100% --layout=default --no-scrollbar) || return 0
    [[ -n "$selected" ]] || return 0
    cd "$selected" && nvim .
  }

  gstage() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
      echo "Not in a git repository"
      return 1
    }

    local output
    output=$(
      {
        git diff --name-only
        git ls-files --others --exclude-standard
        git ls-files --deleted
      } | sort -u | fzf -m --prompt='stage > '
    ) || return 0

    local -a picked
    picked=("${(@f)output}")
    (( ${#picked[@]} )) || return 0

    git add -A -- "${picked[@]}"
  }

  gunstage() {
    git rev-parse --is-inside-work-tree >/dev/null 2>&1 || {
      echo "Not in a git repository"
      return 1
    }

    local output
    output=$(git diff --cached --name-only | fzf -m --prompt='unstage > ') || return 0

    local -a picked
    picked=("${(@f)output}")
    (( ${#picked[@]} )) || return 0

    git restore --staged -- "${picked[@]}"
  }

  _lh_run_widget() {
    local cmd="$1"
    BUFFER=""
    CURSOR=0
    zle -I
    "$cmd"
    zle reset-prompt
  }

  _lh_fp_widget() { _lh_run_widget fp }
  _lh_fe_widget() { _lh_run_widget fe }
  _lh_fs_widget() { _lh_run_widget fs }
  _lh_fv_widget() { _lh_run_widget fv }

  zle -N _lh_fp_widget
  zle -N _lh_fe_widget
  zle -N _lh_fs_widget
  zle -N _lh_fv_widget

  bindkey -M viins '^F' _lh_fp_widget
  bindkey -M viins '^E' _lh_fe_widget
  bindkey -M viins '^S' _lh_fs_widget
  bindkey -M viins '^G' _lh_fv_widget

  typeset -A _LH_ABBR
  _lh_load_abbrs() {
    local abbr_file="$HOME/.config/shell/abbrs.tsv"
    [[ -r "$abbr_file" ]] || return 0

    local name expansion
    while IFS=$'\t' read -r name expansion; do
      [[ -z "$name" || "$name" == \#* || -z "$expansion" ]] && continue
      _LH_ABBR[$name]="$expansion"
    done < "$abbr_file"
  }
  _lh_load_abbrs

  _lh_expand_abbr() {
    local buf="$LBUFFER"
    local -a parts
    parts=(${=buf})
    local last="${parts[-1]}"
    if [[ -n "$last" && -n "${_LH_ABBR[$last]-}" ]]; then
      LBUFFER="${buf%$last}${_LH_ABBR[$last]}"
    fi
  }
  _lh_abbr_space() { _lh_expand_abbr; zle self-insert; }
  zle -N _lh_abbr_space
  bindkey -M viins ' ' _lh_abbr_space
  bindkey -M viins '^M' accept-line

  _lh_git_branch() {
    local branch
    branch="$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    if [[ -n "$branch" ]]; then
      echo -n "$branch"
      return 0
    fi

    command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
    local sha
    sha="$(command git rev-parse --short HEAD 2>/dev/null)"
    [[ -n "$sha" ]] && echo -n "detached:$sha"
  }

  _lh_load_theme_colors() {
    local theme_file="$HOME/.config/theme.json"
    if [[ -r "$theme_file" ]] && command -v jq &>/dev/null; then
      export LH_THEME_NAME=$(jq -r '.name // "vesper"' "$theme_file")
      export LH_COLOR_FG=$(jq -r '.colors.fg // "#FEFEFE"' "$theme_file")
      export LH_COLOR_MUTED=$(jq -r '.colors.muted // "#A0A0A0"' "$theme_file")
      export LH_COLOR_MINT=$(jq -r '.colors.mint // "#99FFE4"' "$theme_file")
      export LH_COLOR_ORANGE=$(jq -r '.colors.orange // "#FFCFA8"' "$theme_file")
      export LH_COLOR_RED=$(jq -r '.colors.red // "#FF8080"' "$theme_file")
    fi
  }

  _lh_load_theme_colors

  _lh_set_prompt() {
    local st=$?
    local branch
    branch="$(_lh_git_branch)"

    local lh_fg="${LH_COLOR_FG:-#FEFEFE}"
    local lh_muted="${LH_COLOR_MUTED:-#A0A0A0}"
    local lh_mint="${LH_COLOR_MINT:-#99FFE4}"
    local lh_orange="${LH_COLOR_ORANGE:-#FFCFA8}"
    local lh_red="${LH_COLOR_RED:-#FF8080}"

    local prompt_text=""

    if [[ -n ${VIRTUAL_ENV-} ]]; then
      prompt_text+="%F{$lh_orange}(${VIRTUAL_ENV:t}) %f"
    fi

    if [[ "$PWD" != "$HOME" || -n "$branch" ]]; then
      prompt_text+="%F{$lh_fg}${PWD:t}%f"
    fi

    if [[ -n "$branch" ]]; then
      prompt_text+=" %F{$lh_muted}git:(%f%F{$lh_orange}${branch}%f%F{$lh_muted})%f"
    fi

    if [[ $st -ne 0 ]]; then
      prompt_text+=" %F{$lh_red}✘ %f"
    else
      prompt_text+=" %F{$lh_mint}✘ %f"
    fi

    typeset -g PROMPT="$prompt_text"
    typeset -g RPROMPT=""
  }
  precmd_functions=(${precmd_functions:#_lh_set_prompt} _lh_set_prompt)
  setopt prompt_subst
  _lh_set_prompt

  _lh_set_cursor_shape() {
    if [[ ${REGION_ACTIVE:-0} -eq 1 || "$KEYMAP" == vicmd ]]; then
      printf '\e[2 q'
    else
      printf '\e[6 q'
    fi
  }

  _lh_keymap_select() {
    _lh_set_cursor_shape
    zle reset-prompt
  }

  _lh_line_init() {
    _lh_set_cursor_shape
    zle reset-prompt
  }

  zle -N zle-keymap-select _lh_keymap_select
  zle -N zle-line-init _lh_line_init

  typeset abbr_name
  for abbr_name in ${(k)_LH_ABBR}; do
    alias -- "$abbr_name=${_LH_ABBR[$abbr_name]}"
  done

  export OPENCODE_ENABLE_EXA=1
  export VISUAL=nvim
  export EDITOR=nvim
fi

export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
export PATH="$PATH:/Users/leohenon/.local/bin"

if [[ -r "$HOME/.config/zsh/local.zsh" ]]; then
  source "$HOME/.config/zsh/local.zsh"
fi
