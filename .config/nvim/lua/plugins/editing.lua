return {
  {
    "kylechui/nvim-surround",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  {
    "numToStr/Comment.nvim",
    event = { "BufReadPre", "BufNewFile" },
    opts = {},
  },

  {
    "windwp/nvim-autopairs",
    event = "InsertEnter",
    opts = {
      check_ts = true,
    },
    config = function(_, opts)
      local ok, npairs = pcall(require, "nvim-autopairs")
      if not ok then
        return
      end
      npairs.setup(opts)

      pcall(function()
        local cmp_ok, cmp = pcall(require, "cmp")
        if not cmp_ok then
          return
        end
        local cmp_autopairs = require("nvim-autopairs.completion.cmp")
        cmp.event:on("confirm_done", cmp_autopairs.on_confirm_done())
      end)
    end,
  },
}
