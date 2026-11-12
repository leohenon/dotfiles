# Universal tmux path picker. Keep commands out of busy shells and preserve ZLE input.
if [[ -o interactive && -n ${TMUX_PANE:-} ]]; then
  _tmux_picker_ready() {
    command tmux set-option -p -t "$TMUX_PANE" @picker-shell-ready "$$" 2>/dev/null
  }
  _tmux_picker_busy() {
    command tmux set-option -pu -t "$TMUX_PANE" @picker-shell-ready 2>/dev/null
  }
  autoload -Uz add-zsh-hook
  add-zsh-hook precmd _tmux_picker_ready
  add-zsh-hook preexec _tmux_picker_busy

  _tmux_picker_open() {
    local selected kind
    selected=$(command tmux show-options -pqv -t "$TMUX_PANE" @picker-path)
    kind=$(command tmux show-options -pqv -t "$TMUX_PANE" @picker-kind)
    command tmux set-option -pu -t "$TMUX_PANE" @picker-path
    command tmux set-option -pu -t "$TMUX_PANE" @picker-kind
    [[ -n $selected ]] || return
    if [[ ( $kind == dir && -d $selected ) || ( $kind == file && -f $selected ) ]]; then
      _tmux_picker_busy
      zle -I
      if [[ $kind == dir ]]; then
        builtin cd -- "$selected" && command nvim -- "$selected"
      else
        command nvim -- "$selected"
      fi
      _tmux_picker_ready
    fi
    # This prompt is computed by precmd rather than expanded from %~.
    (( $+functions[_lh_set_prompt] )) && _lh_set_prompt
    zle reset-prompt
  }
  zle -N _tmux_picker_open
  bindkey -M viins '^X^O' _tmux_picker_open
  bindkey -M vicmd '^X^O' _tmux_picker_open
  bindkey -M emacs '^X^O' _tmux_picker_open
fi
