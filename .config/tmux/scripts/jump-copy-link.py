#!/usr/bin/env python3
"""Jump to the nearest link on a copy-mode line, then cycle at link starts."""
import re
import subprocess
import sys
import unicodedata


ANSI = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")
URL = re.compile(r"(?:https?://|file://|www\.)[^\s<>\"'`]+", re.IGNORECASE)


def width(char):
    return (0 if unicodedata.combining(char) else
            2 if unicodedata.east_asian_width(char) in ("W", "F") else 1)


def link_starts(text, captured=""):
    """Return character offsets for URLs and OSC 8 hyperlink labels."""
    starts = set()
    for match in URL.finditer(text):
        starts.add(match.start())

    # Only use live OSC 8 metadata when it still matches the copy-mode snapshot.
    if ANSI.sub("", captured).rstrip() == text.rstrip():
        offset = index = 0
        pending = False
        while index < len(captured):
            escape = ANSI.match(captured, index)
            if escape:
                code = escape.group()
                if code.startswith("\x1b]8;"):
                    pending = bool(code.split(";", 2)[2].removesuffix("\x07").removesuffix("\x1b\\"))
                index = escape.end()
                continue
            if pending:
                starts.add(offset)
                pending = False
            offset += 1
            index += 1
    return sorted(starts)


def destination(text, cursor_x, captured=""):
    starts = link_starts(text, captured)
    if not starts:
        return None
    columns = [sum(map(width, text[:start])) for start in starts]
    if cursor_x in columns:
        return starts[(columns.index(cursor_x) + 1) % len(starts)]
    return starts[min(range(len(starts)), key=lambda i: abs(columns[i] - cursor_x))]


def jump(pane, text, cursor_x, cursor_y, scroll_position):
    captured = subprocess.run(
        ["tmux", "capture-pane", "-p", "-e", "-t", pane,
         "-S", str(int(cursor_y) - int(scroll_position)),
         "-E", str(int(cursor_y) - int(scroll_position))],
        capture_output=True, text=True, check=True,
    ).stdout.rstrip("\n")
    target = destination(text, int(cursor_x), captured)
    if target is None:
        return
    # cursor-right counts characters, not display cells (wide glyphs count once).
    steps = sum(width(char) != 0 for char in text[:target])
    command = ["tmux", "send-keys", "-t", pane, "-X", "start-of-line"]
    if steps:
        command += [";", "send-keys", "-t", pane, "-N", str(steps), "-X", "cursor-right"]
    subprocess.run(command, check=True)


if __name__ == "__main__":
    jump(*sys.argv[1:])
