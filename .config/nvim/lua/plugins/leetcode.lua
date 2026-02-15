return {
  {
    "kawre/leetcode.nvim",
    build = ":TSUpdate html",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lang = "python3",
    },
    config = function(_, opts)
      require("leetcode").setup(opts)
      local function leet_clean()
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.bo[buf].buflisted then
            vim.bo[buf].buflisted = false
          end
        end
        vim.cmd("enew")
        vim.bo.buflisted = false
        vim.cmd("Leet")
      end
      vim.api.nvim_create_user_command("LeetClean", function()
        leet_clean()
      end, { desc = "Close listed buffers and open leetcode.nvim" })
    end,
  },
}
