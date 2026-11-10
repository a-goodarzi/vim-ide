-- VS Code-style pieces: project-wide Search & Replace, breadcrumbs, outline, zen mode, minimap.
-- The left "activity bar" that ties them together lives in config/activitybar.lua.
local cfg = require("config")
return {
  -- Search & Replace across files (the VS Code Search view). Opens in the left sidebar.
  { "MagicDuck/grug-far.nvim", cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      { "<leader>sr", function() require("config.activitybar").show("search") end, desc = "Search & Replace (sidebar)" },
      { "<leader>sw", function() require("grug-far").open({ prefills = { search = vim.fn.expand("<cword>") }, windowCreationCommand = "topleft 50vsplit" }) end, desc = "Search & Replace word under cursor" },
      { "<leader>sr", function() require("grug-far").with_visual_selection({ windowCreationCommand = "topleft 50vsplit" }) end, mode = "v", desc = "Search & Replace selection" },
      { "<leader>sf", function() require("grug-far").open({ prefills = { paths = vim.fn.expand("%") }, windowCreationCommand = "topleft 50vsplit" }) end, desc = "Search & Replace in this file" },
    },
    opts = { windowCreationCommand = "topleft 50vsplit", transient = true } },

  -- Breadcrumbs (file > symbol path) in the window bar, clickable
  { "Bekaboo/dropbar.nvim", enabled = cfg.feature("breadcrumbs"), event = "BufReadPost",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = { menu = { win_configs = { border = "rounded" } } } },

  -- Outline (symbols of the current file)
  { "stevearc/aerial.nvim", cmd = { "AerialToggle", "AerialOpen", "AerialClose" },
    keys = { { "<leader>co", "<cmd>AerialToggle! left<cr>", desc = "Outline" } },
    opts = { layout = { default_direction = "left", min_width = 28 }, attach_mode = "global" } },

  { "folke/zen-mode.nvim", cmd = "ZenMode", keys = { { "<leader>uz", "<cmd>ZenMode<cr>", desc = "Zen mode" } }, opts = {} },

  { "echasnovski/mini.map", enabled = cfg.feature("minimap"), event = "VeryLazy",
    keys = { { "<leader>um", function() require("mini.map").toggle() end, desc = "Minimap" } },
    config = function()
      local map = require("mini.map")
      map.setup({ integrations = { map.gen_integration.builtin_search(), map.gen_integration.diagnostic(), map.gen_integration.gitsigns() },
        symbols = { encode = map.gen_encode_symbols.dot("4x2") }, window = { width = 12, winblend = 30 } })
      map.open()
    end },
}
