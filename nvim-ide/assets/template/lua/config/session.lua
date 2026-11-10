-- Session restore + recent projects (feature: session_restore).
-- On quit, the open files (with cursor lines) of the current folder are saved; starting `ide` with no file in that folder
-- reopens them. "Recent projects" (palette, dashboard `r` key area) lists every folder you worked in.
--   :IDESessionSave · :IDESessionRestore · :IDEProjects
local M = {}
local dir = vim.fn.stdpath("data") .. "/ide-sessions"
local index_path = vim.fn.stdpath("data") .. "/ide-projects.json"

local function read(path)
  local f = io.open(path, "r"); if not f then return nil end
  local txt = f:read("*a"); f:close()
  local ok, d = pcall(vim.json.decode, txt)
  return ok and d or nil
end
local function write(path, tbl)
  vim.fn.mkdir(vim.fn.fnamemodify(path, ":h"), "p")
  local f = io.open(path, "w"); if f then f:write(vim.json.encode(tbl)); f:close() end
end
local function path_for(cwd) return dir .. "/" .. vim.fn.sha256(cwd):sub(1, 16) .. ".json" end

function M.save()
  local cwd = vim.fn.getcwd()
  local files = {}
  for _, b in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
    if b.name ~= "" and vim.bo[b.bufnr].buftype == "" and vim.uv.fs_stat(b.name) then
      files[#files + 1] = { path = b.name, line = b.lnum, pinned = require("config.tabs").pinned[b.bufnr] or nil }
    end
  end
  if #files == 0 then return false end
  local cur = vim.api.nvim_buf_get_name(0)
  write(path_for(cwd), { cwd = cwd, files = files, current = cur, saved = os.time() })
  local idx = read(index_path) or {}
  local out = { { cwd = cwd, last = os.time() } }
  for _, p in ipairs(idx) do if p.cwd ~= cwd and vim.uv.fs_stat(p.cwd) then out[#out + 1] = p end end
  while #out > 30 do table.remove(out) end
  write(index_path, out)
  return true
end

function M.restore(cwd)
  cwd = cwd or vim.fn.getcwd()
  local s = read(path_for(cwd))
  if not (s and s.files) then return false end
  local cur_bufs = {}
  for _, f in ipairs(s.files) do
    if vim.uv.fs_stat(f.path) then
      vim.cmd(("silent badd +%d %s"):format(f.line or 1, vim.fn.fnameescape(f.path)))
      if f.pinned then require("config.tabs").pinned[vim.fn.bufnr(f.path)] = true end
      cur_bufs[#cur_bufs + 1] = f.path
    end
  end
  if #cur_bufs == 0 then return false end
  local target = vim.tbl_contains(cur_bufs, s.current) and s.current or cur_bufs[1]
  vim.cmd("silent edit " .. vim.fn.fnameescape(target))
  return true
end

--- Folders you worked in, newest first (existing ones only).
function M.list()
  local out = {}
  for _, p in ipairs(read(index_path) or {}) do if vim.uv.fs_stat(p.cwd) then out[#out + 1] = p.cwd end end
  return out
end

--- Switch to the project at `c` (saves the current session first).
function M.switch(c)
  M.save()
  vim.cmd("silent! %bwipeout")
  vim.cmd("cd " .. vim.fn.fnameescape(c))
  if not M.restore(c) then vim.cmd("enew") end
  pcall(function() require("neo-tree.command").execute({ action = "show", dir = c, source = "filesystem", position = "left" }) end)
  vim.notify("Opened " .. vim.fn.fnamemodify(c, ":~"))
end

--- Pick a recent project and switch to it.
function M.projects()
  local idx = read(index_path) or {}
  local items = {}
  for _, p in ipairs(idx) do if vim.uv.fs_stat(p.cwd) then items[#items + 1] = p.cwd end end
  if #items == 0 then return vim.notify("No recent projects yet: they are recorded when you quit.") end
  vim.ui.select(items, { prompt = "Recent projects", format_item = function(c) return vim.fn.fnamemodify(c, ":t") .. "   " .. vim.fn.fnamemodify(c, ":~") end },
    function(c)
      if not c then return end
      M.save()
      vim.cmd("silent! %bwipeout")
      vim.cmd("cd " .. vim.fn.fnameescape(c))
      if not M.restore(c) then vim.cmd("enew") end
      pcall(function() require("neo-tree.command").execute({ action = "show", dir = c, source = "filesystem", position = "left" }) end)
      vim.notify("Opened " .. vim.fn.fnamemodify(c, ":~"))
    end)
end

function M.setup()
  local g = vim.api.nvim_create_augroup("ide-session", { clear = true })
  vim.api.nvim_create_autocmd("VimLeavePre", { group = g, callback = function() pcall(M.save) end })
  if vim.fn.argc() == 0 and not vim.env.IDE_NO_SESSION and #vim.api.nvim_list_uis() > 0 then
    vim.defer_fn(function()
      -- only when nothing is open yet (the dashboard or an empty buffer)
      local b = vim.api.nvim_get_current_buf()
      local empty = vim.api.nvim_buf_get_name(b) == "" or vim.bo[b].filetype == "snacks_dashboard"
      if empty and M.restore() then vim.cmd("redrawtabline") end
    end, 500)
  end
end

vim.api.nvim_create_user_command("IDESessionSave", function() vim.notify(M.save() and "Session saved" or "Nothing to save") end, {})
vim.api.nvim_create_user_command("IDESessionRestore", function() if not M.restore() then vim.notify("No saved session for this folder") end end, {})
vim.api.nvim_create_user_command("IDEProjects", M.projects, { desc = "Switch to a recent project" })
return M
