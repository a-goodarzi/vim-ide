return {
  { "nvim-telescope/telescope.nvim", dependencies = { "nvim-lua/plenary.nvim" },
    keys = { { "<leader>ff", "<cmd>Telescope find_files<cr>" }, { "<leader>fg", "<cmd>Telescope live_grep<cr>" } },
    config = function() require("telescope").setup({}) end },
  { "folke/which-key.nvim", event = "VeryLazy", opts = {} },
  { "williamboman/mason.nvim", cmd = "Mason", opts = {} },
  { "saghen/blink.cmp", version = "1.*", event = "InsertEnter", opts = { keymap = { preset = "default" } } },
  { "nvim-neo-tree/neo-tree.nvim", branch = "v3.x", cmd = "Neotree",
    dependencies = { "nvim-lua/plenary.nvim", "MunifTanjim/nui.nvim" }, opts = {} },
  { "folke/tokyonight.nvim", priority = 1000, config = function() vim.cmd.colorscheme("tokyonight") end },
}
