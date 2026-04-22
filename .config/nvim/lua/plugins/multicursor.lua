return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    lazy = false,
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<leader>mn",
        ["Find Subword Under"] = "<leader>mn",
        ["Select All"] = "<leader>mA",
        ["Add Cursor Down"] = "<leader>mj",
        ["Add Cursor Up"] = "<leader>mk",
      }

      local function add_cursor_and_free_move()
        vim.fn["vm#commands#add_cursor_at_pos"](0)
        if vim.fn.exists("b:VM_Selection") == 1 then
          vim.cmd("call b:VM_Selection.Maps.disable(1)")
        end
      end

      local function resume_mappings()
        if vim.fn.exists("b:VM_Selection") == 1 then
          vim.cmd("call b:VM_Selection.Maps.enable()")
        end
      end

      local function resume_mappings_and_insert()
        if vim.fn.exists("b:VM_Selection") ~= 1 then
          return
        end

        if vim.fn.eval("empty(b:VM_Selection.Global.region_at_pos())") == 1 then
          vim.fn["vm#commands#add_cursor_at_pos"](0)
        end

        resume_mappings()

        vim.schedule(function()
          if vim.fn.exists("b:VM_Selection") == 1 then
            local keys = vim.api.nvim_replace_termcodes("i", true, false, true)
            vim.api.nvim_feedkeys(keys, "m", false)
          end
        end)
      end

      vim.keymap.set("n", "<leader>mm", add_cursor_and_free_move, { desc = "Multicursor: add and free move" })
      vim.keymap.set("n", "<leader>mt", resume_mappings, { desc = "Multicursor: resume mappings" })
      vim.keymap.set("n", "<leader>mi", resume_mappings_and_insert, { desc = "Multicursor: resume and insert" })
    end,
  },
}
