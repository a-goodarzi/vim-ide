-- Colorscheme registry + live switching (used by plugins/ui.lua and the Settings page).
local M = {}

-- name = { plugin repo, :colorscheme to run, lazy.nvim plugin name (optional) }
-- Several names can share one plugin (variants). Light themes are marked with a trailing "(light)" in the Settings page.
M.themes = {
  ["tokyonight"] = { "folke/tokyonight.nvim", "tokyonight" },
  ["tokyonight-storm"] = { "folke/tokyonight.nvim", "tokyonight-storm" },
  ["tokyonight-moon"] = { "folke/tokyonight.nvim", "tokyonight-moon" },
  ["tokyonight-day"] = { "folke/tokyonight.nvim", "tokyonight-day" },
  ["catppuccin"] = { "catppuccin/nvim", "catppuccin", "catppuccin" },
  ["catppuccin-macchiato"] = { "catppuccin/nvim", "catppuccin-macchiato", "catppuccin" },
  ["catppuccin-frappe"] = { "catppuccin/nvim", "catppuccin-frappe", "catppuccin" },
  ["catppuccin-latte"] = { "catppuccin/nvim", "catppuccin-latte", "catppuccin" },
  ["vscode"] = { "Mofiqul/vscode.nvim", "vscode" },
  ["github-dark"] = { "projekt0n/github-nvim-theme", "github_dark", "github-theme" },
  ["github-dimmed"] = { "projekt0n/github-nvim-theme", "github_dark_dimmed", "github-theme" },
  ["github-light"] = { "projekt0n/github-nvim-theme", "github_light", "github-theme" },
  ["dracula"] = { "Mofiqul/dracula.nvim", "dracula" },
  ["nightfox"] = { "EdenEast/nightfox.nvim", "nightfox" },
  ["carbonfox"] = { "EdenEast/nightfox.nvim", "carbonfox" },
  ["duskfox"] = { "EdenEast/nightfox.nvim", "duskfox" },
  ["dayfox"] = { "EdenEast/nightfox.nvim", "dayfox" },
  ["gruvbox"] = { "ellisonleao/gruvbox.nvim", "gruvbox" },
  ["everforest"] = { "neanias/everforest-nvim", "everforest" },
  ["kanagawa"] = { "rebelot/kanagawa.nvim", "kanagawa" },
  ["kanagawa-dragon"] = { "rebelot/kanagawa.nvim", "kanagawa-dragon" },
  ["rose-pine"] = { "rose-pine/neovim", "rose-pine", "rose-pine" },
  ["rose-pine-moon"] = { "rose-pine/neovim", "rose-pine-moon", "rose-pine" },
  ["rose-pine-dawn"] = { "rose-pine/neovim", "rose-pine-dawn", "rose-pine" },
  ["monokai-pro"] = { "loctvl842/monokai-pro.nvim", "monokai-pro" },
  ["ayu"] = { "Shatur/neovim-ayu", "ayu-dark", "ayu" },
  ["solarized-osaka"] = { "craftzdog/solarized-osaka.nvim", "solarized-osaka" },
  ["nord"] = { "shaunsingh/nord.nvim", "nord" },
  ["onedark"] = { "navarasu/onedark.nvim", "onedark" },
}
M.names = {
  "tokyonight", "tokyonight-storm", "tokyonight-moon", "tokyonight-day",
  "catppuccin", "catppuccin-macchiato", "catppuccin-frappe", "catppuccin-latte",
  "vscode", "github-dark", "github-dimmed", "github-light", "dracula",
  "nightfox", "carbonfox", "duskfox", "dayfox", "gruvbox", "everforest",
  "kanagawa", "kanagawa-dragon", "rose-pine", "rose-pine-moon", "rose-pine-dawn",
  "monokai-pro", "ayu", "solarized-osaka", "nord", "onedark",
}

local function clear_backgrounds()
  -- nvim_set_hl REPLACES a group: keep the theme's foreground and attributes, drop only the background.
  for _, g in ipairs({ "Normal", "NormalNC", "NormalFloat", "SignColumn", "EndOfBuffer", "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeEndOfBuffer" }) do
    local cur = vim.api.nvim_get_hl(0, { name = g, link = false })
    cur.bg = nil; cur.ctermbg = nil; cur.default = nil
    cur.bg = "none"
    vim.api.nvim_set_hl(0, g, cur)
  end
end

-- Themes whose own variant is light. Everything else is dark: several plugins (gruvbox, kanagawa, everforest, catppuccin ...)
-- pick their variant from 'background', so it must be set explicitly or a dark theme would inherit the previous light one.
M.light = { ["tokyonight-day"] = true, ["catppuccin-latte"] = true, ["github-light"] = true, ["dayfox"] = true, ["rose-pine-dawn"] = true }

--- Apply a colorscheme (lazy.nvim loads the plugin on demand). Honors the transparent setting.
function M.apply(name)
  name = name or require("config").settings.colorscheme
  vim.o.background = M.light[name] and "light" or "dark"
  local t = M.themes[name] or M.themes.tokyonight
  if name == "solarized-osaka" then   -- this plugin is transparent unless told otherwise: follow the Settings page instead
    pcall(function()
      require("lazy").load({ plugins = { "solarized-osaka.nvim" } })
      require("solarized-osaka").setup({ transparent = require("config").settings.transparent == true })
    end)
  end
  local ok, err = pcall(vim.cmd.colorscheme, t[2])
  if not ok then vim.notify("Colorscheme failed: " .. tostring(err), vim.log.levels.ERROR) end
end

function M.setup_autocmd()
  vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("ide-theme", { clear = true }),
    callback = function()
      if require("config").settings.transparent then clear_backgrounds() end
      -- neo-tree derives its colours from Normal when it is set up; refresh them or the Explorer keeps the previous theme's background
      if package.loaded["neo-tree"] then pcall(function() require("neo-tree.ui.highlights").setup() end) end
      pcall(function() require("config.ui").setup_highlights() end)
      -- The Explorer takes the editor's background in every theme (some themes tint "sidebar" groups, which then outlive a theme switch)
      if not require("config").settings.transparent then
        for _, g in ipairs({ "NeoTreeNormal", "NeoTreeNormalNC", "NeoTreeEndOfBuffer" }) do vim.api.nvim_set_hl(0, g, { link = "Normal" }) end
      end
      pcall(function() require("config.statusline").apply() end) -- statusline colors follow the colorscheme
    end })
end

return M
