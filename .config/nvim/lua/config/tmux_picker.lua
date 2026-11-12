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
	local registration_job
	local register_pending = false
	local leaving = false
	local function register()
		if leaving then
			return
		end
		if registration_job then
			register_pending = true
			return
		end
		local server = vim.v.servername
		if server == "" then
			server = vim.fn.serverstart()
		end
		local registration = vim.json.encode({ server = server, pid = vim.fn.getpid() })
		registration_job = vim.system(
			{ "tmux", "set-option", "-p", "-t", pane, "@picker-nvim", registration },
			{},
			vim.schedule_wrap(function()
				registration_job = nil
				if register_pending and not leaving then
					register_pending = false
					register()
				end
			end)
		)
	end
	local group = vim.api.nvim_create_augroup("TmuxPathPicker", { clear = true })
	vim.api.nvim_create_autocmd({ "VimEnter", "VimResume" }, { group = group, callback = register })
	vim.api.nvim_create_autocmd("VimLeavePre", {
		group = group,
		callback = function()
			leaving = true
			-- Finish registration before checking ownership and removing it.
			if registration_job then
				registration_job:wait()
			end
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
