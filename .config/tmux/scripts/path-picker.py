#!/usr/bin/env python3
"""Context-aware tmux picker: shell widget, Neovim RPC, or a safe new window."""
import json
import os
import shlex
import subprocess
import sys
from pathlib import Path


def tmux(*args):
    return subprocess.check_output(["tmux", *args], text=True).rstrip("\n")


def pane_value(pane, name):
    return tmux("display-message", "-p", "-t", pane, "#{" + name + "}")


def foreground_editor(pane):
    registration = pane_value(pane, "@picker-nvim")
    if not registration:
        return None
    try:
        editor = json.loads(registration)
        pid = int(editor["pid"])
        pane_pid = int(pane_value(pane, "pane_pid"))
        active = False
        # Neovim 0.12 may run an embedded backend behind a terminal UI process.
        # Check its ancestry too, without accepting suspended or other-pane editors.
        for _ in range(32):
            result = subprocess.run(
                ["ps", "-p", str(pid), "-o", "ppid=,pgid=,tpgid=,state=,comm="],
                capture_output=True, text=True, check=True,
            )
            parent, pgid, foreground, state, command = result.stdout.split(maxsplit=4)
            if "T" in state:
                return None
            if Path(command.strip()).name == "nvim" and pgid == foreground:
                active = True
            if pid == pane_pid:
                return editor["server"] if active else None
            pid = int(parent)
            if pid <= 1:
                break
    except (ValueError, KeyError, TypeError, subprocess.SubprocessError):
        pass
    return None


def open_path(pane, kind, path):
    command = pane_value(pane, "pane_current_command")
    server = foreground_editor(pane)
    if server:
        payload = json.dumps([kind, path], ensure_ascii=True).replace("'", "''")
        expression = (
            'luaeval("require(\'config.tmux_picker\').open(_A)", '
            f"json_decode('{payload}'))"
        )
        result = subprocess.run(
            ["nvim", "--headless", "-u", "NONE", "--server", server, "--remote-expr", expression],
            stdin=subprocess.DEVNULL, capture_output=True, text=True, timeout=5,
        )
        if result.returncode or result.stdout.strip() != "ok":
            raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "Neovim RPC failed")
        return

    ready = pane_value(pane, "@picker-shell-ready")
    if command in ("zsh", "fish") and ready:
        # No command text is injected: the shell widget reads these as data.
        tmux("set-option", "-p", "-t", pane, "@picker-path", path)
        tmux("set-option", "-p", "-t", pane, "@picker-kind", kind)
        tmux("send-keys", "-t", pane, "C-x", "C-o")
        return

    # Never send keystrokes to an arbitrary foreground application.
    cwd = path if kind == "dir" else str(Path(path).parent)
    session = pane_value(pane, "session_id")
    tmux("new-window", "-t", session + ":", "-c", cwd, "nvim -- " + shlex.quote(path))


def pick(kind, cwd):
    root = str(Path.home()) if kind == "dir" else cwd
    command = ["fd", "--type", "d" if kind == "dir" else "f", "--hidden",
               "--exclude", ".git", "--absolute-path", "--print0"]
    # Prune before traversal, not after collecting results: entering Library
    # can trigger macOS app-data permission prompts attributed to the terminal.
    search_root = Path(os.path.abspath(root))
    home = Path.home()
    for relative in ("Library", ".Trash", ".cache", ".local/share", ".local/state"):
        excluded = home / relative
        if search_root.is_relative_to(excluded):
            tmux("display-message", "Picker skips app-data directory: " + str(excluded))
            return None
        if excluded.is_relative_to(search_root):
            pattern = "/" + excluded.relative_to(search_root).as_posix() + "/"
            command += ["--exclude", pattern]
    if kind == "dir":
        command += ["--max-depth", "3"]
    command += [".", root]
    env = dict(os.environ, FZF_DEFAULT_OPTS="", FZF_DEFAULT_OPTS_FILE="")
    with subprocess.Popen(command, stdout=subprocess.PIPE, stderr=subprocess.DEVNULL) as finder:
        assert finder.stdout is not None
        result = subprocess.run(
            ["fzf", "--read0", "--print0", "--no-multi", "--layout=reverse",
             "--height=100%", "--prompt=" + kind + "> ", "--no-scrollbar"],
            stdin=finder.stdout, stdout=subprocess.PIPE, env=env,
        )
        finder.stdout.close()
        if finder.poll() is None:
            finder.terminate()
    if result.returncode in (1, 130):
        return None
    if result.returncode:
        raise RuntimeError("fzf failed")
    return os.fsdecode(result.stdout.rstrip(b"\0")) or None


def main():
    kind, pane = sys.argv[1:]
    if kind not in ("dir", "file"):
        raise ValueError("Expected dir or file")
    cwd = pane_value(pane, "pane_current_path")
    server = foreground_editor(pane) if kind == "file" else None
    if server:
        # The embedded Neovim backend may have changed directory independently
        # of its terminal UI process (which is what tmux sees).
        result = subprocess.run(
            ["nvim", "--headless", "-u", "NONE", "--server", server, "--remote-expr", "json_encode(getcwd())"],
            stdin=subprocess.DEVNULL, capture_output=True, text=True, check=True, timeout=5,
        )
        try:
            cwd = json.loads(result.stdout)
        except ValueError as error:
            raise RuntimeError("Invalid directory response from Neovim") from error
    path = pick(kind, cwd)
    if path:
        open_path(pane, kind, path)


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, RuntimeError, subprocess.SubprocessError) as error:
        subprocess.run(["tmux", "display-message", "Picker: " + str(error)])
        sys.exit(1)
