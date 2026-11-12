local M = {}

-- Called over RPC with data, never interpolated Ex commands.
function M.open(selection)
	local kind, path = selection[1], selection[2]
	local ok, err = pcall(function()
		vim.cmd.edit({ args = { path }, magic = { file = false, bar = false } })
		if kind == "dir" then
			vim.cmd.cd({ args = { path }, magic = { file = false, bar = false } })
		end
	end)
	return ok and "ok" or tostring(err)
end

function M.setup()
	local pane = vim.env.TMUX_PANE
	if not pane or vim.fn.executable("tmux") == 0 then
		return
	end
	local function register()
		local server = vim.v.servername
		if server == "" then
			server = vim.fn.serverstart()
		end
		local registration = vim.json.encode({ server = server, pid = vim.fn.getpid() })
		vim.fn.system({ "tmux", "set-option", "-p", "-t", pane, "@picker-nvim", registration })
	end
	local group = vim.api.nvim_create_augroup("TmuxPathPicker", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, { group = group, callback = register })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			local server = vim.fn.system({ "tmux", "show-options", "-pqv", "-t", pane, "@picker-nvim" })
			local ok, registration = pcall(vim.json.decode, server)
			if ok and registration.pid == vim.fn.getpid() then
				vim.fn.system({ "tmux", "set-option", "-pu", "-t", pane, "@picker-nvim" })
			end
		end,
	})
	if vim.v.vim_did_enter == 1 then
		register()
	end
end

return M
