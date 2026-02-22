return {
  {
    "nvim-telescope/telescope.nvim",
    tag = "0.1.5",
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      pcall(function()
        require("telescope").setup({
          defaults = {
            sorting_strategy = "ascending",
            layout_config = { prompt_position = "top" },
            preview = {
              treesitter = { enable = false },
            },
          },
        })
      end)
      pcall(function()
        require("telescope").load_extension("fzf")
      end)
      local builtin = require("telescope.builtin")
      local function telescope_startup_cwd()
        local cwd = vim.g.startup_cwd
        if not cwd or cwd == "" then
          return vim.fn.getcwd()
        end
        return cwd
      end

      local function telescope_find_files_startup()
        builtin.find_files({ cwd = telescope_startup_cwd() })
      end

      local function telescope_live_grep_startup()
        builtin.live_grep({ cwd = telescope_startup_cwd() })
      end

      vim.keymap.set(
        "n",
        "<leader>ff",
        telescope_find_files_startup,
        { desc = "Telescope find files" }
      )
      vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "Telescope git status" })
      vim.keymap.set("n", "<leader>ft", builtin.git_files, { desc = "Telescope git files" })
      vim.keymap.set(
        "n",
        "<leader>fg",
        telescope_live_grep_startup,
        { desc = "Telescope live grep" }
      )
      vim.keymap.set("n", "<leader>rr", builtin.lsp_references, { desc = "Telescope references" })
      vim.keymap.set("n", "<leader>rd", builtin.lsp_definitions, { desc = "Telescope definitions" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
      vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git: branches (fzf)" })
      vim.keymap.set("n", "<leader>gB", function()
        builtin.git_branches({ pattern = "refs/remotes/*" })
      end, { desc = "Git: remote branches (fzf)" })
      vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git: commits (repo)" })
      vim.keymap.set("n", "<leader>gC", builtin.git_bcommits, { desc = "Git: commits (buffer)" })
    end,
  },
}
