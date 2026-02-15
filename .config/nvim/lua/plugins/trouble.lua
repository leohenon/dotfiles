return {
  {
    "folke/trouble.nvim",
    cmd = { "Trouble" },
    opts = {
      focus = true,
      auto_close = true,
    },
    keys = {
      { "<leader>dd", "<cmd>Trouble diagnostics toggle<cr>", desc = "Diagnostics (Trouble)" },
      {
        "<leader>db",
        "<cmd>Trouble diagnostics toggle filter.buf=0<cr>",
        desc = "Buffer diagnostics (Trouble)",
      },
      { "<leader>cs", "<cmd>Trouble symbols toggle focus=false<cr>", desc = "Symbols (Trouble)" },
      { "<leader>cl", "<cmd>Trouble lsp toggle focus=false<cr>", desc = "LSP list (Trouble)" },
    },
  },
}
