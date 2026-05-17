import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { VERSION } from "@earendil-works/pi-coding-agent";

function renderHeader(theme: Theme, _terminalWidth: number): string[] {
  const art = [
    " ____  _",
    "|  _ \\(_) ",
    "| |_) | |",
    "|  __/| |",
    "|_|   |_|",
  ];

  return [
    "",
    ...art.map((line) => `  ${theme.fg("accent", line)}`),
    `  ${theme.fg("dim", `v${VERSION}`)}`,
    "",
  ];
}

export default function piStartupHeader(pi: ExtensionAPI) {
  pi.on("session_start", async (_event, ctx) => {
    if (!ctx.hasUI) return;

    ctx.ui.setHeader((_tui, theme) => ({
      render(width: number) {
        return renderHeader(theme, width);
      },
      invalidate() {},
    }));
  });
}
