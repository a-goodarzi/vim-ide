local group = vim.api.nvim_create_augroup("ide", { clear = true })
local au = function(ev, opts) opts.group = group; vim.api.nvim_create_autocmd(ev, opts) end

au("TextYankPost", { callback = function() vim.hl.on_yank() end })

-- Reopen at last cursor position
au("BufReadPost", {
  callback = function(a)
    local m = vim.api.nvim_buf_get_mark(a.buf, '"')
    if m[1] > 0 and m[1] <= vim.api.nvim_buf_line_count(a.buf) then pcall(vim.api.nvim_win_set_cursor, 0, m) end
  end,
})

-- Reload files changed outside nvim
au({ "FocusGained", "BufEnter" }, { command = "checktime" })

-- Wrap + spell for prose
au("FileType", { pattern = { "markdown", "gitcommit", "text" }, callback = function()
  vim.opt_local.wrap = true; vim.opt_local.spell = true
end })

-- Per-language indentation (Go/C/Rust/Python conventions)
au("FileType", { pattern = { "go" }, callback = function() vim.opt_local.expandtab = false; vim.opt_local.tabstop = 4; vim.opt_local.shiftwidth = 4 end })
au("FileType", { pattern = { "python", "rust", "c", "cpp", "java" }, callback = function() vim.opt_local.shiftwidth = 4; vim.opt_local.tabstop = 4 end })

-- File browser sidebar at startup (settings: features.explorer_on_start)
local standalone = vim.env.IDE_SETTINGS_ONLY ~= nil -- `ide settings` / `ide help`: no sidebar, no panel
if require("config").feature("activity_bar") and not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.schedule(function() require("config.activitybar").setup() end)
  end })
elseif require("config").feature("explorer_on_start") and not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.schedule(function() pcall(vim.cmd, "Neotree show") end)
  end })
end

-- Claude panel at startup (settings: claude.autostart, or launch with `ide claude`)
local c = require("config").settings.claude or {}
if c.autostart and require("config").feature("claude") and not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.defer_fn(function() pcall(vim.cmd, "ClaudeCode") end, 200)
  end })
end

-- Clickable settings (gear) button, top-right corner
if not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.schedule(function() require("config.ui_button").show() end)
  end })
end

-- Statusline (config/statusline.lua)
vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
  vim.schedule(function() require("config.statusline").setup() end)
end })
