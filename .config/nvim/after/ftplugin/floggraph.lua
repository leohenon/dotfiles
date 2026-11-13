-- Keep gq available for formatting instead of closing the graph.
vim.keymap.del("n", "gq", { buffer = true })

vim.keymap.set("n", "yy", function()
	local commit = vim.fn["flog#floggraph#commit#GetAtLine"](".")
	if commit.hash then
		vim.fn.setreg('"', commit.hash)
		vim.fn.setreg("+", commit.hash)
		vim.notify("Copied commit " .. commit.hash)
	end
end, { buffer = true, silent = true, desc = "Copy commit hash to clipboard" })

vim.keymap.set("n", "<CR>", function()
	local split = vim.fn["flog#backend#GetUserSplitCommand"]()
	local command = vim.fn["flog#Format"]("vertical belowright " .. split .. " %h")
	vim.fn["flog#ExecTmp"](command, { blur = 0, static = 1 })
end, { buffer = true, silent = true, desc = "Open and focus commit" })
