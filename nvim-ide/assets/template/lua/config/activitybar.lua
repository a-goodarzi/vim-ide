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
    open = function() require("config.scm").open_panel() end, close = function() require("config.scm").close_panel() end },
  { id = "debug", glyph = "\xef\x86\x88", ascii = "D", tip = "Run & Debug",
    open = function() pcall(require, "dap") --[[ loading nvim-dap runs dapui.setup ]]; local ok, d = pcall(require, "dapui"); if ok then d.open() else vim.notify("Debugger is disabled in Settings > Features", vim.log.levels.WARN) end end,
    close = function() local ok, d = pcall(require, "dapui"); if ok and package.loaded["dap"] then d.close() end end },
  { id = "outline", glyph = "\xef\x80\xba", ascii = "O", tip = "Outline",
    open = function() vim.cmd("AerialOpen! left") end, close = function() pcall(vim.cmd, "AerialClose") end },
  { id = "plugins", glyph = "\xef\x84\xae", ascii = "P", tip = "Plugins (lazy.nvim)",
    open = function() require("config.plugins_ui").open() end,
    close = function() end,
    -- Clicking the active Plugins icon again closes the page (the other views hide their sidebar the same way).
    toggle_off = function()
      for _, b in ipairs(vim.api.nvim_list_bufs()) do
        if vim.bo[b].filetype == "ide-plugins" then
          local ok, sn = pcall(require, "snacks")
          if ok and sn.bufdelete then sn.bufdelete(b) else pcall(vim.api.nvim_buf_delete, b, { force = true }) end
        end
      end
    end },
}
-- Features switched off in Settings leave no icon behind.
if not require("config").feature("debug") then
  for i = #views, 1, -1 do if views[i].id == "debug" then table.remove(views, i) end end
end
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
  local v = by_id[id]
  if not v then
    if id == "debug" then vim.notify("The debugger is switched off: Settings > Features > Debugger", vim.log.levels.INFO) end
    return
  end
  local keep = vim.api.nvim_get_current_win()
  if M.active and by_id[M.active] then pcall(by_id[M.active].close) end
  if M.active == id then
    if v.toggle_off then pcall(v.toggle_off) end
    M.active = nil; highlight(); return
  end
  M.active = id
  pcall(v.open)
  keep_leftmost(); M.fix_sidebar(id); highlight()
end

local widths = { explorer = 34, git = 38, search = 50, outline = 32, debug = 44 }
--- Give the sidebar next to the bar a fixed width, so opening/closing editors never reshuffles it.
function M.fix_sidebar(id)
  id = id or M.active
  local w = widths[id]; if not (w and bar_valid()) then return end
  local fts = { explorer = { "neo-tree" }, git = { "idescm" }, search = { "grug-far" }, outline = { "aerial" },
    debug = { "dapui_scopes", "dapui_breakpoints", "dapui_stacks", "dapui_watches" } }
  for _, win in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(win).relative == "" and vim.tbl_contains(fts[id], vim.bo[vim.api.nvim_win_get_buf(win)].filetype) then
      require("config.ui").setwo(win, { winfixwidth = true }); pcall(vim.api.nvim_win_set_width, win, w)
    end
  end
  if bar_valid() then pcall(vim.api.nvim_win_set_width, M.win, 4) end
end
M.relayout = function() M.fix_sidebar() end

local ft_view = { ["neo-tree"] = "explorer", ["grug-far"] = "search", aerial = "outline", dapui_scopes = "debug", idescm = "git" }
function M.sync()
  if not bar_valid() then return end
  -- Only one sidebar view at a time, whichever path opened it (<leader>e, :Neotree, :AerialToggle ...): the newest
  -- window wins and the others are closed, instead of stacking sidebars side by side.
  local open_views, newest, newest_view = {}, -1, nil
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local v = ft_view[vim.bo[vim.api.nvim_win_get_buf(w)].filetype]
      if v then open_views[v] = true; if w > newest then newest, newest_view = w, v end end
    end
  end
  for v in pairs(open_views) do
    if v ~= newest_view then pcall(by_id[v].close) end
  end
  local found
  for _, w in ipairs(vim.api.nvim_list_wins()) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local v = ft_view[vim.bo[vim.api.nvim_win_get_buf(w)].filetype]
      if v then found = v; break end
    end
  end
  if found then M.active = found
  elseif M.active == "plugins" then
    local shown = false      -- the Plugins page is not a sidebar: it is "active" only while a window shows it
    for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "ide-plugins" then shown = true end end
    if not shown then M.active = nil end
  elseif M.active then M.active = nil end
  if vim.api.nvim_win_get_position(M.win)[2] ~= 0 then keep_leftmost() end
  if M.active then M.fix_sidebar(); vim.defer_fn(function() if M.active then M.fix_sidebar() end end, 80) -- aerial sizes itself late
  else pcall(vim.api.nvim_win_set_width, M.win, 4) end
  -- Focus must never rest on the (non-editable) bar, e.g. after the sidebar it sat beside was closed.
  if vim.api.nvim_get_current_win() == M.win then
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local b = vim.api.nvim_win_get_buf(w)
      if w ~= M.win and vim.api.nvim_win_get_config(w).relative == "" and vim.bo[b].buftype == "" then vim.api.nvim_set_current_win(w) break end
    end
  end
  highlight()
end

--- Open a Search & Replace panel (word / selection / file variants): replace an existing panel instead of stacking a second.
function M.open_search(open_fn)
  pcall(by_id.search.close)
  open_fn()
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
    list = false, wrap = false, statusline = " ", winhighlight = "Normal:IDEActivityBar,EndOfBuffer:IDEActivityBar" }) do require("config.ui").setwo(M.win, { [k] = v }) end
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
  -- Sidebars can also be opened/closed by other keys (<leader>e, :Neotree, :AerialToggle ...). Re-sync the highlighted
  -- icon with what is really open and keep the bar leftmost, so no path leaves the bar stale or in the middle.
  vim.api.nvim_create_autocmd({ "WinClosed", "WinNew" }, { callback = function() vim.schedule(M.sync) end })
  vim.api.nvim_create_autocmd("FileType", { pattern = { "neo-tree", "grug-far", "aerial", "dapui_scopes", "idescm" },
    callback = function() vim.schedule(M.sync) end })
  -- Window navigation (Ctrl-h/j/k/l, Alt-h/j/k/l, :wincmd) can land on the bar; it is not editable, so step to the window
  -- on its right (the sidebar or the editor) instead.
  vim.api.nvim_create_autocmd("WinEnter", { callback = function()
    if vim.api.nvim_get_current_win() ~= M.win then return end
    vim.schedule(function()
      if not (bar_valid() and vim.api.nvim_get_current_win() == M.win) then return end
      vim.cmd("wincmd l")
      if vim.api.nvim_get_current_win() == M.win then
        for _, w in ipairs(vim.api.nvim_list_wins()) do
          if w ~= M.win and vim.api.nvim_win_get_config(w).relative == "" then vim.api.nvim_set_current_win(w) break end
        end
      end
    end)
  end })
  local cfg = require("config")
  if cfg.feature("explorer_on_start") then vim.schedule(function() M.show("explorer") end) end
end

M.views = views
return M
