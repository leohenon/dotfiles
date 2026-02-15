vim.api.nvim_create_user_command("W", "noautocmd w", { desc = "Save without formatting" })

return {
  {
    "stevearc/conform.nvim",
    event = { "BufWritePre" },
    cmd = { "ConformInfo" },
    keys = {
      {
        "<leader>F",
        "<cmd>lua require('conform').format({ async = true, lsp_fallback = true })<cr>",
        mode = "n",
        desc = "Format buffer",
      },
      {
        "<leader>F",
        function()
          require("conform").format({ async = true, lsp_fallback = true })
        end,
        mode = "v",
        desc = "Format range",
      },
    },
    opts = {
      notify_on_error = false,
      format_on_save = { timeout_ms = 2000, lsp_fallback = true },
      formatters_by_ft = {
        lua = { "stylua" },
        python = { "black" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        yaml = { "prettier" },
        c = { "clang_format" },
        cpp = { "clang_format" },
      },
    },
  },
}
