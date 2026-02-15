local M = {}
local DEFAULT_COLORSCHEME = "vesper"

M.defaults = {
  guifont = "FiraCode Nerd Font:h14",
  winblend = 0,
  pumblend = 0,
  transparent = true,
  colorscheme = DEFAULT_COLORSCHEME,
}

M.fonts = {
  "JetBrainsMono Nerd Font:h14",
  "FiraCode Nerd Font:h14",
  "Iosevka Nerd Font:h14",
  "Hack Nerd Font:h14",
  "SF Mono:h14",
  "Monaco:h14",
}

local function state_path()
  return vim.fn.stdpath("state") .. "/appearance.json"
end

local function read_state()
  local path = state_path()
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines or #lines == 0 then
    return {}
  end
  local ok_json, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_json or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function write_state(state)
  local path = state_path()
  local encoded = vim.json.encode(state or {})
  pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile({ encoded }, path)
end

function M.get()
  local state = read_state()
  if type(state.guifont) ~= "string" then
    state.guifont = M.defaults.guifont
  end
  if type(state.winblend) ~= "number" then
    state.winblend = M.defaults.winblend
  end
  if type(state.pumblend) ~= "number" then
    state.pumblend = M.defaults.pumblend
  end
  if type(state.transparent) ~= "boolean" then
    state.transparent = M.defaults.transparent
  end
  if type(state.colorscheme) ~= "string" or state.colorscheme == "" then
    state.colorscheme = M.defaults.colorscheme
  end
  return state
end

function M.set(partial)
  local state = M.get()
  for k, v in pairs(partial or {}) do
    state[k] = v
  end
  write_state(state)
  return state
end

function M.apply(opts)
  opts = opts or {}
  local state = M.get()

  local colorscheme = opts.colorscheme
  if colorscheme == nil then
    colorscheme = state.colorscheme
  end
  if type(colorscheme) ~= "string" or colorscheme == "" then
    colorscheme = M.defaults.colorscheme
  end

  local ok = pcall(vim.cmd.colorscheme, colorscheme)
  if not ok and colorscheme ~= M.defaults.colorscheme then
    pcall(vim.cmd.colorscheme, M.defaults.colorscheme)
  end

  local transparent = opts.transparent
  if transparent == nil then
    transparent = state.transparent
  end
  if transparent then
    M.apply_transparency()
  end

  local font = opts.guifont
  if font == nil then
    font = state.guifont
  end
  if type(font) == "string" and font ~= "" then
    local ok = pcall(function()
      vim.opt.guifont = font
    end)
    if not ok and vim.fn.has("gui_running") == 0 then
      vim.notify(
        "Font changes require a GUI client (guifont is ignored in terminal UIs).",
        vim.log.levels.WARN
      )
    end
  end

  local winblend = opts.winblend or state.winblend
  if transparent then
    vim.opt.winblend = 0
  elseif type(winblend) == "number" then
    vim.opt.winblend = winblend
  end

  local pumblend = opts.pumblend or state.pumblend
  if transparent then
    vim.opt.pumblend = 0
  elseif type(pumblend) == "number" then
    vim.opt.pumblend = pumblend
  end
end

function M.apply_transparency()
  local groups = {
    "Normal",
    "NormalNC",
    "SignColumn",
    "EndOfBuffer",
    "MsgArea",
    "WinBar",
    "WinBarNC",
    "WinSeparator",
    "VertSplit",
    "NormalFloat",
    "FloatBorder",
    "FloatTitle",
    "CmdlinePopup",
    "CmdlinePopupBorder",
    "CmdlinePopupTitle",
    "Pmenu",
    "PmenuSel",
    "PmenuSbar",
    "PmenuThumb",
    "NoiceCmdlinePopup",
    "NoiceCmdlinePopupBorder",
    "NoiceCmdlinePopupTitle",
    "NoicePopup",
    "NoicePopupBorder",
    "TreesitterContext",
    "TreesitterContextLineNumber",
    "TreesitterContextSeparator",
    "TreesitterContextBottom",
  }

  for _, group in ipairs(groups) do
    pcall(vim.api.nvim_set_hl, 0, group, { bg = "none" })
  end

  local augroup = vim.api.nvim_create_augroup("NoBlendFloatingWindows", { clear = true })
  vim.api.nvim_create_autocmd({ "WinNew", "WinEnter", "BufWinEnter" }, {
    group = augroup,
    callback = function()
      local win = vim.api.nvim_get_current_win()
      local ok, cfg = pcall(vim.api.nvim_win_get_config, win)
      if ok and cfg and cfg.relative and cfg.relative ~= "" then
        pcall(function()
          vim.wo[win].winblend = 0
        end)
      end
    end,
  })
end

function M.reset()
  write_state(vim.deepcopy(M.defaults))
  M.apply(M.defaults)
end

return M
