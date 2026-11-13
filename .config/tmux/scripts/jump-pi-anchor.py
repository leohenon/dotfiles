#!/usr/bin/env python3
"""Navigate renderer OSC 8 anchors in a frozen tmux copy-mode snapshot.

The after-copy-mode hook captures the live grid synchronously at snapshot
creation. tmux next-3.8's copy backing grid loses its hyperlink registry, so
later live captures must NOT be used to locate anchors in that snapshot.
"""
import hashlib
import json
import os
import re
import subprocess
import sys
from pathlib import Path

ANSI = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")
LINK = re.compile(r"\x1b\]8;[^;]*;(pi-anchor://v1/(prompt|diff)/[A-Za-z0-9_.~%!'()*-]+)(?:\x07|\x1b\\)")


def tmux(*args):
    return subprocess.run(["tmux", *args], check=True, capture_output=True,
                          text=True).stdout


def cache_path(pane):
    # Separate servers may use the same pane ID. Store no transcript contents.
    server = hashlib.sha256(os.environ.get("TMUX", "").encode()).hexdigest()[:16]
    root = Path.home() / ".cache" / "pi-tmux-navigation"
    root.mkdir(mode=0o700, parents=True, exist_ok=True)
    return root / f"{server}-{pane.lstrip('%')}.json"


def fingerprint(text):
    return hashlib.sha256(text.encode()).hexdigest()


def parse_anchors(captured):
    anchors = []
    for line in captured.splitlines():
        number, sep, body = line.partition(" ")
        if not sep:
            continue
        for match in LINK.finditer(body):
            anchor = [int(number), match[2], match[1]]
            if anchor not in anchors:
                anchors.append(anchor)
    return anchors


def snapshot(pane):
    return tmux("capture-pane", "-p", "-M", "-L", "-N", "-S", "-", "-E", "-", "-t", pane)


def initialize(pane, optional=False):
    name = f"pi-nav-{pane}"
    try:
        captured = tmux("save-buffer", "-b", name, "-")
    except subprocess.CalledProcessError:
        if optional:
            return  # Already indexed: reuse the cache for this snapshot.
        raise
    tmux("delete-buffer", "-b", name)
    path = cache_path(pane)
    path.unlink(missing_ok=True)
    plain = snapshot(pane)
    if ANSI.sub("", captured) != plain:
        return  # Resize or another mode transition: never guess coordinates.
    data = {"fingerprint": fingerprint(plain), "anchors": parse_anchors(captured)}
    temporary = path.with_suffix(".tmp")
    temporary.write_text(json.dumps(data))
    temporary.replace(path)


def target_row(anchors, kind, direction, cursor):
    rows = sorted({row for row, anchor_kind, _uri in anchors if anchor_kind == kind})
    candidates = [row for row in rows if row < cursor] if direction == "prev" else [row for row in rows if row > cursor]
    return (candidates[-1] if direction == "prev" else candidates[0]) if candidates else None


def move_commands(pane, row, history, limit):
    top = min(row, 0)
    argument = -top if limit == history else history + top + 1
    commands = ["send-keys", "-t", pane, "-X", "goto-line", str(argument),
                ";", "send-keys", "-t", pane, "-X", "top-line",
                ";", "send-keys", "-t", pane, "-X", "start-of-line"]
    if row > 0:
        commands += [";", "send-keys", "-t", pane, "-N", str(row), "-X", "cursor-down"]
    return commands


def notify(pane, message):
    tmux("display-message", "-t", pane, message)


def jump(pane, kind, direction):
    if kind not in ("prompt", "diff") or direction not in ("prev", "next"):
        raise ValueError("invalid navigation type or direction")
    state = tmux("display-message", "-p", "-t", pane,
                 "#{pane_mode} #{copy_cursor_y} #{scroll_position} #{copy_position_limit} #{pane_height} #{refresh_active}").split()
    if not state or state[0] != "copy-mode":
        return
    if len(state) > 5 and state[5] == "1":
        notify(pane, "Pi jumps require frozen copy mode (disable refresh first)")
        return
    # Entry captures only bytes; defer Python indexing until navigation so
    # after-copy-mode cannot delay the caller's line-numbers-off command.
    initialize(pane, optional=True)
    plain = snapshot(pane)
    try:
        data = json.loads(cache_path(pane).read_text())
    except (FileNotFoundError, ValueError):
        data = {}
    if data.get("fingerprint") != fingerprint(plain):
        notify(pane, "Pi navigation snapshot changed: exit copy mode and enter again")
        return
    cursor_y, scroll, limit, height = map(int, state[1:5])
    history = -int(plain.partition(" ")[0])
    if limit not in (history, history + height):
        notify(pane, "Pi navigation: unsupported copy-mode coordinates")
        return
    row = target_row(data["anchors"], kind, direction, cursor_y - scroll)
    if row is None:
        notify(pane, f"No {direction} Pi {kind} anchor in this snapshot; /reload Pi for new anchors")
        return
    tmux(*move_commands(pane, row, history, limit))


if __name__ == "__main__":
    try:
        if len(sys.argv) == 3 and sys.argv[1] == "init":
            initialize(sys.argv[2])
        else:
            jump(*sys.argv[1:])
    except (subprocess.CalledProcessError, OSError, ValueError) as error:
        print(f"Pi navigation: {error}", file=sys.stderr)
        sys.exit(1)
