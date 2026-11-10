-- Undo an agent turn. Before every prompt you send to Claude (hook), the whole working tree is recorded as a git commit under
-- refs/ide-checkpoints/ (see extras/ide-checkpoint: your index, branch and stash are untouched). Then:
--   undo the last agent turn   put the files back as they were before it (files Claude added are removed; asks first)
--   redo                       undo the undo: every restore first records a "safety" checkpoint
--   checkpoints...             pick any checkpoint and restore it
--   <Space>au undo · :IDEUndoTurn :IDERedoTurn :IDECheckpoints
local M = {}

local function script() return vim.fn.stdpath("config") .. "/extras/ide-checkpoint" end
local function git(root, args, env)
  return vim.system(vim.list_extend({ "git", "-C", root }, args), { text = true, env = env }):wait()
end
local function toplevel(dir)
  local r = vim.system({ "git", "-C", dir or vim.fn.getcwd(), "rev-parse", "--show-toplevel" }, { text = true }):wait()
  return r.code == 0 and vim.trim(r.stdout) or nil
end

--- Record a checkpoint now. Returns the ref (or nil outside a git repository).
function M.create(dir, message)
  local r = vim.system({ script(), dir or vim.fn.getcwd(), message or "checkpoint" }, { text = true }):wait()
  local ref = vim.trim(r.stdout or ""):match("refs/ide%-checkpoints/%S+")
  return ref
end

--- Checkpoints of the repository, newest first: { ref, ts, message }.
function M.list(dir)
  local root = toplevel(dir); if not root then return {}, nil end
  local r = git(root, { "for-each-ref", "--sort=-refname", "--format=%(refname)%09%(committerdate:unix)%09%(subject)", "refs/ide-checkpoints" })
  local out = {}
  for line in (r.stdout or ""):gmatch("[^\n]+") do
    local ref, ts, msg = line:match("^(%S+)\t(%d+)\t(.*)$")
    if ref then out[#out + 1] = { ref = ref, ts = tonumber(ts), message = msg } end
  end
  return out, root
end

--- Files that differ between a checkpoint and the working tree: { { status = "M"|"A"|"D", path }, ... }
--- (status is from the checkpoint's point of view: "A" = added since, "D" = deleted since).
function M.changes_since(root, ref)
  local idx = vim.fn.tempname()
  local env = { GIT_INDEX_FILE = idx }
  local head = git(root, { "rev-parse", "-q", "--verify", "HEAD" })
  if head.code == 0 then git(root, { "read-tree", vim.trim(head.stdout) }, env) end
  git(root, { "add", "-A" }, env)
  local now = git(root, { "write-tree" }, env)
  os.remove(idx)
  if now.code ~= 0 then return {} end
  local d = git(root, { "diff-tree", "-r", "--name-status", "--no-renames", ref, vim.trim(now.stdout) })
  local out = {}
  for line in (d.stdout or ""):gmatch("[^\n]+") do
    local st, path = line:match("^(%a)\t(.+)$")
    if st then out[#out + 1] = { status = st, path = path } end
  end
  return out
end

local function summary(changes)
  local c = { M = 0, A = 0, D = 0 }
  for _, ch in ipairs(changes) do c[ch.status] = (c[ch.status] or 0) + 1 end
  return ("%d changed, %d added (will be removed), %d deleted (will come back)"):format(c.M, c.A, c.D)
end

--- Put the working tree back as it was at `ref`. opts.confirm = false skips the question (tests).
function M.restore(root, ref, opts)
  opts = opts or {}
  local changes = M.changes_since(root, ref)
  if #changes == 0 then vim.notify("Nothing to restore: the files already match that checkpoint."); return true end
  if opts.confirm ~= false then
    local names = {}
    for i = 1, math.min(#changes, 8) do names[#names + 1] = changes[i].status .. " " .. changes[i].path end
    if vim.fn.confirm(("Restore the files to the checkpoint?\n%s\n\n%s%s"):format(summary(changes), table.concat(names, "\n"), #changes > 8 and "\n..." or ""), "&Yes\n&No", 2) ~= 1 then return false end
  end
  M.create(root, "safety: before restoring")     -- so the restore itself can be undone
  for _, ch in ipairs(changes) do
    local path = root .. "/" .. ch.path
    if ch.status == "A" then os.remove(path)
    else git(root, { "restore", "--source=" .. ref, "--worktree", "--", ch.path }) end
  end
  vim.cmd("silent! checktime")
  vim.notify("Restored " .. #changes .. " file(s) from the checkpoint. Redo with :IDERedoTurn.")
  return true
end

local function newest(prefix, dir)
  local list, root = M.list(dir)
  for _, cp in ipairs(list) do if cp.message:find("^" .. prefix) then return cp, root end end
  return nil, root
end

function M.undo_turn() local cp, root = newest("agent", nil); if not cp then return vim.notify("No agent checkpoint yet: they are recorded when you send Claude a prompt (in this repository).") end M.restore(root, cp.ref) end
function M.redo_turn() local cp, root = newest("safety", nil); if not cp then return vim.notify("Nothing to redo.") end M.restore(root, cp.ref) end

function M.pick()
  local list, root = M.list()
  if #list == 0 then return vim.notify("No checkpoints in this repository yet.") end
  vim.ui.select(list, { prompt = "Restore a checkpoint", format_item = function(cp) return os.date("%H:%M:%S", cp.ts) .. "  " .. cp.message end },
    function(cp) if cp then M.restore(root, cp.ref) end end)
end

vim.api.nvim_create_user_command("IDEUndoTurn", M.undo_turn, { desc = "Undo the last Claude turn (restore the files)" })
vim.api.nvim_create_user_command("IDERedoTurn", M.redo_turn, { desc = "Redo: undo the undo" })
vim.api.nvim_create_user_command("IDECheckpoints", M.pick, { desc = "Pick a checkpoint to restore" })
return M
