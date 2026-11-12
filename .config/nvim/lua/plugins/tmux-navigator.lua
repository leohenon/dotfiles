return {
  {
    "christoomey/vim-tmux-navigator",
    lazy = false,
    cmd = {
      "TmuxNavigateLeft",
      "TmuxNavigateDown",
      "TmuxNavigateUp",
      "TmuxNavigateRight",
      "TmuxNavigatePrevious",
      "TmuxNavigatorProcessList",
    },
    init = function()
      vim.g.tmux_navigator_no_mappings = 1
    end,
    keys = {
      { "<C-w>h", "<cmd>TmuxNavigateLeft<cr>", desc = "Navigate left" },
      { "<C-w>j", "<cmd>TmuxNavigateDown<cr>", desc = "Navigate down" },
      { "<C-w>k", "<cmd>TmuxNavigateUp<cr>", desc = "Navigate up" },
      { "<C-w>l", "<cmd>TmuxNavigateRight<cr>", desc = "Navigate right" },
      { "<C-w>\\", "<cmd>TmuxNavigatePrevious<cr>", desc = "Navigate previous" },
    },
  },
}
