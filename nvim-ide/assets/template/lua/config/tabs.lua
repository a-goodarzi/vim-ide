-- Tab bar (self-written, like the statusline). Every open file is a rounded "card" on a darker strip:
--   [ activity-bar gap ][ sidebar title ]  ( icon name  x )( icon name  ● )( ...  )                [ buttons ]
-- * the strip starts where the editor starts, so tabs never slide under the Explorer / Search sidebars
-- * the active tab is the editor's color with an accent underline; idle tabs are a step darker
-- * click a tab to switch, click x to close, middle-click closes; ● marks unsaved changes
-- * colors are derived from the colorscheme, so every theme gets the same shape
local M = {}

local sidebar_titles = { ["neo-tree"] = "Explorer", ["grug-far"] = "Search & Replace", aerial = "Outline", dapui_scopes = "Run & Debug", idescm = "Source Control" }
local skip_ft = { ["neo-tree"] = true, ["ide-activity"] = true, ["grug-far"] = true, idescm = true, aerial = true, minimap = true, qf = true,
  trouble = true, toggleterm = true, snacks_terminal = true, dapui_scopes = true, dapui_breakpoints = true,
  dapui_stacks = true, dapui_watches = true, dapui_console = true, ["dap-repl"] = true }

local function rgb(n) return { math.floor(n / 65536) % 256, math.floor(n / 256) % 256, n % 256 } end
local function hex(c) return c[1] * 65536 + c[2] * 256 + c[3] end
local function mix(a, b, t)
  local x, y = rgb(a), rgb(b)
  return hex({ math.floor(x[1] + (y[1] - x[1]) * t + .5), math.floor(x[2] + (y[2] - x[2]) * t + .5), math.floor(x[3] + (y[3] - x[3]) * t + .5) })
end
local function get(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end
local function lum(n)
  local c = rgb(n)
  local function lin(v) v = v / 255; return v <= 0.03928 and v / 12.92 or ((v + 0.055) / 1.055) ^ 2.4 end
  return 0.2126 * lin(c[1]) + 0.7152 * lin(c[2]) + 0.0722 * lin(c[3])
end
local function ratio(a, b) local x, y = lum(a), lum(b); if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
--- Blend `c` toward `toward` until it reads on `bg` with at least `min` contrast.
local function ensure(c, bg, min, toward)
  for i = 0, 10 do local x = mix(c, toward, i / 10); if ratio(x, bg) >= min then return x end end
  return toward
end

local icon_hl = {}   -- "<fg><state>" -> group
function M.apply()
  local normal = get("Normal")
  local dark = vim.o.background == "dark"
  local base = normal.bg or get("TabLineFill").bg or (dark and 0x1e1e2e or 0xffffff)
  local fg = normal.fg or (dark and 0xcdd6f4 or 0x333333)
  local edge = dark and 0x000000 or 0x808080
  local fill = mix(base, edge, dark and 0.42 or 0.14)
  local idle = mix(base, edge, dark and 0.24 or 0.07)
  if dark and lum(base) < 0.02 then   -- near-black themes: there is no room to go darker, so the strip gets lighter instead
    fill = mix(base, 0xffffff, 0.10); idle = mix(base, 0xffffff, 0.05)
  end
  local accent = get("Function").fg or get("DiagnosticInfo").fg or fg
  local muted = ensure(mix(fg, idle, 0.45), idle, 3.0, fg)
  local warn = get("DiagnosticWarn").fg or fg
  local err = get("DiagnosticError").fg or fg
  local set = function(n, v) vim.api.nvim_set_hl(0, n, v) end
  set("IDETabFill", { bg = fill, fg = muted })
  set("IDETabTitle", { bg = fill, fg = ensure(mix(fg, fill, 0.2), fill, 3.0, fg), bold = true })
  set("IDETabSel", { bg = base, fg = fg, bold = true })
  set("IDETabSelPlain", { bg = base, fg = fg })
  set("IDETabSelMuted", { bg = base, fg = muted })
  set("IDETabSelMod", { bg = base, fg = warn })
  set("IDETabSelEdge", { bg = fill, fg = base })
  set("IDETabIdle", { bg = idle, fg = muted })
  set("IDETabIdleMod", { bg = idle, fg = warn })
  set("IDETabIdleEdge", { bg = fill, fg = idle })
  set("IDETabErr", { bg = idle, fg = err })
  set("IDETabWarn", { bg = idle, fg = warn })
  set("IDETabSelErr", { bg = base, fg = err })
  set("IDETabSelWarn", { bg = base, fg = warn })
  icon_hl = {}
end

local function icons() return require("config.ui").icons() end

local function icon_for(name, state)
  if not icons() then return "" end
  local ok, dev = pcall(require, "nvim-web-devicons")
  if not ok then return "" end
  local ic, col = dev.get_icon_color(name, vim.fn.fnamemodify(name, ":e"), { default = true })
  if not ic then return "" end
  local bg = state == "sel" and get("IDETabSelPlain").bg or get("IDETabIdle").bg
  local key = tostring(col) .. state
  if not icon_hl[key] then
    local n = 0
    for _ in pairs(icon_hl) do n = n + 1 end
    icon_hl[key] = "IDETabIcon" .. n
    vim.api.nvim_set_hl(0, icon_hl[key], { fg = col, bg = bg })
  end
  return "%#" .. icon_hl[key] .. "#" .. ic .. " "
end

local function is_editing_win(w)
  if vim.api.nvim_win_get_config(w).relative ~= "" then return false end
  local b = vim.api.nvim_win_get_buf(w)
  return not skip_ft[vim.bo[b].filetype] and vim.bo[b].buftype ~= "terminal"
end

--- Columns taken by the activity bar and sidebar (everything left of the first editing window) and the sidebar's title.
local function left_offset()
  local col, title, bar = nil, nil, 0
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    if vim.api.nvim_win_get_config(w).relative == "" then
      local c = vim.api.nvim_win_get_position(w)[2]
      if is_editing_win(w) then col = math.min(col or c, c)
      else
        local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
        if ft == "ide-activity" then bar = vim.api.nvim_win_get_width(w) + 1 end
        if sidebar_titles[ft] then
          title = sidebar_titles[ft]
          if ft == "neo-tree" then
            local ab = package.loaded["config.activitybar"]
            if ab and ab.active == "git" then title = "Source Control" end
          end
        end
      end
    end
  end
  return col or 0, title, bar
end

M.pinned, M.order = {}, {}   -- pinned[bufnr] = true; order = bufnrs in the order the user arranged them
local function tab_list()
  local list, names = {}, {}
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    local ft = vim.bo[b.bufnr].filetype
    local empty = b.name == "" and b.changed == 0 and b.linecount <= 1 and #b.windows == 0
    if not skip_ft[ft] and vim.bo[b.bufnr].buftype ~= "terminal" and not empty and not b.name:find("^%a+://") then   -- gitsigns:// diff buffers are not tabs
      local name = b.name == "" and "[No Name]" or vim.fn.fnamemodify(b.name, ":t")
      names[name] = (names[name] or 0) + 1
      list[#list + 1] = { buf = b.bufnr, name = name, path = b.name, changed = b.changed == 1, ft = ft }
    end
  end
  -- user order (Move left / right), pinned tabs first
  local pos, live = {}, {}
  for _, t in ipairs(list) do live[t.buf] = true end
  local kept = {}
  for _, b in ipairs(M.order) do if live[b] then kept[#kept + 1] = b; pos[b] = #kept end end
  for _, t in ipairs(list) do if not pos[t.buf] then kept[#kept + 1] = t.buf; pos[t.buf] = #kept end end
  M.order = kept
  for _, t in ipairs(list) do t.pinned = M.pinned[t.buf] and true or false end
  table.sort(list, function(a, b)
    if a.pinned ~= b.pinned then return a.pinned end
    return pos[a.buf] < pos[b.buf]
  end)
  for _, t in ipairs(list) do      -- two files with the same name: add the parent folder
    if names[t.name] > 1 and t.path ~= "" then t.name = vim.fn.fnamemodify(t.path, ":h:t") .. "/" .. t.name end
    t.diag = vim.diagnostic.count(t.buf)
  end
  return list
end

-- ── clicks (called by the tabline %@ handlers) ────────────────────────────────────────────────────
local function goto_buf(buf)
  if not is_editing_win(vim.api.nvim_get_current_win()) then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do if is_editing_win(w) then vim.api.nvim_set_current_win(w) break end end
  end
  pcall(vim.api.nvim_win_set_buf, 0, buf)
end
function M.close(buf, force)
  if M.pinned[buf] and not force then return vim.notify("Pinned tab: unpin it first (right-click the tab)", vim.log.levels.INFO) end
  local ok, sn = pcall(require, "snacks")
  if ok and sn.bufdelete then sn.bufdelete(buf) else pcall(vim.api.nvim_buf_delete, buf, {}) end
  vim.cmd.redrawtabline()
end
_G.IdeTabClick = function(buf, _, button)
  if button == "m" then M.close(buf) elseif button == "l" then goto_buf(buf)
  elseif button == "r" then vim.schedule(function() M.menu(buf) end) end
end
_G.IdeTabClose = function(buf) M.close(buf) end

-- ── render ──────────────────────────────────────────────────────────────────────────────────────────
local function width(s) return vim.fn.strdisplaywidth(s) end
local esc = function(s) return (s:gsub("%%", "%%%%")) end

function M.render()
  local ok, res = pcall(function()
    local off, title, bar = left_offset()
    local avail = vim.o.columns - off - 14           -- 14 = the 4 top-right buttons
    local fancy = icons()
    local style = require("config").settings.tabs_style or "slanted"
    local flat = style == "flat" or not fancy
    local capl, capr = " ", " "
    if not flat then
      if style == "rounded" then capl, capr = "\xee\x82\xb6", "\xee\x82\xb4" else capl, capr = "\xee\x82\xba", "\xee\x82\xb8" end   -- slanted trapezoid sides
    end
    local tabs = tab_list()
    local sel = vim.api.nvim_get_current_buf()
    if not is_editing_win(vim.api.nvim_get_current_win()) then
      for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
        if is_editing_win(w) then sel = vim.api.nvim_win_get_buf(w) break end
      end
    end

    local parts = {}
    for _, t in ipairs(tabs) do
      local active = t.buf == sel
      local hl, edge = active and "IDETabSel" or "IDETabIdle", active and "IDETabSelEdge" or "IDETabIdleEdge"
      local errc, warnc = t.diag[vim.diagnostic.severity.ERROR] or 0, t.diag[vim.diagnostic.severity.WARN] or 0
      local diag, dw = "", 0
      if errc > 0 then diag = "%#" .. (active and "IDETabSelErr" or "IDETabErr") .. "# E" .. errc; dw = 2 + #tostring(errc)
      elseif warnc > 0 then diag = "%#" .. (active and "IDETabSelWarn" or "IDETabWarn") .. "# W" .. warnc; dw = 2 + #tostring(warnc) end
      local mark = t.changed and (fancy and "\xe2\x97\x8f" or "+") or (fancy and "\xef\x80\x8d" or "x")
      if t.pinned and not t.changed then mark = fancy and "\xef\x82\x8d" or "^" end
      local mark_hl = t.changed and (active and "IDETabSelMod" or "IDETabIdleMod") or (active and "IDETabSelMuted" or "IDETabIdle")
      local label = t.name
      -- Middle ellipsis keeps the distinguishing tail (number_1 vs number_12, extension).
      local n = vim.fn.strchars(label)
      if n > 24 then label = vim.fn.strcharpart(label, 0, 14) .. "\xe2\x80\xa6" .. vim.fn.strcharpart(label, n - 9) end
      local icon = icon_for(t.name:match("[^/]+$"), active and "sel" or "idle")
      if flat then edge = hl end        -- flat tabs: the padding belongs to the tab itself
      local s = "%#" .. edge .. "#" .. capl
        .. "%" .. t.buf .. "@v:lua.IdeTabClick@%#" .. hl .. "# " .. icon .. "%#" .. hl .. "#" .. esc(label) .. diag .. "%#" .. hl .. "# %X"
        .. "%" .. t.buf .. "@v:lua.IdeTabClose@%#" .. mark_hl .. "#" .. mark .. "%#" .. hl .. "# %X"
        .. "%#" .. edge .. "#" .. capr .. (flat and "%#IDETabFill# " or "")
      parts[#parts + 1] = { s = s, w = 1 + 1 + (icon ~= "" and 2 or 0) + width(label) + dw + 1 + 1 + 1 + 1 + 1 + (flat and 1 or 0), active = active }
    end
    local first, total, act = 1, 0, 1
    for i, p in ipairs(parts) do total = total + p.w; if p.active then act = i end end
    while total > avail and first < act do total = total - parts[first].w; first = first + 1 end
    -- Tabs after the active one can overflow too: stop where the strip is full and mark it with a chevron, otherwise
    -- the tabline is cut from the left and eats the sidebar title.
    local last, used = first - 1, (first > 1 and 2 or 0)
    for i = first, #parts do
      if i > act and used + parts[i].w > avail - 2 then break end
      used = used + parts[i].w; last = i
    end

    local out = { "%#IDETabFill#" }
    if off > 0 then
      local t = title or ""
      local room = math.max(off - bar, 0)
      local pad = math.max(room - width(t), 0)
      local left = math.floor(pad / 2)
      out[#out + 1] = string.rep(" ", bar) .. string.rep(" ", left) .. "%#IDETabTitle#" .. esc(t) .. "%#IDETabFill#" .. string.rep(" ", pad - left)
    end
    if first > 1 then out[#out + 1] = "%#IDETabFill#\xe2\x80\xb9 " end
    for i = first, last do out[#out + 1] = parts[i].s end
    if last < #parts then out[#out + 1] = "%#IDETabFill#\xe2\x80\xba" end
    out[#out + 1] = "%#IDETabFill#%="
    return table.concat(out)
  end)
  return ok and res or "%#IDETabFill#%="
end

function M.setup()
  M.apply()
  vim.keymap.set("n", "<A-<>", function() M.move(nil, -1) end, { desc = "Move tab left" })
  vim.keymap.set("n", "<A->>", function() M.move(nil, 1) end, { desc = "Move tab right" })
  vim.keymap.set("n", "<leader>bp", function() M.toggle_pin() end, { desc = "Pin / unpin tab" })
  vim.o.showtabline = 2
  vim.o.tabline = "%!v:lua.require'config.tabs'.render()"
  local g = vim.api.nvim_create_augroup("ide-tabs", { clear = true })
  vim.api.nvim_create_autocmd("ColorScheme", { group = g, callback = function()
    vim.schedule(M.apply); vim.defer_fn(function() M.apply(); vim.cmd.redrawtabline() end, 120)
  end })
  vim.api.nvim_create_autocmd({ "BufEnter", "BufAdd", "BufDelete", "BufWipeout", "BufModifiedSet", "DiagnosticChanged", "WinEnter",
    "WinClosed", "WinNew", "WinResized", "VimResized", "FileType", "BufFilePost" }, { group = g, callback = function()
    vim.schedule(function() vim.cmd.redrawtabline() end)
  end })
end

--- Close every tab except the current one (unsaved ones stay).
function M.close_others()
  local cur = vim.api.nvim_get_current_buf()
  for _, t in ipairs(tab_list()) do if t.buf ~= cur and not t.changed and not t.pinned then M.close(t.buf) end end
end

--- Close the tabs to the right of `buf` (unsaved and pinned ones stay).
function M.close_right(buf)
  local seen = false
  for _, t in ipairs(tab_list()) do
    if seen and not t.changed and not t.pinned then M.close(t.buf) end
    if t.buf == buf then seen = true end
  end
end

function M.toggle_pin(buf)
  buf = buf or vim.api.nvim_get_current_buf()
  M.pinned[buf] = (not M.pinned[buf]) or nil
  vim.cmd.redrawtabline()
end

--- Move a tab one place left (-1) or right (+1).
function M.move(buf, d)
  buf = buf or vim.api.nvim_get_current_buf()
  local list = tab_list()
  local idx
  for i, t in ipairs(list) do if t.buf == buf then idx = i end end
  local j = idx and idx + d
  if not (j and list[j]) or list[j].pinned ~= list[idx].pinned then return end
  M.order = {}
  list[idx], list[j] = list[j], list[idx]
  for _, t in ipairs(list) do M.order[#M.order + 1] = t.buf end
  vim.cmd.redrawtabline()
end

--- Switch to the previous (-1) / next (+1) tab in the order the tab bar shows.
function M.step(d)
  local list, cur = tab_list(), vim.api.nvim_get_current_buf()
  if #list == 0 then return end
  local idx = 0
  for i, t in ipairs(list) do if t.buf == cur then idx = i end end
  goto_buf(list[((idx - 1 + d) % #list) + 1].buf)
end

--- Right-click menu on a tab (a small floating list at the mouse position).
function M.menu(buf)
  local ui = require("config.ui")
  local path = vim.api.nvim_buf_get_name(buf)
  local pinned = M.pinned[buf]
  local items = {
    { pinned and "Unpin" or "Pin", function() M.toggle_pin(buf) end },
    { "Move left", function() M.move(buf, -1) end },
    { "Move right", function() M.move(buf, 1) end },
    { "Close", function() M.close(buf) end },
    { "Close others", function() goto_buf(buf); M.close_others() end },
    { "Close to the right", function() M.close_right(buf) end },
  }
  if path ~= "" then
    items[#items + 1] = { "Copy path", function() vim.fn.setreg("+", path); vim.notify("Copied " .. path) end }
    items[#items + 1] = { "Copy relative path", function() local r = vim.fn.fnamemodify(path, ":.");  vim.fn.setreg("+", r); vim.notify("Copied " .. r) end }
    items[#items + 1] = { "Reveal in Explorer", function()
      goto_buf(buf); local ab = require("config.activitybar"); if ab.active ~= "explorer" then ab.show("explorer") end
      pcall(vim.cmd, "Neotree reveal left")
    end }
  end
  ui.menu(items)
end

return M
