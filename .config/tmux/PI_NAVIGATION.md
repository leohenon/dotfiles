# Pi scrollback navigation

In tmux vi copy mode (`Ctrl-A [`):

- `[` / `]`: previous / next Pi prompt
- `{` / `}`: previous / next completed edit/write diff

Requires `pi-tool-display` anchors; run `/reload` after updates. Old scrollback
and unfinished/failed edits are excluded. Re-enter copy mode after resizing or
loading bindings; keep copy-mode refresh off. No wrapping; busy repeats are dropped.

Bindings: `~/.config/tmux/tmux.conf`  
Helper: `~/.config/tmux/scripts/jump-pi-anchor.py`

```sh
python3 ~/.config/tmux/scripts/test_jump_pi_anchor.py
cd ~/.pi/agent/git/github.com/leohenon/pi-tool-display
npm run typecheck
TMPDIR=/private/tmp npm test
```
