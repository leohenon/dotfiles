"""Unit and isolated-tmux integration tests; never touches the user's server."""
import importlib.util
import os
import subprocess
import tempfile
import unittest
import uuid
from pathlib import Path
from unittest.mock import patch

SPEC = importlib.util.spec_from_file_location("navigation", Path(__file__).with_name("jump-pi-anchor.py"))
assert SPEC is not None and SPEC.loader is not None
nav = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(nav)


class NavigationTests(unittest.TestCase):
    def test_only_typed_hyperlinks(self):
        text = ("-20 literal pi-anchor://v1/prompt/fake and ↳ diff\n"
                "-10 \x1b]8;;pi-anchor://v1/prompt/p1\x1b\\P\x1b]8;;\x1b\\rompt\n"
                "-5 \x1b]8;;pi-anchor://v1/diff/d%2F1\x07D\x1b]8;;\x07iff\n")
        anchors = nav.parse_anchors(text)
        self.assertEqual([a[:2] for a in anchors], [[-10, "prompt"], [-5, "diff"]])
        self.assertEqual(nav.target_row(anchors, "prompt", "prev", 0), -10)
        self.assertIsNone(nav.target_row(anchors, "prompt", "prev", -10))
        self.assertEqual(nav.target_row(anchors, "diff", "next", -10), -5)

    def test_notice_lasts_one_second_without_key_repeat_dismissal(self):
        with patch.object(nav, "tmux") as command:
            nav.notify("%0", "No prev prompt")
            command.assert_called_once_with("display-message", "-N", "-d", "1000", "-t", "%0", "No prev prompt")

    def test_invalid_scheme_is_not_an_anchor(self):
        self.assertEqual(nav.parse_anchors("0 \x1b]8;;https://example.com\x07x\x1b]8;;\x07\n"), [])


class TmuxIntegrationTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.socket = "pi-navigation-test-" + uuid.uuid4().hex
        self.directory = Path(self.temp.name)
        emitter = self.directory / "emit.py"
        self.fifo = self.directory / "input"
        os.mkfifo(self.fifo)
        emitter.write_text('''import subprocess, sys
for i in range(80):
    kind = "prompt" if i in (5, 35, 65) else "diff" if i in (10, 40, 70) else None
    prefix = f"\\033]8;;pi-anchor://v1/{kind}/{i}\\033\\\\" if kind else ""
    suffix = "\\033]8;;\\033\\\\" if kind else ""
    print(f"{prefix}row{i:03}{suffix} ordinary ↳ diff text")
sys.stdout.flush()
subprocess.run(["tmux", "wait-for", "-S", "ready"])
for command in open(sys.argv[1]):
    for i in range(300): print(f"new{i:03}")
    sys.stdout.flush()
    subprocess.run(["tmux", "wait-for", "-S", "grown"])
subprocess.run(["tmux", "wait-for", "finish"])
''')
        config = self.directory / "tmux.conf"
        live_config = Path(__file__).resolve().parents[1] / "tmux.conf"
        hook = next(line for line in live_config.read_text().splitlines()
                    if line.startswith("set-hook -g after-copy-mode[71]"))
        config.write_text("set -g history-limit 100\n" + hook + "\n")
        self.run_tmux("-f", str(config), "new-session", "-d", "-x", "80", "-y", "12", "-s", "test", f"python3 -u {emitter} {self.fifo}")
        self.run_tmux("wait-for", "ready")
        self.patcher = patch.object(nav, "tmux", self.run_tmux)
        self.patcher.start()
        self.cache_patch = patch.object(nav, "cache_path", lambda pane: self.directory / "cache.json")
        self.cache_patch.start()

    def tearDown(self):
        self.cache_patch.stop()
        self.patcher.stop()
        self.run_tmux("kill-server")
        self.temp.cleanup()

    def run_tmux(self, *args):
        return subprocess.run(["tmux", "-L", self.socket, *args], check=True,
                              capture_output=True, text=True, timeout=10).stdout

    def enter(self, numbering):
        self.run_tmux("set-window-option", "-t", "%0", "copy-mode-line-numbers", numbering)
        self.run_tmux("copy-mode", "-t", "%0")

    def cursor_line(self):
        return self.run_tmux("display-message", "-p", "-t", "%0", "#{copy_cursor_line}").strip()

    def test_entry_defers_indexing_until_first_jump(self):
        self.run_tmux("set-window-option", "copy-mode-line-numbers", "relative")
        # Equivalent to prefix-v, including the actual after-copy-mode hook.
        self.run_tmux("copy-mode", "-t", "%0", ";", "send-keys", "-t", "%0",
                      "-X", "line-numbers-off")
        self.assertFalse(nav.cache_path("%0").exists())
        self.assertIn("pi-nav-%0", self.run_tmux("list-buffers", "-F", "#{buffer_name}"))
        history = -int(nav.snapshot("%0").partition(" ")[0])
        limit = int(self.run_tmux("display-message", "-p", "#{copy_position_limit}"))
        self.assertEqual(limit, history)
        nav.jump("%0", "prompt", "prev")
        self.assertTrue(self.cursor_line().startswith("row065"))
        self.assertTrue(nav.cache_path("%0").exists())
        self.assertNotIn("pi-nav-%0", self.run_tmux("list-buffers", "-F", "#{buffer_name}"))
        self.run_tmux("send-keys", "-t", "%0", "-X", "cancel")
        self.enter("relative")  # Prefix-[ keeps the configured numbering.
        limit = int(self.run_tmux("display-message", "-p", "#{copy_position_limit}"))
        self.assertGreater(limit, history)
        nav.jump("%0", "diff", "prev")
        self.assertTrue(self.cursor_line().startswith("row070"))

    def test_navigation_boundaries_notify_once_and_reset(self):
        self.enter("relative")
        with patch.object(nav, "notify") as notify:
            for kind in ("prompt", "diff"):
                for direction in ("prev", "next"):
                    notify.reset_mock()
                    for _ in range(4):
                        nav.jump("%0", kind, direction)
                    before = self.cursor_line()
                    nav.jump("%0", kind, direction)
                    self.assertEqual(self.cursor_line(), before)
                    notify.assert_called_once_with("%0", f"No {direction} {kind}")
            # A successful move rearms the boundary notice.
            notify.reset_mock()
            nav.jump("%0", "diff", "prev")
            nav.jump("%0", "diff", "next")
            nav.jump("%0", "diff", "next")
            nav.jump("%0", "diff", "next")
            notify.assert_called_once_with("%0", "No next diff")
            # New copy-mode entry rearms notices even for identical history.
            self.run_tmux("send-keys", "-t", "%0", "-X", "cancel")
            self.enter("relative")
            notify.reset_mock()
            nav.jump("%0", "diff", "next")
            nav.jump("%0", "diff", "next")
            notify.assert_called_once_with("%0", "No next diff")

    def test_fast_repeats_do_not_queue_helpers(self):
        stub = self.directory / "jump.py"
        log = self.directory / "calls"
        stub.write_text(
            "import subprocess, sys\n"
            f"with open({str(log)!r}, 'a') as f: f.write(' '.join(sys.argv[1:]) + '\\n')\n"
            "subprocess.run(['tmux', 'wait-for', '-S', 'jump-started'], check=True)\n"
            "subprocess.run(['tmux', 'wait-for', 'jump-release'], check=True)\n")
        config = Path(__file__).resolve().parents[1] / "tmux.conf"
        bindings = [line for line in config.read_text().splitlines()
                    if line.startswith("bind -T copy-mode-vi") and "@pi-nav-busy" in line]
        self.assertEqual(len(bindings), 4)
        binding_file = self.directory / "bindings.conf"
        binding_file.write_text("\n".join(
            line.replace("~/.config/tmux/scripts/jump-pi-anchor.py", str(stub))
                .replace("@pi-nav-busy'", "@pi-nav-busy; tmux wait-for -S jump-finished'")
            for line in bindings))
        self.run_tmux("source-file", str(binding_file))
        self.run_tmux("set-window-option", "mode-keys", "vi")
        self.enter("relative")
        self.run_tmux("send-keys", "-t", "%0", "[")
        self.run_tmux("wait-for", "jump-started")
        self.run_tmux("send-keys", "-t", "%0", *(["["] * 100))
        self.assertEqual(log.read_text().splitlines(), ["%0 prompt prev"])
        self.run_tmux("wait-for", "-S", "jump-release")
        self.run_tmux("wait-for", "jump-finished")
        self.assertEqual(self.run_tmux("show-options", "-pqv", "-t", "%0", "@pi-nav-busy"), "")
        # Reverse immediately: no pending 100-helper backlog to drain.
        self.run_tmux("send-keys", "-t", "%0", "]")
        self.run_tmux("wait-for", "jump-started")
        self.assertEqual(log.read_text().splitlines(), ["%0 prompt prev", "%0 prompt next"])
        self.run_tmux("wait-for", "-S", "jump-release")
        self.run_tmux("wait-for", "jump-finished")

    def test_background_jump_aborts_if_cursor_moves(self):
        self.enter("relative")
        initial = nav.copy_state("%0")
        moved = initial.copy()
        moved[1] = str(int(moved[1]) - 1)
        before = self.cursor_line()
        with patch.object(nav, "copy_state", side_effect=[initial, moved]), patch.object(nav, "notify") as notify:
            nav.jump("%0", "prompt", "prev")
            notify.assert_not_called()
        self.assertEqual(self.cursor_line(), before)

    def test_navigation_all_number_modes_and_frozen_output(self):
        for mode in ("off", "default", "absolute", "relative", "hybrid"):
            with self.subTest(mode=mode):
                self.enter(mode)
                nav.jump("%0", "prompt", "prev")
                self.assertTrue(self.cursor_line().startswith("row065"), self.cursor_line())
                nav.jump("%0", "prompt", "prev")
                self.assertTrue(self.cursor_line().startswith("row035"), self.cursor_line())
                nav.jump("%0", "diff", "next")
                self.assertTrue(self.cursor_line().startswith("row040"), self.cursor_line())
                nav.jump("%0", "diff", "prev")
                self.assertTrue(self.cursor_line().startswith("row010"), self.cursor_line())
                nav.jump("%0", "prompt", "next")
                self.assertTrue(self.cursor_line().startswith("row035"), self.cursor_line())
                self.run_tmux("send-keys", "-t", "%0", "-X", "cancel")
        self.enter("relative")
        before = nav.snapshot("%0")
        self.fifo.write_text("grow\n")
        self.run_tmux("wait-for", "grown")
        self.assertEqual(nav.snapshot("%0"), before)
        nav.jump("%0", "prompt", "prev")
        self.assertTrue(self.cursor_line().startswith("row065"), self.cursor_line())
        nav.jump("%0", "prompt", "prev")
        self.assertTrue(self.cursor_line().startswith("row035"), self.cursor_line())
        self.run_tmux("resize-window", "-x", "40", "-y", "10")
        with patch.object(nav, "notify") as notify:
            nav.jump("%0", "prompt", "prev")
            self.assertEqual("Re-enter copy mode", notify.call_args[0][1])


if __name__ == "__main__":
    unittest.main()
