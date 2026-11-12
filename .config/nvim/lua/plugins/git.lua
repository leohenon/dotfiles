local function staged_hunks_to_qflist()
	local bufname = vim.api.nvim_buf_get_name(0)
	local cwd = bufname ~= "" and vim.fs.dirname(bufname) or vim.uv.cwd()

	vim.system({ "git", "rev-parse", "--show-toplevel" }, { cwd = cwd, text = true }, function(root_result)
		vim.schedule(function()
			if root_result.code ~= 0 then
				vim.notify("Staged hunks: not inside a Git repository", vim.log.levels.ERROR)
				return
			end

			local root = vim.trim(root_result.stdout or "")
			vim.system({
				"git",
				"-c",
				"core.quotePath=false",
				"diff",
				"--cached",
				"--no-ext-diff",
				"--no-color",
				"--unified=0",
				"--no-prefix",
				"--",
			}, { cwd = root, text = true }, function(diff_result)
				vim.schedule(function()
					if diff_result.code ~= 0 then
						vim.notify("Staged hunks: " .. vim.trim(diff_result.stderr or "git diff failed"), vim.log.levels.ERROR)
						return
					end

					local items = {}
					local old_path
					local path
					local in_header = false
					local hunk

					local function finish_hunk()
						if not hunk or not hunk.path then
							hunk = nil
							return
						end

						local kind = hunk.old_count == 0 and "Added"
							or hunk.new_count == 0 and "Removed"
							or "Changed"
						local old_range = tostring(hunk.old_start)
							.. (hunk.old_count ~= 1 and "," .. hunk.old_count or "")
						local new_range = tostring(hunk.new_start)
							.. (hunk.new_count ~= 1 and "," .. hunk.new_count or "")
						local line = hunk.added_line or hunk.removed_line or ""

						items[#items + 1] = {
							filename = root .. "/" .. hunk.path,
							lnum = hunk.new_count > 0 and hunk.new_start or math.max(hunk.new_start, 1),
							col = 1,
							text = ("%-7s (-%s +%s): %s"):format(kind, old_range, new_range, line),
						}
						hunk = nil
					end

					for line in (diff_result.stdout or ""):gmatch("[^\r\n]+") do
						if vim.startswith(line, "diff --git ") then
							finish_hunk()
							old_path, path = nil, nil
							in_header = true
						elseif in_header and vim.startswith(line, "--- ") then
							local value = line:sub(5):gsub("\t.*$", "")
							old_path = value ~= "/dev/null" and value or nil
						elseif in_header and vim.startswith(line, "+++ ") then
							local value = line:sub(5):gsub("\t.*$", "")
							path = value ~= "/dev/null" and value or old_path
						else
							local old_start, old_count, new_start, new_count =
								line:match("^@@ %-(%d+),?(%d*) %+(%d+),?(%d*) @@")
							if old_start then
								finish_hunk()
								in_header = false
								hunk = {
									path = path or old_path,
									old_start = tonumber(old_start),
									old_count = old_count == "" and 1 or tonumber(old_count),
									new_start = tonumber(new_start),
									new_count = new_count == "" and 1 or tonumber(new_count),
								}
							elseif hunk and vim.startswith(line, "+") and not hunk.added_line then
								hunk.added_line = line:sub(2)
							elseif hunk and vim.startswith(line, "-") and not hunk.removed_line then
								hunk.removed_line = line:sub(2)
							end
						end
					end
					finish_hunk()

					vim.fn.setqflist({}, " ", { title = "Staged hunks", items = items })
					if #items == 0 then
						vim.notify("No staged hunks", vim.log.levels.INFO)
						return
					end

					local ok, trouble = pcall(require, "trouble")
					if ok then
						trouble.open("qflist")
					else
						vim.cmd.copen()
					end
				end)
			end)
		end)
	end)
end

return {
	{
		"lewis6991/gitsigns.nvim",
		event = { "BufReadPre", "BufNewFile" },
		opts = {
			current_line_blame = false,
			signcolumn = true,
			numhl = true,
			linehl = false,
			attach_to_untracked = true,
		},
		keys = {
			{ "]h",         function() require("gitsigns").next_hunk() end,                 desc = "Next hunk" },
			{ "[h",         function() require("gitsigns").prev_hunk() end,                 desc = "Prev hunk" },
			{ "<leader>hp", function() require("gitsigns").preview_hunk() end,              desc = "Preview hunk" },
			{ "<leader>hi", function() require("gitsigns").preview_hunk_inline() end,       desc = "Preview hunk inline" },
			{ "<leader>hq", function() require("gitsigns").setqflist(0) end,                desc = "Hunks: current file (Trouble)" },
			{ "<leader>hQ", function() require("gitsigns").setqflist("all") end,            desc = "Hunks: repository (Trouble)" },
			{ "<leader>hS", staged_hunks_to_qflist,                                        desc = "Hunks: staged repository (Trouble)" },
			{ "<leader>hs", function() require("gitsigns").stage_hunk() end,                desc = "Stage hunk" },
			{ "<leader>hr", function() require("gitsigns").reset_hunk() end,                desc = "Reset hunk" },
			{ "<leader>hb", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle line blame" },
		},
	},
	{
		"tpope/vim-fugitive",
		cmd = { "Git", "G", "Gdiffsplit", "Gvdiffsplit", "Gclog" },
		keys = {
			{ "<leader>gs", "<cmd>botright Git<cr>", desc = "Source control (Fugitive)" },
		},
		config = function()
			local function highlights()
				local groups = {
					fugitiveHeader = { fg = "#A0A0A0", bold = true },
					fugitiveHeading = { fg = "#FEFEFE", bold = true },
					fugitiveStagedHeading = { fg = "#82D9C2", bold = true },
					fugitiveUnstagedHeading = { fg = "#FFCFA8", bold = true },
					fugitiveUntrackedHeading = { fg = "#FF8080", bold = true },
					fugitiveStagedModifier = { fg = "#82D9C2" },
					fugitiveUnstagedModifier = { fg = "#FFCFA8" },
					fugitiveUntrackedModifier = { fg = "#FF8080" },
					fugitiveHash = { fg = "#A0A0A0" },
					fugitiveSymbolicRef = { fg = "#82D9C2", bold = true },
					fugitiveCount = { fg = "#A0A0A0" },
					FugitiveDiffAdded = { fg = "#82D9C2" },
					FugitiveDiffRemoved = { fg = "#FF8080" },
					FugitiveDiffLine = { fg = "#FFCFA8" },
				}
				for name, value in pairs(groups) do
					vim.api.nvim_set_hl(0, name, value)
				end
			end

			local function clean_window()
				if not vim.tbl_contains({ "fugitive", "fugitiveblame", "git" }, vim.bo.filetype) then
					return
				end
				vim.opt_local.number = false
				vim.opt_local.relativenumber = false
				vim.opt_local.signcolumn = "no"
				vim.opt_local.list = false
				vim.opt_local.wrap = false
				vim.opt_local.spell = false
				vim.opt_local.cursorline = vim.bo.filetype == "fugitive"
				vim.opt_local.winhighlight:append({
					diffAdded = "FugitiveDiffAdded",
					diffRemoved = "FugitiveDiffRemoved",
					diffLine = "FugitiveDiffLine",
				})
			end

			local group = vim.api.nvim_create_augroup("FugitiveAppearance", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = "fugitive",
				callback = function(event)
					for _, key in ipairs({ "<Tab>", "z" }) do
						vim.keymap.set("n", key, "=", {
							buffer = event.buf,
							remap = true,
							desc = "Toggle inline diff",
						})
					end
				end,
			})
			vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = highlights })
			vim.api.nvim_create_autocmd("FileType", {
				group = group,
				pattern = { "fugitive", "fugitiveblame", "git" },
				callback = clean_window,
			})
			vim.api.nvim_create_autocmd("BufWinEnter", { group = group, callback = clean_window })
			highlights()
		end,
	},
	{
		"esmuellert/codediff.nvim",
		cmd = { "CodeDiff", "CodeDiffClose" },
		keys = {
			{ "<leader>dv", "<cmd>CodeDiff<cr>", desc = "Diff: open (unstaged)" },
			{ "<leader>dV", "<cmd>CodeDiff --staged<cr>", desc = "Diff: open (staged)" },
			{ "<leader>dc", "<cmd>CodeDiffClose<cr>", desc = "Diff: close" },
			{ "<leader>df", "<cmd>CodeDiff file HEAD<cr>", desc = "Diff: current file vs HEAD" },
			{ "<leader>dF", "<cmd>CodeDiff history<cr>", desc = "Diff: repo history" },
			{ "<leader>ch", "<cmd>CodeDiff history %<cr>", desc = "Diff: file history" },
		},
		opts = {
			highlights = {
				line_insert = "#203A34",
				line_delete = "#3A2020",
			},
			diff = { layout = "side-by-side", filler_text = "╱", compact = true },
			keymaps = {
				view = {
					quit = { "q", "<leader>dc" },
					next_file = { "]f", "<Tab>" },
					prev_file = { "[f", "<S-Tab>" },
					toggle_explorer = "<leader>dt",
					focus_explorer = "<leader>b",
				},
			},
		},
		config = function(_, opts)
			require("codediff").setup(opts)
			vim.api.nvim_create_autocmd("User", {
				group = vim.api.nvim_create_augroup("CodeDiffExplorerToggle", { clear = true }),
				pattern = "CodeDiffOpen",
				callback = function(event)
					local lifecycle = require("codediff.ui.lifecycle")
					local tab = event.data.tabpage
					if not lifecycle.get_panel_view(tab) then
						return
					end
					lifecycle.set_tab_keymap(tab, "n", "<leader>e", function()
						local panel = lifecycle.get_panel_view(tab)
						if not panel then
							return
						end
						local was_hidden = panel.is_hidden
						require("codediff.ui.explorer").toggle_visibility(panel)
						if was_hidden and panel.split and vim.api.nvim_win_is_valid(panel.split.winid) then
							vim.api.nvim_set_current_win(panel.split.winid)
						end
					end, { desc = "Toggle files panel (focus when opening)" })
				end,
			})
			vim.api.nvim_create_user_command("CodeDiffClose", function()
				local lifecycle = require("codediff.ui.lifecycle")
				local tab = vim.api.nvim_get_current_tabpage()
				if lifecycle.get_session(tab) then
					lifecycle.close(tab)
				end
			end, { desc = "Close the current CodeDiff tab" })
		end,
	},
	{
		"pwntester/octo.nvim",
		cmd = "Octo",
		keys = {
			{ "<leader>oo", "<cmd>Octo<cr>", desc = "GitHub: Octo commands" },
			{ "<leader>op", "<cmd>Octo pr list<cr>", desc = "GitHub: pull requests" },
			{ "<leader>oi", "<cmd>Octo issue list<cr>", desc = "GitHub: issues" },
			{ "<leader>on", "<cmd>Octo notification list<cr>", desc = "GitHub: notifications" },
			{
				"<leader>or",
				function()
					local r = require("octo.config").values.default_remote
					r[1], r[2] = r[2], r[1]
					vim.notify("Octo default remote -> " .. r[1])
				end,
				desc = "GitHub: toggle fork/upstream",
			},
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"nvim-telescope/telescope.nvim",
			"nvim-tree/nvim-web-devicons",
		},
		opts = {
			picker = "telescope",
			enable_builtin = true,
			default_remote = { "origin", "upstream" },
		},
	},
}
