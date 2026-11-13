return {
  {
    "nvim-treesitter/nvim-treesitter",
    event = { "BufReadPre", "BufNewFile", "FileType" },
    cmd = { "TSInstall", "TSInstallFromGrammar", "TSUpdate", "TSUninstall", "TSLog" },
    build = ":TSUpdate",
    opts = {
      ensure_installed = {
        "lua",
        "vim",
        "vimdoc",
        "bash",
        "json",
        "yaml",
        "toml",
        "markdown",
        "markdown_inline",
        "html",
        "css",
        "javascript",
        "typescript",
        "tsx",
        "python",
        "c",
        "cpp",
      },
    },
    config = function(_, opts)
      local ts = require("nvim-treesitter")
      ts.setup({})
      ts.install(opts.ensure_installed)

      vim.api.nvim_create_autocmd("FileType", {
        group = vim.api.nvim_create_augroup("TreesitterHighlighting", { clear = true }),
        callback = function(args)
          local lang = vim.treesitter.language.get_lang(vim.bo[args.buf].filetype)
          if lang and vim.treesitter.language.add(lang) then
            vim.treesitter.start(args.buf, lang)
            vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end,
  },
}
