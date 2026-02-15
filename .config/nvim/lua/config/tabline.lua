local M = {}

local function get_hl(name)
  local ok, hl = pcall(vim.api.nvim_get_hl, 0, { name = name, link = false })
  if not ok or type(hl) ~= "table" then
    return nil
  end
  if hl.fg == nil and hl.bg == nil then
    return nil
  end
  return hl
end

local function set_tabline_highlights()
  local normal = get_hl("Normal") or {}
  local tabline = get_hl("TabLine") or get_hl("StatusLineNC") or normal
  local tabline_sel = get_hl("TabLineSel") or get_hl("StatusLine") or normal

  local tab_fg = tabline.fg or normal.fg
  local tab_bg = tabline.bg or normal.bg
  local sel_fg = tabline_sel.fg or normal.fg
  local sel_bg = tabline_sel.bg or normal.bg

  vim.api.nvim_set_hl(0, "TabLineIndex", { fg = tab_fg, bg = tab_bg, bold = true })
  vim.api.nvim_set_hl(0, "TabLineSelIndex", { fg = sel_fg, bg = sel_bg, bold = true })
  vim.api.nvim_set_hl(0, "TabLineModified", { fg = tab_fg, bg = tab_bg, bold = true })
  vim.api.nvim_set_hl(0, "TabLineSelModified", { fg = sel_fg, bg = sel_bg, bold = true })
end

function M.setup()
  local group = vim.api.nvim_create_augroup("TablineHighlights", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", {
    group = group,
    callback = set_tabline_highlights,
  })
  set_tabline_highlights()
end

local function label_for_tab(tabpage)
  local win = vim.api.nvim_tabpage_get_win(tabpage)
  local buf = vim.api.nvim_win_get_buf(win)
  local name = vim.api.nvim_buf_get_name(buf)
  if name == "" then
    return "No Name"
  end
  return vim.fn.fnamemodify(name, ":t")
end

function M.render()
  local parts = {}
  local tabs = vim.api.nvim_list_tabpages()
  local current = vim.api.nvim_get_current_tabpage()

  for i, tab in ipairs(tabs) do
    local is_current = tab == current
    local base_hl = is_current and "%#TabLineSel#" or "%#TabLine#"
    local index_hl = is_current and "%#TabLineSelIndex#" or "%#TabLineIndex#"
    local modified_hl = is_current and "%#TabLineSelModified#" or "%#TabLineModified#"
    local label = label_for_tab(tab)
    local win = vim.api.nvim_tabpage_get_win(tab)
    local buf = vim.api.nvim_win_get_buf(win)
    local modified = vim.bo[buf].modified

    parts[#parts + 1] = base_hl
      .. "%"
      .. i
      .. "T "
      .. index_hl
      .. i
      .. base_hl
      .. " "
      .. label
      .. " "

    if modified then
      parts[#parts + 1] = modified_hl .. "*" .. base_hl .. " "
    end
  end

  parts[#parts + 1] = "%#TabLineFill#%T"
  return table.concat(parts)
end

M.setup()

return M
