-- ┌──────────────────────────────────────────────────────────────┐
-- │  DEFAULTS.  Edit here, or press <Space>us inside nvim to use │
-- │  the Settings page (your choices are saved separately in     │
-- │  stdpath("data")/ide-settings.json and override this file).  │
-- └──────────────────────────────────────────────────────────────┘
return {
  leader = " ",

  -- tokyonight | catppuccin | gruvbox | kanagawa | rose-pine | nord | onedark
  colorscheme = "tokyonight",
  transparent = false,

  -- Statusline look: "rounded" (powerlevel10k-like pills), "powerline" (arrows), "plain"
  statusline_style = "rounded",

  -- Extra folders appended to PATH for nvim (tools nvim cannot find, e.g. installed by nvm or mise): { "~/my/bin" }
  extra_path = {},

  -- Shortcut notation in Help, palette and tour: "auto" (⌃ ⌥ ⇧ on a Mac, Ctrl / Alt / Shift elsewhere), "mac" or "pc"
  key_style = "auto",

  -- Tab shape: "slanted" (trapezoids), "rounded" (pills) or "flat" (plain blocks)
  tabs_style = "slanted",

  -- Language presets, defined in lua/config/languages.lua.
  languages = { "lua", "python", "go", "html_css", "javascript", "terraform", "bash", "markdown", "json", "yaml" },

  -- Switch whole subsystems on/off. (Most need an nvim restart.)
  features = {
    activity_bar = true,   -- VS Code-style icon column: Explorer, Search & Replace, Git, Debug, Outline, Plugins
    vscode_keys = true,    -- VS Code shortcuts (F1 palette, Ctrl-P, Ctrl-S, F5/F9/F10/F11, Alt-arrows, Alt-b ...)
    breadcrumbs = true,    -- file > symbol path above the editor
    minimap = false,       -- code minimap on the right
    tabs = true,           -- tab bar (config/tabs.lua): open files shown as tabs
    explorer_on_start = true, -- open the file browser sidebar at launch
    context_menu = true,   -- right-click menus in the editor and the Explorer
    session_restore = true, -- reopen the last session's files when you start `ide` in a folder with no file argument
    welcome = true,        -- show the first-run welcome (icon check, doctor, first keys) once
    dashboard = true,      -- welcome screen with shortcuts
    claude = true,         -- Claude Code embedded in a side panel (needs the `claude` CLI)
    git = true,
    debug = true,
    test = true,
    terminal = true,
    format_on_save = true,
    lint = true,
    icons = true,          -- needs a Nerd Font; set false for plain ASCII
  },

  -- Embedded Claude Code panel
  claude = {
    side = "right",        -- "right" | "left"
    width = 0.35,          -- fraction of the screen
    autostart = false,     -- open the Claude panel every time nvim starts (or run `ide claude`)
    terminal_cmd = nil,    -- e.g. "~/.claude/local/claude" if `claude` is not on PATH
  },

  -- vim.opt overrides, e.g. { relativenumber = false, tabstop = 2 }
  options = {},

  -- Per-server LSP overrides: vim.lsp.config(name, cfg)
  lsp_overrides = {},

  -- Extra keymaps: { { "n", "<leader>xx", "<cmd>echo 'hi'<cr>", "Say hi" } }
  keymaps = {},

  -- Extra lazy.nvim plugin specs
  extra_plugins = {},
}
