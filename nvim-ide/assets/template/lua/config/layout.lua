-- Split and layout controls: split right/below, close split, maximize toggle, equalize, and named saved layouts
-- (which files sit in which splits). Palette: "Split ...", "Layout ...".   :IDELayoutSave [name] · :IDELayoutLoad [name]
local M = {}
local path = vim.fn.stdpath("data") .. "/ide-layouts.json"

local function read() local f = io.open(path, "r"); if not f then return {} end local t = f:read("*a"); f:close(); local ok, d = pcall(vim.json.decode, t); return ok and d or {} end
local function write(t) local f = io.open(path, "w"); if f then f:write(vim.json.encode(t)); f:close() end end

function M.split(dir) vim.cmd(dir == "below" and "split" or "vsplit") end
function M.close_split()
  local n = 0
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_win_get_config(w).relative == "" and vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "ide-activity" then n = n + 1 end
  end
  if n > 1 then vim.cmd("close") else vim.notify("This is the only editor split.") end
end

--- Maximize the current editor split, press again to restore the previous sizes.
function M.maximize()
  if vim.t.ide_maxed then
    vim.cmd(vim.t.ide_maxed); vim.t.ide_maxed = nil
  else
    vim.t.ide_maxed = vim.fn.winrestcmd()
    vim.cmd("wincmd |"); vim.cmd("wincmd _")
  end
end
function M.equalize() vim.cmd("wincmd ="); require("config.activitybar").relayout() end

-- layout tree <-> table. Leaves hold the file shown in the window; sidebars, terminals and pages are skipped.
local function capture(node)
  if node[1] == "leaf" then
    local w = node[2]; local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_win_get_config(w).relative ~= "" or vim.bo[b].buftype ~= "" then return nil end
    local name = vim.api.nvim_buf_get_name(b)
    if name == "" then return nil end
    return { leaf = name, line = vim.api.nvim_win_get_cursor(w)[1] }
  end
  local kids = {}
  for _, c in ipairs(node[2]) do local k = capture(c); if k then kids[#kids + 1] = k end end
  if #kids == 0 then return nil end
  if #kids == 1 then return kids[1] end
  return { kind = node[1], kids = kids }
end
local function build(t)
  if t.leaf then pcall(vim.cmd, "edit " .. vim.fn.fnameescape(t.leaf)); pcall(vim.api.nvim_win_set_cursor, 0, { t.line or 1, 0 }); return end
  for i, k in ipairs(t.kids) do
    if i > 1 then vim.cmd(t.kind == "row" and "rightbelow vsplit" or "rightbelow split") end
    build(k)
  end
end

function M.save(name)
  name = name or "default"
  local tree = capture(vim.fn.winlayout())
  if not tree then return vim.notify("No editor splits to save.", vim.log.levels.WARN) end
  local all = read(); all[name] = tree; write(all)
  vim.notify("Layout saved: " .. name)
end
function M.load(name)
  name = name or "default"
  local t = read()[name]
  if not t then return vim.notify("No saved layout named " .. name, vim.log.levels.WARN) end
  -- keep the sidebar: work in the first editing window, close the other editor splits first
  local keep
  for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
    local b = vim.api.nvim_win_get_buf(w)
    if vim.api.nvim_win_get_config(w).relative == "" and vim.bo[b].buftype == "" and vim.bo[b].filetype ~= "ide-activity" then
      if not keep then keep = w else pcall(vim.api.nvim_win_close, w, true) end
    end
  end
  if keep then vim.api.nvim_set_current_win(keep) end
  build(t); M.equalize()
end
function M.pick_load()
  local names = vim.tbl_keys(read()); table.sort(names)
  if #names == 0 then return vim.notify("No saved layouts yet (Layout: save current).") end
  vim.ui.select(names, { prompt = "Load layout" }, function(c) if c then M.load(c) end end)
end
function M.ask_save() vim.ui.input({ prompt = "Layout name: ", default = "default" }, function(n) if n and n ~= "" then M.save(n) end end) end

vim.api.nvim_create_user_command("IDELayoutSave", function(o) M.save(o.args ~= "" and o.args or nil) end, { nargs = "?" })
vim.api.nvim_create_user_command("IDELayoutLoad", function(o) if o.args ~= "" then M.load(o.args) else M.pick_load() end end, { nargs = "?" })
return M
