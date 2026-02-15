return {
  "ThePrimeagen/harpoon",
  dependencies = {
    "nvim-lua/plenary.nvim",
  },
  event = "VeryLazy",
  config = function()
    local ok, harpoon = pcall(require, "harpoon")
    if not ok then
      vim.notify("Harpoon could not be loaded", vim.log.levels.ERROR)
      return
    end

    local mark = require("harpoon.mark")
    local ui = require("harpoon.ui")

    harpoon.setup({
      global_settings = {
        save_on_toggle = true,
        save_on_change = true,
        mark_branch = true,
      },
    })

    vim.keymap.set("n", "<leader>h", mark.add_file, { desc = "Harpoon file" })
    vim.keymap.set("n", "<leader>H", ui.toggle_quick_menu, { desc = "Harpoon quick menu" })

    vim.keymap.set("n", "<C-h>", function()
      ui.nav_file(1)
    end, { desc = "Harpoon select 1" })
    vim.keymap.set("n", "<C-j>", function()
      ui.nav_file(2)
    end, { desc = "Harpoon select 2" })
    vim.keymap.set("n", "<C-k>", function()
      ui.nav_file(3)
    end, { desc = "Harpoon select 3" })
    vim.keymap.set("n", "<C-l>", function()
      ui.nav_file(4)
    end, { desc = "Harpoon select 4" })

    vim.keymap.set("n", "<leader><left>", ui.nav_prev, { desc = "Harpoon prev file" })
    vim.keymap.set("n", "<leader><right>", ui.nav_next, { desc = "Harpoon next file" })

    vim.api.nvim_create_autocmd("FileType", {
      pattern = "harpoon",
      callback = function(ev)
        local function move_menu_item(delta)
          local bufnr = ev.buf
          local line = vim.api.nvim_win_get_cursor(0)[1]
          local target = line + delta
          local line_count = vim.api.nvim_buf_line_count(bufnr)
          if target < 1 or target > line_count then
            return
          end

          local current = vim.api.nvim_buf_get_lines(bufnr, line - 1, line, true)[1]
          local other = vim.api.nvim_buf_get_lines(bufnr, target - 1, target, true)[1]
          vim.api.nvim_buf_set_lines(bufnr, line - 1, line, true, { other })
          vim.api.nvim_buf_set_lines(bufnr, target - 1, target, true, { current })
          vim.api.nvim_win_set_cursor(0, { target, 0 })

          require("harpoon.ui").on_menu_save()
        end

        vim.keymap.set("n", "J", function()
          move_menu_item(1)
        end, { buffer = ev.buf, desc = "Harpoon: move item down" })
        vim.keymap.set("n", "K", function()
          move_menu_item(-1)
        end, { buffer = ev.buf, desc = "Harpoon: move item up" })
      end,
    })

    vim.keymap.set("n", "<leader>ht", function()
      require("harpoon.term").gotoTerminal(1)
    end, { desc = "Harpoon terminal 1" })
  end,
}
