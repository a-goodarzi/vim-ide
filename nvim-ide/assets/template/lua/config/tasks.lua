-- Task runner: finds the commands a project offers and runs the one you pick in the terminal panel.
-- Sources: Makefile targets, package.json scripts (npm/pnpm/yarn/bun), justfile, go.mod, pyproject/pytest, Cargo.toml, .vscode/tasks.json.
--   palette > "Run task..."   <Space>rt pick · <Space>rr run the last one again      :IDETasks · :IDETaskLast
local M = {}
M.last = nil

local function read(path) local f = io.open(path, "r"); if not f then return nil end local t = f:read("*a"); f:close(); return t end
local function exists(p) return vim.uv.fs_stat(p) ~= nil end

function M.collect(root)
  root = root or vim.fn.getcwd()
  local t = {}
  local function add(src, label, cmd) t[#t + 1] = { src = src, label = label, cmd = cmd } end

  local mk = read(root .. "/Makefile") or read(root .. "/makefile")
  if mk then
    local seen = {}
    for name in mk:gmatch("\n?([%w_%-%.]+)%s*:[^=]") do
      if not seen[name] and not name:find("^%.") then seen[name] = true; add("make", name, "make " .. name) end
    end
  end
  local pj = read(root .. "/package.json")
  if pj then
    local ok, d = pcall(vim.json.decode, pj)
    if ok and type(d.scripts) == "table" then
      local runner = exists(root .. "/pnpm-lock.yaml") and "pnpm" or exists(root .. "/yarn.lock") and "yarn" or (exists(root .. "/bun.lockb") and "bun" or "npm")
      local names = vim.tbl_keys(d.scripts); table.sort(names)
      for _, n in ipairs(names) do add(runner, n, runner .. " run " .. n) end
    end
  end
  local jf = read(root .. "/justfile") or read(root .. "/Justfile")
  if jf then for name in jf:gmatch("\n([%a][%w_%-]*)[^\n:=]*:[^=\n]*\n") do add("just", name, "just " .. name) end end
  if exists(root .. "/go.mod") then
    add("go", "run .", "go run ."); add("go", "test ./...", "go test ./..."); add("go", "build ./...", "go build ./..."); add("go", "vet ./...", "go vet ./...")
  end
  if exists(root .. "/pyproject.toml") or exists(root .. "/pytest.ini") or exists(root .. "/setup.cfg") or exists(root .. "/tox.ini") then
    add("python", "pytest", "pytest")
  end
  if exists(root .. "/Cargo.toml") then add("cargo", "run", "cargo run"); add("cargo", "test", "cargo test"); add("cargo", "build", "cargo build") end
  if exists(root .. "/main.tf") or #vim.fn.glob(root .. "/*.tf", false, true) > 0 then
    add("terraform", "init", "terraform init"); add("terraform", "validate", "terraform validate"); add("terraform", "plan", "terraform plan")
  end
  local vs = read(root .. "/.vscode/tasks.json")
  if vs then
    local ok, d = pcall(vim.json.decode, (vs:gsub("//[^\n]*", "")))
    if ok and type(d.tasks) == "table" then
      for _, tk in ipairs(d.tasks) do if tk.label and tk.command then add("vscode", tk.label, tk.command .. (tk.args and (" " .. table.concat(tk.args, " ")) or "")) end end
    end
  end
  -- the current file, by type
  local file, ft = vim.api.nvim_buf_get_name(0), vim.bo.filetype
  if file ~= "" then
    local q = vim.fn.shellescape(file)
    local per = { python = "python3 ", sh = "bash ", bash = "bash ", javascript = "node ", lua = "nvim -l ", go = "go run " }
    if per[ft] then add("file", "Run this file", per[ft] .. q) end
  end
  return t
end

function M.run(task)
  M.last = task
  local ok = pcall(vim.cmd, "ToggleTerm direction=horizontal")   -- make sure the panel exists, then send the command to it
  local term = require("toggleterm.terminal")
  local t = term.get(1) or term.Terminal:new({ id = 1, direction = "horizontal" })
  if not t:is_open() then t:open() end
  t:send(task.cmd, false)
  if not ok then vim.notify("Terminal panel unavailable", vim.log.levels.WARN) end
end

function M.pick()
  local tasks = M.collect()
  if #tasks == 0 then return vim.notify("No tasks found here (Makefile, package.json, go.mod, pyproject, justfile, .vscode/tasks.json).") end
  vim.ui.select(tasks, { prompt = "Run task", format_item = function(t) return ("%-9s %s"):format(t.src, t.label) end },
    function(c) if c then M.run(c) end end)
end
function M.again()
  if M.last then M.run(M.last) else M.pick() end
end

vim.api.nvim_create_user_command("IDETasks", M.pick, { desc = "Run a project task in the terminal panel" })
vim.api.nvim_create_user_command("IDETaskLast", M.again, { desc = "Run the last task again" })
return M
