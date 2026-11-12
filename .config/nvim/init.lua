vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

require("config.options")
require("config.keybinds")
require("config.lazy")
require("config.project_notes")
require("config.pi_sessions")
require("config.tmux_picker").setup()
require("config.appearance").apply()
pcall(require, "config.local")

vim.api.nvim_create_autocmd("FileType", {
  pattern = "gitcommit",
  callback = function()
    vim.opt_local.swapfile = false
  end,
})

vim.api.nvim_create_user_command("CopyFilePath", function()
  vim.fn.setreg("+", vim.fn.expand("%:p"))
end, { desc = "Copy current file's absolute path" })

vim.api.nvim_create_user_command("Finder", function()
  local dir = vim.b.netrw_curdir or vim.fn.expand("%:p:h")
  vim.fn.jobstart({ "open", dir }, { detach = true })
end, { desc = "Open netrw or current file directory in Finder" })

vim.api.nvim_create_user_command("Grip", function()
  if vim.bo.filetype ~= "markdown" then
    vim.notify("Grip requires a Markdown file", vim.log.levels.WARN)
    return
  end

  local file = vim.fn.expand("%:p")
  if file == "" then
    vim.notify("Save the Markdown file before running Grip", vim.log.levels.WARN)
    return
  end
  if vim.fn.executable("go-grip") == 0 then
    vim.notify("go-grip is not available on PATH", vim.log.levels.ERROR)
    return
  end

  vim.cmd("update")
  vim.cmd("botright split")
  vim.cmd("enew")
  vim.fn.jobstart({ "go-grip", "--host", "127.0.0.1", "--port", "0", file }, { term = true })
  vim.cmd("startinsert")
end, { desc = "Preview current Markdown file with go-grip" })

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

  vim.api.nvim_set_hl(0, "GitSignsAdd", { fg = "#A8CC8C" })
  vim.api.nvim_set_hl(0, "GitSignsChange", { fg = "#FFCFA8" })
  vim.api.nvim_set_hl(0, "GitSignsDelete", { fg = "#F28779" })

  vim.api.nvim_set_hl(0, "GitSignsAddNr", { fg = "#A8CC8C" })
  vim.api.nvim_set_hl(0, "GitSignsChangeNr", { fg = "#FFCFA8" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteNr", { fg = "#F28779" })

  vim.api.nvim_set_hl(0, "GitSignsAddLn", { bg = "#12391f" })
  vim.api.nvim_set_hl(0, "GitSignsChangeLn", { bg = "#3b3212" })
  vim.api.nvim_set_hl(0, "GitSignsDeleteLn", { bg = "#3b1212" })

  -- Markdown colors only; embedded code keeps its language's syntax colors.
  local headings = {
    theme_color("accent", "#FFC799"),
    theme_color("cyan", "#99FFE4"),
    theme_color("blue", "#99B3FF"),
    theme_color("purple", "#D4BFFF"),
    theme_color("green", "#A8CC8C"),
    theme_color("yellow", "#F2CA7D"),
  }
  for level, color in ipairs(headings) do
    vim.api.nvim_set_hl(0, "@markup.heading." .. level .. ".markdown", { fg = color, bold = true })
  end
  vim.api.nvim_set_hl(0, "@markup.link.label.markdown_inline", { fg = theme_color("blue", "#99B3FF") })
  vim.api.nvim_set_hl(0, "@markup.link.label.markdown", { fg = theme_color("blue", "#99B3FF") })
  vim.api.nvim_set_hl(0, "@markup.link.url.markdown_inline", { fg = theme_color("cyan", "#99FFE4"), underline = true })
  vim.api.nvim_set_hl(0, "@markup.link.url.markdown", { fg = theme_color("cyan", "#99FFE4"), underline = true })
  vim.api.nvim_set_hl(0, "@markup.raw.markdown_inline", { fg = theme_color("yellow", "#F2CA7D") })
  vim.api.nvim_set_hl(0, "@markup.raw.delimiter.markdown", { fg = theme_color("muted", "#B8B8B8") })
  vim.api.nvim_set_hl(0, "@label.markdown", { fg = theme_color("accent", "#FFC799"), italic = true })


  require("config.appearance").apply_transparency()
end
apply_ui_hl()

vim.api.nvim_create_autocmd("ColorScheme", {
  callback = apply_ui_hl,
})

vim.api.nvim_create_autocmd("FocusGained", {
  callback = apply_ui_hl,
})
