-- ┌──────────────────────────────────────────────────────────────┐
-- │  THE ONE FILE YOU EDIT.  Everything else reads from here.    │
-- └──────────────────────────────────────────────────────────────┘
-- After editing: restart nvim (or :Lazy sync if you added a language/theme).
return {
  -- tokyonight | catppuccin | gruvbox | kanagawa | rose-pine | nord | onedark
  -- Leader key (" " = Space).
  leader = " ",

  colorscheme = "tokyonight",
  transparent = false,

  -- Language presets, defined in lua/config/languages.lua.
  -- Each one brings: treesitter parser, LSP server, formatter, linter, debugger, test adapter.
  languages = { "lua", "python" },

  -- Switch whole subsystems on/off.
  features = {
    git = true,            -- gitsigns + lazygit/diffview helpers
    debug = true,          -- nvim-dap (+ ui, virtual text)
    test = true,           -- neotest
    terminal = true,       -- toggleterm
    format_on_save = true, -- conform.nvim
    lint = true,           -- nvim-lint
    icons = true,          -- set false if your terminal has no Nerd Font
  },

  -- vim.opt overrides, e.g. { relativenumber = false, tabstop = 2 }
  options = {},

  -- Per-server LSP overrides, passed straight to vim.lsp.config(name, cfg).
  -- e.g. { pyright = { settings = { python = { analysis = { typeCheckingMode = "strict" } } } } }
  lsp_overrides = {},

  -- Extra keymaps: { { "n", "<leader>xx", "<cmd>echo 'hi'<cr>", "Say hi" } }
  keymaps = {},

  -- Extra lazy.nvim plugin specs, appended as-is. e.g. { { "folke/flash.nvim", opts = {} } }
  extra_plugins = {},
}
