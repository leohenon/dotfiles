local M = {}

local function decode_uri_component(value)
	return (value:gsub("%%(%x%x)", function(hex)
		return string.char(tonumber(hex, 16))
	end))
end

local function session_uri_under_cursor()
	local line = vim.api.nvim_get_current_line()
	local cursor_col = vim.api.nvim_win_get_cursor(0)[2] + 1
	local from = 1

	while true do
		local start_col, end_col, uri = line:find("%[[^%]]-%]%((pi%-session:[^%)]+)%)", from)
		if not start_col then
			return nil
		end
		if cursor_col >= start_col and cursor_col <= end_col then
			return uri
		end
		from = end_col + 1
	end
end

function M.open_under_cursor()
	local uri = session_uri_under_cursor()
	if not uri then
		vim.notify("No Pi session link under cursor", vim.log.levels.INFO)
		return
	end

	if not vim.env.TMUX or vim.env.TMUX == "" then
		vim.notify("Pi session links must be opened from inside tmux", vim.log.levels.ERROR)
		return
	end

	local session_file = decode_uri_component(uri:sub(#"pi-session:" + 1))
	if vim.fn.filereadable(session_file) ~= 1 then
		vim.notify(("Pi session file not found:\n%s"):format(session_file), vim.log.levels.ERROR)
		return
	end

	local cwd = vim.fn.fnamemodify(session_file, ":h")
	local first_line = io.open(session_file, "r")
	if first_line then
		local header = first_line:read("*l")
		first_line:close()
		local ok, decoded = pcall(vim.json.decode, header or "")
		if ok and type(decoded) == "table" and type(decoded.cwd) == "string" then
			cwd = decoded.cwd
		end
	end

	local command = "pi --session " .. vim.fn.shellescape(session_file)
	vim.system({ "tmux", "new-window", "-n", "pi", "-c", cwd, command }, { text = true }, function(result)
		vim.schedule(function()
			if result.code ~= 0 then
				vim.notify("Could not open Pi session: " .. (result.stderr or "unknown error"), vim.log.levels.ERROR)
			end
		end)
	end)
end

vim.api.nvim_create_autocmd("FileType", {
	pattern = "markdown",
	callback = function(event)
		vim.keymap.set("n", "go", M.open_under_cursor, {
			buffer = event.buf,
			desc = "Open Pi session link in tmux",
		})
	end,
})

return M
