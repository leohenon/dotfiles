return {
  {
    "hrsh7th/nvim-cmp",
    event = { "InsertEnter", "CmdlineEnter" },
    dependencies = {
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-cmdline",
      { "L3MON4D3/LuaSnip", build = "make install_jsregexp" },
      "saadparwaiz1/cmp_luasnip",
      "rafamadriz/friendly-snippets",
    },
    config = function()
      vim.opt.completeopt = { "menu", "menuone", "noselect" }

      local ok_cmp, cmp = pcall(require, "cmp")
      if not ok_cmp then
        return
      end
      local ok_snip, luasnip = pcall(require, "luasnip")
      if ok_snip then
        local ok_loader, loader = pcall(require, "luasnip.loaders.from_vscode")
        if ok_loader and type(loader) == "table" and type(loader.lazy_load) == "function" then
          loader.lazy_load()
        end
      end

      local copilot_suggestion_ok, copilot_suggestion = pcall(require, "copilot.suggestion")

      local function has_words_before()
        local line, col = unpack(vim.api.nvim_win_get_cursor(0))
        if col == 0 then
          return false
        end
        local current = vim.api.nvim_buf_get_lines(0, line - 1, line, true)[1] or ""
        return current:sub(col, col):match("%s") == nil
      end

      cmp.setup({
        snippet = {
          expand = function(args)
            if ok_snip then
              luasnip.lsp_expand(args.body)
            end
          end,
        },
        mapping = cmp.mapping.preset.insert({
          ["<CR>"] = cmp.mapping.confirm({ select = true }),
          ["<C-n>"] = cmp.mapping.select_next_item(),
          ["<C-p>"] = cmp.mapping.select_prev_item(),
          ["<C-Space>"] = cmp.mapping.complete(),
          ["<C-e>"] = cmp.mapping.abort(),
          ["<Esc>"] = cmp.mapping(function()
            if cmp.visible() then
              cmp.abort()
            end
            local esc = vim.api.nvim_replace_termcodes("<Esc>", true, false, true)
            vim.api.nvim_feedkeys(esc, "n", true)
          end, { "i", "s" }),

          ["<Tab>"] = cmp.mapping(function(fallback)
            if copilot_suggestion_ok and copilot_suggestion.is_visible() then
              copilot_suggestion.accept()
              return
            end

            if cmp.visible() then
              cmp.select_next_item()
              return
            end

            if has_words_before() then
              cmp.complete()
              return
            end

            if ok_snip and luasnip.expand_or_jumpable() then
              luasnip.expand_or_jump()
              return
            end

            fallback()
          end, { "i", "s" }),

          ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
              cmp.select_prev_item()
              return
            end

            if ok_snip and luasnip.jumpable(-1) then
              luasnip.jump(-1)
              return
            end

            fallback()
          end, { "i", "s" }),
        }),
        sources = cmp.config.sources({
          { name = "nvim_lsp" },
          { name = "luasnip" },
          { name = "path" },
          { name = "buffer" },
        }),
        window = {
          completion = cmp.config.window.bordered(),
          documentation = cmp.config.window.bordered(),
        },
      })

      cmp.setup.cmdline({ "/", "?" }, {
        mapping = cmp.mapping.preset.cmdline(),
        sources = { { name = "buffer" } },
      })

      cmp.setup.cmdline(":", {
        mapping = cmp.mapping.preset.cmdline(),
        sources = cmp.config.sources({ { name = "path" } }, { { name = "cmdline" } }),
      })
    end,
  },
}
