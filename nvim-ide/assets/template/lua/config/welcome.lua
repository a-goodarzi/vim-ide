-- First-run welcome: checks that icons render, runs the doctor and lists the first keys to learn.
-- Shown once (flag file in the data dir) when features.welcome is on; reopen with :IDEWelcome or the palette.
--   y icons look fine · n they are boxes (switch to plain text) · d doctor · h help · s settings · q close
local M = {}
local ui = require("config.ui")
local cfg = require("config")

local function flag_path() return vim.env.IDE_WELCOME_FLAG or (vim.fn.stdpath("data") .. "/ide-first-run") end
local function seen() return vim.uv.fs_stat(flag_path()) ~= nil end
local function mark_seen()
  vim.fn.mkdir(vim.fn.fnamemodify(flag_path(), ":h"), "p")
  local f = io.open(flag_path(), "w"); if f then f:write("seen\n"); f:close() end
end

local function set_icons(on)
  local o = cfg.load_overrides()
  o.features = o.features or {}
  if on then o.features.icons = nil else o.features.icons = false end
  cfg.save_overrides(o)
  cfg.settings.features.icons = on
  vim.notify(on and "Icons stay on." or "Icons off: plain text everywhere. Restart nvim (or press A in Settings) to apply.")
end

local page = ui.page({
  name = "Welcome", ft = "ide-welcome",
  render = function(_, b)
    local keys = require("config.keys"); keys.wrap(b)
    b:title("Welcome to nvim-ide", "A short first-run check. q closes this; :IDEWelcome brings it back.")
    b:head("1  Do the icons look right?", 1)
    b:add(b.margin .. "   \xee\x9c\xa5   \xef\x80\x82   \xef\x85\x9b   \xef\x84\xa0   \xee\x82\xb2\xee\x82\xb0   \xee\x82\xba\xee\x82\xb8", "IDEAccent")
    b:add(b.margin .. "You should see a git branch, a magnifier, a file, a terminal prompt and two arrow shapes.", "IDEMuted")
    b:add(b.margin .. "Boxes or question marks mean your terminal font is not a Nerd Font.", "IDEMuted")
    b:blank()
    b:add(b.margin .. "y   They look fine", "IDEKey", { act = "y" })
    b:add(b.margin .. "n   They are boxes: use plain text instead (no font needed)", "IDEKey", { act = "n" })
    b:add(b.margin .. "    Get a font: https://www.nerdfonts.com  (then set it in your terminal profile)", "IDEMuted")

    b:head("2  Tools", 2)
    local res, cmd = require("config.doctor").run()
    local s = require("config.doctor").summary(res)
    if s.fail + s.warn == 0 then b:add(b.margin .. "All required tools were found.", "IDEOn")
    else
      b:add(b.margin .. ("%d need attention:"):format(s.fail + s.warn), "IDEWarn")
      for _, r in ipairs(res) do if r.level ~= "ok" then b:add(b.margin .. "  " .. r.name .. " - " .. r.detail) end end
      if cmd ~= "" then b:add(b.margin .. "  " .. cmd, "IDEKey") end
    end
    b:add(b.margin .. "d   Open the full Doctor", "IDEKey", { act = "d" })

    b:head("3  First keys", 3)
    for _, k in ipairs({
      { "F1", "Command palette: everything the IDE can do" }, { "Ctrl-P", "Open a file by name" },
      { "Alt-f", "Search & Replace in the project" }, { "Alt-g", "Source Control: stage, commit, push" },
      { "Alt-t", "Terminal panel" }, { "Alt-c", "Claude Code panel" }, { "<Space>", "Pause after it: a menu lists every shortcut" },
    }) do b:add(b.margin .. ui.pad(keys.fmt(k[1]), 9) .. " " .. k[2], nil, { keycol = true }) end
    if keys.mac_note() then b:blank(); b:add(b.margin .. keys.mac_note(), "IDEWarn") end
    b:blank()
    b:add(b.margin .. "t   Take a one-minute tour", "IDEKey", { act = "t" })
    b:add(b.margin .. "h   Full Help       s   Settings       q   Close", "IDEKey")
  end,
  sections = { "Icons", "Tools", "First keys" },
  keys = {
    y = function(p) set_icons(true); p:close() end,
    n = function(p) set_icons(false); p:close() end,
    d = function(p) p:close(); require("config.doctor").open() end,
    t = function(p) p:close(); vim.schedule(function() require("config.tour").start() end) end,
    h = function(p) p:close(); require("config.help").open() end,
    s = function(p) p:close(); require("config.settings_ui").open() end,
  },
  click = function(p, _, meta) if meta and meta.act and p.spec.keys[meta.act] then p.spec.keys[meta.act](p) end end,
})

function M.open() mark_seen(); page:open() end

--- Called once at start-up.
function M.maybe_show()
  if not cfg.feature("welcome") or vim.env.IDE_NO_WELCOME or vim.env.IDE_SETTINGS_ONLY then return end
  if #vim.api.nvim_list_uis() == 0 or seen() then return end
  M.open()
end

return M
