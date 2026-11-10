-- Safe updates: the plugin lockfile is saved before every update, the changes are listed afterwards, and a bad update can be undone.
--   :IDEUpdate (<Space>pU, `ide update`)  update plugins and tools, then list what changed
--   :IDEUpdateReport                       list what the last update changed
--   :IDERollback (`ide rollback`)          put the saved lockfile back and restore those plugin versions
-- Backups live in <data>/ide-lock-backups (the newest 10 are kept). The lockfile itself is lazy-lock.json next to the config.
local M = {}

local function lockfile() return vim.fn.stdpath("config") .. "/lazy-lock.json" end
local function dir() return vim.fn.stdpath("data") .. "/ide-lock-backups" end

local function read_json(path)
  local f = io.open(path, "r"); if not f then return nil end
  local ok, d = pcall(vim.json.decode, f:read("*a")); f:close()
  return ok and type(d) == "table" and d or nil
end
local function out(msg) if #vim.api.nvim_list_uis() == 0 then io.stdout:write(msg .. "\n") else vim.notify(msg, vim.log.levels.INFO, { title = "Update" }) end end

function M.backups()
  local list = vim.fn.glob(dir() .. "/lazy-lock-*.json", false, true)
  table.sort(list)
  return list
end

--- Save the current lockfile. Returns the path, or nil when there is no lockfile yet.
function M.snapshot()
  if not vim.uv.fs_stat(lockfile()) then return nil end
  vim.fn.mkdir(dir(), "p")
  local path = ("%s/lazy-lock-%s.json"):format(dir(), os.date("%Y%m%d-%H%M%S"))
  local ok = vim.uv.fs_copyfile(lockfile(), path)
  if not ok then return nil end
  local all = M.backups()
  while #all > 10 do os.remove(table.remove(all, 1)) end
  return path
end

--- Compare two lockfile tables: { added = {...}, removed = {...}, changed = { {name, old, new} } }.
function M.diff(old, new)
  local d = { added = {}, removed = {}, changed = {} }
  for name, v in pairs(new or {}) do
    local o = old and old[name]
    if not o then d.added[#d.added + 1] = name
    elseif o.commit ~= v.commit then d.changed[#d.changed + 1] = { name, (o.commit or "?"):sub(1, 7), (v.commit or "?"):sub(1, 7) } end
  end
  for name in pairs(old or {}) do if not (new and new[name]) then d.removed[#d.removed + 1] = name end end
  table.sort(d.added); table.sort(d.removed); table.sort(d.changed, function(a, b) return a[1] < b[1] end)
  return d
end

function M.format(d)
  if #d.added + #d.removed + #d.changed == 0 then return "No plugin changes." end
  local lines = {}
  for _, c in ipairs(d.changed) do lines[#lines + 1] = ("  updated  %s  %s -> %s"):format(c[1], c[2], c[3]) end
  for _, n in ipairs(d.added) do lines[#lines + 1] = "  added    " .. n end
  for _, n in ipairs(d.removed) do lines[#lines + 1] = "  removed  " .. n end
  return ("%d updated, %d added, %d removed:\n%s"):format(#d.changed, #d.added, #d.removed, table.concat(lines, "\n"))
end

--- What changed since the newest backup.
function M.report()
  local b = M.backups()
  if #b == 0 then return out("No saved lockfile yet: run an update first.") end
  out(M.format(M.diff(read_json(b[#b]), read_json(lockfile()))) .. "\nUndo with :IDERollback (or `ide rollback`).")
end

--- Put the newest backup back and restore the plugins to those versions.
function M.rollback()
  local b = M.backups()
  if #b == 0 then return out("Nothing to roll back: no saved lockfile.") end
  local newest = b[#b]
  local d = M.diff(read_json(lockfile()), read_json(newest))
  vim.uv.fs_copyfile(newest, lockfile())
  os.remove(newest)      -- one rollback per backup: the next one goes one step further back
  out("Rolling back " .. vim.fn.fnamemodify(newest, ":t") .. "\n" .. M.format(d))
  vim.cmd(#vim.api.nvim_list_uis() == 0 and "Lazy! restore" or "Lazy restore")
end

--- Snapshot, update plugins and tools, then show the changes.
function M.update_all()
  M.snapshot()
  if #vim.api.nvim_list_uis() == 0 then
    vim.cmd("Lazy! update"); pcall(vim.cmd, "MasonToolsUpdate"); M.report()
    return
  end
  vim.api.nvim_create_autocmd("User", { pattern = "LazyUpdate", once = true, callback = function() vim.schedule(M.report) end })
  vim.cmd("Lazy update"); pcall(vim.cmd, "MasonToolsUpdate")
end

vim.api.nvim_create_user_command("IDEUpdateReport", M.report, { desc = "List what the last update changed" })
vim.api.nvim_create_user_command("IDERollback", M.rollback, { desc = "Undo the last update (lockfile + plugins)" })
return M
