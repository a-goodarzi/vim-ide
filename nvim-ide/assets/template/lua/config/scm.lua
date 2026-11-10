-- Source Control sidebar (activity bar > Source Control, Alt-g): branch, commit box, staged / changed / untracked files with
-- stage, unstage, discard, commit, push, pull, branch switch and diff. Plain git underneath (async), no extra plugin needed;
-- the diff of a file uses gitsigns when it is loaded.
--   click a file / Enter  open its diff        + / - / x at the right edge  stage / unstage / discard
--   s u x on a file       stage / unstage / discard      S U   all        m  commit message      c  commit
--   P pull  p push  b branches  r refresh  i git init (when not a repo)  ?  list these keys
local ui = require("config.ui")
local M = {}
M.win, M.buf, M.root, M.msg = nil, nil, nil, ""
M.state = { branch = "", ahead = 0, behind = 0, staged = {}, changed = {}, untracked = {}, repo = true }
local meta = {}
local ns = vim.api.nvim_create_namespace("ide-scm")
local FT = "idescm"   -- no "ide-" prefix: that prefix marks full-screen pages, which count as editing windows

local function icons() return require("config").icons() end
local function valid() return M.buf and vim.api.nvim_buf_is_valid(M.buf) end
local function visible() return M.win and vim.api.nvim_win_is_valid(M.win) end
local function width() return visible() and vim.api.nvim_win_get_width(M.win) or 38 end

local function git(args, cb, cwd)
  local cmd = vim.list_extend({ "git" }, args)
  vim.system(cmd, { cwd = cwd or M.root or vim.fn.getcwd(), text = true,
    env = { GIT_TERMINAL_PROMPT = "0", GIT_ASKPASS = "true", SSH_ASKPASS_REQUIRE = "never", LC_ALL = "C" } },
    function(r) vim.schedule(function() cb(r) end) end)
end
local function say(msg, lvl) vim.notify(msg, lvl or vim.log.levels.INFO, { title = "Source Control" }) end

-- ── data ──────────────────────────────────────────────────────────────────────────────────────────
local function parse(out)
  local st = { branch = "", ahead = 0, behind = 0, staged = {}, changed = {}, untracked = {}, repo = true }
  for line in out:gmatch("[^\n]+") do
    if line:sub(1, 2) == "##" then
      local b = line:sub(4)
      st.ahead = tonumber(b:match("ahead (%d+)")) or 0
      st.behind = tonumber(b:match("behind (%d+)")) or 0
      b = b:gsub("%s*%[.*%]$", ""):gsub("%.%.%..*$", ""):gsub("^No commits yet on ", ""):gsub("^Initial commit on ", "")
      st.branch = b
    else
      local x, y, path = line:sub(1, 1), line:sub(2, 2), line:sub(4)
      path = path:gsub("^.* %-> ", ""):gsub('^"(.*)"$', "%1")
      if x == "?" then st.untracked[#st.untracked + 1] = { path = path, code = "?" }
      else
        if x ~= " " and x ~= "U" then st.staged[#st.staged + 1] = { path = path, code = x } end
        if y ~= " " or x == "U" then st.changed[#st.changed + 1] = { path = path, code = y ~= " " and y or x } end
      end
    end
  end
  return st
end

local render
function M.refresh(cb)
  git({ "rev-parse", "--show-toplevel" }, function(r)
    if r.code ~= 0 then M.root = nil; M.state = { repo = false, staged = {}, changed = {}, untracked = {} }; render(); if cb then cb() end; return end
    M.root = vim.trim(r.stdout)
    git({ "status", "--porcelain=v1", "-b", "--untracked-files=all" }, function(s)
      M.state = parse(s.stdout or ""); render(); if cb then cb() end
    end, M.root)
  end, vim.fn.getcwd())
end

-- ── drawing ───────────────────────────────────────────────────────────────────────────────────────
local CODE_HL = { M = "IDEWarn", A = "IDEOn", D = "DiagnosticError", R = "IDEInfo", C = "IDEInfo", U = "DiagnosticError", ["?"] = "IDEOn" }

render = function()
  if not valid() then return end
  local W, lines, hls = width(), {}, {}
  meta = {}
  local function add(text, hl, m)
    lines[#lines + 1] = text; meta[#lines] = m
    if hl then hls[#hls + 1] = { #lines, 0, -1, hl } end
    return #lines
  end
  local function span(row, from, to, hl) hls[#hls + 1] = { row, from, to, hl } end
  local g = icons()
  local s = M.state
  if not s.repo then
    add("")
    add("  Not a git repository", "IDEHeading")
    add("")
    add("  Press i (or click here) to run", "IDEMuted", { kind = "init" })
    add("  git init in " .. vim.fn.fnamemodify(vim.fn.getcwd(), ":t"), "IDEMuted", { kind = "init" })
  else
    local head = "  " .. (g and "\xee\x9c\xa5 " or "") .. (s.branch ~= "" and s.branch or "(detached)")
    if s.ahead > 0 then head = head .. "  \xe2\x86\x91" .. s.ahead end
    if s.behind > 0 then head = head .. " \xe2\x86\x93" .. s.behind end
    add(head, "IDEHeading", { kind = "branch" })
    add("")
    local msg = M.msg ~= "" and M.msg or "Commit message (click or press m)"
    add("  " .. (g and "\xef\x81\x84 " or "> ") .. ui.pad(msg, W - 6), M.msg ~= "" and "Normal" or "IDEMuted", { kind = "msg" })
    local br = add("")
    local btn, col, spans = "  ", 2, {}
    for _, b in ipairs({ { "Commit", "commit" }, { "Pull", "pull" }, { "Push", "push" } }) do
      local label = "[ " .. b[1] .. " ]"
      spans[#spans + 1] = { from = col, to = col + #label, act = b[2] }
      hls[#hls + 1] = { br, col, col + #label, "IDEKey" }
      btn = btn .. label .. " "; col = col + #label + 1
    end
    lines[br] = btn; meta[br] = { kind = "buttons", spans = spans }

    local function section(title, list, staged)
      if #list == 0 then return end
      add("")
      local r = add(("  %s (%d)"):format(title, #list), "IDEHeading", { kind = "section", staged = staged })
      for _, f in ipairs(list) do
        local base, dir = vim.fn.fnamemodify(f.path, ":t"), vim.fn.fnamemodify(f.path, ":h")
        local left = ("  %s %s"):format(f.code, base)
        local row = add("", nil, { kind = "file", file = f, staged = staged })
        local dirtxt = dir ~= "." and ("  " .. dir) or ""
        local actions = staged and "\xe2\x88\x92" or (f.code == "?" and "+  \xc3\x97" or "+  \xc3\x97")
        lines[row] = ui.pad(left .. dirtxt, W - 6) .. actions
        span(row, 2, 3, CODE_HL[f.code] or "Normal")
        span(row, #left, #left + #dirtxt, "IDEMuted")
        span(row, #lines[row] - #actions, -1, "IDEMuted")
      end
    end
    section("Staged Changes", s.staged, true)
    section("Changes", s.changed, false)
    section("Untracked", s.untracked, false)
    if #s.staged + #s.changed + #s.untracked == 0 then add(""); add("  Working tree clean", "IDEMuted") end
    add(""); add("  ? shows the keys", "IDEMuted")
  end
  vim.bo[M.buf].modifiable = true
  vim.api.nvim_buf_set_lines(M.buf, 0, -1, false, lines)
  vim.bo[M.buf].modifiable = false
  vim.api.nvim_buf_clear_namespace(M.buf, ns, 0, -1)
  for _, h in ipairs(hls) do pcall(vim.api.nvim_buf_add_highlight, M.buf, ns, h[4], h[1] - 1, h[2], h[3]) end
end

-- ── actions ───────────────────────────────────────────────────────────────────────────────────────
local function after(r, ok_msg)
  if r.code ~= 0 then say(vim.trim((r.stderr ~= "" and r.stderr or r.stdout) or "git failed"), vim.log.levels.ERROR)
  elseif ok_msg then say(ok_msg) end
  M.refresh()
end
local function entry(line) return meta[line or vim.api.nvim_win_get_cursor(M.win)[1]] end
local function file_here() local e = entry(); return e and e.kind == "file" and e or nil end

function M.stage(e) git({ "add", "--", e.file.path }, after) end
function M.unstage(e) git({ "reset", "-q", "--", e.file.path }, after) end
function M.discard(e)
  local f = e.file
  local what = f.code == "?" and "Delete the untracked file " or "Discard changes in "
  if vim.fn.confirm(what .. f.path .. "?", "&Yes\n&No", 2) ~= 1 then return end
  if f.code == "?" then git({ "clean", "-fq", "--", f.path }, after) else git({ "restore", "--", f.path }, after) end
end
function M.stage_all() git({ "add", "-A" }, after) end
function M.unstage_all() git({ "reset", "-q" }, after) end

function M.edit_message()
  vim.ui.input({ prompt = "Commit message: ", default = M.msg }, function(v)
    if v ~= nil then M.msg = v; render() end
  end)
end
function M.commit()
  local function go()
    if vim.trim(M.msg) == "" then return say("Write a commit message first (m).", vim.log.levels.WARN) end
    git({ "commit", "-m", M.msg }, function(r)
      if r.code == 0 then M.msg = "" end
      after(r, r.code == 0 and "Committed" or nil)
    end)
  end
  if #M.state.staged == 0 then
    if #M.state.changed + #M.state.untracked == 0 then return say("Nothing to commit.", vim.log.levels.WARN) end
    if vim.fn.confirm("Nothing is staged. Stage all changes and commit?", "&Yes\n&No", 1) ~= 1 then return end
    return git({ "add", "-A" }, function() M.refresh(go) end)
  end
  if vim.trim(M.msg) == "" then
    return vim.ui.input({ prompt = "Commit message: " }, function(v) if v and vim.trim(v) ~= "" then M.msg = v; go() end end)
  end
  go()
end
function M.push()
  say("Pushing...")
  local function run(args) git(args, function(r) after(r, "Pushed") end) end
  if M.state.branch ~= "" and M.state.ahead == 0 and M.state.behind == 0 then
    git({ "rev-parse", "--abbrev-ref", "@{u}" }, function(u)
      if u.code ~= 0 then run({ "push", "-u", "origin", M.state.branch }) else run({ "push" }) end
    end)
  else run({ "push" }) end
end
function M.pull() say("Pulling..."); git({ "pull", "--ff-only" }, function(r) after(r, "Up to date") end) end
function M.branches()
  git({ "branch", "--format=%(refname:short)" }, function(r)
    local items = vim.split(vim.trim(r.stdout or ""), "\n", { trimempty = true })
    items[#items + 1] = "+ New branch..."
    vim.ui.select(items, { prompt = "Switch branch" }, function(c)
      if not c then return end
      if c:sub(1, 1) == "+" then
        vim.ui.input({ prompt = "New branch name: " }, function(n) if n and n ~= "" then git({ "checkout", "-b", n }, after) end end)
      else git({ "checkout", c }, function(x) after(x); vim.cmd("checktime") end) end
    end)
  end)
end
function M.init() git({ "init" }, function(r) after(r, "Initialized an empty repository") end, vim.fn.getcwd()) end

--- The window files should open in: first normal editing window, else a new column on the right.
local function editor_win()
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_win_get_config(w).relative == "" and vim.bo[b].buftype == "" and w ~= M.win and vim.bo[b].filetype ~= "ide-activity" then return w end
  end
  vim.cmd("botright vnew"); return vim.api.nvim_get_current_win()
end

function M.open(e, diff)
  local f, path = e.file, M.root .. "/" .. e.file.path
  vim.api.nvim_set_current_win(editor_win())
  vim.cmd("diffoff!")
  vim.cmd("edit " .. vim.fn.fnameescape(path))
  if diff and f.code ~= "?" and f.code ~= "A" then
    vim.defer_fn(function()
      local ok, gs = pcall(require, "gitsigns")
      if ok then pcall(gs.diffthis, e.staged and "HEAD" or nil) end
    end, 200)
  end
end

local function run_button(act)
  if act == "commit" then M.commit() elseif act == "pull" then M.pull() elseif act == "push" then M.push() end
end

-- A click: buttons, the action glyphs at the right edge of a file row, or the row itself (opens the diff).
local function click(line, wincol)
  local e = entry(line); if not e then return end
  pcall(vim.api.nvim_win_set_cursor, M.win, { line, 0 })
  local W = width()
  if e.kind == "buttons" then
    for _, s in ipairs(e.spans) do if wincol - 1 >= s.from and wincol - 1 < s.to then return run_button(s.act) end end
  elseif e.kind == "branch" then M.branches()
  elseif e.kind == "msg" then M.edit_message()
  elseif e.kind == "init" then M.init()
  elseif e.kind == "section" then if e.staged then M.unstage_all() elseif wincol >= W - 4 then M.stage_all() end
  elseif e.kind == "file" then
    if wincol >= W - 6 and wincol <= W - 4 then if e.staged then M.unstage(e) else M.stage(e) end
    elseif wincol >= W - 3 and not e.staged then M.discard(e)
    else M.open(e, true) end
  end
end

local KEYS = {
  { "Enter / click", "Open the file's diff" }, { "o", "Open the file" }, { "s / u / x", "Stage / unstage / discard the file" },
  { "S / U", "Stage all / unstage all" }, { "m", "Edit the commit message" }, { "c", "Commit (offers to stage all)" },
  { "p / P", "Push / pull" }, { "b", "Switch or create a branch" }, { "r", "Refresh" }, { "i", "git init (not a repo)" },
}

function M.show_keys()
  local out = {}
  for _, k in ipairs(KEYS) do out[#out + 1] = ("%-14s %s"):format(k[1], k[2]) end
  say(table.concat(out, "\n"))
end

-- ── window ────────────────────────────────────────────────────────────────────────────────────────
function M.is_open() return visible() end

function M.open_panel()
  if visible() then vim.api.nvim_set_current_win(M.win); return end
  local cur = vim.api.nvim_get_current_win()
  vim.cmd("topleft 38vsplit")
  M.win = vim.api.nvim_get_current_win()
  M.buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_win_set_buf(M.win, M.buf)
  vim.bo[M.buf].buftype = "nofile"; vim.bo[M.buf].bufhidden = "wipe"; vim.bo[M.buf].swapfile = false
  vim.bo[M.buf].filetype = FT; vim.bo[M.buf].modifiable = false; vim.bo[M.buf].buflisted = false
  ui.setwo(M.win, { number = false, relativenumber = false, signcolumn = "no", foldcolumn = "0", cursorline = true, wrap = false,
    list = false, winfixwidth = true, spell = false, statusline = " ", scrolloff = 0 })
  local k = function(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = M.buf, nowait = true, silent = true }) end
  local on_file = function(fn) return function() local e = file_here(); if e then fn(e) end end end
  k("<CR>", function() click(vim.api.nvim_win_get_cursor(M.win)[1], 1) end)
  k("o", on_file(function(e) M.open(e, false) end))
  k("s", on_file(M.stage)); k("u", on_file(M.unstage)); k("x", on_file(M.discard))
  k("S", M.stage_all); k("U", M.unstage_all); k("m", M.edit_message); k("c", M.commit)
  k("p", M.push); k("P", M.pull); k("b", M.branches); k("r", function() M.refresh() end); k("i", M.init); k("?", M.show_keys)
  k("q", function() require("config.activitybar").show("git") end)
  ui.install_click_handler()
  if not M._hooked then
    M._hooked = true
    table.insert(ui.hooks, function(m)
      if M.win and m.winid == M.win and m.line and m.line >= 1 then
        vim.schedule(function() click(m.line, m.wincol) end); return true
      end
    end)
    local grp = vim.api.nvim_create_augroup("IdeScm", { clear = true })
    vim.api.nvim_create_autocmd({ "BufWritePost", "FocusGained", "ShellCmdPost", "TermClose", "DirChanged" }, { group = grp,
      callback = function() if visible() then M.refresh() end end })
    vim.api.nvim_create_autocmd("User", { group = grp, pattern = "GitSignsUpdate", callback = function() if visible() then M.refresh() end end })
  end
  if vim.api.nvim_win_is_valid(cur) then vim.api.nvim_set_current_win(cur) end
  render(); M.refresh()
end

function M.close_panel()
  if visible() and #vim.api.nvim_list_wins() > 1 then pcall(vim.api.nvim_win_close, M.win, true) end
  M.win = nil
end

M.FT = FT
return M
