-- VS Code-style activity bar: a narrow icon column at the far left that switches the sidebar view.
--   Explorer · Search & Replace · Source Control · Run & Debug · Outline · Plugins
-- Click an icon (or Enter on it, or <A-e> <A-f> <A-g> <A-d> <A-o> <A-x>); click the active one again to hide the sidebar.
local M = {}
M.active, M.win, M.buf = nil, nil, nil
local ns = vim.api.nvim_create_namespace("ide-activity")

local icons = function() return require("config").icons() end
local function closer(ft) return function()
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft and #vim.api.nvim_list_wins() > 1 then pcall(vim.api.nvim_win_close, w, true) end
  end
end end

local views = {
  { id = "explorer", glyph = "\xef\x85\x9b", ascii = "E", tip = "Explorer",
    open = function() vim.cmd("Neotree show filesystem left") end, close = function() pcall(vim.cmd, "Neotree close") end },
  { id = "search", glyph = "\xef\x80\x82", ascii = "S", tip = "Search & Replace",
    open = function() require("grug-far").open({ windowCreationCommand = "topleft 50vsplit", transient = true }) end, close = closer("grug-far") },
  { id = "git", glyph = "\xee\x9c\xa5", ascii = "G", tip = "Source Control",
    open = function() vim.cmd("Neotree show git_status left") end, close = function() pcall(vim.cmd, "Neotree close") end },
  { id = "debug", glyph = "\xef\x86\x88", ascii = "D", tip = "Run & Debug",
    open = function() local ok, d = pcall(require, "dapui"); if ok then d.open() else vim.notify("Debugger is disabled in Settings > Features", vim.log.levels.WARN) end end,
    close = function() local ok, d = pcall(require, "dapui"); if ok then d.close() end end },
  { id = "outline", glyph = "\xef\x80\xba", ascii = "O", tip = "Outline",
    open = function() vim.cmd("AerialOpen! left") end, close = function() pcall(vim.cmd, "AerialClose") end },
  { id = "plugins", glyph = "\xef\x84\xae", ascii = "P", tip = "Plugins (lazy.nvim)",
    open = function() require("config.plugins_ui").open() end,
    close = function() local ui = require("config.plugins_ui"); end },
}
local by_id = {}
for _, v in ipairs(views) do by_id[v.id] = v end

local function bar_valid() return M.win and vim.api.nvim_win_is_valid(M.win) end

local function highlight()
  if not (M.buf and vim.api.nvim_buf_is_valid(M.buf)) then return end
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
  for i, v in ipairs(views) do
    local line = (i - 1) * 3 + 1                      -- 0-based row of the icon line
    if M.active == v.id then
      vim.api.nvim_buf_add_highlight(M.buf, ns, "IDEActivityActive", line, 0, -1)
      vim.api.nvim_buf_set_extmark(M.buf, ns, line, 0, { virt_text = { { "\xe2\x96\x8e", "IDEActivityMark" } }, virt_text_pos = "overlay" })
    else vim.api.nvim_buf_add_highlight(M.buf, ns, "IDEActivityIcon", line, 0, -1) end
  end
end

local function keep_leftmost()
  if not bar_valid() then return end
  local cur = vim.api.nvim_get_current_win()
  vim.api.nvim_set_current_win(M.win); vim.cmd("wincmd H"); vim.cmd("vertical resize 4")
  if vim.api.nvim_win_is_valid(cur) then vim.api.nvim_set_current_win(cur) end
end

--- Show a view (hides the current one). Clicking the active view hides the sidebar.
function M.show(id)
  local v = by_id[id]; if not v then return end
  local keep = vim.api.nvim_get_current_win()
  if M.active and by_id[M.active] then pcall(by_id[M.active].close) end
  if M.active == id then M.active = nil; highlight(); return end
  M.active = id
  pcall(v.open)
  keep_leftmost(); highlight()
end

--- Hide the sidebar / show the Explorer (VS Code: Ctrl+B).
function M.toggle() if M.active then M.show(M.active) else M.show("explorer") end end

local function set_hl()
  vim.api.nvim_set_hl(0, "IDEActivityBar", { link = "NormalFloat", default = true })
  vim.api.nvim_set_hl(0, "IDEActivityIcon", { link = "Comment", default = true })
  vim.api.nvim_set_hl(0, "IDEActivityActive", { link = "Normal", default = true, bold = true })
  vim.api.nvim_set_hl(0, "IDEActivityMark", { link = "DiagnosticInfo", default = true })
end

local function build()
  local lines = {}
  for _, v in ipairs(views) do
    lines[#lines + 1] = ""; lines[#lines + 1] = "  " .. (icons() and v.glyph or v.ascii); lines[#lines + 1] = ""
  end
  vim.bo[M.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.bo[M.buf].modifiable = false
end

local function view_at(row) return views[math.floor((row - 1) / 3) + 1] end

function M.setup()
  if bar_valid() then return end
  set_hl()
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("topleft 4vnew")
  M.win, M.buf = vim.api.nvim_get_current_win(), vim.api.nvim_get_current_buf()
  vim.bo[M.buf].buftype = "nofile"; vim.bo[M.buf].bufhidden = "wipe"; vim.bo[M.buf].swapfile = false
  vim.bo[M.buf].buflisted = false; vim.bo[M.buf].filetype = "ide-activity"
  for k, v in pairs({ number = false, relativenumber = false, signcolumn = "no", cursorline = false, winfixwidth = true,
    list = false, wrap = false, statusline = " ", winhighlight = "Normal:IDEActivityBar,EndOfBuffer:IDEActivityBar" }) do vim.wo[M.win][k] = v end
  build(); highlight()
  local k = function(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = M.buf, nowait = true, silent = true }) end
  k("<LeftMouse>", function()
    local m = vim.fn.getmousepos(); if m.winid ~= M.win or not m.line then return end
    local v = view_at(m.line); if v then M.show(v.id) end
  end)
  k("<CR>", function() local v = view_at(vim.api.nvim_win_get_cursor(M.win)[1]); if v then M.show(v.id) end end)
  -- A buffer-local <LeftMouse> only works once the bar is focused, so also hook the global click handler.
  require("config.ui").install_click_handler()
  table.insert(require("config.ui").hooks, function(m)
    if M.win and m.winid == M.win and m.line and m.line >= 1 then
      local v = view_at(m.line); if v then vim.schedule(function() M.show(v.id) end) end
      return true
    end
  end)
  if cur and vim.api.nvim_win_is_valid(cur) then vim.api.nvim_set_current_win(cur) end
  vim.api.nvim_create_autocmd("ColorScheme", { callback = function() set_hl(); highlight() end })

  local cfg = require("config")
  if cfg.feature("explorer_on_start") then vim.schedule(function() M.show("explorer") end) end
end

M.views = views
return M
