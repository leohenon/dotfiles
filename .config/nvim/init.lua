vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keybinds")
require("config.lazy")
require("config.project_notes")
require("config.tmux_picker").setup()
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

local function theme_color(name, fallback)
  local ok, lines = pcall(vim.fn.readfile, vim.fn.expand("~/.config/vesper-variant.json"))
  if not ok or #lines == 0 then
    return fallback
  end

  local decoded_ok, palette = pcall(vim.json.decode, table.concat(lines, "\n"))
  if decoded_ok and type(palette) == "table" and type(palette[name]) == "string" then
    return palette[name]
  end

  return fallback
end

local function apply_ui_hl()
  vim.api.nvim_set_hl(0, "Cursor", { reverse = true })
  vim.api.nvim_set_hl(0, "lCursor", { reverse = true })
  vim.api.nvim_set_hl(0, "TermCursor", { reverse = true })
  local cursorline_bg = theme_color("mode", "") == "brighter" and "#484848"
    or theme_color("border", "#343434")
  vim.api.nvim_set_hl(0, "CursorLine", { bg = cursorline_bg })
  vim.api.nvim_set_hl(0, "CursorColumn", { link = "CursorLine" })

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

vim.api.nvim_create_autocmd("FocusGained", {
  callback = apply_ui_hl,
})
