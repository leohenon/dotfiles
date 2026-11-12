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
		"NeogitOrg/neogit",
		cmd = "Neogit",
		init = function()
			local namespace = vim.api.nvim_create_namespace("NeogitDiffstatTotals")
			local request = 0

			local function get_totals(cwd, staged, callback)
				local args = { "git", "diff" }
				if staged then
					table.insert(args, "--cached")
				end
				vim.list_extend(args, { "--numstat", "--" })

				vim.system(args, { cwd = cwd, text = true }, function(result)
					local additions, deletions = 0, 0
					if result.code == 0 then
						for line in (result.stdout or ""):gmatch("[^\r\n]+") do
							local added, deleted = line:match("^(%d+)%s+(%d+)%s+")
							additions = additions + (tonumber(added) or 0)
							deletions = deletions + (tonumber(deleted) or 0)
						end
					end
					callback(additions, deletions)
				end)
			end

			vim.api.nvim_create_autocmd("User", {
				group = vim.api.nvim_create_augroup("NeogitDiffstatTotals", { clear = true }),
				pattern = { "NeogitStatusRefreshed", "NeogitDiffLoaded" },
				callback = function()
					request = request + 1
					local current_request = request
					local ok, status = pcall(function()
						return require("neogit.buffers.status").instance()
					end)
					if not ok or not status or not status.buffer then
						return
					end

					local bufnr = status.buffer.handle
					local cwd = status.root or status.cwd
					if not vim.api.nvim_buf_is_valid(bufnr) or not cwd then
						return
					end

					local totals = {}
					local pending = 2
					local function done(kind, additions, deletions)
						totals[kind] = { additions = additions, deletions = deletions }
						pending = pending - 1
						if pending > 0 then
							return
						end

						vim.schedule(function()
							if current_request ~= request or not vim.api.nvim_buf_is_valid(bufnr) then
								return
							end

							vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
							for row, line in ipairs(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)) do
								local kind = line:find("Unstaged changes", 1, true) and "unstaged"
									or line:find("Staged changes", 1, true) and "staged"
								local total = kind and totals[kind] or nil
								if total then
									vim.api.nvim_buf_set_extmark(bufnr, namespace, row - 1, 0, {
										virt_text = {
											{ ("  +%d"):format(total.additions), "NeogitDiffAdditions" },
											{ (" -%d"):format(total.deletions), "NeogitDiffDeletions" },
										},
										virt_text_pos = "eol",
										hl_mode = "combine",
									})
								end
							end
						end)
					end

					get_totals(cwd, false, function(additions, deletions)
						done("unstaged", additions, deletions)
					end)
					get_totals(cwd, true, function(additions, deletions)
						done("staged", additions, deletions)
					end)
				end,
			})
		end,
		keys = {
			{ "<leader>gs", function() require("neogit").open({ kind = "replace" }) end, desc = "Source control (Neogit)" },
		},
		dependencies = {
			"nvim-lua/plenary.nvim",
			"sindrets/diffview.nvim",
			"nvim-telescope/telescope.nvim",
		},
		opts = {
			kind = "replace",
			disable_signs = false,
			disable_context_highlighting = false,
			mappings = {
				status = {
					["<CR>"] = "GoToFile",
				},
			},
			integrations = {
				diffview = true,
				telescope = true,
			},
		},
	},
	{
		"sindrets/diffview.nvim",
		cmd = { "DiffviewOpen", "DiffviewClose", "DiffviewFileHistory", "DiffviewFocusFiles", "DiffviewToggleFiles" },
		keys = {
			{ "<leader>dv", "<cmd>DiffviewOpen<cr>",                                                            desc = "Diff: open (unstaged)" },
			{ "<leader>dV", "<cmd>DiffviewOpen --staged<cr>",                                                   desc = "Diff: open (staged)" },
			{ "<leader>dc", "<cmd>DiffviewClose<cr>",                                                           desc = "Diff: close" },
			{ "<leader>dt", "<cmd>DiffviewToggleFiles<cr>",                                                     desc = "Diff: toggle files panel" },
			{ "<leader>df", function()
				vim.g.diffview_single_file = true
				vim.cmd("DiffviewOpen HEAD -- %")
			end,                                                                                                desc = "Diff: current file vs HEAD" },
			{ "<leader>dF", "<cmd>DiffviewFileHistory<cr>",                                                     desc = "Diff: repo history" },
			{ "<leader>ch", "<cmd>DiffviewFileHistory %<cr>",                                                   desc = "Diff: file history" },
		},
		opts = {
			enhanced_diff_hl = true,
			keymaps = {
				view = {
					{ "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle the file panel" } },
				},
				file_panel = {
					{ "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle the file panel" } },
				},
				file_history_panel = {
					{ "n", "<leader>e", "<cmd>DiffviewToggleFiles<cr>", { desc = "Toggle the file panel" } },
				},
			},
			diff_algorithm = "myers",
			diff_opts = {
				"--unified=3",
				"--no-color-moved",
				"--patience",
				"--minimal",
			},
			view = {
				default = {
					layout = "diff2_horizontal",
				},
			},
				hooks = {
				diff_buf_win_enter = function(bufnr, winid, ctx)
					if ctx.layout_name:match("^diff2") then
						if ctx.symbol == "a" then
							vim.opt_local.winhl = table.concat({
								"DiffAdd:DiffviewDiffRed",
								"DiffDelete:DiffviewDiffFiller",
								"DiffChange:DiffviewDiffRed",
								"DiffText:DiffviewDiffRed",
							}, ",")
						elseif ctx.symbol == "b" then
							vim.opt_local.winhl = table.concat({
								"DiffAdd:DiffviewDiffGreen",
								"DiffDelete:DiffviewDiffFiller",
								"DiffChange:DiffviewDiffGreen",
								"DiffText:DiffviewDiffGreen",
							}, ",")
						end
					end
				end,
				view_opened = function()
					if vim.g.diffview_single_file then
						vim.cmd("DiffviewToggleFiles")
						vim.g.diffview_single_file = nil
					end

					vim.opt.fillchars:append({ diff = "╱" })
					vim.api.nvim_set_hl(0, "DiffviewDiffRed", { bg = "#3A2020" })
					vim.api.nvim_set_hl(0, "DiffviewDiffGreen", { bg = "#203A34" })
					vim.api.nvim_set_hl(0, "DiffviewDiffFiller", { bg = "none", fg = "#6b6b6b" })
				end,
			},
		},
		config = function(_, opts)
			require("diffview").setup(opts)

			local function set_diffview_hl()
				vim.api.nvim_set_hl(0, "DiffviewDiffRed", { bg = "#3A2020" })
				vim.api.nvim_set_hl(0, "DiffviewDiffGreen", { bg = "#203A34" })
				vim.api.nvim_set_hl(0, "DiffviewDiffFiller", { bg = "none", fg = "#6b6b6b" })
				vim.api.nvim_set_hl(0, "DiffviewFilePanelInsertions", { fg = "#6BB29F", bold = true })
				vim.api.nvim_set_hl(0, "DiffviewFilePanelDeletions", { fg = "#D16969", bold = true })
				vim.api.nvim_set_hl(0, "DiffviewStatusAdded", { fg = "#A8CC8C", bold = true })
				vim.api.nvim_set_hl(0, "DiffviewStatusModified", { fg = "#FFCFA8", bold = true })
				vim.api.nvim_set_hl(0, "DiffviewStatusDeleted", { fg = "#F28779", bold = true })
			end

			set_diffview_hl()
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = set_diffview_hl,
			})

			local group_folds = vim.api.nvim_create_augroup("DiffviewFolds", { clear = true })
			vim.api.nvim_create_autocmd("FileType", {
				group = group_folds,
				pattern = { "DiffviewDiff" },
				callback = function()
					vim.opt_local.foldmethod = "manual"
					vim.opt_local.foldenable = false
					vim.opt_local.foldlevel = 99
					vim.opt_local.modifiable = false
					vim.opt_local.readonly = true
				end,
			})

			local group = vim.api.nvim_create_augroup("DiffviewHighlightOverrides", { clear = true })
			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "DiffviewViewOpened",
				callback = function()
					if vim.g.diffview_single_file then
						vim.cmd("DiffviewToggleFiles")
						vim.g.diffview_single_file = nil
					end

					set_diffview_hl()
				end,
			})
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
