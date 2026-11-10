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
    },
    config = function()
      local ts = require("telescope")
      ts.setup({ defaults = { layout_strategy = "flex", sorting_strategy = "ascending",
        layout_config = { prompt_position = "top" } } })
      pcall(ts.load_extension, "fzf")
    end },

  -- File explorer ---------------------------------------------------------
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim", icons and "nvim-tree/nvim-web-devicons" or nil },
    keys = { { "<leader>e", "<cmd>Neotree toggle reveal<cr>", desc = "Explorer" } },
    opts = { filesystem = { follow_current_file = { enabled = true }, filtered_items = { visible = true } } } },

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
