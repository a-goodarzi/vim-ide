-- Shortcut notation. On a Mac the Help page, palette, tour and welcome page show ⌃ ⌥ ⇧ instead of Ctrl / Alt / Shift.
-- Setting `key_style`: "auto" (symbols on macOS only), "mac" or "pc". The keys themselves do not change.
local M = {}

function M.is_mac()
  local style = require("config").settings.key_style or "auto"
  if style == "mac" then return true elseif style == "pc" then return false end
  return (vim.uv or vim.loop).os_uname().sysname == "Darwin"
end

local ARROWS = { Up = "\xe2\x86\x91", Down = "\xe2\x86\x93", Left = "\xe2\x86\x90", Right = "\xe2\x86\x92" }

--- "Alt-e / f / g  ·  Ctrl-Shift-p  ·  Alt-Up" -> "⌥e / f / g  ·  ⌃⇧p  ·  ⌥↑" on a Mac, unchanged elsewhere.
function M.fmt(s)
  if type(s) ~= "string" or not M.is_mac() then return s end
  s = s:gsub("Ctrl%-", "\xe2\x8c\x83"):gsub("Alt%-", "\xe2\x8c\xa5"):gsub("Shift%-", "\xe2\x87\xa7")
  for name, arrow in pairs(ARROWS) do s = s:gsub("(\xe2\x8c\xa5)" .. name, "%1" .. arrow) end
  return s
end

--- Make a page builder format every line it is given (and return it).
function M.wrap(b)
  if not M.is_mac() then return b end
  local add = b.add
  b.add = function(self, text, ...) return add(self, M.fmt(text), ...) end
  return b
end

--- A hint about Option / Meta, shown on a Mac where the Alt-based shortcuts need it.
function M.mac_note()
  if not M.is_mac() then return nil end
  return "\xe2\x8c\xa5 shortcuts need Option sent as Meta: Terminal > Settings > Profiles > Keyboard > Use Option as Meta key (iTerm2: Profiles > Keys > Left Option key = Esc+)."
end

return M
