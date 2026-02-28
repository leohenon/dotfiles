local map = vim.keymap.set
local cmd = vim.cmd

local function cnoreabbrev(lhs, rhs)
  cmd(
    string.format(
      [[cnoreabbrev <expr> %s (getcmdtype() ==# ':' && getcmdline() ==# '%s') ? '%s' : '%s']],
      lhs,
      lhs,
      rhs,
      lhs
    )
  )
end

local startup_cwd = vim.fn.getcwd()
vim.g.startup_cwd = startup_cwd

local function explore_current_file()
  local file = vim.api.nvim_buf_get_name(0)
  if file == "" then
    cmd.Ex()
    return
  end

  local dir = vim.fn.fnamemodify(file, ":p:h")
  local base = vim.fn.fnamemodify(file, ":t")

  pcall(cmd, "silent! packadd netrw")
  cmd("silent keepalt keepjumps Ex " .. vim.fn.fnameescape(dir))

  vim.schedule(function()
    if vim.bo.filetype ~= "netrw" then
      return
    end
    pcall(vim.fn["netrw#SetTreetop"], 1, dir)
    local pattern = "\\V" .. vim.fn.escape(base, "\\")
    pcall(vim.fn.search, pattern, "W")
  end)
end

local function back_to_startup_cwd()
  cmd.cd(vim.fn.fnameescape(startup_cwd))

  local escaped = vim.fn.fnameescape(startup_cwd)
  local current_win = vim.api.nvim_get_current_win()
  local netrw_win = nil

  for _, win in ipairs(vim.api.nvim_list_wins()) do
    local buf = vim.api.nvim_win_get_buf(win)
    if vim.bo[buf].filetype == "netrw" then
      netrw_win = win
      break
    end
  end

  if netrw_win then
    vim.api.nvim_set_current_win(netrw_win)
    pcall(cmd, "silent! packadd netrw")
    local ok = pcall(function()
      vim.fn["netrw#SetTreetop"](1, startup_cwd)
    end)
    if not ok then
      pcall(cmd, "silent keepalt keepjumps Explore! " .. escaped)
    end
    vim.api.nvim_set_current_win(current_win)
  else
    pcall(cmd, "silent keepalt keepjumps Ex " .. escaped)
  end

  vim.notify("CWD: " .. startup_cwd)
end

local function toggle_buffer_diagnostics()
  local bufnr = vim.api.nvim_get_current_buf()
  local enabled = true

  if type(vim.diagnostic.is_enabled) == "function" then
    enabled = vim.diagnostic.is_enabled({ bufnr = bufnr })
  elseif vim.b[bufnr].diagnostics_enabled ~= nil then
    enabled = vim.b[bufnr].diagnostics_enabled
  end

  if type(vim.diagnostic.is_enabled) == "function" then
    vim.diagnostic.enable(not enabled, { bufnr = bufnr })
  else
    if enabled then
      vim.diagnostic.disable(bufnr)
    else
      vim.diagnostic.enable(bufnr)
    end
  end

  vim.b[bufnr].diagnostics_enabled = not enabled
  vim.notify("Diagnostics: " .. (not enabled and "on" or "off"))
end

local function copy_diagnostic_under_cursor()
  local line = vim.fn.line(".") - 1
  local col = vim.fn.col(".") - 1
  local diags = vim.diagnostic.get(0, { lnum = line })
  local picked = nil

  for _, diag in ipairs(diags) do
    local start_col = diag.col or 0
    local end_col = diag.end_col or start_col
    if col >= start_col and col <= end_col then
      picked = diag
      break
    end
  end

  picked = picked or diags[1]
  local message = picked and picked.message or nil
  if not message or message == "" then
    vim.notify("No diagnostic on this line", vim.log.levels.INFO)
    return
  end

  vim.fn.setreg("+", message)
  vim.notify("Diagnostic copied to clipboard")
end

local function run_project_lint_checks()
  local cwd = vim.fn.getcwd()
  local function has(file)
    return vim.fn.filereadable(cwd .. "/" .. file) == 1
  end

  local eslint_configs = {
    "eslint.config.js",
    "eslint.config.cjs",
    "eslint.config.mjs",
    "eslint.config.ts",
    ".eslintrc",
    ".eslintrc.js",
    ".eslintrc.cjs",
    ".eslintrc.json",
    ".eslintrc.yaml",
    ".eslintrc.yml",
  }

  local has_eslint = false
  for _, file in ipairs(eslint_configs) do
    if has(file) then
      has_eslint = true
      break
    end
  end

  local args
  local title
  local efm

  if has_eslint then
    title = "Project lint (eslint)"
    efm = "%f:%l:%c: %m"
    if vim.fn.executable("pnpm") == 1 and has("pnpm-lock.yaml") then
      args = { "pnpm", "-s", "eslint", ".", "--ext", ".ts,.tsx,.js,.jsx", "-f", "unix" }
    elseif vim.fn.executable("yarn") == 1 and has("yarn.lock") then
      args = { "yarn", "eslint", ".", "--ext", ".ts,.tsx,.js,.jsx", "-f", "unix" }
    elseif vim.fn.executable("bunx") == 1 then
      args = { "bunx", "eslint", ".", "--ext", ".ts,.tsx,.js,.jsx", "-f", "unix" }
    elseif vim.fn.executable("npx") == 1 then
      args = { "npx", "--yes", "eslint", ".", "--ext", ".ts,.tsx,.js,.jsx", "-f", "unix" }
    else
      vim.notify(
        "Lint: eslint detected but no runner found (pnpm/yarn/bunx/npx)",
        vim.log.levels.ERROR
      )
      return
    end
  elseif has("tsconfig.json") then
    title = "Project lint (tsc --noEmit)"
    efm = "%f(%l\\,%c): %m"
    if vim.fn.executable("pnpm") == 1 and has("pnpm-lock.yaml") then
      args = { "pnpm", "-s", "tsc", "-p", "tsconfig.json", "--noEmit", "--pretty", "false" }
    elseif vim.fn.executable("yarn") == 1 and has("yarn.lock") then
      args = { "yarn", "tsc", "-p", "tsconfig.json", "--noEmit", "--pretty", "false" }
    elseif vim.fn.executable("bunx") == 1 then
      args = { "bunx", "tsc", "-p", "tsconfig.json", "--noEmit", "--pretty", "false" }
    elseif vim.fn.executable("npx") == 1 then
      args = { "npx", "--yes", "tsc", "-p", "tsconfig.json", "--noEmit", "--pretty", "false" }
    else
      vim.notify(
        "Lint: tsconfig detected but no runner found (pnpm/yarn/bunx/npx)",
        vim.log.levels.ERROR
      )
      return
    end
  else
    vim.notify("Lint: no eslint config or tsconfig.json in project root", vim.log.levels.WARN)
    return
  end

  local result = vim.system(args, { cwd = cwd, text = true }):wait()
  local output = (result.stdout or "")
  if result.stderr and result.stderr ~= "" then
    output = output .. (output ~= "" and "\n" or "") .. result.stderr
  end
  local lines = vim.split(output, "\n", { trimempty = true })

  if #lines == 0 then
    vim.fn.setqflist({}, "r", { title = title, items = {} })
    vim.notify("Lint: no issues", vim.log.levels.INFO)
    return
  end

  vim.fn.setqflist({}, "r", {
    title = title,
    lines = lines,
    efm = efm,
  })

  if not pcall(cmd, "Trouble qflist toggle") then
    cmd("copen")
  end
end

local function toggle_markdown_strikethrough()
  local line = vim.api.nvim_get_current_line()
  local indent = line:match("^(%s*)") or ""
  local content = line:sub(#indent + 1)

  if content:match("^~~.*~~$") then
    content = content:gsub("^~~(.*)~~$", "%1")
  else
    content = "~~" .. content .. "~~"
  end

  vim.api.nvim_set_current_line(indent .. content)
end

local function toggle_markdown_checkbox()
  local line = vim.api.nvim_get_current_line()

  if line:match("%[ %]") then
    line = line:gsub("%[ %]", "[x]", 1)
  elseif line:match("%[[xX]%]") then
    line = line:gsub("%[[xX]%]", "[ ]", 1)
  else
    return
  end

  vim.api.nvim_set_current_line(line)
end

local function replace_word_under_cursor()
  local word = vim.fn.expand("<cword>")
  if word == nil or word == "" then
    vim.notify("No word under cursor", vim.log.levels.INFO)
    return
  end

  local escaped = vim.fn.escape(word, [[\/]])
  local command = string.format([[:%%s/\<%s\>//gI<Left><Left><Left>]], escaped)
  local keys = vim.api.nvim_replace_termcodes(command, true, false, true)
  vim.fn.feedkeys(keys, "n")
end

vim.api.nvim_create_user_command("Root", back_to_startup_cwd, { desc = "CWD: back to startup" })
vim.api.nvim_create_user_command(
  "ToggleDiagnostics",
  toggle_buffer_diagnostics,
  { desc = "Diagnostics: toggle (buffer)" }
)
vim.api.nvim_create_user_command("Rd", function()
  cmd("RenderMarkdown toggle")
end, { desc = "RenderMarkdown: toggle" })

cnoreabbrev("hs", "split")
cnoreabbrev("hs!", "split!")
cnoreabbrev("ex", "Ex")
cnoreabbrev("vsl", "leftabove vsplit")
cnoreabbrev("vsl!", "leftabove vsplit!")
cnoreabbrev("hst", "leftabove split")
cnoreabbrev("hst!", "leftabove split!")
cnoreabbrev("dt", "ToggleDiagnostics")
cnoreabbrev("dv", "DiffviewOpen")
cnoreabbrev("dc", "DiffviewClose")
cnoreabbrev("df", [[lua vim.g.diffview_single_file = true vim.cmd("DiffviewOpen HEAD -- %")]])
cnoreabbrev("gh", "DiffviewFileHistory %")
cnoreabbrev("ro", "Root")
cnoreabbrev("o", "only")

map("n", "<leader>cd", cmd.Ex)
map("n", "<leader>j", explore_current_file, { desc = "Explorer (:Ex) on current file" })
map("n", "<leader>se", function()
  cmd("Vexplore")
end, { desc = "Explorer in vertical split (:Vexplore)" })
map("n", "<leader>ro", back_to_startup_cwd, { desc = "CWD: back to startup" })
map("n", "<D-p>", back_to_startup_cwd, { desc = "CWD: back to startup (Cmd+P)" })

map("n", "<C-Left>", "<cmd>vertical resize -5<cr>", { silent = true, desc = "Decrease width" })
map("n", "<C-Right>", "<cmd>vertical resize +5<cr>", { silent = true, desc = "Increase width" })
map("n", "<C-Up>", "<cmd>resize +2<cr>", { silent = true, desc = "Increase height" })
map("n", "<C-Down>", "<cmd>resize -2<cr>", { silent = true, desc = "Decrease height" })
map("n", "<M-h>", function()
  if vim.fn.winnr("l") ~= vim.fn.winnr() then
    vim.cmd("vertical resize -5")
  else
    vim.cmd("vertical resize +5")
  end
end, { silent = true, desc = "Resize: move border left" })
map("n", "<M-l>", function()
  if vim.fn.winnr("l") ~= vim.fn.winnr() then
    vim.cmd("vertical resize +5")
  else
    vim.cmd("vertical resize -5")
  end
end, { silent = true, desc = "Resize: move border right" })
map("n", "<M-k>", function()
  if vim.fn.winnr("j") ~= vim.fn.winnr() then
    vim.cmd("resize -2")
  else
    vim.cmd("resize +2")
  end
end, { silent = true, desc = "Resize: move border up" })
map("n", "<M-j>", function()
  if vim.fn.winnr("j") ~= vim.fn.winnr() then
    vim.cmd("resize +2")
  else
    vim.cmd("resize -2")
  end
end, { silent = true, desc = "Resize: move border down" })

map("n", "<leader>tn", "<cmd>tabnew<cr>", { desc = "Tab: new" })
map("n", "<leader>tc", "<cmd>tabclose<cr>", { desc = "Tab: close" })
map("n", "<leader>to", "<cmd>tabonly<cr>", { desc = "Tab: only" })
map("n", "<leader>tl", "<cmd>tabnext<cr>", { desc = "Tab: next" })
map("n", "<leader>th", "<cmd>tabprevious<cr>", { desc = "Tab: previous" })
map("n", "<S-Left>", "<cmd>tabprevious<cr>", { desc = "Tab: previous" })
map("n", "<S-Right>", "<cmd>tabnext<cr>", { desc = "Tab: next" })

map("n", "<leader>de", vim.diagnostic.open_float, { desc = "Diagnostic: float" })
map("n", "[d", vim.diagnostic.goto_prev, { desc = "Go to previous diagnostic" })
map("n", "]d", vim.diagnostic.goto_next, { desc = "Go to next diagnostic" })
map("n", "<leader>dy", copy_diagnostic_under_cursor, { desc = "Diagnostic: copy message" })

map("n", "<C-d>", "<C-d>zz", { silent = true })
map("n", "<C-u>", "<C-u>zz", { silent = true })
map("n", "n", "nzzzv", { silent = true })
map("n", "N", "Nzzzv", { silent = true })

map("n", "<leader>ss", toggle_markdown_strikethrough, { desc = "Toggle strikethrough (Markdown)" })
map("n", "<leader>cb", toggle_markdown_checkbox, { desc = "Toggle markdown checkbox" })

map("n", "<leader>gh", "<cmd>DiffviewFileHistory %<cr>", { desc = "Git history: file" })
map("n", "<leader>ns", function()
  require("neogit").open({ kind = "vsplit" })
end, { desc = "Neogit in vertical split" })

map({ "n", "x" }, "y", '""y', { desc = "Yank to vim register" })
map("n", "yy", '""yy', { desc = "Yank line to vim register" })
map("n", "p", '""p', { desc = "Paste from vim register" })
map("x", "p", '"_d""P', { desc = "Paste from vim register (selection discarded)" })
map("n", "P", '""P', { desc = "Paste above from vim register" })

map({ "n", "x" }, "<leader>y", '"+y', { desc = "Yank to system clipboard" })
map("n", "<leader>yy", '"+yy', { desc = "Yank line to system clipboard" })
map("n", "<leader>p", '"+p', { desc = "Paste from system clipboard" })
map("x", "<leader>p", '"_d"+P', { desc = "Paste from system clipboard (selection discarded)" })
map("n", "<leader>P", '"+P', { desc = "Paste above from system clipboard" })

map({ "n", "x" }, "d", '""d', { desc = "Delete to vim register" })
map("n", "dd", '""dd', { desc = "Delete line to vim register" })

map("x", "<leader>rp", '""p', { desc = "Paste from vim register (selection to register)" })

map("n", "x", '"_x', { desc = "Delete char to void register" })
map("n", "X", '"_X', { desc = "Delete char before cursor to void register" })
map({ "n", "x" }, "<leader>x", '"_d', { desc = "Delete to void register" })
map("n", "<leader>xx", '"_dd', { desc = "Delete line to void register" })
map("n", "<leader>rw", replace_word_under_cursor, { desc = "Find/replace current word" })
