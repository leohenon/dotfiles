# Pi scrollback navigation

In tmux vi copy mode (`Ctrl-A [`):

- `[` / `]`: previous / next Pi user prompt
- `{` / `}`: previous / next completed edit/write diff

These keys use typed OSC 8 hyperlink metadata emitted by the local
`pi-tool-display` renderer, not visible text searches or shell prompt markers.
The internal URI format is `pi-anchor://v1/prompt/<id>` or
`pi-anchor://v1/diff/<id>`. Anchors occupy an existing rendered cell and do not
add visible text. They are only emitted inside tmux.

After updating the extension, run `/reload` in Pi. Old scrollback that has not
been rendered with anchors cannot be navigated semantically. Anchors that have
fallen out of tmux's history cannot be recovered. Pending previews, failures,
and ordinary assistant text are not diff destinations.

Local extension checkout:
`~/.pi/agent/git/github.com/leohenon/pi-tool-display`

Bindings: `~/.config/tmux/tmux.conf`
Helper: `~/.config/tmux/scripts/jump-pi-anchor.py`

The `after-copy-mode[71]` hook captures the ANSI snapshot into a named tmux
buffer (`pi-nav-<pane>`) when copy mode starts. Python indexing runs only on
the first navigation keypress, then deletes that buffer. Until then it is
replaced on the next copy-mode entry; it does not replace the default paste
buffer. Entry therefore does not wait on Python before `prefix v` hides line
numbers; `prefix [` continues to use the configured line numbers.
This works around tmux next-3.8 not retaining the hyperlink registry on its
copy backing grid. A text fingerprint validates that the saved index belongs
to the current snapshot. Metadata (not transcript text) is cached under
`~/.cache/pi-tmux-navigation/`, one file per server/pane.

After resizing, or if copy mode was already open when these bindings were
loaded, exit and enter copy mode again. A changed snapshot is rejected rather
than navigated using potentially stale coordinates. Copy-mode refresh must be
off. The keys do not wrap at the oldest/newest anchor or change search history.

Validation:

```sh
python3 ~/.config/tmux/scripts/test_jump_pi_anchor.py
cd ~/.pi/agent/git/github.com/leohenon/pi-tool-display
npm run typecheck
TMPDIR=/private/tmp npm test
```

The temporary-directory override avoids existing macOS `/var` versus
`/private/var` path assertion failures in the extension tests.
