local function is_fullscreen_editing()
  local bufnr = vim.api.nvim_get_current_buf()
  local bt = vim.bo[bufnr].buftype
  local ft = vim.bo[bufnr].filetype

  if bt == "terminal" or ft == "toggleterm" then
    return false
  end

  local wins = vim.api.nvim_list_wins()
  local normal_edit_wins = 0
  for _, win in ipairs(wins) do
    local cfg = vim.api.nvim_win_get_config(win)
    if not cfg.relative or cfg.relative == "" then
      local b = vim.api.nvim_win_get_buf(win)
      local wbt = vim.bo[b].buftype
      local wft = vim.bo[b].filetype
      if wft ~= "aerial" and wbt ~= "terminal" and wft ~= "toggleterm" then
        normal_edit_wins = normal_edit_wins + 1
      end
    end
  end

  return normal_edit_wins == 1
end

return {
  {
    "stevearc/aerial.nvim",
    keys = {
      {
        "<leader>ao",
        function()
          local ok, aerial = pcall(require, "aerial")
          if not ok then
            vim.notify("aerial.nvim is not installed.", vim.log.levels.WARN)
            return
          end

          if not is_fullscreen_editing() then
            if aerial.is_open() then
              aerial.close()
            end
            vim.notify(
              "Outline only opens in a single full-screen editing window.",
              vim.log.levels.INFO
            )
            return
          end
          aerial.toggle({ direction = "right" })
        end,
        desc = "Outline (Aerial)",
      },
    },
    dependencies = {
      "nvim-treesitter/nvim-treesitter",
      "nvim-tree/nvim-web-devicons",
    },
    opts = {
      backends = { "treesitter", "lsp", "markdown", "man" },
      layout = {
        default_direction = "right",
        placement = "window",
        width = 30,
      },
      attach_mode = "global",
      close_automatic_events = { "unsupported" },
      filter_kind = false,
      show_guides = true,
    },
    config = function(_, opts)
      require("aerial").setup(opts)

      local group = vim.api.nvim_create_augroup("AerialFullscreenOnly", { clear = true })
      vim.api.nvim_create_autocmd(
        { "WinEnter", "BufEnter", "WinResized", "TermOpen", "TermEnter" },
        {
          group = group,
          callback = function()
            if is_fullscreen_editing() then
              return
            end
            local ok, aerial = pcall(require, "aerial")
            if ok and aerial.is_open() then
              aerial.close()
            end
          end,
        }
      )
    end,
  },
}
