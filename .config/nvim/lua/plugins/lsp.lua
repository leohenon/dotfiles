return {
  {
    "SmiteshP/nvim-navic",
    event = "LspAttach",
    opts = {
      highlight = true,
      separator = " > ",
      depth_limit = 0,
      depth_limit_indicator = "..",
      lazy_update_context = true,
    },
    config = function(_, opts)
      require("nvim-navic").setup(opts)
    end,
  },
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = function()
      require("mason").setup()
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    dependencies = { "williamboman/mason.nvim" },
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ts_ls",
          "eslint",
          "lua_ls",
          "pyright",
          "ruff",
          "clangd",
          "html",
          "cssls",
        },
        handlers = {
          function(server_name)
            local capabilities = vim.lsp.protocol.make_client_capabilities()
            pcall(function()
              capabilities = require("cmp_nvim_lsp").default_capabilities(capabilities)
            end)

            require("lspconfig")[server_name].setup({
              capabilities = capabilities,
            })
          end,
        },
      })
    end,
  },
  {
    "neovim/nvim-lspconfig",
    dependencies = { "williamboman/mason-lspconfig.nvim" },
    config = function()
      vim.diagnostic.config({
        virtual_text = true,
        signs = true,
        underline = true,
        update_in_insert = false,
      })

      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("lsp_attach", { clear = true }),
        callback = function(event)
          local bufnr = event.buf
          local client = vim.lsp.get_client_by_id(event.data.client_id)

          local map = function(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
          end

          local function to_quickfix(title)
            return function(result)
              local items = (result and result.items) or {}
              if vim.tbl_isempty(items) then
                vim.notify(title .. ": no results", vim.log.levels.INFO)
                return
              end
              vim.fn.setqflist(
                {},
                " ",
                { title = title, items = items, context = result and result.context or nil }
              )
              vim.cmd("copen")
            end
          end

          map("n", "gd", vim.lsp.buf.definition, "LSP: Definition")
          map("n", "gD", vim.lsp.buf.declaration, "LSP: Declaration")
          map("n", "gr", vim.lsp.buf.references, "LSP: References")
          map("n", "gi", vim.lsp.buf.implementation, "LSP: Implementation")
          map("n", "K", vim.lsp.buf.hover, "LSP: Hover")
          map("n", "<leader>rn", vim.lsp.buf.rename, "LSP: Rename")
          map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "LSP: Code action")
          map("n", "<leader>sd", vim.lsp.buf.document_symbol, "LSP: Document symbols")
          map("n", "<leader>sw", vim.lsp.buf.workspace_symbol, "LSP: Workspace symbols")
          map("n", "<leader>rR", function()
            vim.lsp.buf.references(nil, { on_list = to_quickfix("LSP References") })
          end, "LSP: References -> quickfix")
          map("n", "<leader>rD", function()
            vim.lsp.buf.definition({ on_list = to_quickfix("LSP Definitions") })
          end, "LSP: Definitions -> quickfix")

          pcall(function()
            if
              client
              and client.server_capabilities
              and client.server_capabilities.documentSymbolProvider
            then
              require("nvim-navic").attach(client, bufnr)
            end
          end)

          local group = vim.api.nvim_create_augroup("lsp_cursorhold_diagnostics", { clear = false })
          vim.api.nvim_clear_autocmds({ group = group, buffer = bufnr })
          vim.api.nvim_create_autocmd("CursorHold", {
            group = group,
            buffer = bufnr,
            callback = function()
              vim.diagnostic.open_float(nil, { focus = false })
            end,
          })
        end,
      })
    end,
  },
}
