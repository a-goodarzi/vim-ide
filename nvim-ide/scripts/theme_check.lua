-- Contrast check for every colour theme.   NVIM_APPNAME=nvim-ide nvim --headless -l scripts/theme_check.lua
-- For each theme (dark / light as the theme decides) it applies the theme, builds the tab bar colours and reports pairs whose
-- contrast is too low. Exit status 1 when any pair is below its minimum.
local theme = require("config.theme")
local cfg = require("config")
cfg.settings.transparent = false
require("config.tabs").setup()

local function lin(c) c = c / 255; return c <= 0.03928 and c / 12.92 or ((c + 0.055) / 1.055) ^ 2.4 end
local function lum(n) return 0.2126 * lin(math.floor(n / 65536) % 256) + 0.7152 * lin(math.floor(n / 256) % 256) + 0.0722 * lin(n % 256) end
local function ratio(a, b) local x, y = lum(a), lum(b); if x < y then x, y = y, x end return (x + 0.05) / (y + 0.05) end
local function hl(name) return vim.api.nvim_get_hl(0, { name = name, link = false }) end

-- { label, fg group, bg group (or "fg"/"bg" of the same group), minimum ratio }
local pairs_ = {
  { "editor text", "Normal", "Normal", 4.5 },
  { "comments", "Comment", "Normal", 2.2 },
  { "line numbers", "LineNr", "Normal", 1.2 },
  { "selected tab", "IDETabSel", "IDETabSel", 4.5 },
  { "idle tab", "IDETabIdle", "IDETabIdle", 3.0 },
  { "tab bar title", "IDETabTitle", "IDETabTitle", 3.0 },
  { "selected tab vs idle tab", "bgsel", "bgidle", 1.05 },
  { "idle tab vs strip", "bgidle", "bgfill", 1.03 },
}
local function color(kind, name)
  if name == "bgsel" then return hl("IDETabSel").bg elseif name == "bgidle" then return hl("IDETabIdle").bg elseif name == "bgfill" then return hl("IDETabFill").bg end
  return hl(name)[kind]
end

local bad, total = 0, 0
for _, name in ipairs(theme.names) do
  theme.apply(name); vim.wait(400); require("config.tabs").apply()
  local dark = vim.o.background == "dark"
  local problems = {}
  for _, p in ipairs(pairs_) do
    local fg, bg
    if p[2]:find("^bg") then fg, bg = color("bg", p[2]), color("bg", p[3]) else fg, bg = color("fg", p[2]), color("bg", p[3]) end
    total = total + 1
    if fg and bg then
      local r = ratio(fg, bg)
      if r < p[4] then problems[#problems + 1] = ("%s %.2f<%.1f"):format(p[1], r, p[4]) end
    else problems[#problems + 1] = p[1] .. " (no colour)" end
  end
  if #problems > 0 then bad = bad + 1 end
  print(("%-22s %-5s %s"):format(name, dark and "dark" or "light", #problems == 0 and "ok" or table.concat(problems, "; ")))
end
print(("\n%d themes, %d with low-contrast pairs (%d pairs checked each)"):format(#theme.names, bad, #pairs_))
vim.cmd(bad == 0 and "qa!" or "cquit")
