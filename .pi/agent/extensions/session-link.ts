import { spawnSync } from "node:child_process";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

function markdownLabel(text: string): string {
	return text.replaceAll("\\", "\\\\").replaceAll("[", "\\[").replaceAll("]", "\\]");
}

export default function (pi: ExtensionAPI) {
	pi.registerCommand("link", {
		description: "Copy a Markdown link to the current session",
		handler: async (_args, ctx) => {
			const sessionFile = ctx.sessionManager.getSessionFile();
			if (!sessionFile) {
				ctx.ui.notify("This session is not persisted, so it cannot be linked", "warning");
				return;
			}

			const sessionId = ctx.sessionManager.getSessionId();
			const label = markdownLabel(pi.getSessionName() ?? `Pi session ${sessionId.slice(0, 8)}`);
			const link = `[${label}](pi-session:${encodeURIComponent(sessionFile)})`;
			const result = spawnSync("pbcopy", { input: link, encoding: "utf8" });

			if (result.error || result.status !== 0) {
				ctx.ui.notify(`Could not copy session link: ${result.error?.message ?? result.stderr}`, "error");
				return;
			}

			ctx.ui.notify("Markdown session link copied", "info");
		},
	});
}
