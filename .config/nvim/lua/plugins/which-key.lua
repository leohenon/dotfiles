return {
	{
		"folke/which-key.nvim",
		event = "VeryLazy",
		cmd = { "WhichKeyEnable", "WhichKeyDisable", "WhichKeyToggle" },
		init = function()
			vim.o.timeout = true
			vim.o.timeoutlen = 300
		end,
		opts = {
			triggers = {},
			icons = {
				breadcrumb = "»",
				separator = "➜",
				group = "+",
			},
		},
		config = function(_, opts)
			local wk = require("which-key")
			local modes = { "n", "x" }
			local enabled = false

			wk.setup(opts)

			local function set_enabled(value)
				enabled = value
				vim.g.which_key_enabled = value

				for _, mode in ipairs(modes) do
					if value then
						vim.keymap.set(mode, "<leader>", function()
							wk.show({ keys = "<leader>" })
						end, {
							desc = "which-key-trigger",
							nowait = true,
							silent = true,
						})
					else
						pcall(vim.keymap.del, mode, "<leader>")
					end
				end
			end

			vim.api.nvim_create_user_command("WhichKeyEnable", function()
				set_enabled(true)
				vim.notify("which-key enabled", vim.log.levels.INFO)
			end, { desc = "Enable which-key UI" })

			vim.api.nvim_create_user_command("WhichKeyDisable", function()
				set_enabled(false)
				vim.notify("which-key disabled", vim.log.levels.INFO)
			end, { desc = "Disable which-key UI" })

			vim.api.nvim_create_user_command("WhichKeyToggle", function()
				set_enabled(not enabled)
				vim.notify("which-key " .. (enabled and "enabled" or "disabled"), vim.log.levels.INFO)
			end, { desc = "Toggle which-key UI" })

			set_enabled(false)
		end,
	},
}
