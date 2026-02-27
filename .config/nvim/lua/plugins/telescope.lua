return {
  {
    "nvim-telescope/telescope.nvim",
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
            sorting_strategy = "descending",
            layout_config = { prompt_position = "top" },
            preview = {
              treesitter = { enable = false },
            },
          },
          pickers = {
            find_files = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.55 },
            },
            git_files = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.55 },
            },
            git_status = {
              layout_strategy = "horizontal",
              layout_config = { prompt_position = "bottom", width = 0.85, height = 0.70, preview_width = 0.55 },
            },
            git_branches = {
              layout_config = { prompt_position = "bottom" },
            },
            git_commits = {
              layout_config = { prompt_position = "bottom" },
            },
            live_grep = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            grep_string = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            lsp_references = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            buffers = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.55, height = 0.45 },
            },
            help_tags = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.50 },
            },
            git_bcommits = {
              layout_strategy = "horizontal",
              layout_config = { prompt_position = "bottom", width = 0.80, height = 0.70, preview_width = 0.60 },
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
      vim.keymap.set("n", "<leader>fG", builtin.current_buffer_fuzzy_find, { desc = "Telescope buffer grep" })
      vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Telescope find word under cursor" })
      vim.keymap.set("n", "<leader>rr", builtin.lsp_references, { desc = "Telescope references" })
      vim.keymap.set("n", "<leader>rd", builtin.lsp_definitions, { desc = "Telescope definitions" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
      vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git: branches (fzf)" })
      vim.keymap.set("n", "<leader>gB", function()
        builtin.git_branches({ pattern = "refs/remotes" })
      end, { desc = "Git: remote branches (fzf)" })
      vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git: commits (repo)" })
      vim.keymap.set("n", "<leader>gC", builtin.git_bcommits, { desc = "Git: commits (buffer)" })
    end,
  },
}
