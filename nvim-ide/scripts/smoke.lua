-- Headless smoke tests. Run by dev.sh:  NVIM_APPNAME=<name> nvim --headless -l scripts/smoke.lua  (or -c "luafile …")
local fails, passes = {}, 0
local function check(name, cond, detail)
  if cond then passes = passes + 1; print("  ok   " .. name)
  else fails[#fails + 1] = name; print("  FAIL " .. name .. (detail and (" — " .. tostring(detail)) or "")) end
end

vim.cmd("edit /tmp/ide-smoke.py"); vim.wait(1500)
-- load the VeryLazy plugins deterministically (faking the event races with lazy.nvim's own trigger)
require("lazy").load({ plugins = { "which-key.nvim" } }); vim.wait(500)
require("config.statusline").setup()
local cfg = require("config")

for _, m in ipairs({ "snacks", "which-key", "telescope", "neo-tree", "blink.cmp", "conform",
  "lint", "gitsigns", "trouble", "flash", "dap", "neotest", "toggleterm" }) do
  local ok, err = pcall(require, m); check("plugin loads: " .. m, ok, ok or tostring(err):gsub("\n.*", ""))
end
local ok = pcall(function() vim.cmd("Lazy load claudecode.nvim") end); check("plugin loads: claudecode.nvim", ok)

for _, c in ipairs({ "IDESettings", "IDEHelp", "ClaudeCode", "Lazy", "Mason", "Neotree", "ConformInfo" }) do
  check("command :" .. c, vim.fn.exists(":" .. c) == 2)
end

-- language presets resolve for the default set
local want = { lsp = { "basedpyright", "gopls", "terraformls", "bashls", "marksman", "ts_ls", "html", "cssls" },
  parsers = { "python", "go", "terraform", "hcl", "bash", "markdown", "javascript", "html", "css" } }
for field, names in pairs(want) do
  local have = cfg.collect(field)
  for _, n in ipairs(names) do check(field .. " includes " .. n, vim.tbl_contains(have, n)) end
end

-- cheat sheet + settings page open without error
do
  local ok4 = pcall(function() require("config.help").open() end)
  local txt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check("help opens as a tab named Help", ok4 and vim.fn.bufname("%"):find("Help", 1, true) ~= nil and vim.bo.buflisted)
  check("help covers features, commands and shortcuts", txt:find("File browser", 1, true) and txt:find(":IDEUpdate", 1, true)
    and txt:find("Toggle Claude panel", 1, true) and txt:find("Tips", 1, true))
  vim.api.nvim_feedkeys("3", "x", false)
  check("help: number key jumps to Commands", vim.api.nvim_get_current_line():find("Commands", 1, true) ~= nil)
  vim.api.nvim_feedkeys("q", "x", false); vim.wait(200)
end

-- Settings tab: keyboard, mouse, search, section jump; restores the user's saved file afterwards
local path = cfg.override_path
local f = io.open(path, "r"); local backup = f and f:read("*a"); if f then f:close() end
local S = require("config.settings_ui"); S.open()
local function text() return table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n") end
local function line_of(pat) for i, l in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do if l:find(pat, 1, true) then return i end end end
check("settings opens as a tab (listed buffer named Settings)", vim.bo.buflisted and vim.fn.bufname("%"):find("Settings", 1, true) ~= nil)
check("settings shows headlines and descriptions", text():find("Appearance", 1, true) and text():find("Claude Code", 1, true)
  and text():find("═", 1, true) and text():find("applies instantly", 1, true))
local before = cfg.settings.statusline_style
vim.api.nvim_win_set_cursor(0, { line_of("Statusline style"), 0 })
vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false)
check("keyboard toggle changes value", cfg.settings.statusline_style ~= before)
check("keyboard toggle persists to json", (cfg.load_overrides().statusline_style or "") == cfg.settings.statusline_style)
check("changed setting is marked with ●", text():find("● Statusline style", 1, true) ~= nil)
-- mouse (getmousepos is stubbed: headless nvim has no real screen)
local trow = line_of("Transparent background")
local t0 = cfg.settings.transparent
local real, win = vim.fn.getmousepos, vim.api.nvim_get_current_win()
vim.fn.getmousepos = function() return { winid = win, line = trow + 2, column = 8, wincol = 8 } end   -- the control line
local map = vim.fn.maparg("<LeftMouse>", "n", false, true)
if map.callback then map.callback() end
vim.wait(200); vim.fn.getmousepos = real
check("mouse click on a control toggles it", (cfg.settings.transparent or false) ~= (t0 or false))
-- regression: clicking below the content (or on line 0) must never raise "Invalid cursor line"
do
  local real2, win2 = vim.fn.getmousepos, vim.api.nvim_get_current_win()
  local cb = vim.fn.maparg("<LeftMouse>", "n", false, true).callback
  local all_ok = true
  for _, ln in ipairs({ 100000, 0 }) do
    vim.fn.getmousepos = function() return { winid = win2, line = ln, column = 3, wincol = 3 } end
    local ok3 = pcall(cb); all_ok = all_ok and ok3
  end
  vim.fn.getmousepos = real2
  check("clicking below the content does not error", all_ok)
end
-- jump to a section with a number key
vim.api.nvim_feedkeys("4", "x", false)
check("number key jumps to section 4 (Claude Code)", vim.api.nvim_get_current_line():find("Claude Code", 1, true) ~= nil)
-- search
vim.ui.input = function(_, cb) cb("terraform") end
vim.api.nvim_feedkeys("/", "x", false); vim.wait(200)
check("search filters settings", text():find("terraform", 1, true) and not text():find("Statusline style", 1, true))
vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false)
vim.api.nvim_feedkeys("q", "x", false); vim.wait(200)
if backup then local w = io.open(path, "w"); w:write(backup); w:close() else os.remove(path) end

-- VS Code layer: activity bar views and keys
do
  local AB = require("config.activitybar")
  AB.setup()
  check("activity bar window exists", AB.win and vim.api.nvim_win_is_valid(AB.win))
  local function has_ft(ft) for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft then return true end end end
  vim.wait(500)
  AB.show("search"); vim.wait(800)
  check("Search & Replace view opens in the sidebar (grug-far)", has_ft("grug-far"))
  AB.show("search"); vim.wait(300)
  check("clicking the active view again hides it", not has_ft("grug-far"))
  AB.show("explorer"); vim.wait(800)
  check("Explorer view opens", has_ft("neo-tree"))
  check("activity bar stays leftmost", vim.api.nvim_win_get_position(AB.win)[2] == 0)
  for _, lhs in ipairs({ "<F1>", "<C-s>", "<A-b>", "<A-f>", "<F5>", "<F12>", "<A-Down>", "<C-p>" }) do
    check("VS Code key mapped: " .. lhs, vim.fn.maparg(lhs, "n") ~= "" or vim.fn.maparg(lhs, "i") ~= "")
  end
  check("click hooks registered in the shared UI kit", #require("config.ui").hooks > 0)
  -- UI kit: glyph fallbacks and the Plugins tab
  local ui = require("config.ui")
  check("ui kit defines highlight roles", vim.fn.hlexists("IDEHeading") == 1 and vim.fn.hlexists("IDERule") == 1 and vim.fn.hlexists("IDEMuted") == 1)
  check("ui kit glyphs have values", ui.g("on") ~= "" and ui.g("restart") ~= "")
  require("config.plugins_ui").open(); vim.wait(300)
  local ptxt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check("plugins tab opens with actions, plugins and tools", vim.fn.bufname("%"):find("Plugins", 1, true) and ptxt:find("Update all plugins", 1, true)
    and ptxt:find("blink.cmp", 1, true) and ptxt:find("Language tools", 1, true))
  vim.api.nvim_feedkeys("q", "x", false); vim.wait(200)
end

-- layout regressions: pages and sidebars must not break each other
do
  local AB2 = require("config.activitybar")
  local function wins_of(ft) local n = 0 for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == ft then n = n + 1 end end return n end
  local function bar_ok() return AB2.win and vim.api.nvim_win_is_valid(AB2.win) and vim.api.nvim_win_get_width(AB2.win) == 4 and vim.api.nvim_win_get_position(AB2.win)[2] == 0 end
  vim.cmd("only"); AB2.setup(); vim.wait(600); AB2.show("git"); vim.wait(400)  -- (grug-far needs a real UI; the git view uses the same sidebar path)
  check("sidebar next to the bar has a fixed width", (function() for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "neo-tree" then return vim.api.nvim_win_get_width(w) == 34 end end end)())
  local tabs0 = #vim.api.nvim_list_tabpages()
  require("config.settings_ui").open(); vim.wait(200)
  check("settings opened beside the sidebar, not in a new tab", #vim.api.nvim_list_tabpages() == tabs0)
  vim.cmd("q"); vim.wait(500)
  check("closing Settings keeps the IDE and the activity bar intact", wins_of("ide-activity") == 1 and bar_ok() and wins_of("neo-tree") == 1)
  AB2.show("plugins"); require("config.help").open(); vim.wait(200)
  check("Help opened over the Plugins page stays in the same tab", #vim.api.nvim_list_tabpages() == tabs0)
  AB2.show("explorer"); vim.wait(400); vim.cmd("Neotree close"); vim.wait(300)
  check("closing the explorer by command updates the bar state", AB2.active ~= "explorer")
  vim.cmd("Neotree show filesystem left"); vim.wait(500)
  check("explorer opened by command keeps the bar leftmost", bar_ok())
end

-- regressions found by driving the real UI (see references/lessons.md 31-36)
do
  local AB3 = require("config.activitybar")
  local function sidebar_views()
    local seen, n = {}, 0
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
      local v = ({ ["neo-tree"] = "explorer", ["grug-far"] = "search", aerial = "outline", dapui_scopes = "debug" })[ft]
      if v and not seen[v] then seen[v] = true; n = n + 1 end
    end
    return n
  end
  local function editors()
    local n = 0
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local b = vim.api.nvim_win_get_buf(w)
      local ft = vim.bo[b].filetype
      if vim.api.nvim_win_get_config(w).relative == "" and vim.bo[b].buftype ~= "terminal"
        and not ({ ["neo-tree"] = 1, ["ide-activity"] = 1, ["grug-far"] = 1, aerial = 1 })[ft] and not ft:find("^dap") then n = n + 1 end
    end
    return n
  end
  local function layout()
    local o = {}
    for _, w in ipairs(vim.api.nvim_list_wins()) do
      local b = vim.api.nvim_win_get_buf(w)
      o[#o + 1] = (vim.api.nvim_win_get_config(w).relative ~= "" and "float:" or "") .. vim.bo[b].filetype .. "/" .. vim.bo[b].buftype
    end
    return table.concat(o, " ")
  end
  vim.cmd("only"); vim.cmd("enew"); AB3.setup(); vim.wait(300)

  -- window options of a page must stay local: a file opened afterwards keeps numbers and the sign column
  local nu, sc = vim.go.number, vim.go.signcolumn
  require("config.settings_ui").open(); vim.wait(100)
  check("page window options do not leak into the global defaults", vim.go.number == nu and vim.go.signcolumn == sc)
  vim.cmd("edit /tmp/ide-smoke-leak.txt")
  check("a file opened over a page keeps line numbers", vim.wo.number == nu and vim.wo.signcolumn == sc)

  -- opening a second page keeps the first one as a tab
  require("config.settings_ui").open(); require("config.help").open(); vim.wait(100)
  check("opening Help over Settings keeps Settings open as a tab", vim.fn.bufexists("Settings") == 1 and vim.fn.buflisted(vim.fn.bufnr("Settings")) == 1)
  -- and a hidden page can be shown again and still reacts (its window is re-bound)
  vim.cmd("buffer " .. vim.fn.bufnr("Settings")); vim.wait(100)
  check("a hidden page comes back with its window options re-applied", vim.bo.filetype == "ide-settings" and vim.wo.number == false and vim.wo.signcolumn == "no")
  vim.cmd("only"); vim.cmd("enew"); AB3.setup(); vim.wait(300)

  -- :bd on the only editor must leave an editor beside the sidebar, not a stretched sidebar
  AB3.show("git"); vim.wait(500)
  require("config.help").open(); vim.wait(100)
  vim.cmd("bdelete"); vim.wait(400)
  check(":bd of the last editor buffer keeps an editor window beside the sidebar", editors() >= 1, layout())

  -- one sidebar view at a time, whichever path opens it
  AB3.show("git"); vim.wait(400)
  pcall(vim.cmd, "AerialOpen! left"); vim.wait(600)
  check("opening a second sidebar by command closes the first", sidebar_views() == 1, sidebar_views())
  pcall(vim.cmd, "AerialClose")

  -- a page opened over the start dashboard replaces it instead of splitting beside it
  vim.cmd("only"); vim.cmd("enew"); vim.bo.buftype = "nofile"; vim.bo.filetype = "snacks_dashboard"
  local nwin = #vim.api.nvim_list_wins()
  require("config.help").open(); vim.wait(100)
  check("a page opened from the dashboard replaces it (no extra split)", #vim.api.nvim_list_wins() == nwin, #vim.api.nvim_list_wins() .. " vs " .. nwin)

  -- transparent mode keeps the theme's foreground colours (nvim_set_hl replaces the whole group)
  do
    local theme0 = require("config.theme"); local was = cfg.settings.transparent
    cfg.settings.transparent = true; theme0.apply(cfg.settings.colorscheme); vim.wait(100)
    local n = vim.api.nvim_get_hl(0, { name = "Normal", link = false })
    check("transparent mode clears the background but keeps the foreground", n.bg == nil and n.fg ~= nil, vim.inspect(n))
    cfg.settings.transparent = was; theme0.apply(cfg.settings.colorscheme)
  end

  -- the debug sidebar has a fixed width, however often it is opened
  vim.cmd("only"); vim.cmd("enew"); AB3.setup(); vim.wait(300)
  pcall(function() AB3.show("debug"); vim.wait(400); AB3.show("debug"); vim.wait(300); AB3.show("debug"); vim.wait(400) end)
  local dw
  for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "dapui_scopes" then dw = vim.api.nvim_win_get_width(w) end end
  check("debug sidebar keeps its fixed width after reopening", dw == nil or dw == 44, dw)
  pcall(function() if AB3.active == "debug" then AB3.show("debug") end end)

  -- the bar can never keep focus (Ctrl-hjkl / Alt-hjkl / :wincmd)
  vim.cmd("only"); AB3.setup(); vim.wait(300)
  vim.api.nvim_set_current_win(AB3.win); vim.wait(300)
  check("focus is moved off the activity bar", vim.api.nvim_get_current_win() ~= AB3.win)

  -- <C-\> in terminal mode must not shadow <C-\><C-n>
  check("terminal-mode <C-\\> is not mapped (keeps <C-\\><C-n> working)", vim.fn.maparg("<C-\\>", "t") == "")

  -- tabs: long names keep their distinguishing tail, and the strip never overflows the screen
  local T3 = require("config.tabs")
  for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative ~= "" then pcall(vim.api.nvim_win_close, w, true) end end
  vim.cmd("botright vnew"); vim.cmd("only")        -- only a real editor window may be the survivor (not a sidebar)
  local names = {}
  for i = 1, 14 do
    local b = vim.api.nvim_create_buf(true, false); vim.api.nvim_buf_set_name(b, "/tmp/ide-smoke-dir/long_file_name_number_" .. i .. ".txt")
    vim.api.nvim_buf_set_lines(b, 0, -1, false, { "x" }); names[#names + 1] = b
  end
  vim.api.nvim_set_current_buf(names[1])
  local out = T3.render()
  local shown = vim.api.nvim_eval_statusline(out, { use_tabline = true, maxwidth = 10000 }).width
  check("tab strip never overflows the screen width", shown <= vim.o.columns, shown .. " > " .. vim.o.columns)
  vim.api.nvim_set_current_buf(names[#names]); out = T3.render()
  local lbl = vim.api.nvim_eval_statusline(out, { use_tabline = true, maxwidth = 10000 }).str
  check("a long tab name keeps its tail (number_14 vs number_1)", lbl:find("er_14.txt", 1, true) ~= nil, lbl .. " | " .. layout())
  for _, b in ipairs(names) do pcall(vim.api.nvim_buf_delete, b, { force = true }) end
  for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.api.nvim_win_get_config(w).relative ~= "" then pcall(vim.api.nvim_win_close, w, true) end end
  vim.cmd("botright vnew"); vim.cmd("only"); vim.cmd("edit /tmp/ide-smoke.py")
end

-- search results must open in the editor to the right of the sidebar
do
  pcall(function() require("lazy").load({ plugins = { "grug-far.nvim" } }) end)
  local o = require("grug-far").get_instance and require("grug-far.opts").defaults or nil
  local lazy_opts = require("lazy.core.config").plugins["grug-far.nvim"].opts
  local resolved = type(lazy_opts) == "function" and lazy_opts() or lazy_opts or {}
  check("search results open to the right of the sidebar", resolved.openTargetWindow and resolved.openTargetWindow.preferredLocation == "right")
end

-- tabs: the self-written tab bar renders every open file, marks the active one and survives odd buffers
do
  local T = require("config.tabs"); T.setup()
  vim.cmd("edit /tmp/ide-smoke.py"); vim.cmd("enew"); vim.bo.modified = true; vim.api.nvim_buf_set_lines(0, 0, -1, false, { "x" })
  local out = T.render()
  check("tab bar renders tabs with click handlers", out:find("IdeTabClick", 1, true), out:sub(1, 200))
  check("tab bar marks the active tab and unsaved changes", out:find("IDETabSel#", 1, true) ~= nil and out:find("IDETabSelMod", 1, true) ~= nil)
  local function bg(n) return vim.api.nvim_get_hl(0, { name = n, link = false }).bg end
  check("tabs: active, idle and strip use three different backgrounds", bg("IDETabSel") ~= bg("IDETabIdle") and bg("IDETabIdle") ~= bg("IDETabFill"))
  vim.bo.modified = false
end

-- statusline: each style renders its own glyphs (deterministic, no lualine)
local SL = require("config.statusline")
local function style(st) cfg.settings.statusline_style = st; SL.apply(); return SL.render() end
local r, p, pl = style("rounded"), style("powerline"), style("plain")
check("rounded style uses round caps", r:find("\238\130\182", 1, true) and r:find("\238\130\180", 1, true) and not r:find("\238\130\176", 1, true))
check("powerline style uses arrows, no round caps", p:find("\238\130\176", 1, true) and p:find("\238\130\178", 1, true) and not p:find("\238\130\182", 1, true))
local sep = false
for _, g in ipairs({ "\238\130\176", "\238\130\178", "\238\130\180", "\238\130\182" }) do if pl:find(g, 1, true) then sep = true end end
check("plain style has no arrow or cap separators", not sep)
check("statusline renders without error", #SL.render() > 10)

-- every theme loads
local theme = require("config.theme")
for _, n in ipairs(theme.names) do
  local ok2 = pcall(vim.cmd.colorscheme, theme.themes[n][2])
  if not ok2 then check("theme loads: " .. n, false) end
end
check("all " .. #theme.names .. " themes load", true)

-- Curated command palette: every entry has a callable action; user commands it names exist
local pal = require("config.palette")
check("palette has curated entries", #pal.items > 20)
local pbad = {}
for _, it in ipairs(pal.items) do
  if type(it[4]) ~= "function" or it[2] == "" then pbad[#pbad + 1] = it[2] end
end
check("palette entries are well-formed", #pbad == 0, table.concat(pbad, ","))
check("F1 opens the curated palette", (vim.fn.maparg("<F1>", "n", false, true).desc or "") == "Command palette")

print(string.format("\n%d passed, %d failed", passes, #fails))
vim.cmd(#fails == 0 and "qa!" or "cquit")
