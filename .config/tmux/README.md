# tmux

- `C-a` prefix
- popup/session helpers with `fzf`

Plugins:

- `tmux-plugins/tpm`
- `tmux-plugins/tmux-resurrect`
- `leohenon/tmux-grip`
- `leohenon/tmux-palette`
- `leohenon/tmux-tab`

Key scripts:

| key        | script                    | does                                                            |
| ---------- | ------------------------- | --------------------------------------------------------------- |
| `prefix C` | `clone-dev-session.sh`    | clone repo to `~/dev`, open session                             |
| `prefix N` | `new-dev-session.sh`      | create `~/dev` directory and open new session at that directory |
| `prefix K` | `kill-current-session.sh` | kill current session, return to last                            |
| `prefix S` | `new-session -s`          | create named sessions                                           |

Other scripts:

| script                  | does                        |
| ----------------------- | --------------------------- |
| `tmux-session-popup.sh` | `fzf` dir picker -> session |
| `join-pane-right.sh`    | join pane as right split    |
| `short-path.sh`         | shorten status path         |

Files:

- `tmux.conf`
- `scripts/`
