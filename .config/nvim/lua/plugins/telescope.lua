return {
  {
    "nvim-telescope/telescope.nvim",
    event = "VeryLazy",
    cmd = { "Telescope", "Fv" },
    -- Lazy replays the first keypress after config installs the real mappings.
    keys = {
      { "<leader>ff", desc = "Telescope find files" },
      { "<leader>fs", desc = "Telescope git status" },
      { "<leader>ft", desc = "Telescope git files" },
      { "<leader>fg", desc = "Telescope live grep" },
      { "<leader>fd", desc = "Telescope find directories" },
      { "<leader>fG", desc = "Telescope buffer grep" },
      { "<leader>fw", desc = "Telescope find word under cursor" },
      { "<leader>rr", desc = "Telescope references" },
      { "<leader>rd", desc = "Telescope definitions" },
      { "<leader>fb", desc = "Telescope buffers" },
      { "<leader>fh", desc = "Telescope help tags" },
      { "<leader>gw", desc = "Git: switch worktree" },
      { "<leader>gb", desc = "Git: branches (fzf)" },
      { "<leader>gB", desc = "Git: remote branches (fzf)" },
      { "<leader>gc", desc = "Git: commits (repo)" },
      { "<leader>gC", desc = "Git: commits (buffer)" },
      { "<leader>fT", desc = "Telescope grep tracked files" },
    },
    dependencies = {
      "nvim-lua/plenary.nvim",
      {
        "nvim-telescope/telescope-fzf-native.nvim",
        build = "make",
      },
    },
    config = function()
      local function open_commit_in_fugitive(prompt_bufnr)
        local actions = require("telescope.actions")
        local state = require("telescope.actions.state")
        local selection = state.get_selected_entry()
        local cwd = state.get_current_picker(prompt_bufnr).cwd or vim.fn.getcwd()
        if not selection then
          return
        end
        actions.close(prompt_bufnr)
        require("lazy").load({ plugins = { "vim-fugitive" } })
        local path = vim.fn.FugitiveFind(selection.value, vim.fn.FugitiveExtractGitDir(cwd))
        vim.cmd.edit(vim.fn.fnameescape(path))
      end

      local function commit_mappings()
        require("telescope.actions").select_default:replace(open_commit_in_fugitive)
        return true
      end

      pcall(function()
        require("telescope").setup({
          defaults = {
            sorting_strategy = "ascending",
            layout_config = { prompt_position = "top" },
            preview = {
              treesitter = { enable = false },
            },
          },
          pickers = {
            find_files = {
              hidden = true,
              file_ignore_patterns = { "%.git/" },
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.55 },
            },
            git_files = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.55 },
            },
            git_status = {
              layout_strategy = "horizontal",
              layout_config = { prompt_position = "bottom", width = 0.85, height = 0.70, preview_width = 0.55 },
            },
            git_branches = {
              layout_config = { prompt_position = "bottom" },
            },
            git_commits = {
              layout_config = { prompt_position = "bottom" },
              attach_mappings = commit_mappings,
            },
            live_grep = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            grep_string = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            lsp_references = {
              theme = "ivy",
              sorting_strategy = "ascending",
              layout_config = { height = 0.35 },
            },
            buffers = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.55, height = 0.45 },
            },
            help_tags = {
              theme = "dropdown",
              previewer = false,
              layout_config = { width = 0.60, height = 0.50 },
            },
            git_bcommits = {
              attach_mappings = commit_mappings,
              layout_strategy = "horizontal",
              layout_config = { prompt_position = "bottom", width = 0.80, height = 0.70, preview_width = 0.60 },
            },
          },
        })
      end)
      pcall(function()
        require("telescope").load_extension("fzf")
      end)
      local builtin = require("telescope.builtin")
      local function telescope_startup_cwd()
        local cwd = vim.g.startup_cwd
        if not cwd or cwd == "" then
          return vim.fn.getcwd()
        end
        return cwd
      end

      local function telescope_find_files_startup()
        builtin.find_files({ cwd = telescope_startup_cwd() })
      end

      local function telescope_live_grep_startup()
        builtin.live_grep({ cwd = telescope_startup_cwd() })
      end

      local function telescope_find_directories()
        local home = vim.fn.expand("$HOME")
        local command = string.format(
          "find %s -mindepth 1 -maxdepth 3 -type d 2>/dev/null | sort -u",
          vim.fn.shellescape(home)
        )
        local dirs = vim.fn.systemlist(command)

        if vim.tbl_isempty(dirs) then
          vim.notify("No directories found", vim.log.levels.WARN)
          return
        end

        local pickers = require("telescope.pickers")
        local finders = require("telescope.finders")
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local conf = require("telescope.config").values

        pickers
          .new({}, {
            prompt_title = "Directories",
            finder = finders.new_table({ results = dirs }),
            sorter = conf.generic_sorter({}),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)

                if not selection then
                  return
                end

                local dir = selection.value
                vim.g.startup_cwd = dir
                vim.cmd.cd(vim.fn.fnameescape(dir))
                vim.cmd.edit(vim.fn.fnameescape(dir))
                vim.notify("CWD: " .. dir)
              end)
              return true
            end,
          })
          :find()
      end

      local function telescope_git_root()
        local dirs = {}
        local buf = vim.api.nvim_buf_get_name(0)

        if buf ~= "" then
          table.insert(dirs, vim.fs.dirname(buf))
        end

        table.insert(dirs, telescope_startup_cwd())
        table.insert(dirs, vim.fn.getcwd())

        for _, dir in ipairs(dirs) do
          local root = vim.fn.systemlist({ "git", "-C", dir, "rev-parse", "--show-toplevel" })[1]
          if vim.v.shell_error == 0 and root and root ~= "" then
            return root
          end
        end
      end

      local function telescope_git_worktrees()
        -- Prefer the selected project over buffers left open in another worktree.
        local cwd = telescope_startup_cwd()
        local root = vim.fn.systemlist({ "git", "-C", cwd, "rev-parse", "--show-toplevel" })[1]
        if vim.v.shell_error ~= 0 then
          root = telescope_git_root()
        end
        if not root then
          vim.notify("Not in a git repo", vim.log.levels.WARN)
          return
        end

        local result = vim.system({ "git", "-C", root, "worktree", "list", "--porcelain", "-z" }):wait()
        if result.code ~= 0 then
          vim.notify(result.stderr or "Could not list worktrees", vim.log.levels.ERROR)
          return
        end

        local worktrees = {}
        for _, record in ipairs(vim.split(result.stdout, "\0\0", { plain = true, trimempty = true })) do
          local worktree = {}
          for _, line in ipairs(vim.split(record, "\0", { plain = true, trimempty = true })) do
            local key, value = line:match("^(%S+)%s?(.*)$")
            worktree[key] = value
          end
          if worktree.worktree and not worktree.bare then
            worktree.path = worktree.worktree
            worktree.label = worktree.branch and worktree.branch:gsub("^refs/heads/", "")
              or ("detached " .. (worktree.HEAD or ""):sub(1, 8))
            table.insert(worktrees, worktree)
          end
        end

        if vim.tbl_isempty(worktrees) then
          vim.notify("No worktrees found", vim.log.levels.WARN)
          return
        end

        local parent = vim.fs.dirname(worktrees[1].path)
        for _, worktree in ipairs(worktrees) do
          while parent ~= "/" and worktree.path:sub(1, #parent + 1) ~= parent .. "/" do
            parent = vim.fs.dirname(parent)
          end
        end
        local prefix = parent == "/" and "/" or parent .. "/"
        local branch_width, path_width = 0, 0
        for _, worktree in ipairs(worktrees) do
          worktree.short_path = worktree.path:sub(#prefix + 1)
          branch_width = math.max(branch_width, vim.fn.strdisplaywidth(worktree.label))
          path_width = math.max(path_width, vim.fn.strdisplaywidth(worktree.short_path))
        end
        branch_width = math.min(branch_width, 40)
        local display = require("telescope.pickers.entry_display").create({
          separator = "  ",
          items = { { width = branch_width }, { remaining = true } },
        })
        local actions = require("telescope.actions")
        local action_state = require("telescope.actions.state")
        local opts = require("telescope.themes").get_dropdown({
          previewer = false,
          layout_config = {
            width = function(_, columns)
              return math.min(math.max(branch_width + path_width + 7, 60), 110, math.floor(columns * 0.9))
            end,
            height = function(_, _, lines)
              return math.min(#worktrees + 4, lines - 2)
            end,
          },
        })
        require("telescope.pickers")
          .new(opts, {
            prompt_title = "Git Worktrees",
            finder = require("telescope.finders").new_table({
              results = worktrees,
              entry_maker = function(worktree)
                return {
                  value = worktree,
                  ordinal = worktree.label .. " " .. worktree.path,
                  display = function()
                    return display({
                      worktree.label,
                      { worktree.short_path, "TelescopeResultsComment" },
                    })
                  end,
                }
              end,
            }),
            sorter = require("telescope.config").values.generic_sorter(opts),
            attach_mappings = function(prompt_bufnr)
              actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if not selection then
                  return
                end
                local path = selection.value.path
                if vim.fn.isdirectory(path) == 0 then
                  vim.notify("Worktree directory is missing: " .. path, vim.log.levels.WARN)
                  return
                end
                vim.cmd.cd(vim.fn.fnameescape(path))
                vim.g.startup_cwd = path
                -- Show the new project without discarding modified buffers.
                vim.cmd("silent! packadd netrw")
                vim.cmd("keepalt hide Explore " .. vim.fn.fnameescape(path))
                vim.fn["netrw#SetTreetop"](1, path)
                vim.notify("Worktree: " .. selection.value.label .. " (" .. path .. ")")
              end)
              return true
            end,
          })
          :find()
      end

      local function telescope_live_grep_tracked()
        local cwd = telescope_git_root()
        if not cwd then
          vim.notify("Not in a git repo", vim.log.levels.WARN)
          return
        end

        local files = vim.fn.systemlist({ "git", "-C", cwd, "ls-files" })
        if vim.v.shell_error ~= 0 or vim.tbl_isempty(files) then
          vim.notify("No tracked files in git repo", vim.log.levels.WARN)
          return
        end

        builtin.live_grep({
          cwd = cwd,
          search_dirs = files,
          prompt_title = "Git Tracked Grep",
        })
      end

      vim.keymap.set(
        "n",
        "<leader>ff",
        telescope_find_files_startup,
        { desc = "Telescope find files" }
      )
      vim.keymap.set("n", "<leader>fs", builtin.git_status, { desc = "Telescope git status" })
      vim.keymap.set("n", "<leader>ft", builtin.git_files, { desc = "Telescope git files" })
      vim.keymap.set(
        "n",
        "<leader>fg",
        telescope_live_grep_startup,
        { desc = "Telescope live grep" }
      )
      vim.keymap.set("n", "<leader>fd", telescope_find_directories, { desc = "Telescope find directories" })
      vim.api.nvim_create_user_command("Fv", telescope_find_directories, { desc = "Find directory and open it" })
      vim.keymap.set("n", "<leader>fG", builtin.current_buffer_fuzzy_find, { desc = "Telescope buffer grep" })
      vim.keymap.set("n", "<leader>fw", builtin.grep_string, { desc = "Telescope find word under cursor" })
      vim.keymap.set("n", "<leader>rr", builtin.lsp_references, { desc = "Telescope references" })
      vim.keymap.set("n", "<leader>rd", builtin.lsp_definitions, { desc = "Telescope definitions" })
      vim.keymap.set("n", "<leader>fb", builtin.buffers, { desc = "Telescope buffers" })
      vim.keymap.set("n", "<leader>fh", builtin.help_tags, { desc = "Telescope help tags" })
      vim.keymap.set("n", "<leader>gw", telescope_git_worktrees, { desc = "Git: switch worktree" })
      vim.keymap.set("n", "<leader>gb", builtin.git_branches, { desc = "Git: branches (fzf)" })
      vim.keymap.set("n", "<leader>gB", function()
        builtin.git_branches({ pattern = "refs/remotes" })
      end, { desc = "Git: remote branches (fzf)" })
      vim.keymap.set("n", "<leader>gc", builtin.git_commits, { desc = "Git: commits (repo)" })
      vim.keymap.set("n", "<leader>gC", builtin.git_bcommits, { desc = "Git: commits (buffer)" })
      vim.keymap.set("n", "<leader>fT", telescope_live_grep_tracked, { desc = "Telescope grep tracked files" })
    end,
  },
}
