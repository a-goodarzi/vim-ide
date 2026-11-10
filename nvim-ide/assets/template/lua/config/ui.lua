-- Shared UI kit: design tokens + the "page" framework every full-screen view is built on
-- (Settings, Help, Plugins). One place for borders, glyphs, highlight roles, click handling and page lifecycle,
-- so all screens look and behave the same. See the nvim-tui-ux skill for the design rules behind it.
local M = {}

-- ── tokens ─────────────────────────────────────────────────────────────────────────────────────────
M.border = "rounded"
M.brand = { claude = "#d97757" }   -- the only place raw brand colors live
M.RULE, M.THICK = "\xe2\x94\x80", "\xe2\x95\x90"   -- ─ ═

--- Glyph with an ASCII fallback (used when features.icons = false / no Nerd Font).
local glyphs = {
  gear = { "\xef\x80\x93 ", "* " },
  on = { "\xef\x85\x8a ", "[x] " }, off = { "\xef\x82\x96 ", "[ ] " },           -- check-square / square
  search = { "\xef\x80\x82 ", "/ " }, changed = { "\xe2\x97\x8f ", "* " },       -- ● changed
  restart = { "\xe2\x86\xbb", "(r)" }, bar = { "\xe2\x96\x8e", "|" },            -- ↻ / ▎
  chev_l = { "\xe2\x80\xb9 ", "< " }, chev_r = { " \xe2\x80\xba", " >" },        -- ‹ ›
  bullet = { "\xe2\x80\xa2 ", "- " }, loaded = { "\xe2\x97\x8f", "*" }, idle = { "\xe2\x97\x8b", "o" },
}
--- Are Nerd Font glyphs allowed? The kit has no hard dependency on this project's `config` module:
--- it asks `require("config").icons()` when that exists, else honors `vim.g.ide_icons` (set false for ASCII).
function M.icons()
  local ok, c = pcall(require, "config")
  if ok and type(c) == "table" and c.icons then return c.icons() end
  return vim.g.ide_icons ~= false
end
function M.g(name)
  local pair = glyphs[name]
  if not pair then return "" end
  return M.icons() and pair[1] or pair[2]
end

--- Highlight roles. Every screen uses these names, never raw colors; they follow the colorscheme.
local roles = {
  IDEHeading = "Title", IDERule = "FloatBorder", IDEMuted = "Comment", IDEKey = "String", IDEAccent = "Function",
  IDEOn = "DiagnosticOk", IDEWarn = "DiagnosticWarn", IDEInfo = "DiagnosticInfo", IDEBar = "DiagnosticInfo",
}
-- Third-party widgets follow the same roles, so a Telescope picker looks like a Settings headline.
local widgets = {
  TelescopeBorder = "IDERule", TelescopePromptBorder = "IDERule", TelescopeResultsBorder = "IDERule", TelescopePreviewBorder = "IDERule",
  TelescopePromptTitle = "IDEHeading", TelescopeResultsTitle = "IDEHeading", TelescopePreviewTitle = "IDEHeading",
  TelescopeSelectionCaret = "IDEBar", TelescopeMatching = "IDEKey", TelescopePromptPrefix = "IDEAccent",
  LazyH1 = "IDEHeading", WhichKeyTitle = "IDEHeading", WhichKeyBorder = "IDERule", BlinkCmpMenuBorder = "IDERule",
  BlinkCmpDocBorder = "IDERule", BlinkCmpSignatureHelpBorder = "IDERule",
  -- Search & Replace sidebar (grug-far)
  GrugFarInputLabel = "IDEHeading", GrugFarInputPlaceholder = "IDEMuted", GrugFarHelpHeader = "IDEMuted",
  GrugFarHelpHeaderKey = "IDEKey", GrugFarHelpWinHeader = "IDEHeading", GrugFarHelpWinActionPrefix = "IDEHeading",
  GrugFarHelpWinActionKey = "IDEKey", GrugFarResultsHeader = "IDEMuted", GrugFarResultsStats = "IDEMuted",
  GrugFarResultsPath = "IDEAccent", GrugFarResultsCmdHeader = "IDEMuted", GrugFarResultsNumberLabel = "IDEKey",
  GrugFarResultsMatch = "IncSearch", GrugFarResultsMatchAdded = "DiffAdd", GrugFarResultsMatchRemoved = "DiffDelete",
  GrugFarResultsChangeIndicator = "DiagnosticWarn", GrugFarResultsRemoveIndicator = "DiagnosticError",
  GrugFarResultsAddIndicator = "DiagnosticOk", GrugFarResultsActionMessage = "IDEOn",
}
function M.setup_highlights()
  for name, link in pairs(roles) do vim.api.nvim_set_hl(0, name, { link = link, default = true }) end
  for name, link in pairs(widgets) do vim.api.nvim_set_hl(0, name, { link = link }) end
end
vim.api.nvim_create_autocmd("ColorScheme", { group = vim.api.nvim_create_augroup("ide-ui-hl", { clear = true }), callback = M.setup_highlights })
M.setup_highlights()

function M.pad(s, w)
  local sw = vim.fn.strdisplaywidth(s)
  if sw > w then s = vim.fn.strcharpart(s, 0, math.max(w - 1, 0)) .. "\xe2\x80\xa6"; sw = vim.fn.strdisplaywidth(s) end
  return s .. string.rep(" ", math.max(w - sw, 0))
end

-- ── click hooks ────────────────────────────────────────────────────────────────────────────────────
-- A buffer-local <LeftMouse> map only fires in the focused window, so clicks on UI the cursor is not in
-- (activity bar, top-right buttons, a settings tab in another split) go through ONE global handler.
M.hooks = {}   -- function(mousepos) -> true when the click was handled
function M.install_click_handler()
  if M._installed then return end
  M._installed = true
  vim.keymap.set({ "n", "i", "v" }, "<LeftMouse>", function()
    local m = vim.fn.getmousepos()
    for _, h in ipairs(M.hooks) do
      local ok, handled = pcall(h, m)
      if ok and handled then return "" end
    end
    return "<LeftMouse>"
  end, { expr = true, desc = "Click (IDE UI aware)" })
end

-- ── context menu ───────────────────────────────────────────────────────────────────────────────────
--- Small floating menu at the mouse (or the cursor). items = { { "Label", fn }, ..., "-" = separator }.
--- j/k and Enter or a click choose; Esc, q, a right-click or a click elsewhere closes it.
function M.menu(items, opts)
  opts = opts or {}
  local rows, lines, w = {}, {}, 0
  for _, it in ipairs(items) do
    if it == "-" then rows[#rows + 1] = false else rows[#rows + 1] = it end
  end
  for _, r in ipairs(rows) do
    lines[#lines + 1] = r and ("  " .. r[1] .. "  ") or ""
    w = math.max(w, vim.fn.strdisplaywidth(lines[#lines]))
  end
  for i, r in ipairs(rows) do if not r then lines[i] = string.rep(M.RULE, w) end end
  local m = vim.fn.getmousepos()
  local b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].bufhidden = "wipe"
  local row = opts.row or math.max(0, math.min((m.screenrow or 2), vim.o.lines - #lines - 3))
  local col = opts.col or math.max(0, math.min((m.screencol or 1) - 1, vim.o.columns - w - 2))
  local win = vim.api.nvim_open_win(b, true, { relative = "editor", row = row, col = col, width = w, height = #lines,
    style = "minimal", border = M.border, zindex = 80 })
  M.setwo(win, { cursorline = true, winhighlight = "FloatBorder:IDERule,CursorLine:Visual" })
  for i, r in ipairs(rows) do if not r then vim.api.nvim_buf_add_highlight(b, -1, "IDERule", i - 1, 0, -1) end end
  local function first() for i, r in ipairs(rows) do if r then return i end end end
  pcall(vim.api.nvim_win_set_cursor, win, { first() or 1, 0 })
  local function close() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_win_close(win, true) end end
  local function run(i) local it = rows[i]; close(); if it then vim.schedule(it[2]) end end
  local function step(d)
    local i = vim.api.nvim_win_get_cursor(win)[1]
    repeat i = i + d until rows[i] or i < 1 or i > #rows
    if rows[i] then vim.api.nvim_win_set_cursor(win, { i, 0 }) end
  end
  local k = function(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = b, nowait = true, silent = true }) end
  k("<CR>", function() run(vim.api.nvim_win_get_cursor(win)[1]) end)
  k("j", function() step(1) end); k("k", function() step(-1) end); k("<Down>", function() step(1) end); k("<Up>", function() step(-1) end)
  k("<Esc>", close); k("q", close); k("<RightMouse>", close)
  k("<LeftMouse>", function()
    local p = vim.fn.getmousepos()
    if p.winid == win then run(p.line) else close() end
  end)
  vim.api.nvim_create_autocmd("WinLeave", { buffer = b, once = true, callback = close })
  return win
end

-- ── document builder ───────────────────────────────────────────────────────────────────────────────
local Builder = {}; Builder.__index = Builder
function M.builder(width)
  return setmetatable({ lines = {}, hls = {}, meta = {}, width = width, margin = "   ", heads = {}, jumps = {} }, Builder)
end
function Builder:add(text, hl, meta)
  self.lines[#self.lines + 1] = text
  if hl then self.hls[#self.hls + 1] = { #self.lines, hl } end
  self.meta[#self.lines] = meta
  return #self.lines
end
function Builder:blank() return self:add("") end
function Builder:rule(thick) return self:add(self.margin .. string.rep(thick and M.THICK or M.RULE, self.width), "IDERule") end
function Builder:title(text, sub)
  self:add(self.margin .. text, "IDEHeading")
  if sub then self:add(self.margin .. sub, "IDEMuted") end
  self:blank()
end
--- Section headline: blank, text, thick rule, blank. `id` lets number keys / jump bar find it.
function Builder:head(text, id)
  self:blank()
  self.heads[#self.heads + 1] = { line = #self.lines + 1, id = id }
  self:add(self.margin .. text, "IDEHeading", { head = id })
  self:rule(true); self:blank()
end
--- Clickable jump bar of "1 Name   2 Name ..." entries.
function Builder:jumpbar(names)
  local bar, col = self.margin, #self.margin
  self.jumps = {}
  for i, name in ipairs(names) do
    local label = i .. " " .. name
    self.jumps[#self.jumps + 1] = { from = col, to = col + #label, id = i }
    bar = bar .. label .. "   "; col = col + #label + 3
  end
  self:add(bar, "Directory", { jumpbar = true })
  self:rule()
end

-- ── page framework ─────────────────────────────────────────────────────────────────────────────────
--- spec = { name, ft, render = function(p, b) end, keys = { lhs = function(p) end },
---          select = function(p, line) -> first, last | nil,  click = function(p, m, meta) end,
---          sections = {names} (number keys 1-9 + ]] [[ jump to headlines) }
local Page = {}; Page.__index = Page

--- Set window-LOCAL options. `vim.wo[win].x = v` on the current window also changes the global default (like :set), so
--- the next file opened in any window would lose its line numbers / sign column. Always use this for chrome windows.
function M.setwo(win, opts)
  for k, v in pairs(opts) do pcall(vim.api.nvim_set_option_value, k, v, { scope = "local", win = win }) end
end
local PAGE_WINOPTS = { cursorline = true, wrap = false, number = false, relativenumber = false, signcolumn = "no", list = false,
  spell = false, foldenable = false, scrolloff = 0 }

local function editing_window()
  -- A window that holds a file or another page counts; sidebars (activity bar, explorer, search...) and terminals do not.
  local function ok(w)
    local b = vim.api.nvim_win_get_buf(w)
    local ft = vim.bo[b].filetype
    if vim.api.nvim_win_get_config(w).relative ~= "" then return false end
    return vim.bo[b].buftype == "" or ft == "snacks_dashboard" or (ft:find("^ide%-") ~= nil and ft ~= "ide-activity")
  end
  if ok(vim.api.nvim_get_current_win()) then return vim.api.nvim_get_current_win() end
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if ok(w) then return w end end
  -- Only sidebars are left: add an editor column beside them instead of a new tab page (a tab has no sidebar).
  vim.cmd("botright vnew"); return vim.api.nvim_get_current_win()
end

function M.page(spec)
  local p = setmetatable({ spec = spec, buf = nil, win = nil, meta = {}, heads = {}, jumps = {}, filter = "" }, Page)
  p.ns = vim.api.nvim_create_namespace("ide-page-" .. spec.ft)
  p.ns_sel = vim.api.nvim_create_namespace("ide-page-sel-" .. spec.ft)
  return p
end

function Page:valid() return self.buf and vim.api.nvim_buf_is_valid(self.buf) and vim.api.nvim_buf_is_loaded(self.buf) end

--- Move the cursor, clamped to the buffer (stale line numbers and clicks below the content must never raise).
function Page:setcur(line)
  if not (self.win and vim.api.nvim_win_is_valid(self.win) and self:valid()) then return end
  local n = vim.api.nvim_buf_line_count(self.buf)
  pcall(vim.api.nvim_win_set_cursor, self.win, { math.max(1, math.min(tonumber(line) or 1, n)), 0 })
end
function Page:line() return vim.api.nvim_win_get_cursor(self.win)[1] end

function Page:mark()
  if not (self:valid() and self.win and vim.api.nvim_win_is_valid(self.win)) then return end
  vim.api.nvim_buf_clear_namespace(self.buf, self.ns_sel, 0, -1)
  if not self.spec.select then return end
  local first, last = self.spec.select(self, self:line())
  if not first then return end
  for l = first, last or first do
    vim.api.nvim_buf_set_extmark(self.buf, self.ns_sel, l - 1, 0, { virt_text = { { M.g("bar"), "IDEBar" } }, virt_text_pos = "overlay", priority = 200 })
  end
end

function Page:render()
  if not self:valid() then return end
  local width = (self.win and vim.api.nvim_win_is_valid(self.win)) and vim.api.nvim_win_get_width(self.win) or 100
  local b = M.builder(math.max(math.min(width - 8, 100), 40))
  self.spec.render(self, b)
  vim.bo[self.buf].modifiable = true
  vim.api.nvim_buf_set_lines(self.buf, 0, -1, false, b.lines)
  vim.bo[self.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(self.buf, self.ns, 0, -1)
  for _, h in ipairs(b.hls) do vim.api.nvim_buf_add_highlight(self.buf, self.ns, h[2], h[1] - 1, 0, -1) end
  self.meta, self.heads, self.jumps, self.lines = b.meta, b.heads, b.jumps, b.lines
  return b
end

function Page:goto_head(i)
  local h = self.heads[i]
  if h then self:setcur(h.line); vim.cmd("normal! zt"); self:mark() end
end
function Page:next_head(d)
  local line, target = self:line(), nil
  if d > 0 then for _, h in ipairs(self.heads) do if h.line > line then target = h.line break end end
  else for i = #self.heads, 1, -1 do if self.heads[i].line < line then target = self.heads[i].line break end end end
  if target then self:setcur(target); vim.cmd("normal! zt"); self:mark() end
end

function Page:close()
  if vim.env.IDE_SETTINGS_ONLY then return vim.cmd("qa!") end
  local b = self.buf
  local ok, sn = pcall(require, "snacks")
  if ok and sn.bufdelete then sn.bufdelete(b) else pcall(vim.api.nvim_buf_delete, b, { force = true }) end
end

--- Handle a mouse position (from the buffer-local map or the global hook). Returns true when it was on this page.
function Page:on_click(m)
  if not (self.win and m.winid == self.win and m.line and m.line >= 1) then return false end
  self:setcur(m.line); self:mark()
  local meta = self.meta[m.line]
  if meta and meta.jumpbar then
    for _, j in ipairs(self.jumps) do if m.column - 1 >= j.from and m.column - 1 <= j.to then self:goto_head(j.id); return true end end
  end
  if self.spec.click then self.spec.click(self, m, meta) end
  return true
end

function Page:open()
  local spec = self.spec
  if self:valid() then
    local w = vim.fn.bufwinid(self.buf)
    if w ~= -1 then vim.api.nvim_set_current_win(w) else vim.api.nvim_win_set_buf(editing_window(), self.buf) end
    self.win = vim.api.nvim_get_current_win(); self:render(); self:mark(); return self
  end
  self.win = editing_window(); vim.api.nvim_set_current_win(self.win)
  local stale = vim.fn.bufnr("^" .. spec.name .. "$")      -- a deleted-but-not-yet-wiped copy would make set_name fail (E95)
  if stale > 0 then pcall(vim.api.nvim_buf_delete, stale, { force = true }) end
  self.buf = vim.api.nvim_create_buf(true, true)
  vim.api.nvim_buf_set_name(self.buf, spec.name)
  vim.bo[self.buf].buftype = "nofile"; vim.bo[self.buf].bufhidden = "hide"; vim.bo[self.buf].swapfile = false -- hide: opening another page keeps this one as a tab
  vim.bo[self.buf].filetype = spec.ft
  local old = vim.api.nvim_win_get_buf(self.win)
  vim.api.nvim_win_set_buf(self.win, self.buf)
  if old ~= self.buf and vim.api.nvim_buf_is_valid(old) and vim.api.nvim_buf_get_name(old) == "" and not vim.bo[old].modified and vim.api.nvim_buf_line_count(old) <= 1
    and vim.api.nvim_buf_get_lines(old, 0, -1, false)[1] == "" then pcall(vim.api.nvim_buf_delete, old, { force = true }) end
  M.setwo(self.win, PAGE_WINOPTS)
  M.install_click_handler()
  self:render()
  self:setcur(spec.start_line and spec.start_line(self) or 1); self:mark()

  local k = function(lhs, fn) vim.keymap.set("n", lhs, function() fn(self) end, { buffer = self.buf, nowait = true, silent = true }) end
  for lhs, fn in pairs(spec.keys or {}) do k(lhs, fn) end
  if spec.sections then
    for i = 1, math.min(#spec.sections, 9) do k(tostring(i), function(p) p:goto_head(i) end) end
    k("]]", function(p) p:next_head(1) end); k("[[", function(p) p:next_head(-1) end)
  end
  k("q", function(p) p:close() end)
  -- No buffer-local <LeftMouse>: it would swallow clicks meant for other windows (activity bar, buttons).
  -- The global handler below reaches this page through ui.hooks.
  if not self._hooked then self._hooked = true; table.insert(M.hooks, function(m) return self:valid() and self:on_click(m) end) end -- clicks while another window has focus
  local g = vim.api.nvim_create_augroup("ide-page-" .. spec.ft, { clear = true })
  vim.api.nvim_create_autocmd("CursorMoved", { group = g, buffer = self.buf, callback = function() self:mark() end })
  vim.api.nvim_create_autocmd({ "VimResized", "WinResized" }, { group = g, callback = function() if self:valid() then self:render(); self:mark() end end })
  -- Coming back to a hidden page (tab click, :b) may be in a different window: follow it.
  vim.api.nvim_create_autocmd("BufWinEnter", { group = g, buffer = self.buf, callback = function()
    self.win = vim.api.nvim_get_current_win()
    M.setwo(self.win, PAGE_WINOPTS)
    vim.schedule(function() if self:valid() then self:render(); self:mark() end end)
  end })
  -- :bd only unloads/unlists; a page has no file behind it, so wipe it for real (and forget it) when it is deleted.
  vim.api.nvim_create_autocmd("BufDelete", { group = g, buffer = self.buf, callback = function(a)
    vim.schedule(function() if vim.api.nvim_buf_is_valid(a.buf) then pcall(vim.api.nvim_buf_delete, a.buf, { force = true }) end end)
  end })
  vim.api.nvim_create_autocmd("BufWipeout", { group = g, buffer = self.buf, callback = function() self.buf = nil end })
  return self
end

return M
