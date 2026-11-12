#!/usr/bin/env python3
"""Open a copy-mode hyperlink, file, or directory without interpreting it as shell code."""
import os
from pathlib import Path
import re
import subprocess
import sys
import unicodedata
from urllib.parse import unquote, urlsplit


def cursor_token(text, cursor_x):
    """Find the whitespace-delimited token at a terminal column, preserving / . : ."""
    column = 0
    for match in re.finditer(r"\s+|\S+", text):
        width = sum(
            0 if unicodedata.combining(char) else
            2 if unicodedata.east_asian_width(char) in ("W", "F") else 1
            for char in match.group()
        )
        if column <= int(cursor_x) < column + width:
            return match.group() if not match.group().isspace() else ""
        column += width
    return ""


ANSI = re.compile(r"\x1b\][^\x07\x1b]*(?:\x07|\x1b\\)|\x1b\[[0-?]*[ -/]*[@-~]")


def captured_hyperlink(pane, row, cursor_x, expected_text):
    """Read OSC 8 from the original grid, avoiding tmux's line-number offset bug."""
    result = subprocess.run(
        ["tmux", "capture-pane", "-p", "-e", "-t", pane,
         "-S", str(row), "-E", str(row)],
        capture_output=True, text=True, check=True,
    )
    captured = result.stdout.rstrip("\n")
    if ANSI.sub("", captured).rstrip() != expected_text.rstrip():
        return None  # The live pane changed since copy mode took its snapshot.
    column = 0
    active = ""
    index = 0
    while index < len(captured):
        escape = ANSI.match(captured, index)
        if escape:
            code = escape.group()
            if code.startswith("\x1b]8;"):
                active = code.split(";", 2)[2].removesuffix("\x07").removesuffix("\x1b\\")
            index = escape.end()
            continue
        char = captured[index]
        width = (0 if unicodedata.combining(char) else
                 2 if unicodedata.east_asian_width(char) in ("W", "F") else 1)
        if column <= int(cursor_x) < column + width:
            return active
        column += width
        index += 1
    return ""


def open_target(link, word, cwd, session, text=None, cursor_x=None,
                pane=None, cursor_y=None, position=None):
    if pane and cursor_x and cursor_y and position and text is not None:
        recovered = captured_hyperlink(
            pane, int(cursor_y) - int(position), cursor_x, text,
        )
        if recovered is not None:
            link = recovered
    if not link and text is not None and cursor_x:
        word = cursor_token(text, cursor_x)
    target = link or word.strip("`\"'()[]{}<>,;")
    if not target:
        return
    if urlsplit(target).scheme in ("http", "https"):
        subprocess.run(["open", target], check=True)
        return

    line = column = None
    if link:
        url = urlsplit(link)
        if url.scheme != "file" or url.netloc not in ("", "localhost"):
            subprocess.run(["tmux", "display-message", "Unsupported link type"])
            return
        filename = unquote(url.path)
    else:
        filename = target.strip("`\"'()[]{}<>,;")

    path = Path(os.path.expanduser(filename))
    if not path.is_absolute():
        path = Path(cwd) / path
    # Prefer an exact filename, including filenames containing colons.
    if not (path.is_file() or path.is_dir()):
        match = re.fullmatch(r"(.+?):(\d+)(?::(\d+))?:?", filename)
        if match:
            filename, line, column = match.groups()
            path = Path(os.path.expanduser(filename))
            if not path.is_absolute():
                path = Path(cwd) / path
    if not (path.is_file() or path.is_dir()):
        subprocess.run(["tmux", "display-message", "No file found under cursor"])
        return

    command = ["tmux", "new-window", "-t", session + ":", "-c", str(path.absolute()) if path.is_dir() else cwd,
               "-n", path.name or "/", "nvim"]
    if line and path.is_file():
        command.append(f"+call cursor({int(line)},{int(column or 1)})")
    command.extend(["--", str(path.absolute())])
    subprocess.run(command, check=True)


if __name__ == "__main__":
    open_target(*sys.argv[1:])
