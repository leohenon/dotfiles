/**
 * Timestamps Extension for pi coding agent
 *
 * - Footer status: live elapsed timer during streaming
 * - Widget above editor disabled locally; my-pi-statusline renders the status
 * - /timestamps command: interactive message timeline browser
 *
 * Configure timezone via ~/.pi/agent/timestamps.json:
 *   { "timeZone": "America/Los_Angeles" }
 */

import type { ExtensionAPI, ExtensionContext } from "@mariozechner/pi-coding-agent";
import { matchesKey, Key, truncateToWidth } from "@mariozechner/pi-tui";

const CONFIG_PATH = `${process.env.HOME}/.pi/agent/timestamps.json`;
const SETTINGS_PATH = `${process.env.HOME}/.pi/agent/settings.json`;

function loadConfig(): { timeZone?: string } {
  try {
    return JSON.parse(require("node:fs").readFileSync(CONFIG_PATH, "utf-8"));
  } catch {
    return {};
  }
}

function formatTime(date: Date): string {
  const config = loadConfig();
  const opts: Intl.DateTimeFormatOptions = { hour: "2-digit", minute: "2-digit", second: "2-digit" };
  if (config.timeZone) opts.timeZone = config.timeZone;
  return date.toLocaleTimeString([], opts);
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  const s = ms / 1000;
  if (s < 60) return `${s.toFixed(1)}s`;
  const m = Math.floor(s / 60);
  const rem = s - m * 60;
  return `${m}m ${rem.toFixed(0)}s`;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function isMyStatuslineTimerEnabled(): boolean {
  try {
    const settings = JSON.parse(require("node:fs").readFileSync(SETTINGS_PATH, "utf-8"));
    if (!isRecord(settings)) return false;

    const packages = Array.isArray(settings.packages) ? settings.packages : [];
    const hasMyStatusline = packages.some((pkg: unknown) => {
      if (typeof pkg === "string") return pkg.includes("my-pi-statusline");
      return isRecord(pkg) && typeof pkg.source === "string" && pkg.source.includes("my-pi-statusline");
    });
    if (!hasMyStatusline) return false;

    const powerline = isRecord(settings.powerline) ? settings.powerline : null;
    const customItems = Array.isArray(powerline?.customItems) ? powerline.customItems : [];
    return customItems.some((item: unknown) => {
      return isRecord(item) && (item.statusKey === "timestamps" || item.id === "timestamps");
    });
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  let promptTime: Date | null = null;
  let responseTime: Date | null = null;
  let agentStartMs: number | null = null;
  let timerInterval: ReturnType<typeof setInterval> | null = null;
  let lastCtx: ExtensionContext | null = null;
  let spinnerIndex = 0;
  const spinnerFrames = ["⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏"];

  function clearTimer() {
    if (timerInterval) {
      clearInterval(timerInterval);
      timerInterval = null;
    }
  }

  function updateWidget(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;

    if (isMyStatuslineTimerEnabled()) {
      // Widget intentionally disabled only when my-pi-statusline renders the
      // same `timestamps` status via powerline.customItems.
      ctx.ui.setWidget("timestamps", undefined);
      return;
    }

    const theme = ctx.ui.theme;

    if (!promptTime) {
      ctx.ui.setWidget("timestamps", undefined);
      return;
    }

    let line = theme.fg("dim", "↑ ") + theme.fg("dim", formatTime(promptTime));

    if (responseTime && agentStartMs) {
      const duration = responseTime.getTime() - agentStartMs;
      line += theme.fg("dim", "  ↓ ") + theme.fg("dim", formatTime(responseTime));
      line += theme.fg("dim", "  ⏱ ") + theme.fg("dim", formatDuration(duration));
    }

    ctx.ui.setWidget("timestamps", [line]);
  }

  function hideBuiltInWorkingRow(ctx: ExtensionContext) {
    if (!ctx.hasUI) return;
    ctx.ui.setWorkingVisible(false);
  }

  pi.on("before_agent_start", async (_event, ctx) => {
    hideBuiltInWorkingRow(ctx);
    promptTime = new Date();
    responseTime = null;
    agentStartMs = promptTime.getTime();
    lastCtx = ctx;
    updateWidget(ctx);
  });

  pi.on("turn_start", async (_event, ctx) => {
    hideBuiltInWorkingRow(ctx);
    lastCtx = ctx;
    clearTimer();
    spinnerIndex = 0;
    timerInterval = setInterval(() => {
      if (!agentStartMs || !lastCtx) return;
      const elapsed = Date.now() - agentStartMs;
      const theme = lastCtx.ui.theme;
      const frame = spinnerFrames[spinnerIndex % spinnerFrames.length] ?? "⠋";
      spinnerIndex++;
      lastCtx.ui.setStatus("timestamps", theme.fg("accent", frame) + theme.fg("dim", ` ${formatDuration(elapsed)}`));
    }, 100);
  });

  pi.on("turn_end", async (_event, ctx) => {
    clearTimer();
  });

  pi.on("agent_end", async (event, ctx) => {
    clearTimer();
    responseTime = new Date();
    if (agentStartMs) {
      const total = Date.now() - agentStartMs;
      const theme = ctx.ui.theme;
      const messages = Array.isArray((event as any).messages) ? (event as any).messages : [];
      const lastAssistant = [...messages].reverse().find((msg: any) => msg?.role === "assistant");
      const wasAborted = lastAssistant?.stopReason === "aborted";
      const icon = wasAborted ? theme.fg("error", "✘ ") : theme.fg("success", "✓ ");
      ctx.ui.setStatus("timestamps", icon + theme.fg("dim", formatDuration(total)));
    }
    updateWidget(ctx);
  });

  pi.on("session_start", async (_event, ctx) => {
    hideBuiltInWorkingRow(ctx);
    promptTime = null;
    responseTime = null;
    agentStartMs = null;
    lastCtx = ctx;
    clearTimer();
  });

  pi.on("session_switch", async (_event, ctx) => {
    hideBuiltInWorkingRow(ctx);
    promptTime = null;
    responseTime = null;
    agentStartMs = null;
    clearTimer();
    ctx.ui.setWidget("timestamps", undefined);
    ctx.ui.setStatus("timestamps", "");
  });

  pi.on("session_shutdown", async () => {
    clearTimer();
  });

  // --- /timestamps command: interactive message timeline ---
  pi.registerCommand("timestamps", {
    description: "Browse message timestamps interactively",
    handler: async (_args, ctx) => {
      const entries = ctx.sessionManager.getBranch();

      interface MsgEntry {
        time: string;
        role: string;
        arrow: string;
        preview: string;
        fullText: string;
      }

      const msgs: MsgEntry[] = [];
      for (const entry of entries) {
        if (entry.type !== "message") continue;
        const msg = entry.message;
        if (msg.role !== "user" && msg.role !== "assistant") continue;
        const ts = entry.timestamp;
        if (!ts) continue;

        let text = "";
        if (typeof msg.content === "string") {
          text = msg.content;
        } else if (Array.isArray(msg.content)) {
          const textBlock = msg.content.find((b: any) => b.type === "text");
          text = textBlock?.text ?? "";
        }

        msgs.push({
          time: formatTime(new Date(typeof ts === "string" ? Date.parse(ts) : ts)),
          role: msg.role,
          arrow: msg.role === "user" ? "↑" : "↓",
          preview: text.replace(/\n/g, " ").slice(0, 80),
          fullText: text,
        });
      }

      if (msgs.length === 0) {
        ctx.ui.notify("No messages in session yet", "info");
        return;
      }

      await ctx.ui.custom<void>((tui, theme, _kb, done) => {
        let selected = msgs.length - 1;
        let search = "";
        let cachedWidth: number | undefined;
        let cachedLines: string[] | undefined;

        function getFiltered(): MsgEntry[] {
          if (!search) return msgs;
          const q = search.toLowerCase();
          return msgs.filter(
            (m) =>
              m.fullText.toLowerCase().includes(q) ||
              m.role.includes(q) ||
              m.time.includes(q),
          );
        }

        return {
          render(width: number): string[] {
            if (cachedLines && cachedWidth === width) return cachedLines;

            const filtered = getFiltered();
            const lines: string[] = [];
            const termH = tui.height ?? 24;

            // Search bar
            if (search) {
              lines.push(truncateToWidth(theme.fg("accent", "🔍 ") + theme.fg("text", search), width));
            } else {
              lines.push(truncateToWidth(theme.fg("dim", "type to search • ↑↓ navigate • esc close"), width));
            }
            lines.push(theme.fg("dim", "─".repeat(Math.min(width, 60))));

            if (filtered.length === 0) {
              lines.push(theme.fg("warning", "  No matches"));
              cachedWidth = width;
              cachedLines = lines;
              return lines;
            }

            // Clamp selected
            if (selected >= filtered.length) selected = filtered.length - 1;
            if (selected < 0) selected = 0;

            // Split space: top half for list, bottom half for preview
            const availH = termH - 4;
            const listH = Math.max(3, Math.floor(availH * 0.4));
            const previewH = Math.max(3, availH - listH - 1);

            // Scrollable list — keep selected item centered
            let scrollStart = selected - Math.floor(listH / 2);
            if (scrollStart < 0) scrollStart = 0;
            if (scrollStart > filtered.length - listH) scrollStart = Math.max(0, filtered.length - listH);

            for (let i = scrollStart; i < Math.min(scrollStart + listH, filtered.length); i++) {
              const m = filtered[i]!;
              const pointer = i === selected ? theme.fg("accent", "▸ ") : "  ";
              const timeStr = theme.fg("dim", m.time);
              const arrow = theme.fg("dim", ` ${m.arrow} `);
              const role = theme.fg(m.role === "user" ? "accent" : "success", m.role);
              const preview = theme.fg(i === selected ? "text" : "dim", `: ${m.preview}`);
              lines.push(truncateToWidth(pointer + timeStr + arrow + role + preview, width));
            }

            if (filtered.length > listH) {
              lines.push(theme.fg("dim", `  (${filtered.length} messages, showing ${scrollStart + 1}-${Math.min(scrollStart + listH, filtered.length)})`));
            }

            // Separator
            lines.push(theme.fg("dim", "─".repeat(Math.min(width, 60))));

            // Preview of selected message
            const sel = filtered[selected]!;
            const previewLines = sel.fullText.split("\n");
            for (let i = 0; i < Math.min(previewH, previewLines.length); i++) {
              lines.push(truncateToWidth(theme.fg("text", previewLines[i]!), width));
            }
            if (previewLines.length > previewH) {
              lines.push(theme.fg("dim", `  … ${previewLines.length - previewH} more lines`));
            }

            cachedWidth = width;
            cachedLines = lines;
            return lines;
          },

          handleInput(data: string) {
            if (matchesKey(data, Key.escape)) {
              done();
            } else if (matchesKey(data, Key.up)) {
              const filtered = getFiltered();
              if (selected > 0) selected--;
              else selected = filtered.length - 1;
            } else if (matchesKey(data, Key.down)) {
              const filtered = getFiltered();
              if (selected < filtered.length - 1) selected++;
              else selected = 0;
            } else if (matchesKey(data, Key.backspace)) {
              search = search.slice(0, -1);
              selected = 0;
            } else if (data.length === 1 && data.charCodeAt(0) >= 32) {
              search += data;
              selected = 0;
            } else {
              return;
            }
            cachedWidth = undefined;
            cachedLines = undefined;
            tui.requestRender();
          },

          invalidate() {
            cachedWidth = undefined;
            cachedLines = undefined;
          },
        };
      });
    },
  });
}
