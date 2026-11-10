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

-- First-run welcome (once, after the layout is up)
if not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.defer_fn(function() pcall(function() require("config.welcome").maybe_show() end) end, 700)
  end })
end
-- Commands that live in lazily loaded modules
vim.api.nvim_create_user_command("IDEDoctor", function() require("config.doctor").open() end, { desc = "Check the tools the IDE needs" })
vim.api.nvim_create_user_command("IDEWelcome", function() require("config.welcome").open() end, { desc = "Open the welcome / first-run check" })

-- Session restore + recent projects. Commands of lazily loaded modules get a stub: the first call loads the module (which
-- redefines the command) and repeats it.
local function lazycmd(name, mod, nargs)
  vim.api.nvim_create_user_command(name, function(o) require(mod); vim.cmd(name .. " " .. o.args) end, { nargs = nargs or 0 })
end
for _, n in ipairs({ "IDESessionSave", "IDESessionRestore", "IDEProjects" }) do lazycmd(n, "config.session") end
if require("config").feature("session_restore") and not standalone then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function() require("config.session").setup() end })
end

-- Split layouts
lazycmd("IDELayoutSave", "config.layout", "?"); lazycmd("IDELayoutLoad", "config.layout", "?")

-- Task runner
lazycmd("IDETasks", "config.tasks"); lazycmd("IDETaskLast", "config.tasks")

-- Remote and containers
lazycmd("IDERemote", "config.remote"); lazycmd("IDEContainers", "config.remote")

-- Snippets browser
lazycmd("IDESnippets", "config.assist")

-- Statusline (config/statusline.lua)
vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
  vim.schedule(function() require("config.statusline").setup() end)
end })

-- Closing the last editor window must quit, not leave a sidebar (Explorer, activity bar, outline...) stretched
-- across the whole screen.
local sidebar_ft = { ["neo-tree"] = true, ["ide-activity"] = true, idescm = true, aerial = true, ["grug-far"] = true, trouble = true,
  ["dapui_scopes"] = true, ["dapui_breakpoints"] = true, ["dapui_stacks"] = true, ["dapui_watches"] = true,
  ["dapui_console"] = true, ["dap-repl"] = true, qf = true, help = false }
local page_ft = { ["ide-settings"] = true, ["ide-help"] = true, ["ide-plugins"] = true }
--- Re-create the editor column beside the sidebars, showing the most recently used buffer instead of an empty one.
local function restore_editor()
  pcall(vim.cmd, "botright vnew")
  local win, empty = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  local best
  for _, i in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if i.bufnr ~= empty and i.hidden == 1 and vim.bo[i.bufnr].buftype ~= "terminal" and (not best or i.lastused > best.lastused) then best = i end
  end
  if best then
    pcall(vim.api.nvim_win_set_buf, win, best.bufnr)
    if vim.api.nvim_buf_is_valid(empty) and vim.api.nvim_buf_get_name(empty) == "" then pcall(vim.api.nvim_buf_delete, empty, { force = true }) end
  end
  pcall(function() require("config.activitybar").relayout() end)
end
local quitting = false
vim.api.nvim_create_autocmd("QuitPre", { group = group, callback = function()
  local was_page = page_ft[vim.bo.filetype]
  quitting = true
  vim.schedule(function()
    quitting = false
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local cfg = vim.api.nvim_win_get_config(w)
      local b = vim.api.nvim_win_get_buf(w)
      if cfg.relative == "" and not sidebar_ft[vim.bo[b].filetype] and vim.bo[b].buftype ~= "terminal" then return end
    end
    -- Closing a Settings/Help/Plugins tab must not quit the IDE: leave an empty editor beside the sidebar instead.
    if was_page then
      restore_editor()
    else pcall(vim.cmd, "qa") end
  end)
end })

-- :bd / :bw on the only editor buffer closes its window (every other window still exists), which would leave the
-- sidebars stretched across the screen. Keep an empty editor beside them, like the page-close path above.
vim.api.nvim_create_autocmd("WinClosed", { group = group, callback = function(a)
  local closed = tonumber(a.match)
  if quitting or vim.v.exiting ~= vim.NIL or not (closed and vim.api.nvim_win_is_valid(closed))
    or vim.api.nvim_win_get_config(closed).relative ~= "" or sidebar_ft[vim.bo[vim.api.nvim_win_get_buf(closed)].filetype] then return end
  vim.schedule(function()
    local side = false
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local b = vim.api.nvim_win_get_buf(w)
      if vim.api.nvim_win_get_config(w).relative == "" then
        if vim.bo[b].buftype == "terminal" or not sidebar_ft[vim.bo[b].filetype] then return end
        if vim.bo[b].filetype == "neo-tree" or vim.bo[b].filetype == "ide-activity" then side = true end
      end
    end
    if side then restore_editor() end
  end)
end })

-- Tab bar (config/tabs.lua)
if require("config").feature("tabs") then
  vim.api.nvim_create_autocmd("VimEnter", { group = group, once = true, callback = function()
    vim.schedule(function() require("config.tabs").setup() end)
  end })
end
