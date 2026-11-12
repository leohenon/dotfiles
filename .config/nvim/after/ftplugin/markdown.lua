-- Keep Markdown source visible, including code fences and link destinations.
vim.opt_local.conceallevel = 0
vim.b.undo_ftplugin = (vim.b.undo_ftplugin or "") .. "\nsetlocal conceallevel<"
