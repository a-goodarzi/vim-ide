-- VS Code-style pieces: project-wide Search & Replace, breadcrumbs, outline, zen mode, minimap.
-- The left "activity bar" that ties them together lives in config/activitybar.lua.
local cfg = require("config")
return {
  -- Search & Replace across files (the VS Code Search view). Opens in the left sidebar.
  { "MagicDuck/grug-far.nvim", cmd = { "GrugFar", "GrugFarWithin" },
    keys = {
      { "<leader>sr", function() require("config.activitybar").show("search") end, desc = "Search & Replace (sidebar)" },
      { "<leader>sw", function() local w = vim.fn.expand("<cword>"); require("config.activitybar").open_search(function() require("grug-far").open({ prefills = { search = w }, windowCreationCommand = "topleft 50vsplit" }) end) end, desc = "Search & Replace word under cursor" },
      { "<leader>sr", function() require("config.activitybar").open_search(function() require("grug-far").with_visual_selection({ windowCreationCommand = "topleft 50vsplit" }) end) end, mode = "v", desc = "Search & Replace selection" },
      { "<leader>sf", function() local f = vim.fn.expand("%"); require("config.activitybar").open_search(function() require("grug-far").open({ prefills = { paths = f }, windowCreationCommand = "topleft 50vsplit" }) end) end, desc = "Search & Replace in this file" },
    },
    opts = function()
      return {
        windowCreationCommand = "topleft 50vsplit", transient = true,
        -- a narrow sidebar, not a page: labeled inputs, no wrapping, no line numbers, theme-linked colors (config/ui.lua)
        showCompactInputs = false, showInputsTopPadding = false, showInputsBottomPadding = false,
        wrap = false, startInInsertMode = true, helpLine = { enabled = true }, resultsSeparatorLineChar = "\xe2\x94\x80",
        icons = { enabled = require("config").icons() },
        folding = { enabled = true },
        -- Results open in the editor area to the RIGHT of the sidebar, never in a new split beside the bar or in a float/sidebar.
        openTargetWindow = { preferredLocation = "right", exclude = { function(win)
          local b = vim.api.nvim_win_get_buf(win)
          local ft = vim.bo[b].filetype
          return vim.api.nvim_win_get_config(win).relative ~= "" or vim.bo[b].buftype == "terminal"
            or ({ ["neo-tree"] = 1, ["ide-activity"] = 1, aerial = 1, minimap = 1, qf = 1, trouble = 1 })[ft] ~= nil
            or ft:find("^dap") ~= nil
        end } },
        engines = { ripgrep = { placeholders = { enabled = true, search = "text or regex", replacement = "replace with",
          filesFilter = "*.lua, src/**", flags = "--ignore-case", paths = "./ (current folder)" } } },
      }
    end,
    config = function(_, opts)
      require("grug-far").setup(opts)
      -- Sidebar chrome: same look as the Explorer (no gutter; the title comes from the tab bar offset).
      vim.api.nvim_create_autocmd("FileType", { group = vim.api.nvim_create_augroup("ide-grugfar", { clear = true }),
        pattern = "grug-far", callback = function()
          local w = vim.api.nvim_get_current_win()
          -- double-click a result to open it (same as <Enter>)
          vim.keymap.set("n", "<2-LeftMouse>", "<LeftMouse><CR>", { buffer = true, remap = true, desc = "Open result" })
          require("config.ui").setwo(w, { number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0", cursorline = true,
            list = false, spell = false, wrap = false, winfixwidth = true, colorcolumn = "" })
        end })
    end },

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
      if not vim.env.IDE_SETTINGS_ONLY then map.open() end   -- `ide settings` / `ide help` are full-screen pages: no minimap
      -- The minimap is a float pinned to the screen's right edge; it would cover the Claude panel and full-screen pages
      -- (Settings, Help, Plugins...), so step aside while one is visible and come back when it closes (only if we hid it).
      local hidden = false
      local function sync()
        local claude = false
        for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
          if vim.api.nvim_win_get_config(w).relative == "" then
            local b = vim.api.nvim_win_get_buf(w)
            local ft = vim.bo[b].filetype
            if ft == "snacks_terminal" or vim.bo[b].buftype == "terminal" or (ft:find("^ide%-") and ft ~= "ide-activity") then claude = true end
          end
        end
        local open = map.current.win_data[vim.api.nvim_get_current_tabpage()] ~= nil
        if claude and open then hidden = true; pcall(map.close)
        elseif not claude and hidden then hidden = false; pcall(map.open) end
      end
      -- the panel's filetype is set after its window appears, so look again shortly afterwards
      vim.api.nvim_create_autocmd({ "WinNew", "WinClosed", "TermOpen", "BufWinEnter", "FileType" }, { group = vim.api.nvim_create_augroup("ide-minimap-claude", { clear = true }),
        callback = function() vim.schedule(sync); vim.defer_fn(sync, 200) end })
    end },
}
