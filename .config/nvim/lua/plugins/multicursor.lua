return {
  {
    "mg979/vim-visual-multi",
    branch = "master",
    cmd = { "VMTheme", "VMDebug", "VMClear", "VMLive", "VMRegisters", "VMSearch", "VMFromSearch" },
    keys = {
      { "<leader>mn", mode = { "n", "x" }, desc = "Multicursor: find under cursor" },
      { "<leader>mA", desc = "Multicursor: select all" },
      { "<leader>mj", desc = "Multicursor: add cursor down" },
      { "<leader>mk", desc = "Multicursor: add cursor up" },
      { "<leader>mm", desc = "Multicursor: add and free move" },
      { "<leader>mt", desc = "Multicursor: resume mappings" },
      { "<leader>mi", desc = "Multicursor: resume and insert" },
      -- Preserve the plugin's other default entry points too.
      { [[\\gS]], desc = "Multicursor: reselect last" },
      { [[\\\]], desc = "Multicursor: add cursor at position" },
      { [[\\/]], mode = { "n", "x" }, desc = "Multicursor: regex search" },
      { "<S-Right>", desc = "Multicursor: select right" },
      { "<S-Left>", desc = "Multicursor: select left" },
      { [[\\A]], mode = "x", desc = "Multicursor: visual select all" },
      { [[\\a]], mode = "x", desc = "Multicursor: visual add" },
      { [[\\f]], mode = "x", desc = "Multicursor: visual find" },
      { [[\\c]], mode = "x", desc = "Multicursor: visual cursors" },
    },
    init = function()
      vim.g.VM_maps = {
        ["Find Under"] = "<leader>mn",
        ["Find Subword Under"] = "<leader>mn",
        ["Select All"] = "<leader>mA",
        ["Add Cursor Down"] = "<leader>mj",
        ["Add Cursor Up"] = "<leader>mk",
      }
    end,
    config = function()
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
