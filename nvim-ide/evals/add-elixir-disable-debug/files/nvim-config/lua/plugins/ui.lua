local cfg = require("config")
local s = cfg.settings

local themes = {
  tokyonight = { "folke/tokyonight.nvim", "tokyonight" },
  catppuccin = { "catppuccin/nvim", "catppuccin", name = "catppuccin" },
  gruvbox = { "ellisonleao/gruvbox.nvim", "gruvbox" },
  kanagawa = { "rebelot/kanagawa.nvim", "kanagawa" },
  ["rose-pine"] = { "rose-pine/neovim", "rose-pine", name = "rose-pine" },
  nord = { "shaunsingh/nord.nvim", "nord" },
  onedark = { "navarasu/onedark.nvim", "onedark" },
}
local t = themes[s.colorscheme] or themes.tokyonight

local icons = cfg.icons()

return {
  { t[1], name = t.name, lazy = false, priority = 1000, config = function()
    if s.transparent then
      vim.api.nvim_create_autocmd("ColorScheme", { callback = function()
        for _, g in ipairs({ "Normal", "NormalFloat", "SignColumn" }) do vim.api.nvim_set_hl(0, g, { bg = "none" }) end
      end })
    end
    vim.cmd.colorscheme(t[2])
  end },

  { "nvim-lualine/lualine.nvim", event = "VeryLazy",
    dependencies = icons and { "nvim-tree/nvim-web-devicons" } or {},
    opts = { options = { globalstatus = true, icons_enabled = icons } } },

  { "folke/which-key.nvim", event = "VeryLazy", opts = {
    icons = { mappings = icons },
    spec = {
      { "<leader>f", group = "find" }, { "<leader>g", group = "git" }, { "<leader>c", group = "code" },
      { "<leader>d", group = "debug" }, { "<leader>t", group = "test/terminal" }, { "<leader>b", group = "buffer" },
      { "<leader>x", group = "diagnostics" }, { "<leader>u", group = "ui" },
    } } },

  { "nvim-tree/nvim-web-devicons", enabled = icons, lazy = true },

  { "lukas-reineke/indent-blankline.nvim", main = "ibl", event = "BufReadPost", opts = { scope = { enabled = false } } },

}
