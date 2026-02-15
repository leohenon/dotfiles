return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "bash",
        "json",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "python",
        "c",
        "cpp",
      },
      highlight = { enable = true },
      indent = { enable = true },
      auto_install = false,
    },
    config = function(_, opts)
      require("nvim-treesitter.configs").setup(opts)
    end,
  },

  {
    "nvim-treesitter/nvim-treesitter-context",
    event = { "BufReadPre", "BufNewFile" },
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    opts = {
      max_lines = 3,
      trim_scope = "inner",
      mode = "cursor",
      separator = "─",
      zindex = 20,
    },
    config = function(_, opts)
      require("treesitter-context").setup(opts)
      pcall(function()
        require("config.appearance").apply_transparency()
      end)

      local group = vim.api.nvim_create_augroup("TreesitterContextWindowTuning", { clear = true })
      local function tune_context_windows()
        for _, win in ipairs(vim.api.nvim_list_wins()) do
          local ok, is_ctx = pcall(function()
            return vim.w[win].treesitter_context or vim.w[win].treesitter_context_line_number
          end)
          if ok and is_ctx then
            pcall(function()
              vim.wo[win].winblend = 0
            end)
          end
        end
      end

      vim.api.nvim_create_autocmd(
        { "VimEnter", "WinNew", "WinResized", "WinScrolled", "CursorMoved", "BufEnter" },
        {
          group = group,
          callback = function()
            tune_context_windows()
          end,
        }
      )
    end,
  },
}
