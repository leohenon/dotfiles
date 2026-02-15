return {
  "mbbill/undotree",
  cmd = { "UndotreeToggle", "UndotreeShow", "UndotreeHide", "UndotreeFocus" },
  keys = {
    { "<leader>uu", "<cmd>UndotreeToggle<cr>", desc = "Undo tree" },
  },
  init = function()
    vim.g.undotree_SetFocusWhenToggle = 1
    vim.g.undotree_ShortIndicators = 1
    vim.g.undotree_WindowLayout = 2
  end,
}
