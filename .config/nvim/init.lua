vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keybinds")
require("config.lazy")
require("config.project_notes")
require("config.appearance").apply()
pcall(require, "config.local")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.swapfile = false
  end,
})

vim.opt.mouse = "a"

vim.api.nvim_create_autocmd("VimEnter", {
  callback = function()
    if vim.g.neovide then
      vim.g.neovide_hide_mouse_when_typing = true
      return
    end
    if vim.fn.exists(":GuiMousehide") == 2 then
      pcall(vim.cmd, "GuiMousehide")
    end
  end,
})

vim.opt.guicursor = table.concat({
  "n-v-c:block-Cursor",
  "i-ci-ve:ver25-Cursor",
  "r-cr:hor20-Cursor",
  "o:hor50-Cursor",
  "a:blinkon0",
}, ",")

local function apply_ui_hl()
  vim.api.nvim_set_hl(0, "Cursor", { reverse = true })
  vim.api.nvim_set_hl(0, "lCursor", { reverse = true })
  vim.api.nvim_set_hl(0, "TermCursor", { reverse = true })

  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#00c853" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#ffd54f" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#ff5252" })

  vim.api.nvim_set_hl(0, "GitSignsAddNr", { fg = "#00c853" })
  vim.api.nvim_set_hl(0, "GitSignsChangeNr", { fg = "#ffd54f" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { fg = "#ff5252" })

  vim.api.nvim_set_hl(0, "GitSignsAddLn", { bg = "#12391f" })
  vim.api.nvim_set_hl(0, "GitSignsChangeLn", { bg = "#3b3212" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteLn", { bg = "#3b1212" })

  require("config.appearance").apply_transparency()
end
apply_ui_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_ui_hl,
})
