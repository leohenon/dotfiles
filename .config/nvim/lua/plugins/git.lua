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
			{ "<leader>hs", function() require("gitsigns").stage_hunk() end,                desc = "Stage hunk" },
			{ "<leader>hr", function() require("gitsigns").reset_hunk() end,                desc = "Reset hunk" },
			{ "<leader>hb", function() require("gitsigns").toggle_current_line_blame() end, desc = "Toggle line blame" },
		},
	},
	{
		"NeogitOrg/neogit",
		cmd = "Neogit",
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
					vim.api.nvim_set_hl(0, "DiffviewDiffRed", { bg = "#3c1f1f" })
					vim.api.nvim_set_hl(0, "DiffviewDiffGreen", { bg = "#1f3825" })
					vim.api.nvim_set_hl(0, "DiffviewDiffFiller", { bg = "none", fg = "#6e7681" })
				end,
			},
		},
		config = function(_, opts)
			require("diffview").setup(opts)
			vim.api.nvim_create_autocmd("ColorScheme", {
				callback = function()
					vim.api.nvim_set_hl(0, "DiffviewDiffRed", { bg = "#3c1f1f" })
					vim.api.nvim_set_hl(0, "DiffviewDiffGreen", { bg = "#1f3825" })
					vim.api.nvim_set_hl(0, "DiffviewDiffFiller", { bg = "none", fg = "#6e7681" })
				end,
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

					vim.api.nvim_set_hl(0, "DiffviewDiffRed", { bg = "#3c1f1f" })
					vim.api.nvim_set_hl(0, "DiffviewDiffGreen", { bg = "#1f3825" })
					vim.api.nvim_set_hl(0, "DiffviewDiffFiller", { bg = "none", fg = "#6e7681" })
				end,
			})
		end,
	},
}
