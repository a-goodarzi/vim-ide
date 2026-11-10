-- Clickable buttons pinned to the top-right corner (tiny floating windows):  Claude Code · Terminal · Settings · Help
-- Click them, or use <leader>ac / <leader>us. Remove the require in autocmds.lua to disable.
local M = {}
local group = vim.api.nvim_create_augroup("ide-button", { clear = true })

local icons = function() return require("config").icons() end

-- offset = columns from the right edge to the button's left edge
local buttons = {
  { id = "claude", offset = 12, hl = "IDEClaudeButton",
    label = function() return icons() and " \xef\x81\xa9 " or "[C]" end,       -- nf-fa-asterisk (the Claude Code asterisk, a font glyph)
    enabled = function() return require("config").feature("claude") end,
    action = function() vim.cmd("ClaudeCode") end },
  { id = "terminal", offset = 9, hl = "IDESettingsButton",
    label = function() return icons() and " \xef\x84\xa0 " or "[T]" end,       -- nf-fa-terminal
    enabled = function() return require("config").feature("terminal") end,
    action = function() require("lazy").load({ plugins = { "toggleterm.nvim" } }); vim.cmd("ToggleTerm direction=horizontal") end },
  { id = "settings", offset = 6, hl = "IDESettingsButton",
    label = function() return icons() and " \xef\x80\x93 " or "[S]" end,       -- nf-fa-cog
    enabled = function() return true end,
    action = function() require("config.settings_ui").open() end },
  { id = "help", offset = 3, hl = "IDESettingsButton",
    label = function() return icons() and " \xef\x81\x99 " or "[?]" end,       -- nf-fa-question_circle
    enabled = function() return true end,
    action = function() require("config.help").open() end },
}

local function set_highlights()
  local base = vim.api.nvim_get_hl(0, { name = "TabLineSel", link = false })
  vim.api.nvim_set_hl(0, "IDESettingsButton", { link = "TabLineSel", default = true })
  vim.api.nvim_set_hl(0, "IDEClaudeButton", { fg = require("config.ui").brand.claude, bg = base.bg, bold = true }) -- Claude orange
end

local function place(b)
  if b.win and vim.api.nvim_win_is_valid(b.win) then
    vim.api.nvim_win_set_config(b.win, { relative = "editor", row = 0, col = math.max(vim.o.columns - b.offset, 0) })
  end
end

local function create(b)
  if b.win and vim.api.nvim_win_is_valid(b.win) then return end
  local buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, { b.label() })
  vim.bo[buf].modifiable = false; vim.bo[buf].bufhidden = "wipe"
  b.win = vim.api.nvim_open_win(buf, false, { relative = "editor", row = 0, col = math.max(vim.o.columns - b.offset, 0),
    width = 3, height = 1, style = "minimal", border = "none", focusable = true, zindex = 60, noautocmd = true })
  vim.wo[b.win].winhighlight = "Normal:" .. b.hl
end

function M.show()
  set_highlights()
  for _, b in ipairs(buttons) do if b.enabled() then create(b) end end

  -- Clicks on a button run its action (shared global click handler, see config/ui.lua).
  local ui = require("config.ui")
  ui.install_click_handler()
  table.insert(ui.hooks, function(m)
    for _, b in ipairs(buttons) do
      if b.win and m.winid == b.win then vim.schedule(function() pcall(b.action) end); return true end
    end
  end)

  vim.api.nvim_create_autocmd({ "VimResized", "WinNew", "WinClosed" }, { group = group, callback = function()
    vim.schedule(function() for _, b in ipairs(buttons) do place(b) end end)
  end })
  vim.api.nvim_create_autocmd("ColorScheme", { group = group, callback = set_highlights })
end

return M
