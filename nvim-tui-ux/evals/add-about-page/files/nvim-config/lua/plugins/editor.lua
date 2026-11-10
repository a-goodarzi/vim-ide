local icons = require("config").icons()
return {
  -- Fuzzy finding ---------------------------------------------------------
  { "nvim-telescope/telescope.nvim", cmd = "Telescope",
    dependencies = { "nvim-lua/plenary.nvim", { "nvim-telescope/telescope-fzf-native.nvim", build = "make", cond = vim.fn.executable("make") == 1 } },
    keys = {
      { "<leader><space>", "<cmd>Telescope find_files<cr>", desc = "Find files" },
      { "<leader>ff", "<cmd>Telescope find_files<cr>", desc = "Files" },
      { "<leader>fg", "<cmd>Telescope live_grep<cr>", desc = "Grep (needs ripgrep)" },
      { "<leader>fb", "<cmd>Telescope buffers<cr>", desc = "Buffers" },
      { "<leader>fr", "<cmd>Telescope oldfiles<cr>", desc = "Recent" },
      { "<leader>fh", "<cmd>Telescope help_tags<cr>", desc = "Help" },
      { "<leader>fk", "<cmd>Telescope keymaps<cr>", desc = "Keymaps" },
      { "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", desc = "Symbols" },
      { "<leader>fd", "<cmd>Telescope diagnostics<cr>", desc = "Diagnostics" },
      { "<leader>fc", "<cmd>Telescope commands<cr>", desc = "Commands" },
    },
    config = function()
      local ts = require("telescope")
      local ui = require("config.ui")
      ts.setup({ defaults = {
        -- one look for every picker: rounded frame, top prompt, titled panes, matching accent colors
        prompt_prefix = " " .. ui.g("search"), selection_caret = ui.g("bar") .. " ", entry_prefix = "  ",
        borderchars = { "\xe2\x94\x80", "\xe2\x94\x82", "\xe2\x94\x80", "\xe2\x94\x82", "\xe2\x95\xad", "\xe2\x95\xae", "\xe2\x95\xaf", "\xe2\x95\xb0" },
        layout_strategy = "horizontal", sorting_strategy = "ascending", path_display = { "truncate" },
        layout_config = { prompt_position = "top", width = 0.88, height = 0.8, horizontal = { preview_width = 0.55 }, vertical = { preview_height = 0.5 } },
        prompt_title = "Search", results_title = "Results", preview_title = "Preview",
        -- previewers set their own title ("Grep Preview"); force ours
        file_previewer = function(o) o = o or {}; o.title = "Preview"; return require("telescope.previewers").vim_buffer_cat.new(o) end,
        grep_previewer = function(o) o = o or {}; o.title = "Preview"; return require("telescope.previewers").vim_buffer_vimgrep.new(o) end,
      }, pickers = {
        find_files = { prompt_title = "Find files", hidden = true },
        live_grep = { prompt_title = "Search in files" },
        buffers = { prompt_title = "Open tabs", sort_mru = true },
        oldfiles = { prompt_title = "Recent files" },
        commands = { prompt_title = "Command palette" },
        keymaps = { prompt_title = "Keymaps" },
        help_tags = { prompt_title = "Help" },
        diagnostics = { prompt_title = "Problems" },
        lsp_document_symbols = { prompt_title = "Symbols in file" },
        lsp_dynamic_workspace_symbols = { prompt_title = "Symbols in project" },
      } })
      pcall(ts.load_extension, "fzf")
    end },

  -- File explorer ---------------------------------------------------------
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", icons and "nvim-tree/nvim-web-devicons" or nil },
    keys = { { "<leader>e", "<cmd>Neotree toggle reveal<cr>", desc = "Explorer" } },
    opts = { popup_border_style = "rounded", window = { width = 34 },
      filesystem = { follow_current_file = { enabled = true }, filtered_items = { visible = true } } } },

  -- Editing helpers -------------------------------------------------------
  { "echasnovski/mini.pairs", event = "InsertEnter", opts = {} },
  { "echasnovski/mini.surround", keys = { "gsa", "gsd", "gsr" }, opts = {
    mappings = { add = "gsa", delete = "gsd", replace = "gsr", find = "", find_left = "", highlight = "", update_n_lines = "" } } },
  { "echasnovski/mini.ai", event = "VeryLazy", opts = {} },
  { "folke/flash.nvim", event = "VeryLazy", opts = {},
    keys = { { "s", mode = { "n", "x", "o" }, function() require("flash").jump() end, desc = "Flash jump" } } },

  -- Diagnostics list ------------------------------------------------------
  { "folke/trouble.nvim", cmd = "Trouble", opts = {},
    keys = {
      { "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", desc = "Workspace diagnostics" },
      { "<leader>xb", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", desc = "Buffer diagnostics" },
      { "<leader>xs", "<cmd>Trouble symbols toggle<cr>", desc = "Symbols" },
    } },

  { "folke/todo-comments.nvim", event = "BufReadPost", dependencies = "nvim-lua/plenary.nvim", opts = {} },
}
