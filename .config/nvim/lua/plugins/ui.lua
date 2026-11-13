local function vesper_variant()
	local fallback = {
		panelBg = "#161616",
		panelFg = "#FEFEFE",
		muted = "#A0A0A0",
		darkText = "#101010",
	}
	local path = vim.fn.expand("~/.config/vesper-variant.json")
	if vim.fn.filereadable(path) ~= 1 then
		return fallback
	end

	local ok, decoded = pcall(function()
		return vim.fn.json_decode(table.concat(vim.fn.readfile(path), "\n"))
	end)
	if not ok or type(decoded) ~= "table" then
		return fallback
	end

	return vim.tbl_extend("force", fallback, decoded)
end


local function lualine_theme()
	local variant = vesper_variant()
	local bg = variant.panelBg
	local fg = variant.panelFg
	local muted = variant.muted
	local mint = "#99FFE4"
	local orange = "#FFCFA8"
	local white = "#FEFEFE"
	local red = "#FF8080"
	local dark = variant.darkText

	return {
		normal = {
			a = { fg = dark, bg = muted, gui = "bold" },
			b = { fg = fg, bg = bg },
			c = { fg = fg, bg = bg },
		},
		insert = { a = { fg = dark, bg = mint, gui = "bold" } },
		visual = { a = { fg = dark, bg = white, gui = "bold" } },
		replace = { a = { fg = dark, bg = red, gui = "bold" } },
		command = { a = { fg = dark, bg = orange, gui = "bold" } },
		inactive = {
			a = { fg = muted, bg = bg, gui = "bold" },
			b = { fg = muted, bg = bg },
			c = { fg = muted, bg = bg },
		},
	}
end

return {
	{
		"nvim-tree/nvim-web-devicons",
		lazy = false,
		priority = 1000,
		opts = {
			color_icons = true,
			default = true,
			strict = true,
		},
	},

	{
		"folke/ts-comments.nvim",
		event = "VeryLazy",
		opts = {},
	},

	{
		"nvim-lualine/lualine.nvim",
		dependencies = { "nvim-tree/nvim-web-devicons" },
		opts = {
			options = {
				theme = lualine_theme(),
				icons_enabled = true,
				section_separators = { left = "", right = "" },
				component_separators = { left = "|", right = "|" },
				globalstatus = true,
			},
			sections = {
				lualine_a = {},
				lualine_b = {},
				lualine_c = { "%<%f %h%m%r%w" },
				lualine_x = {
					{
						"diff",
						symbols = { added = "+", modified = "~", removed = "-" },
						diff_color = {
							added = { fg = "#A8CC8C" },
							modified = { fg = "#FFCFA8" },
							removed = { fg = "#F28779" },
						},
					},
					{ "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
				},
				lualine_y = { "filetype", "progress" },
				lualine_z = {},
			},
		},
		config = function(_, opts)
			local lualine = require("lualine")
			opts.options.theme = lualine_theme()
			lualine.setup(opts)

			local group = vim.api.nvim_create_augroup("LualineRefresh", { clear = true })
			vim.api.nvim_create_autocmd("ColorScheme", {
				group = group,
				callback = function()
					opts.options.theme = lualine_theme()
					lualine.setup(opts)
					lualine.refresh({ place = { "statusline" } })
				end,
			})
			vim.api.nvim_create_autocmd("User", {
				group = group,
				pattern = "GitsignsStatusUpdate",
				callback = function()
					lualine.refresh({ place = { "statusline" } })
				end,
			})
		end,
	},

	{
		"akinsho/toggleterm.nvim",
		version = "*",
		keys = {
			{ "<leader>-", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (split)" },
		},
		opts = {
			start_in_insert = true,
			insert_mappings = true,
			persist_mode = true,
			close_on_exit = true,
			shade_terminals = false,
			highlights = {
				Normal = { link = "TermNormal" },
				NormalFloat = { link = "TermNormal" },
				FloatBorder = { link = "FloatBorder" },
			},
			size = function(term)
				if term.direction == "horizontal" then
					return math.max(8, math.floor(vim.o.lines * 0.3))
				end
				if term.direction == "vertical" then
					return math.max(40, math.floor(vim.o.columns * 0.4))
				end
				return 20
			end,
			direction = "float",
			float_opts = { border = "rounded" },
		},
		config = function(_, opts)
			require("toggleterm").setup(opts)
			vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Terminal: Window command" })
		end,
	},
}
