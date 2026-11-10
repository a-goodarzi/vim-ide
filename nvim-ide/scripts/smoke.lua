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
check("changed setting is marked as changed on its card", (function() local l = vim.api.nvim_buf_get_lines(0, line_of("Statusline style") - 1, line_of("Statusline style"), false)[1] or "" return l:find("changed", 1, true) ~= nil end)())
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
  vim.cmd("only"); AB2.setup(); vim.wait(600); if AB2.active ~= "explorer" then AB2.show("explorer") end; vim.wait(400)  -- (grug-far needs a real UI; the explorer uses the same sidebar path)
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

-- Debugger option: the Run & Debug icon and palette group follow features.debug
do
  local has_debug = false
  for _, v in ipairs(require("config.activitybar").views) do if v.id == "debug" then has_debug = true end end
  check("Run & Debug icon follows features.debug", has_debug == cfg.feature("debug"))
  local pal_debug = false
  for _, it in ipairs(require("config.palette").items) do if it[1] == "Debug" then pal_debug = true end end
  check("palette Debug group follows features.debug", pal_debug == cfg.feature("debug"))
end

-- Source Control panel (scm) on a scratch repo
do
  local ABv = require("config.activitybar")
  local dir = vim.fn.tempname(); vim.fn.mkdir(dir, "p")
  local oldcwd = vim.fn.getcwd()
  vim.env.GIT_AUTHOR_NAME, vim.env.GIT_AUTHOR_EMAIL, vim.env.GIT_COMMITTER_NAME, vim.env.GIT_COMMITTER_EMAIL = "t", "t@example.com", "t", "t@example.com"
  vim.fn.system({ "git", "-C", dir, "init", "-q", "-b", "main" })
  vim.fn.writefile({ "hello" }, dir .. "/a.txt")
  vim.cmd("cd " .. vim.fn.fnameescape(dir))
  local scm = require("config.scm")
  ABv.setup(); vim.wait(300)
  ABv.show("git"); vim.wait(2500, function() return scm.root == vim.uv.fs_realpath(dir) and #scm.state.untracked == 1 end)   -- the repo this test runs in may have untracked files of its own
  check("scm lists an untracked file", #scm.state.untracked == 1)
  scm.stage({ file = { path = "a.txt", code = "?" } })
  vim.wait(1500, function() return #scm.state.staged == 1 end)
  check("scm stage moves the file to Staged", #scm.state.staged == 1)
  scm.msg = "first"; scm.commit()
  vim.wait(2500, function() return #scm.state.staged == 0 and scm.msg == "" end)
  check("scm commit empties the staged list", #scm.state.staged == 0 and #scm.state.untracked == 0)
  check("scm commit exists in git log", vim.fn.system({ "git", "-C", dir, "log", "--oneline" }):find("first") ~= nil)
  vim.fn.writefile({ "hello", "again" }, dir .. "/a.txt")
  scm.refresh(); vim.wait(1500, function() return #scm.state.changed == 1 end)
  check("scm lists a modified file", #scm.state.changed == 1)
  check("scm sidebar counts as a sidebar for the tab bar", vim.bo[scm.buf].filetype == "idescm" and scm.is_open())
  ABv.show("git"); vim.wait(300)
  check("activity bar closes the scm panel", not scm.is_open())
  vim.cmd("cd " .. vim.fn.fnameescape(oldcwd))
end

-- Doctor and first-run welcome
do
  local doc = require("config.doctor")
  local res, cmd = doc.run()
  check("doctor reports neovim and git", #res >= 5 and res[1].name == "Neovim" and type(cmd) == "string")
  vim.env.IDE_WELCOME_FLAG = vim.fn.tempname()
  require("config.welcome").open(); vim.wait(300)
  check("welcome page opens and is marked seen", vim.bo.filetype == "ide-welcome" and vim.uv.fs_stat(vim.env.IDE_WELCOME_FLAG) ~= nil)
  vim.cmd("IDEDoctor"); vim.wait(300)
  check("doctor page opens", vim.bo.filetype == "ide-doctor")
  vim.cmd("enew")
end

-- Session restore: save and restore a file list
do
  local pd = vim.fn.tempname(); vim.fn.mkdir(pd, "p")
  vim.fn.writefile({ "1" }, pd .. "/one.txt"); vim.fn.writefile({ "2" }, pd .. "/two.txt")
  vim.cmd("cd " .. vim.fn.fnameescape(pd)); vim.cmd("edit one.txt"); vim.cmd("edit two.txt")
  local S = require("config.session")
  check("session saves open files", S.save() == true)
  vim.cmd("silent! %bwipeout!"); vim.cmd("enew")
  check("session restores them", S.restore() == true and vim.fn.bufnr(pd .. "/one.txt") > 0)
  check("command :IDEProjects exists", vim.fn.exists(":IDEProjects") == 2)
end

-- Tab features: pin, order, step, right-click menu
do
  local pd = vim.fn.tempname(); vim.fn.mkdir(pd, "p")
  vim.fn.writefile({ "1" }, pd .. "/one.txt"); vim.fn.writefile({ "2" }, pd .. "/two.txt")
  local T = require("config.tabs")
  vim.cmd("edit " .. pd .. "/one.txt"); local b1 = vim.api.nvim_get_current_buf()
  vim.cmd("edit " .. pd .. "/two.txt"); local b2 = vim.api.nvim_get_current_buf()
  T.toggle_pin(b2)
  check("pinned tab is marked", T.pinned[b2] == true)
  T.close(b2)
  check("a pinned tab does not close", vim.api.nvim_buf_is_valid(b2) and vim.bo[b2].buflisted)
  T.toggle_pin(b2); T.move(b2, -1)
  check("tab move changes the order", #T.order >= 2)
  vim.cmd("buffer " .. b1); T.step(1)
  check("tab step goes to the next tab", vim.api.nvim_get_current_buf() ~= b1)
  local ok_menu = pcall(T.menu, b1); vim.wait(100)
  check("tab right-click menu opens", ok_menu and vim.api.nvim_win_get_config(0).relative ~= "")
  vim.api.nvim_feedkeys(vim.keycode("<Esc>"), "x", false); vim.wait(100)
  check("tab menu closes with Esc", vim.api.nvim_win_get_config(0).relative == "")
end

-- Splits and layouts: save and load a split layout
do
  local pd = vim.fn.tempname(); vim.fn.mkdir(pd, "p")
  vim.fn.writefile({ "1" }, pd .. "/one.txt"); vim.fn.writefile({ "2" }, pd .. "/two.txt")
  local L = require("config.layout")
  vim.cmd("only"); vim.cmd("edit " .. pd .. "/one.txt"); L.split("right"); vim.cmd("edit " .. pd .. "/two.txt")
  L.save("smoke"); vim.cmd("only"); L.load("smoke"); vim.wait(100)
  local eds = 0
  for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].buftype == "" then eds = eds + 1 end end
  check("a saved layout restores both splits", eds >= 2, eds)
  vim.cmd("only")
end

-- Task runner: finds make targets, npm scripts and go commands
do
  local pd = vim.fn.tempname(); vim.fn.mkdir(pd, "p")
  vim.fn.writefile({ "build:", "\techo hi", "test: build", "\techo t" }, pd .. "/Makefile")
  vim.fn.writefile({ '{"scripts":{"dev":"vite","lint":"eslint ."}}' }, pd .. "/package.json")
  vim.fn.writefile({ "module x" }, pd .. "/go.mod")
  local labels = {}
  for _, t in ipairs(require("config.tasks").collect(pd)) do labels[t.src .. ":" .. t.label] = t.cmd end
  check("tasks finds make targets", labels["make:build"] == "make build" and labels["make:test"] == "make test", vim.inspect(labels))
  check("tasks finds npm scripts", labels["npm:dev"] == "npm run dev" and labels["npm:lint"] == "npm run lint")
  check("tasks finds go commands", labels["go:test ./..."] == "go test ./...")
  check("command :IDETasks exists", vim.fn.exists(":IDETasks") == 2)
end

-- Explorer actions are wired into neo-tree
do
  local ea = require("config.explorer_actions")
  check("explorer actions are wired into neo-tree", ea.mappings.T == "terminal_here" and type(ea.commands.copy_path) == "function")
  ea.copy_path("/tmp/one.txt", false)
  check("explorer copy path fills the register", vim.fn.getreg('"'):find("one.txt", 1, true) ~= nil)
end

-- Snippet browser lists the snippets of the file type
do
  vim.cmd("enew"); vim.bo.filetype = "lua"
  local real_select, nsn = vim.ui.select, 0
  vim.ui.select = function(items) nsn = #items end
  pcall(require("config.assist").snippets)
  vim.ui.select = real_select
  check("snippet browser lists lua snippets", nsn > 0, nsn)
  check("command :IDESnippets exists", vim.fn.exists(":IDESnippets") == 2)
end

-- Remote module and commands
do
  check("remote module loads", type(require("config.remote").pick) == "function")
  check("commands :IDERemote and :IDELayoutLoad exist", vim.fn.exists(":IDERemote") == 2 and vim.fn.exists(":IDELayoutLoad") == 2)
end

-- Smarter palette: recents first, tasks / projects / themes as entries
do
  local pal = require("config.palette")
  local es = pal.entries()
  local themes = 0
  for _, it in ipairs(es) do if it[1] == "Theme" then themes = themes + 1 end end
  check("palette has one entry per theme", themes == #require("config.theme").names, themes)
  check("palette keeps the raw Vim commands last", es[#es][2] == "All Vim commands...")
  local f = io.open(vim.fn.stdpath("data") .. "/ide-palette-recent.json", "r")
  local keep = f and f:read("*a"); if f then f:close() end
  local w = io.open(vim.fn.stdpath("data") .. "/ide-palette-recent.json", "w"); w:write(vim.json.encode({ "File|Save" })); w:close()
  check("palette lists the most recently used entry first", pal.entries()[1][1] == "Recent" and pal.entries()[1][2] == "Save")
  if keep then local r = io.open(vim.fn.stdpath("data") .. "/ide-palette-recent.json", "w"); r:write(keep); r:close()
  else os.remove(vim.fn.stdpath("data") .. "/ide-palette-recent.json") end
end

-- Right-click menus: item lists, the generic menu and mouse hook
do
  local CM = require("config.context_menu")
  check("editor context menu has LSP and clipboard rows", #CM.editor_items(false) >= 8 and #CM.editor_items(true) > #CM.editor_items(false))
  vim.cmd("enew")
  local ui = require("config.ui")
  local hit = 0
  local win = ui.menu({ { "One", function() hit = 1 end }, "-", { "Two", function() hit = 2 end } }, { row = 2, col = 2 })
  vim.wait(50)
  check("ui.menu opens a floating menu", vim.api.nvim_win_get_config(win).relative == "editor")
  vim.api.nvim_feedkeys(vim.keycode("jj<CR>"), "x", false); vim.wait(200)
  check("ui.menu skips separators and runs the chosen row", hit == 2, hit)
  CM.setup()
  check("right-click is mapped", vim.fn.maparg("<RightMouse>", "n", false, true).desc == "Context menu")
end

-- Guided tour
do
  local tour = require("config.tour")
  vim.cmd("enew"); tour.start(); vim.wait(100)
  check("tour opens at step 1 as a float", tour.is_open() and tour.step() == 1 and vim.api.nvim_win_get_config(0).relative == "editor")
  vim.api.nvim_feedkeys(vim.keycode("<CR><CR><CR><CR>"), "x", false); vim.wait(100)
  check("tour reaches step 5", tour.step() == 5)
  vim.api.nvim_feedkeys(vim.keycode("<CR>"), "x", false); vim.wait(100)
  check("tour closes after the last step", not tour.is_open())
  check("command :IDETour exists", vim.fn.exists(":IDETour") == 2)
end

-- Themes: a dark theme after a light one stays dark; solarized-osaka follows the transparent setting
do
  local th = require("config.theme")
  local was_t = cfg.settings.transparent; cfg.settings.transparent = false
  th.apply("tokyonight-day"); vim.wait(200)
  check("a light theme sets a light background", vim.o.background == "light")
  th.apply("gruvbox"); vim.wait(200)
  check("a dark theme after a light one is dark again", vim.o.background == "dark")
  th.apply("solarized-osaka"); vim.wait(300)
  check("solarized-osaka has a background when transparent is off", vim.api.nvim_get_hl(0, { name = "Normal", link = false }).bg ~= nil)
  cfg.settings.transparent = was_t; th.apply(cfg.settings.colorscheme)
end

-- Tab style option: each style renders and the flat style has no powerline glyphs
do
  local T = require("config.tabs")
  local was = cfg.settings.tabs_style
  for _, st in ipairs({ "slanted", "rounded", "flat" }) do
    cfg.settings.tabs_style = st
    local out = T.render()
    check("tab bar renders in the " .. st .. " style", type(out) == "string" and out:find("IdeTabClick", 1, true) ~= nil)
    if st == "flat" then check("flat tabs use no powerline glyphs", not out:find("\xee\x82", 1, true)) end
    if st == "rounded" then check("rounded tabs use the pill glyphs", out:find("\xee\x82\xb6", 1, true) ~= nil) end
  end
  cfg.settings.tabs_style = was
end

-- Known issues fixed: the Plugins icon toggles its page off; the minimap steps aside for pages
do
  local ABp = require("config.activitybar")
  vim.cmd("only"); vim.cmd("enew")
  ABp.setup(); vim.wait(600)
  ABp.show("plugins"); vim.wait(500)
  local function plugin_win() for _, w in ipairs(vim.api.nvim_list_wins()) do if vim.bo[vim.api.nvim_win_get_buf(w)].filetype == "ide-plugins" then return true end end return false end
  check("Plugins icon opens the Plugins page", plugin_win() and ABp.active == "plugins")
  ABp.show("plugins"); vim.wait(500)
  check("clicking the active Plugins icon closes the page", not plugin_win() and ABp.active == nil)
  vim.cmd("only")
end

-- Safe updates: lockfile diff, formatting and snapshot
do
  local U = require("config.updater")
  local d = U.diff({ a = { commit = "1111111aaa" }, b = { commit = "2222222bbb" }, gone = { commit = "3" } },
                   { a = { commit = "9999999zzz" }, b = { commit = "2222222bbb" }, new = { commit = "4" } })
  check("updater lists updated, added and removed plugins", #d.changed == 1 and d.changed[1][2] == "1111111" and d.changed[1][3] == "9999999" and d.added[1] == "new" and d.removed[1] == "gone")
  check("updater formats a readable summary", U.format(d):find("1 updated, 1 added, 1 removed", 1, true) ~= nil and U.format({ added = {}, removed = {}, changed = {} }) == "No plugin changes.")
  local snap = U.snapshot()
  check("updater saves a copy of the lockfile", snap == nil or vim.uv.fs_stat(snap) ~= nil)
  if snap then os.remove(snap) end
  check("commands :IDERollback and :IDEUpdateReport exist", vim.fn.exists(":IDERollback") == 2 and vim.fn.exists(":IDEUpdateReport") == 2)
end

-- Doctor package names: on macOS the tree-sitter CLI is the "tree-sitter-cli" formula
do
  local P = require("config.doctor").packages
  check("doctor names the tree-sitter CLI package for Homebrew", P["tree-sitter"].brew == "tree-sitter-cli" and P["tree-sitter"].dnf == "tree-sitter-cli")
end

-- The ide launcher: version and update usage
do
  local launcher = vim.fn.stdpath("config") .. "/extras/ide"
  local v = vim.fn.system({ "bash", launcher, "version" })
  check("ide version prints the version and nvim", v:find("vim%-ide") ~= nil and v:find("NVIM") ~= nil, v)
  vim.fn.system({ "bash", launcher, "update", "bogus" })
  check("ide update rejects an unknown mode", vim.v.shell_error == 2)
end

-- Shortcut notation: macOS symbols on a Mac (or key_style = "mac"), unchanged elsewhere
do
  local K = require("config.keys")
  local was = cfg.settings.key_style
  cfg.settings.key_style = "mac"
  check("mac notation converts Alt, Ctrl and Shift", K.fmt("Alt-e / f / g") == "\xe2\x8c\xa5e / f / g" and K.fmt("Ctrl-Shift-p") == "\xe2\x8c\x83\xe2\x87\xa7p")
  check("mac notation converts Alt-arrows", K.fmt("Alt-Up") == "\xe2\x8c\xa5\xe2\x86\x91")
  require("config.help").open(); vim.wait(300)
  local txt = table.concat(vim.api.nvim_buf_get_lines(0, 0, -1, false), "\n")
  check("the Help page shows mac symbols and the Option note", txt:find("\xe2\x8c\xa5", 1, true) ~= nil and txt:find("Use Option as Meta", 1, true) ~= nil and not txt:find("Alt%-e"))
  vim.cmd("bdelete!")
  cfg.settings.key_style = "pc"
  check("pc notation leaves shortcuts alone", K.fmt("Alt-e / Ctrl-P") == "Alt-e / Ctrl-P")
  cfg.settings.key_style = was
end

-- Finding tools outside nvim's PATH: extra folders and the login-shell lookup
do
  local P = require("config.path")
  local d = vim.fn.tempname(); vim.fn.mkdir(d, "p")
  local tool = d .. "/faketool-xyz"
  vim.fn.writefile({ "#!/bin/sh", "echo hi" }, tool); vim.fn.setfperm(tool, "rwxr-xr-x")
  local fakesh = d .. "/fakesh"      -- a "shell" that prints a banner and then the tool's location, like `command -v` in a login shell
  vim.fn.writefile({ "#!/bin/sh", "echo 'welcome banner'", "echo " .. tool }, fakesh); vim.fn.setfperm(fakesh, "rwxr-xr-x")
  check("path.add appends an existing folder once", P.add(d) == true and P.add(d) == false)
  vim.env.PATH = vim.env.PATH:gsub(":" .. vim.pesc(d), "")
  check("a tool outside PATH is not found by nvim itself", vim.fn.executable("faketool-xyz") == 0)
  check("path.find asks the login shell and puts the folder on PATH", P.find("faketool-xyz", { shell = fakesh }) == tool and vim.fn.executable("faketool-xyz") == 1)
  check("the extra_path setting is applied", type(P.apply_extra) == "function")
end

-- Agent status: hook settings, hook script, event handling and the spool watcher
do
  local A = require("config.agent")
  local js = vim.json.decode(A.settings_json())
  check("agent settings carry the hooks", js.hooks and js.hooks.Stop and js.hooks.Notification and js.hooks.UserPromptSubmit and js.hooks.PreToolUse)
  check("agent command passes the spool and settings", A.command():find("IDE_AGENT_SPOOL=", 1, true) ~= nil and A.command():find("--settings", 1, true) ~= nil)
  check("the hook script is executable", vim.fn.executable(A.hook_path()) == 1)
  -- the hook script appends the event to the spool
  local spool = vim.fn.tempname()
  vim.fn.system({ "bash", "-c", "printf '%s' '{\"hook_event_name\":\"Stop\"}' | IDE_AGENT_SPOOL=" .. spool .. " " .. A.hook_path() })
  local lines = vim.fn.readfile(spool)
  check("the hook script writes one timestamped line per event", #lines == 1 and lines[1]:match("^%d+\t{") ~= nil, vim.inspect(lines))
  vim.fn.system({ "bash", "-c", "echo '{}' | env -u IDE_AGENT_SPOOL " .. A.hook_path() })
  check("the hook script does nothing outside the IDE", vim.v.shell_error == 0)
  -- state machine
  local real_notify, notes = vim.notify, {}
  vim.notify = function(m) notes[#notes + 1] = m end
  A.handle("100\t" .. vim.json.encode({ hook_event_name = "UserPromptSubmit" }))
  check("a prompt makes the status working", A.state.status == "working")
  A.handle("101\t" .. vim.json.encode({ hook_event_name = "PreToolUse", tool_name = "Edit" }))
  check("a tool call shows the tool name", A.state.tool == "Edit")
  A.handle("102\t" .. vim.json.encode({ hook_event_name = "Notification", notification_type = "permission_prompt", message = "Claude needs your permission to use Bash" }))
  check("a permission prompt means waiting and notifies", A.state.status == "waiting" and #notes == 1 and notes[1]:find("needs you", 1, true) ~= nil)
  A.handle("103\t" .. vim.json.encode({ hook_event_name = "Stop", last_assistant_message = "All done.\nSecond line" }))
  check("stop means done with a short message", A.state.status == "done" and A.state.message == "All done. Second line" and #notes == 2)
  A.handle("104\t" .. vim.json.encode({ hook_event_name = "SessionEnd" }))
  check("session end clears the status", A.state.status == "none")
  vim.notify = real_notify
  check("the statusline segment shows a finished session", (function() A.state.status, A.state.since = "done", os.time(); local s = A.segment(true, { pos = 1, warn = 2, lsp = 3 }); A.state.status = "none"; return s ~= nil and s.text:find("done", 1, true) ~= nil end)())
  -- the watcher picks up lines appended to the real spool
  A.start()
  local f = io.open(A.spool, "a"); f:write("200\t" .. vim.json.encode({ hook_event_name = "UserPromptSubmit" }) .. "\n"); f:close()
  vim.wait(2000, function() return A.state.status == "working" end)
  check("the spool watcher applies appended events", A.state.status == "working")
  A.state.status = "none"
  vim.cmd("IDEAgent"); vim.wait(200)
  check("the activity log page opens", vim.bo.filetype == "ide-agent")
  vim.cmd("bdelete!")
end

-- Undo agent turns: checkpoints in a scratch repository
do
  local CP = require("config.checkpoints")
  local d = vim.fn.tempname(); vim.fn.mkdir(d, "p")
  local function sh(...) return vim.fn.system({ "git", "-C", d, "-c", "user.name=t", "-c", "user.email=t@example.com", ... }) end
  sh("init", "-q", "-b", "main")
  vim.fn.writefile({ "one" }, d .. "/a.txt"); vim.fn.writefile({ "keep" }, d .. "/c.txt")
  sh("add", "-A"); sh("commit", "-qm", "init")
  vim.fn.writefile({ "my uncommitted edit" }, d .. "/a.txt")
  local before_index = sh("status", "--porcelain")
  local ref = CP.create(d, "agent: before \"test\"")
  check("a checkpoint is recorded as a ref", ref ~= nil and ref:find("refs/ide-checkpoints/", 1, true) ~= nil, ref)
  check("recording a checkpoint leaves the index and files alone", sh("status", "--porcelain") == before_index)
  -- the agent edits a file, adds one and deletes one
  vim.fn.writefile({ "agent edit" }, d .. "/a.txt"); vim.fn.writefile({ "new" }, d .. "/b.txt"); os.remove(d .. "/c.txt")
  local ch = CP.changes_since(d, ref)
  local by = {}
  for _, c in ipairs(ch) do by[c.path] = c.status end
  check("changes since a checkpoint list M, A and D", by["a.txt"] == "M" and by["b.txt"] == "A" and by["c.txt"] == "D", vim.inspect(by))
  CP.restore(d, ref, { confirm = false })
  check("restoring brings back the edited file", vim.fn.readfile(d .. "/a.txt")[1] == "my uncommitted edit")
  check("restoring removes files the agent added", vim.uv.fs_stat(d .. "/b.txt") == nil)
  check("restoring brings back deleted files", vim.fn.readfile(d .. "/c.txt")[1] == "keep")
  local list = CP.list(d)
  check("a restore records a safety checkpoint so it can be redone", list[1] and list[1].message:find("^safety") ~= nil)
  -- the hook script checkpoints on UserPromptSubmit
  local spool = vim.fn.tempname()
  local payload = vim.json.encode({ hook_event_name = "UserPromptSubmit", cwd = d, prompt = "fix the bug" })
  local n0 = #CP.list(d)
  vim.fn.system({ "bash", "-c", "printf '%s' '" .. payload .. "' | IDE_AGENT_SPOOL=" .. spool .. " IDE_AGENT_CHECKPOINT=1 " .. require("config.agent").hook_path() })
  local after = CP.list(d)
  check("the hook records a checkpoint before a prompt", #after == n0 + 1 and after[1].message:find("fix the bug", 1, true) ~= nil, after[1] and after[1].message)
  check("commands :IDEUndoTurn and :IDECheckpoints exist", vim.fn.exists(":IDEUndoTurn") == 2 and vim.fn.exists(":IDECheckpoints") == 2)
end

print(string.format("\n%d passed, %d failed", passes, #fails))
vim.cmd(#fails == 0 and "qa!" or "cquit")
