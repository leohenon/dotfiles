local M = {}

local function notes_state_path()
  return vim.fn.stdpath("data") .. "/project_notes.json"
end

local function recent_state_path()
  return vim.fn.stdpath("data") .. "/project_notes_recent.json"
end

local function read_file(path)
  local f = io.open(path, "r")
  if not f then
    return nil
  end
  local ok, content = pcall(f.read, f, "*a")
  f:close()
  if not ok then
    return nil
  end
  return content
end

local function write_file(path, content)
  local f = io.open(path, "w")
  if not f then
    return false
  end
  f:write(content)
  f:close()
  return true
end

local function file_exists(path)
  return vim.uv.fs_stat(path) ~= nil
end

local function ensure_dir(path)
  local ok, err = pcall(vim.fn.mkdir, path, "p")
  if not ok then
    vim.notify(
      ("Failed to create directory:\n%s\n\n%s"):format(path, tostring(err)),
      vim.log.levels.ERROR
    )
    return false
  end
  return true
end

local function normpath(path)
  return vim.fs.normalize(vim.fn.fnamemodify(path, ":p"))
end

local root_markers = { ".git", "_darcs", ".hg", ".bzr", ".svn", "Makefile", "package.json" }

local function project_root_from(dir)
  dir = normpath(dir)
  local root = vim.fs.root(dir, root_markers)
  if root and root ~= "" then
    return normpath(root)
  end
  return dir
end

local function default_project_notes_dir(root)
  local base = vim.fn.expand("~/notes")
  local name = vim.fn.fnamemodify(root, ":t")
  return normpath(base .. "/" .. name)
end

local function notes_home()
  return normpath(vim.fn.expand("~/notes"))
end

M._startup_cwd = normpath(vim.fn.getcwd())
M._root = project_root_from(M._startup_cwd)

local function resolve_notes_dir(arg)
  arg = arg or ""
  arg = vim.trim(arg)
  if arg == "" then
    return nil
  end

  local expanded = normpath(vim.fn.expand(arg))
  local base = notes_home()

  if expanded == base or expanded:sub(1, #base + 1) == (base .. "/") then
    return expanded
  end

  arg = arg:gsub("^~/?notes/?", "")
  arg = arg:gsub("^/?", "")
  return normpath(base .. "/" .. arg)
end

local function load_map()
  local content = read_file(notes_state_path())
  if not content or content == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function save_map(map)
  ensure_dir(vim.fn.stdpath("data"))
  write_file(notes_state_path(), vim.json.encode(map))
end

local function load_recent_map()
  local content = read_file(recent_state_path())
  if not content or content == "" then
    return {}
  end
  local ok, decoded = pcall(vim.json.decode, content)
  if not ok or type(decoded) ~= "table" then
    return {}
  end
  return decoded
end

local function save_recent_map(map)
  ensure_dir(vim.fn.stdpath("data"))
  write_file(recent_state_path(), vim.json.encode(map))
end

local function slugify(title)
  local s = title:lower()
  s = s:gsub("%s+", "-")
  s = s:gsub("[^%w%-_]", "")
  s = s:gsub("%-+", "-")
  s = s:gsub("^%-", ""):gsub("%-$", "")
  if s == "" then
    s = "note"
  end
  return s
end

function M.get_project_root()
  return M._root or project_root_from(vim.fn.getcwd())
end

local function root_is_under_notes(root)
  local base = notes_home()
  root = normpath(root)
  return root == base or root:sub(1, #base + 1) == (base .. "/")
end

local function effective_project_root()
  local root = M.get_project_root()
  if root_is_under_notes(root) then
    return project_root_from(M._startup_cwd)
  end
  return root
end

local function recent_key()
  local root = effective_project_root()
  local base = M.get_notes_base_dir_for_root(root)
  return base
end

function M.get_notes_base_dir_for_root(root)
  root = normpath(root)
  local map = load_map()
  local dir = map[root]
  if type(dir) == "string" and dir ~= "" then
    return normpath(vim.fn.expand(dir)), root
  end
  return default_project_notes_dir(root), root
end

function M.get_notes_base_dir()
  return M.get_notes_base_dir_for_root(M.get_project_root())
end

function M.set_notes_base_dir(dir)
  local root = project_root_from(vim.fn.getcwd())
  M._root = root
  local map = load_map()
  map[root] = normpath(vim.fn.expand(dir))
  save_map(map)
  return root, map[root]
end

local function note_path_for(title)
  local base, root = M.get_notes_base_dir()
  ensure_dir(base)
  local filename = slugify(title) .. ".md"
  return normpath(base .. "/" .. filename)
end

local function open_note(title)
  local path = note_path_for(title)
  vim.cmd.edit(vim.fn.fnameescape(path))
  local map = load_recent_map()
  map[recent_key()] = path
  save_recent_map(map)
end

local function index_path()
  local base = M.get_notes_base_dir()
  return normpath(base .. "/index.md")
end

local function ensure_index_file()
  local path = index_path()
  if not file_exists(path) then
    if not ensure_dir(vim.fn.fnamemodify(path, ":h")) then
      return path
    end
    if not write_file(path, "# Index\n") then
      vim.notify(("Failed to write index file:\n%s"):format(path), vim.log.levels.ERROR)
      return path
    end
  end
  return path
end

vim.api.nvim_create_user_command("SetNotes", function(opts)
  local dir = resolve_notes_dir(opts.args)
  if not dir then
    local base, root = M.get_notes_base_dir()
    vim.notify(("Project notes dir for %s:\n%s"):format(root, base))
    return
  end
  local _, saved = M.set_notes_base_dir(dir)
  if not ensure_dir(saved) then
    return
  end
  ensure_index_file()
  vim.notify(("Project notes base dir set:\n%s"):format(saved))
end, {
  nargs = "?",
  complete = "dir",
  desc = "Set notes base dir for current project root",
})

vim.api.nvim_create_user_command("NoteNew", function(opts)
  local title = opts.args
  ensure_index_file()
  if title ~= "" then
    open_note(title)
    return
  end
  vim.ui.input({ prompt = "Note title: " }, function(input)
    if not input or input == "" then
      return
    end
    open_note(input)
  end)
end, {
  nargs = "*",
  desc = "Create/open a note under the current project's notes dir",
})

vim.api.nvim_create_user_command("NoteIndex", function()
  if root_is_under_notes(M.get_project_root()) then
    M._root = project_root_from(M._startup_cwd)
  end
  local path = ensure_index_file()
  vim.cmd.edit(vim.fn.fnameescape(path))
  local map = load_recent_map()
  map[recent_key()] = path
  save_recent_map(map)
end, { desc = "Open current project's notes index" })

vim.keymap.set("n", "<leader>nn", "<cmd>NoteIndex<cr>", { desc = "Notes: index (project)" })

vim.keymap.set("n", "<leader>nR", function()
  local key = recent_key()
  local map = load_recent_map()
  local path = map[key]
  if type(path) ~= "string" or path == "" then
    vim.notify("No recent note for this project", vim.log.levels.INFO)
    return
  end
  if not file_exists(path) then
    vim.notify(("Recent note not found:\n%s"):format(path), vim.log.levels.WARN)
    return
  end
  vim.cmd.edit(vim.fn.fnameescape(path))
end, { desc = "Notes: recent (project)" })

vim.api.nvim_create_autocmd("BufEnter", {
  pattern = "*.md",
  callback = function(ev)
    local path = normpath(ev.file or "")
    local base = notes_home()
    if path == "" or not (path == base or path:sub(1, #base + 1) == (base .. "/")) then
      return
    end
    local dir = normpath(vim.fn.fnamemodify(path, ":h"))
    local map = load_recent_map()
    map[dir] = path
    save_recent_map(map)
  end,
})
vim.keymap.set("n", "<leader>nS", function()
  if root_is_under_notes(M.get_project_root()) then
    M._root = project_root_from(M._startup_cwd)
  end
  local base = M.get_notes_base_dir()
  if not ensure_dir(base) then
    return
  end

  local current_win = vim.api.nvim_get_current_win()
  local netrw_win = nil
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "netrw" then
      netrw_win = win
      break
    end
  end

  local escaped = vim.fn.fnameescape(base)
  if netrw_win then
    vim.api.nvim_set_current_win(netrw_win)
    pcall(vim.cmd, "silent! packadd netrw")
    local ok = pcall(function()
      vim.fn["netrw#SetTreetop"](1, base)
    end)
    if not ok then
      pcall(vim.cmd, "silent keepalt keepjumps Ex " .. escaped)
    end
    vim.api.nvim_set_current_win(current_win)
  else
    vim.cmd("Ex " .. escaped)
  end
end, { desc = "Notes: open dir (netrw)" })
vim.keymap.set("n", "<leader>nN", "<cmd>NoteNew<cr>", { desc = "Notes: new (project)" })

return M
