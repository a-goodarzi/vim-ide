local cfg = require("config")
local s = cfg.settings
local icons = cfg.icons()

local theme = require("config.theme")

local function dashboard_keys()
  local i = function(glyph, fallback) return icons and glyph or fallback end
  return {
    { icon = i("\xef\x80\x82 ", ""), key = "f", desc = "Find file", action = ":Telescope find_files" },
    { icon = i("\xef\x85\x9b ", ""), key = "n", desc = "New file", action = ":enew" },
    { icon = i("\xef\x80\xa2 ", ""), key = "g", desc = "Grep text", action = ":Telescope live_grep" },
    { icon = i("\xef\x83\x85 ", ""), key = "r", desc = "Recent files", action = ":Telescope oldfiles" },
    { icon = i("\xef\x81\xbb ", ""), key = "o", desc = "Recent projects", action = ":IDEProjects", enabled = cfg.feature("session_restore") },
    { icon = i("\xef\x81\xa9 ", ""), key = "c", desc = "Claude Code", action = ":ClaudeCode", enabled = cfg.feature("claude") },
    { icon = i("\xef\x90\xa3 ", ""), key = "s", desc = "Settings page", action = ":IDESettings" },
    { icon = i("\xef\x84\x9c ", ""), key = "?", desc = "Commands & shortcuts", action = ":IDEHelp" },
    { icon = i("\xef\x92\x87 ", ""), key = "p", desc = "Plugins (lazy.nvim)", action = function() require("config.plugins_ui").open() end },
    { icon = i("\xef\x80\x8d ", ""), key = "q", desc = "Quit", action = ":qa" },
  }
end

-- Every theme plugin is registered lazily (one spec per repo, shared by its variants) so the Settings page can
-- switch live; only the chosen theme's plugin loads at startup.
local theme_specs, seen = {}, {}
local chosen_repo = (theme.themes[s.colorscheme] or theme.themes.tokyonight)[1]
for _, n in ipairs(theme.names) do
  local th = theme.themes[n]
  if not seen[th[1]] then
    seen[th[1]] = true
    local is_chosen = th[1] == chosen_repo
    theme_specs[#theme_specs + 1] = { th[1], name = th[3], lazy = not is_chosen, priority = 1000,
      config = is_chosen and function() theme.setup_autocmd(); theme.apply(s.colorscheme) end or nil }
  end
end

return vim.list_extend(theme_specs, {
  -- Tabs are drawn by config/tabs.lua (self-written tab bar, no plugin).

  -- Welcome screen, notifications, terminal helper (also required by claudecode.nvim)
  { "folke/snacks.nvim", priority = 1000, lazy = false, opts = {
    dashboard = { enabled = cfg.feature("dashboard"), preset = { keys = dashboard_keys(),
      header = "  N V I M   I D E  " },
      sections = { { section = "header" }, { section = "keys", gap = 1, padding = 1 }, { section = "startup" } } },
    notifier = { enabled = true }, styles = { notification = { wo = { wrap = true } } }, -- long messages wrap instead of being cut
    terminal = { enabled = true }, input = { enabled = true },
  } },

  { "folke/which-key.nvim", event = "VeryLazy", opts = {
    preset = "modern", icons = { mappings = icons }, win = { border = "rounded", title = true, title_pos = "center" },
    spec = {
      { "<leader>f", group = "find" }, { "<leader>g", group = "git" }, { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" }, { "<leader>t", group = "test/terminal" }, { "<leader>b", group = "buffers/tabs" },
      { "<leader>x", group = "diagnostics" }, { "<leader>u", group = "ui/settings" },
      { "<leader>a", group = "Claude Code" }, { "<leader>p", group = "plugins" }, { "<leader><tab>", group = "tab pages" },
    } } },

  { "nvim-tree/nvim-web-devicons", enabled = icons, lazy = true },
  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = "BufReadPost", opts = { scope = { enabled = false } } },
})
