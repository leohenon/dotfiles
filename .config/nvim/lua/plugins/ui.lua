local function lualine_filename()
  local name = vim.api.nvim_buf_get_name(0)
  if name == "" then
    return "[No Name]"
  end

  local abs = vim.fs.normalize(vim.fn.fnamemodify(name, ":p"))
  local root = vim.fs.root(abs, { ".git" })
  if not root or root == "" then
    root = vim.fn.getcwd()
  end
  root = vim.fs.normalize(root)

  local rel = vim.fs.relpath(root, abs) or vim.fn.fnamemodify(abs, ":~")
  if vim.bo.modified then
    rel = rel .. " ●"
  end
  return rel
end

local function lualine_ahead_behind()
  local cache = vim.b._git_ahead_behind
  local now = vim.uv.hrtime()
  if cache and (now - cache.t) < 2e9 then
    return cache.v
  end

  local cwd = vim.fn.expand("%:p:h")
  if cwd == "" then
    return ""
  end

  local root =
    vim.fn.systemlist("git -C " .. vim.fn.shellescape(cwd) .. " rev-parse --show-toplevel")[1]
  if not root or root == "" then
    return ""
  end

  local out = vim.fn.systemlist(
    "git -C " .. vim.fn.shellescape(root) .. " rev-list --left-right --count HEAD...@{upstream}"
  )[1] or ""
  local ahead, behind = out:match("^(%d+)%s+(%d+)$")
  ahead = tonumber(ahead) or 0
  behind = tonumber(behind) or 0

  local parts = {}
  if behind > 0 then
    table.insert(parts, behind .. "▼")
  end
  if ahead > 0 then
    table.insert(parts, ahead .. "▲")
  end

  local value = table.concat(parts, " ")
  vim.b._git_ahead_behind = { t = now, v = value }
  return value
end

local function lualine_theme()
  local bg = "#161616"
  local fg = "#FEFEFE"
  local muted = "#A0A0A0"
  local mint = "#99FFE4"
  local orange = "#FFCFA8"
  local white = "#FEFEFE"
  local red = "#FF8080"
  local dark = "#101010"

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
    "folke/todo-comments.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
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
        lualine_b = {
          { "branch", icon = "" },
          { lualine_ahead_behind },
          { lualine_filename },
        },
        lualine_c = {},
        lualine_x = {
          { "diff", symbols = { added = "+", modified = "~", removed = "-" } },
          { "diagnostics", symbols = { error = "E:", warn = "W:", info = "I:", hint = "H:" } },
        },
        lualine_y = { "filetype", "progress" },
        lualine_z = {},
      },
    },
    config = function(_, opts)
      local lualine = require("lualine")
      lualine.setup(opts)

      local group = vim.api.nvim_create_augroup("LualineRefresh", { clear = true })
      vim.api.nvim_create_autocmd("ColorScheme", {
        group = group,
        callback = function()
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
      { "<leader>ts", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (small split)" },
      { "<leader>tH", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (split)" },
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
      vim.keymap.set("t", "<Esc>", [[<C-\><C-n>]], { desc = "Terminal: Normal mode" })
      vim.keymap.set("t", "<C-w>", [[<C-\><C-n><C-w>]], { desc = "Terminal: Window command" })
    end,
  },

  {
    "MeanderingProgrammer/render-markdown.nvim",
    ft = { "markdown" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      anti_conceal = { enabled = false },
      file_types = { "markdown" },
    },
  },
}
