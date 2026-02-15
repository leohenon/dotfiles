export PATH="$PATH:$HOME/.lmstudio/bin"

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
    if [[ -n ${ZSH_AUTOSUGGEST_BUFFER-} ]]; then
      zle autosuggest-accept
    fi
  }
  zle -N _lh_accept_suggestion_only
  bindkey -M viins '^I' _lh_accept_suggestion_only
  bindkey -M viins '^F' autosuggest-accept 2>/dev/null || true
  bindkey -M viins $'\e\t' expand-or-complete
  if [[ -n "${terminfo[kcbt]-}" ]]; then
    bindkey -M viins "${terminfo[kcbt]}" reverse-menu-complete
  fi

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
  _lh_abbr_accept_line() { _lh_expand_abbr; zle accept-line; }
  zle -N _lh_abbr_space
  zle -N _lh_abbr_accept_line
  bindkey -M viins ' ' _lh_abbr_space
  bindkey -M viins '^M' _lh_abbr_accept_line

  _lh_git_branch() {
    command git rev-parse --is-inside-work-tree >/dev/null 2>&1 || return 1
    local branch
    branch="$(command git symbolic-ref --quiet --short HEAD 2>/dev/null)"
    if [[ -n "$branch" ]]; then
      echo -n "$branch"
      return 0
    fi
    local sha
    sha="$(command git rev-parse --short HEAD 2>/dev/null)"
    [[ -n "$sha" ]] && echo -n "detached:$sha"
  }

  _lh_load_theme_colors() {
    local theme_file="$HOME/.config/shell/theme-colors"
    if [[ -r "$theme_file" ]]; then
      source "$theme_file" 2>/dev/null || true
    fi
  }

  _lh_set_prompt() {
    local st=$?
    local branch
    branch="$(_lh_git_branch)"

    _lh_load_theme_colors
    local lh_fg="${LH_COLOR_FG:-#FEFEFE}"
    local lh_muted="${LH_COLOR_MUTED:-#A0A0A0}"
    local lh_mint="${LH_COLOR_MINT:-#99FFE4}"
    local lh_red="${LH_COLOR_RED:-#FF8080}"

    local c_fg="%F{$lh_fg}"
    local c_muted="%F{$lh_muted}"
    local c_mint="%F{$lh_mint}"
    local c_red="%F{$lh_red}"
    local c_reset="%f"

    if [[ "$PWD" == "$HOME" && -z "$branch" ]]; then
      if [[ $st -eq 0 ]]; then
        _LH_PROMPT_BASE="${c_muted}~>${c_reset} "
      else
        _LH_PROMPT_BASE="${c_red}✖${c_reset} ${c_muted}~>${c_reset} "
      fi
      PROMPT="${_LH_MODE_PREFIX}${_LH_PROMPT_BASE}"
      return
    fi

    _LH_PROMPT_BASE="${c_fg}${PWD:t}${c_reset}"
    if [[ -n "$branch" ]]; then
      _LH_PROMPT_BASE+=" ${c_muted}git:(${c_mint}${branch}${c_muted})${c_reset}"
    fi
    if [[ $st -ne 0 ]]; then
      _LH_PROMPT_BASE+=" ${c_red}✖${c_reset}"
    fi
    _LH_PROMPT_BASE+="${c_muted} ~>${c_reset} "
    PROMPT="${_LH_MODE_PREFIX}${_LH_PROMPT_BASE}"
  }
  precmd_functions+=(_lh_set_prompt)

  _lh_update_mode() {
    _lh_load_theme_colors
    local lh_fg="${LH_COLOR_FG:-#FEFEFE}"
    local lh_mint="${LH_COLOR_MINT:-#99FFE4}"
    local lh_orange="${LH_COLOR_ORANGE:-#FFCFA8}"
    local lh_red="${LH_COLOR_RED:-#FF8080}"

    local icon color
    if [[ ${REGION_ACTIVE:-0} -eq 1 ]]; then
      icon=" 󰈈 "
      color="%F{$lh_orange}"
    elif [[ "$ZLE_STATE" == *overwrite* ]]; then
      icon=" 󰛔 "
      color="%F{$lh_red}"
    else
      case "$KEYMAP" in
        vicmd) icon="  "; color="%F{$lh_orange}" ;;
        viins|main) icon="  "; color="%F{$lh_mint}" ;;
        *) icon=" ? "; color="%F{$lh_fg}" ;;
      esac
    fi
    _LH_MODE_PREFIX="${color}%B${icon}%b%f"
    if [[ -n "${_LH_PROMPT_BASE-}" ]]; then
      PROMPT="${_LH_MODE_PREFIX}${_LH_PROMPT_BASE}"
    fi
  }
  _lh_keymap_select() {
    _lh_update_mode
    zle reset-prompt
  }
  zle -N zle-keymap-select _lh_keymap_select
  zle -N zle-line-init _lh_keymap_select
  zle -N zle-line-pre-redraw _lh_keymap_select
  _lh_update_mode
  setopt prompt_subst

  typeset abbr_name
  for abbr_name in ${(k)_LH_ABBR}; do
    alias -- "$abbr_name=${_LH_ABBR[$abbr_name]}"
  done

  export VISUAL=nvim
  export EDITOR=nvim
fi

if [[ -r "$HOME/.config/zsh/local.zsh" ]]; then
  source "$HOME/.config/zsh/local.zsh"
fi
