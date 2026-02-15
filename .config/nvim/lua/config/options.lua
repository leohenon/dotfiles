vim.opt.background = "dark"
vim.opt.relativenumber = true
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.shiftwidth = 4
vim.opt.termguicolors = true
vim.opt.cmdheight = 1
vim.opt.laststatus = 3
vim.opt.signcolumn = "yes"
vim.opt.clipboard = ""
vim.opt.scrolloff = 20
vim.opt.winbar = "%{%v:lua.require'config.winbar'.navic()%}"
vim.opt.tabline = "%!v:lua.require'config.tabline'.render()"
vim.opt.fillchars:append({ diff = " " })
vim.opt.splitright = true
vim.opt.splitbelow = true

local function ruler_state_path()
  return vim.fn.stdpath("state") .. "/ruler_state.json"
end

local function read_ruler_state()
  local path = ruler_state_path()
  local ok, lines = pcall(vim.fn.readfile, path)
  if not ok or not lines or #lines == 0 then
    return false
  end

  local ok_json, decoded = pcall(vim.json.decode, table.concat(lines, "\n"))
  if not ok_json or type(decoded) ~= "table" then
    return false
  end

  return decoded.visible == true
end

local function write_ruler_state(visible)
  local path = ruler_state_path()
  pcall(vim.fn.mkdir, vim.fn.fnamemodify(path, ":h"), "p")
  vim.fn.writefile({ vim.json.encode({ visible = visible == true }) }, path)
end

local function apply_ruler_state()
  vim.opt.colorcolumn = vim.g.ruler_visible and "120" or ""
end

vim.g.ruler_visible = read_ruler_state()
apply_ruler_state()

vim.api.nvim_create_user_command("ToggleRuler", function()
  vim.g.ruler_visible = not vim.g.ruler_visible
  apply_ruler_state()
  write_ruler_state(vim.g.ruler_visible)
  pcall(function()
    require("lualine").refresh({ place = { "statusline" } })
  end)
end, { desc = "Toggle 120-column ruler" })

local ruler_group = vim.api.nvim_create_augroup("PersistRulerState", { clear = true })
vim.api.nvim_create_autocmd("VimLeavePre", {
  group = ruler_group,
  callback = function()
    write_ruler_state(vim.g.ruler_visible)
  end,
})

vim.g.netrw_banner = 0
vim.g.netrw_browse_split = 0
vim.g.netrw_altv = 1
vim.g.netrw_winsize = 25
vim.g.netrw_keepdir = 0
vim.g.netrw_localcopydircmd = "cp -r"

vim.api.nvim_create_autocmd({ "FileType", "BufWinEnter", "WinEnter" }, {
  pattern = "*",
  callback = function()
    local ft = vim.bo.filetype
    if ft ~= "netrw" and not ft:match("^Neogit") and not ft:match("^neogit") then
      return
    end

    if ft == "netrw" then
      pcall(vim.keymap.del, "n", "<Space>", { buffer = true })

      vim.opt_local.number = false
      vim.opt_local.relativenumber = false
      vim.opt_local.statuscolumn = ""
    end

    vim.opt_local.colorcolumn = ""
  end,
})

do
  local function remove_diffopt_prefix(prefix)
    local current = vim.opt.diffopt:get() or {}
    for _, item in ipairs(current) do
      if type(item) == "string" and item:sub(1, #prefix) == prefix then
        vim.opt.diffopt:remove(item)
      end
    end
  end

  vim.opt.diffopt:remove("linematch")
  remove_diffopt_prefix("algorithm:")
  remove_diffopt_prefix("context:")
  vim.opt.diffopt:append("algorithm:patience")
  vim.opt.diffopt:append("indent-heuristic")
  vim.opt.diffopt:append("context:3")
end

vim.opt.undofile = true
do
  local undo_dir = vim.fn.stdpath("state") .. "/undo"
  vim.fn.mkdir(undo_dir, "p")
  vim.opt.undodir = undo_dir
end

do
  local group = vim.api.nvim_create_augroup("ActiveWindowCursorline", { clear = true })
  vim.api.nvim_create_autocmd({ "WinEnter", "BufWinEnter" }, {
    group = group,
    callback = function()
      vim.opt_local.cursorline = true
    end,
  })
  vim.api.nvim_create_autocmd("WinLeave", {
    group = group,
    callback = function()
      vim.opt_local.cursorline = false
    end,
  })
end

vim.opt.wildmenu = true
vim.opt.wildmode = "longest:full,full"
vim.opt.wildignorecase = true
pcall(function()
  vim.opt.wildoptions = "pum"
end)
