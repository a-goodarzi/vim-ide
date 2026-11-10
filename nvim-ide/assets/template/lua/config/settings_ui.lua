-- VS Code-style Settings TAB:  :IDESettings · <leader>us · click the gear · `ide settings`
-- A normal buffer named "Settings" (it shows up in the tab bar). Each section has a headline; each setting has a
-- title, a description and a control. ● marks values you changed, ↻ marks settings that need a restart.
--   j/k scroll · <Tab>/<S-Tab> next/prev setting · ]]/[[ next/prev section · 1-9 jump to section
--   <CR>/<Space>/click change · / search · r reset · R reset all · A apply + restart nvim · q close
-- Choices persist to stdpath("data")/ide-settings.json and override config/settings.lua.
-- To expose a new option, add a row to `schema` below (section rows define the categories).
local cfg = require("config")
local M = {}

local presets = require("config.languages")
local lang_names = vim.tbl_keys(presets); table.sort(lang_names)
local themes = require("config.theme").names

-- type: bool | enum | number | string | lang ; restart=true => applies after restarting nvim ; live => applies instantly
local schema = {
  { section = "Appearance" },
  { key = "colorscheme", type = "enum", values = themes, label = "Colorscheme", desc = "Color theme (applies instantly)",
    live = function(v) require("config.theme").apply(v) end },
  { key = "transparent", type = "bool", label = "Transparent background", desc = "Let the terminal background show through",
    live = function() require("config.theme").apply() end },
  { key = "statusline_style", type = "enum", values = { "rounded", "powerline", "plain" }, label = "Statusline style",
    desc = "rounded = powerlevel10k-like pills, powerline = arrows (needs icons)", live = function() require("config.statusline").apply() end },
  { key = "key_style", type = "enum", values = { "auto", "mac", "pc" }, label = "Shortcut notation",
    desc = "auto = ⌃ ⌥ ⇧ symbols on a Mac, Ctrl / Alt / Shift elsewhere (the keys themselves do not change)" },
  { key = "icon_size", type = "enum", values = { "large", "normal" }, label = "Icon size",
    desc = "large = 4-row tiles in the activity bar and extra room after icons. Terminals draw text on a grid: for even bigger icons use a Nerd Font variant without 'Mono' in its name",
    live = function() require("config.activitybar").rebuild(); vim.cmd.redrawtabline() end },
  { key = "tabs_style", type = "enum", values = { "slanted", "rounded", "flat" }, label = "Tab style",
    desc = "slanted = trapezoid tabs, rounded = pills, flat = plain blocks", live = function() vim.cmd.redrawtabline() end },
  { key = "features.icons", type = "bool", label = "Icons (Nerd Font)", desc = "Turn off if icons look broken; forces plain statusline", restart = true },
  { key = "options.relativenumber", type = "bool", label = "Relative line numbers", desc = "Distance numbers for fast jumps (5j)",
    live = function(v) vim.o.relativenumber = v end, default = true },
  { key = "options.wrap", type = "bool", label = "Wrap long lines", desc = "Soft-wrap lines that exceed the window",
    live = function(v) vim.o.wrap = v end, default = false },

  { section = "VS Code layout" },
  { key = "features.activity_bar", type = "bool", label = "Activity bar", desc = "Icon column: Explorer, Search & Replace, Git, Debug, Outline, Plugins", restart = true },
  { key = "features.vscode_keys", type = "bool", label = "VS Code shortcuts", desc = "F1 palette, Ctrl-P, Ctrl-S, F5/F9/F10/F11, Alt-arrows, Alt-b sidebar...", restart = true },
  { key = "features.breadcrumbs", type = "bool", label = "Breadcrumbs", desc = "file > function path above the editor (clickable)", restart = true },
  { key = "features.minimap", type = "bool", label = "Minimap", desc = "Code overview on the right edge", restart = true },

  { section = "Layout" },
  { key = "features.tabs", type = "bool", label = "Tabs", desc = "Show open files as tabs", restart = true,
    live = function(v) vim.o.showtabline = v and 2 or 0 end },
  { key = "features.explorer_on_start", type = "bool", label = "File browser at start", desc = "Open the sidebar when nvim launches", restart = true },
  { key = "features.dashboard", type = "bool", label = "Welcome dashboard", desc = "Start screen with shortcuts", restart = true },

  { section = "Claude Code" },
  { key = "features.claude", type = "bool", label = "Enable Claude panel", desc = "Embedded Claude Code (needs the claude CLI)", restart = true },
  { key = "features.agent_status", type = "bool", label = "Agent status", desc = "Show what Claude is doing in the statusline (working, needs you, done) through Claude Code hooks; :IDEAgent shows the log", restart = true },
  { key = "features.agent_checkpoints", type = "bool", label = "Undo agent turns", desc = "Before each prompt, record the working tree as a hidden git checkpoint (refs/ide-checkpoints, newest 30) so the turn can be undone", restart = true },
  { key = "claude.notify", type = "bool", label = "Notify me", desc = "A toast when Claude needs you (permission, question) or has finished, unless you are in the Claude panel", default = true },
  { key = "claude.autostart", type = "bool", label = "Open panel at start", desc = "Or launch with `ide claude`", restart = true },
  { key = "claude.side", type = "enum", values = { "right", "left" }, label = "Panel side", desc = "Which edge the panel docks to", restart = true },
  { key = "claude.width", type = "number", label = "Panel width", desc = "Fraction of the screen, 0.1 - 0.9", restart = true, min = 0.1, max = 0.9 },
  { key = "claude.terminal_cmd", type = "string", label = "claude CLI path", desc = "Blank = use PATH", restart = true },

  { section = "Features" },
  { key = "features.git", type = "bool", label = "Git integration", desc = "Hunks, blame, diff view", restart = true },
  { key = "features.context_menu", type = "bool", label = "Right-click menus", desc = "Context menus in the editor and the Explorer (tabs always have one)", restart = true },
  { key = "features.session_restore", type = "bool", label = "Restore last session", desc = "Reopen the files you had open in this folder when you start without a file", restart = true },
  { key = "features.welcome", type = "bool", label = "First-run welcome", desc = "Show the welcome / icon check on the first start (:IDEWelcome reopens it)", restart = false },
  { key = "features.debug", type = "bool", label = "Debugger (Run & Debug)", desc = "The Run & Debug sidebar icon, F5/F9/F10/F11, breakpoints and stepping. Off = lighter, no debug plugins load", restart = true },
  { key = "features.test", type = "bool", label = "Test runner", desc = "neotest: run tests from the editor", restart = true },
  { key = "features.terminal", type = "bool", label = "Terminal toggle", desc = "Floating terminal and lazygit", restart = true },
  { key = "features.format_on_save", type = "bool", label = "Format on save", desc = "Run the formatter when saving (instant)", live = function() end },
  { key = "features.lint", type = "bool", label = "Linting", desc = "Run linters (shellcheck, tflint, ...)", restart = true },

  { section = "Editor" },
  { key = "options.tabstop", type = "number", label = "Tab width", desc = "Columns per tab character", live = function(v) vim.o.tabstop = v end, default = 2, min = 1, max = 16 },
  { key = "options.shiftwidth", type = "number", label = "Indent width", desc = "Columns per indent level", live = function(v) vim.o.shiftwidth = v end, default = 2, min = 1, max = 16 },
  { key = "options.scrolloff", type = "number", label = "Scroll offset", desc = "Lines kept visible around the cursor", live = function(v) vim.o.scrolloff = v end, default = 8, min = 0, max = 50 },

  { section = "Languages" },
}
for _, n in ipairs(lang_names) do
  local p = presets[n]
  local bits = {}
  if p.lsp then bits[#bits + 1] = "LSP " .. table.concat(p.lsp, "+") end
  if p.formatters then local f = {}; for _, t in pairs(p.formatters) do f[t[1]] = true end; bits[#bits + 1] = "fmt " .. table.concat(vim.tbl_keys(f), "+") end
  if p.dap then bits[#bits + 1] = "debug " .. table.concat(p.dap, "+") end
  schema[#schema + 1] = { key = "languages", type = "lang", name = n, label = n, desc = table.concat(bits, " · "), restart = true }
end

-- categories built from section rows -------------------------------------------------
local categories = {}
do
  local cur
  for _, it in ipairs(schema) do
    if it.section then cur = { name = it.section, items = {} }; categories[#categories + 1] = cur
    else it.category = cur.name; cur.items[#cur.items + 1] = it end
  end
end

-- dotted-path helpers ------------------------------------------------------------------
local function get(tbl, path)
  for part in path:gmatch("[^.]+") do
    if type(tbl) ~= "table" then return nil end
    tbl = tbl[part]
  end
  return tbl
end
local function set(tbl, path, v)
  local parts = vim.split(path, ".", { plain = true })
  for i = 1, #parts - 1 do tbl[parts[i]] = tbl[parts[i]] or {}; tbl = tbl[parts[i]] end
  tbl[parts[#parts]] = v
end
local function current(item)
  local v = get(cfg.settings, item.key)
  if v == nil then v = item.default end
  return v
end
local function lang_on(name) return vim.tbl_contains(cfg.settings.languages, name) end

local function value_text(item)
  local icons = cfg.icons()
  if item.type == "bool" or item.type == "lang" then
    local on = (item.type == "bool") and current(item) or lang_on(item.name)
    if icons then return on and "\xef\x85\x8a  on" or "\xef\x82\x96  off" end -- check-square / square
    return on and "[x] on" or "[ ] off"
  end
  local v = current(item)
  if item.type == "enum" then return "\xe2\x80\xb9 " .. tostring(v) .. " \xe2\x80\xba" end -- ‹ value ›
  return (v == nil or v == "") and "(unset)" or tostring(v)
end

-- persistence ----------------------------------------------------------------------------
local restart_needed = {}
local function apply(item, value)
  local ov = cfg.load_overrides()
  set(ov, item.key, value); set(cfg.settings, item.key, value)
  cfg.save_overrides(ov)
  if item.live then pcall(item.live, value) end
  if item.restart and not item.live then restart_needed[item.label] = true end
  if item.restart and item.live and item.key == "features.tabs" then restart_needed[item.label] = true end
end
local function reset_item(item)
  local ov = cfg.load_overrides()
  local parts = vim.split(item.key, ".", { plain = true })
  local node = ov
  for i = 1, #parts - 1 do node = type(node) == "table" and node[parts[i]] or nil end
  if type(node) == "table" then node[parts[#parts]] = nil end
  cfg.save_overrides(ov)
  local d = get(cfg.defaults, item.key)
  if d == nil then d = item.default end
  set(cfg.settings, item.key, d)
  if item.live and d ~= nil then pcall(item.live, d) end
  if item.restart then restart_needed[item.label] = true end
end
local function cycle(item)
  local vals, cur = item.values, current(item)
  for i, v in ipairs(vals) do if v == cur then return vals[i % #vals + 1] end end
  return vals[1]
end

-- UI (built on config/ui.lua so it matches Help and Plugins) ----------------------------------------
local ui = require("config.ui")
local filter = ""

local function matches(it, q)
  q = q:lower()
  return (it.label or ""):lower():find(q, 1, true) or (it.desc or ""):lower():find(q, 1, true)
    or (it.category or ""):lower():find(q, 1, true) or (it.key or ""):lower():find(q, 1, true)
end

local function changed(item, ov)
  if item.type == "lang" then
    local d = get(cfg.defaults, "languages") or {}
    return (ov.languages ~= nil) and (vim.tbl_contains(d, item.name) ~= lang_on(item.name))
  end
  return get(ov, item.key) ~= nil
end

local page
local cat_names = {}
for _, c in ipairs(categories) do cat_names[#cat_names + 1] = c.name end

local function activate(p, item)
  if not item then return end
  local line = p:line()
  local function done() p:render(); p:setcur(line); p:mark() end
  if item.type == "bool" then apply(item, not current(item)); done()
  elseif item.type == "enum" then apply(item, cycle(item)); done()
  elseif item.type == "lang" then
    local list = vim.deepcopy(cfg.settings.languages)
    if lang_on(item.name) then for i, v in ipairs(list) do if v == item.name then table.remove(list, i) break end end
    else list[#list + 1] = item.name end
    apply(item, list); done()
  else
    vim.ui.input({ prompt = item.label .. ": ", default = tostring(current(item) or "") }, function(inp)
      if inp == nil then return end
      if item.type == "number" then
        local n = tonumber(inp)
        if not n or (item.min and n < item.min) or (item.max and n > item.max) then
          return vim.notify(("Enter a number between %s and %s"):format(item.min, item.max), vim.log.levels.WARN)
        end
        inp = n
      elseif inp == "" then inp = nil end
      if inp == nil then reset_item(item) else apply(item, inp) end
      done()
    end)
  end
end

local function block_lines(p)
  local out = {}
  for l, m in pairs(p.meta) do if m and m.item and m.first == l then out[#out + 1] = l end end
  table.sort(out); return out
end
local function next_block(p, d)
  local line, target = p:line(), nil
  local bl = block_lines(p)
  if d > 0 then for _, b in ipairs(bl) do if b > line then target = b break end end
  else for i = #bl, 1, -1 do if bl[i] < line then target = bl[i] break end end end
  if target then p:setcur(target); p:mark() end
end

-- one accent per section and an icon, so each part of the page is recognisable at a glance
local accents = { "IDEAccent", "IDEOn", "IDEWarn", "IDEInfo", "IDEKey", "Special" }
local cat_style = {
  ["Appearance"] = { icon = "\xef\x87\xbc" }, ["VS Code layout"] = { icon = "\xef\x83\x9b" }, ["Layout"] = { icon = "\xef\x80\x89" },
  ["Claude Code"] = { icon = "\xef\x81\xa9" }, ["Features"] = { icon = "\xef\x82\x85" }, ["Editor"] = { icon = "\xef\x81\x84" },
  ["Languages"] = { icon = "\xef\x84\xa1" },
}

--- The control as one line of chips: a switch, the options of an enum (the current one filled) or an input box.
--- Returns text, spans (byte offsets in the text) and, for enums, clickable chips { from, to, value }.
local function control_row(it)
  local text, spans, chips = "", {}, nil
  local function seg(s, hl, value)
    if hl then spans[#spans + 1] = { #text, #text + #s, hl } end
    if value ~= nil then chips = chips or {}; chips[#chips + 1] = { from = #text, to = #text + #s, value = value } end
    text = text .. s
  end
  if it.type == "bool" then
    local on = current(it)
    seg(on and " \xe2\x97\x8f ON  " or " \xe2\x97\x8b OFF ", on and "IDEChipOn" or "IDEChipOff"); seg("   Enter / click toggles", "IDEMuted")
  elseif it.type == "enum" then
    local vs, cur = it.values, current(it)
    local idx = 1
    for i, v in ipairs(vs) do if v == cur then idx = i end end
    if #vs <= 5 then
      for _, v in ipairs(vs) do seg(" " .. tostring(v) .. " ", v == cur and "IDEChipSel" or "IDEChip", v); seg(" ") end
      seg("  Enter: next", "IDEMuted")
    else      -- a long list (themes): the previous and next option around the current one, click either to jump
      local prev, nxt = vs[(idx - 2) % #vs + 1], vs[idx % #vs + 1]
      seg(" \xe2\x80\xb9 " .. tostring(prev) .. " ", "IDEChip", prev); seg(" ")
      seg(" " .. tostring(cur) .. " ", "IDEChipSel", cur); seg(" ")
      seg(" " .. tostring(nxt) .. " \xe2\x80\xba ", "IDEChip", nxt)
      seg(("   %d / %d   Enter: next"):format(idx, #vs), "IDEMuted")
    end
  else
    local v = current(it)
    seg(" " .. ((v == nil or v == "") and "(not set)" or tostring(v)) .. " ", "IDEChip"); seg("   Enter: edit", "IDEMuted")
  end
  return text, spans, chips
end

page = ui.page({
  name = "Settings", ft = "ide-settings", sections = cat_names,
  render = function(_, b)
    local ov = cfg.load_overrides()
    b:title("Settings", ui.g("changed") .. "changed from default    " .. ui.g("restart") .. " needs restart    Enter / click to change    / to search")
    local searching = filter ~= ""
    b:add(b.margin .. ui.g("search") .. (searching and ("Search: " .. filter .. "    (Esc clears)") or "Search settings\xe2\x80\xa6  (press /)"), searching and "Search" or "IDEMuted")
    b:blank()
    b:jumpbar(cat_names)

    local shown = 0
    for ci, cat in ipairs(categories) do
      local items = {}
      for _, it in ipairs(cat.items) do if not searching or matches(it, filter) then items[#items + 1] = it end end
      if #items > 0 then
        local style = cat_style[cat.name] or {}
        local accent = accents[(ci - 1) % #accents + 1]
        b:head(cat.name, ci, { icon = cfg.icons() and style.icon or nil, accent = accent })
        local compact = cat.name == "Languages"
        for _, it in ipairs(items) do
          shown = shown + 1
          local is_changed = changed(it, ov)
          local needs_restart = it.restart and not it.live
          if compact then
            local on = lang_on(it.name)
            local first = #b.lines + 1
            local chip = on and " \xe2\x97\x8f " or " \xe2\x97\x8b "
            local label = string.format("%-14s", it.label)
            local text = b.margin .. (is_changed and ui.g("changed") or "  ") .. chip .. " " .. label .. "  " .. (it.desc or "") .. (needs_restart and ("  " .. ui.g("restart")) or "")
            local l = b:add(text, on and nil or "IDEMuted", { item = it, kind = "control", first = first, last = first })
            local c0 = #b.margin + #(is_changed and ui.g("changed") or "  ")
            b:span(l, c0, c0 + #chip, on and "IDEChipOn" or "IDEChipOff")
            if on then b:span(l, c0 + #chip + 1, c0 + #chip + 1 + #label, accent) end
          else
            local ctext, spans, chips = control_row(it)
            local tag
            if is_changed and needs_restart then tag = { ui.g("changed") .. "changed  " .. ui.g("restart") .. " restart", "IDEChipWarn" }
            elseif is_changed then tag = { ui.g("changed") .. "changed", "IDEChipWarn" }
            elseif needs_restart then tag = { ui.g("restart") .. " needs restart", "IDEChipInfo" } end
            local first, last = b:card({ title = it.label, accent = accent, tag = tag, meta = { item = it, kind = "title" },
              lines = { { it.desc or "", "IDEMuted", meta = { kind = "desc" } }, { ctext, nil, nowrap = true, spans = spans, meta = { kind = "control", chips = chips } } } })
            for l = first, last do b.meta[l].first, b.meta[l].last = first, last end
            if chips then for _, ch in ipairs(chips) do ch.from, ch.to = ch.from + #b.margin + 4, ch.to + #b.margin + 4 end end   -- "│ " = 4 bytes before the text
            b:blank()
          end
        end
      end
    end
    if shown == 0 then b:blank(); b:add(b.margin .. "No settings match \"" .. filter .. "\".", "IDEWarn") end
    b:blank(); b:rule()
    local pending = vim.tbl_keys(restart_needed); table.sort(pending)
    if #pending > 0 then b:add(b.margin .. ui.g("restart") .. " Restart needed for: " .. table.concat(pending, ", ") .. "   (press A to restart now)", "IDEWarn")
    else b:add(b.margin .. "Saved to " .. cfg.override_path, "IDEMuted") end
  end,
  select = function(p, line) local m = p.meta[line]; if m and m.item then return m.first, m.last end end,
  start_line = function(p) return block_lines(p)[1] or 1 end,
  click = function(p, m, meta)
    if not (meta and meta.item and meta.kind == "control") then return end
    if meta.chips and m and m.column then      -- a click on one option of an enum picks that option
      for _, ch in ipairs(meta.chips) do
        if m.column - 1 >= ch.from and m.column - 1 < ch.to then
          local line = p:line()
          apply(meta.item, ch.value); p:render(); p:setcur(line); p:mark(); return
        end
      end
    end
    activate(p, meta.item)
  end,
  keys = {
    ["<CR>"] = function(p) local m = p.meta[p:line()]; activate(p, m and m.item) end,
    ["<Space>"] = function(p) local m = p.meta[p:line()]; activate(p, m and m.item) end,
    ["<Tab>"] = function(p) next_block(p, 1) end, ["<S-Tab>"] = function(p) next_block(p, -1) end,
    ["/"] = function(p)
      vim.ui.input({ prompt = "Search settings: ", default = filter }, function(q)
        if q == nil then return end
        filter = q; p:render(); p:setcur(block_lines(p)[1] or 1); p:mark()
      end)
    end,
    ["<Esc>"] = function(p) if filter ~= "" then filter = ""; p:render(); p:mark() end end,
    r = function(p) local m = p.meta[p:line()]; if m and m.item then reset_item(m.item); p:render(); p:mark() end end,
    R = function(p)
      vim.ui.select({ "Cancel", "Reset ALL settings" }, { prompt = "Discard every saved setting?" }, function(c)
        if c == "Reset ALL settings" then cfg.save_overrides({}); restart_needed["everything"] = true; vim.notify("Settings reset. Restart nvim."); p:render() end
      end)
    end,
    A = function()
      if vim.env.IDE_SETTINGS_ONLY then return vim.cmd("qa!") end
      if vim.fn.exists(":restart") == 2 then vim.cmd("restart") else vim.notify("Quit and reopen nvim to apply (in-place restart needs nvim 0.12).") end
    end,
  },
})

function M.open() filter = ""; page:open() end

vim.api.nvim_create_user_command("IDESettings", M.open, { desc = "Open the Settings tab" })
return M
