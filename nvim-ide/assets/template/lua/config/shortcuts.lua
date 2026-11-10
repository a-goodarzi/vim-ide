-- Customizable shortcuts. The VS Code-style keys (vscode_keys.lua) register here instead of calling vim.keymap.set, so a key
-- chosen on the Shortcuts page replaces the default at once and is saved in the settings file (`shortcuts`, default key -> your key).
--   :IDEShortcuts · <Space>uk · "K" on the Settings page · the command palette
local M = { items = {} }
local cfg = require("config")
local ui = require("config.ui")

local group = "General"
function M.group(name) group = name end

local function modes(m) return type(m) == "table" and m or { m } end
local function norm(k) return (k:gsub("<[Mm]%-", "<A-")) end

local function apply_item(it)
  if it.active then for _, m in ipairs(modes(it.mode)) do pcall(vim.keymap.del, m, it.active) end end
  it.active = nil
  local o = (cfg.settings.shortcuts or {})[it.default]
  local lhs = (o == nil) and it.default or o
  if lhs == false or lhs == "" then it.key = nil; return end
  vim.keymap.set(it.mode, lhs, it.rhs, { desc = it.desc, silent = true })
  it.active, it.key = lhs, lhs
end

--- Register a shortcut with its default key and bind it (honouring the user's choice).
function M.bind(mode, default, rhs, desc)
  local it = { mode = mode, default = default, rhs = rhs, desc = desc, group = group }
  M.items[#M.items + 1] = it
  apply_item(it)
end

local function save(it, key)   -- key: string = custom, false = unbound, nil = default
  local ov = cfg.load_overrides()
  ov.shortcuts = type(ov.shortcuts) == "table" and ov.shortcuts or {}
  ov.shortcuts[it.default] = key
  if next(ov.shortcuts) == nil then ov.shortcuts = nil end
  cfg.save_overrides(ov)
  cfg.settings.shortcuts = ov.shortcuts or {}
  apply_item(it)
end

M.set = save   -- (it, key|false|nil)

function M.owner(key, except)
  for _, o in ipairs(M.items) do if o ~= except and o.key == key then return o end end
end

--- Wait for one key press and return it as a mapping string (nil on <Esc>).
local function capture()
  vim.api.nvim_echo({ { "Press the new shortcut (Esc cancels)...", "Question" } }, false, {})
  vim.cmd("redraw")
  local ok, ch = pcall(vim.fn.getcharstr)
  vim.cmd("echo ''")
  if not ok or ch == "\27" then return nil end
  local k = norm(vim.fn.keytrans(ch))
  if k:find("Mouse", 1, true) or k:find("Scroll", 1, true) then return nil end
  return k
end

function M.rebind(it)
  local k = capture()
  if not k then return false end
  local other = M.owner(k, it)
  if other then vim.notify(("%s is already used by \"%s\". Change that one first."):format(k, other.desc), vim.log.levels.WARN); return false end
  save(it, k)
  return true
end
function M.reset(it) save(it, nil) end
function M.unbind(it) save(it, false) end
function M.reset_all()
  local ov = cfg.load_overrides(); ov.shortcuts = nil; cfg.save_overrides(ov); cfg.settings.shortcuts = {}
  for _, it in ipairs(M.items) do apply_item(it) end
end

-- ── page ────────────────────────────────────────────────────────────────────────────────────────
local function label(k) local ok, K = pcall(require, "config.keys"); return ok and K.fmt(k) or k end
local function row_action(fn)
  return function(p)
    local m = p.meta[p:line()]
    if m and m.item then local l = p:line(); fn(m.item); p:render(); p:setcur(l); p:mark() end
  end
end
local page = ui.page({
  name = "Shortcuts", ft = "ide-shortcuts",
  render = function(_, b)
    b:title("Shortcuts", "Enter changes the key of the row, d unbinds it, r restores the default, R restores all, q closes.")
    local last
    for _, it in ipairs(M.items) do
      if it.group ~= last then last = it.group; b:head(it.group, it.group) end
      local chip = " " .. (it.key and label(it.key) or "unbound") .. " "
      local custom = it.key ~= it.default
      local l = b:add(b.margin .. ui.pad(chip, 18) .. "  " .. it.desc .. (custom and ("   (default " .. label(it.default) .. ")") or ""), nil, { item = it })
      b:span(l, #b.margin, #b.margin + #chip, not it.key and "IDEChipErr" or custom and "IDEChipWarn" or "IDEChip")
    end
    b:blank(); b:rule()
    b:add(b.margin .. "Saved in the settings file. Terminals cannot send Ctrl-Shift combinations, and Ctrl-I = Tab, Ctrl-M = Enter.", "IDEMuted")
  end,
  start_line = function(p) for l = 1, #p.lines do if p.meta[l] and p.meta[l].item then return l end end return 1 end,
  select = function(p, line) local m = p.meta[line]; if m and m.item then return line end end,
  click = function(p, _, meta) if meta and meta.item and M.rebind(meta.item) then p:render(); p:mark() end end,
  keys = {
    ["<CR>"] = row_action(M.rebind), d = row_action(M.unbind), r = row_action(M.reset),
    R = function(p) M.reset_all(); p:render(); p:mark() end,
  },
})

function M.open()
  if cfg.feature("vscode_keys") then require("config.vscode_keys") end   -- make sure the list is filled
  page:open()
end
vim.api.nvim_create_user_command("IDEShortcuts", M.open, { desc = "Customize shortcuts" })
return M
