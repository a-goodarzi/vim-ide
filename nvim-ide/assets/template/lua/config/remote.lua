-- Remote work and containers. Neovim is not a remote-IDE client: the supported ways are (1) a shell on the remote machine in
-- the terminal panel (run `ide` there, ideally inside tmux), (2) editing a remote file over scp (netrw), (3) a shell in a
-- running Docker container or the folder's dev container.
--   palette > "Remote: ..."     :IDERemote · :IDEContainers
local M = {}

local function term(cmd)
  pcall(vim.cmd, "ToggleTerm direction=horizontal")
  local T = require("toggleterm.terminal")
  local t = T.get(1) or T.Terminal:new({ id = 1, direction = "horizontal" })
  if not t:is_open() then t:open() end
  t:send(cmd, false)
end

local function ssh_hosts()
  local hosts, f = {}, io.open(vim.fn.expand("~/.ssh/config"), "r")
  if f then
    for l in f:lines() do
      local h = l:match("^%s*[Hh]ost%s+(.+)$")
      if h then for name in h:gmatch("%S+") do if not name:find("[*?!]") then hosts[#hosts + 1] = name end end end
    end
    f:close()
  end
  table.sort(hosts)
  return hosts
end

function M.ssh()
  local hosts = ssh_hosts()
  local function go(h) if h and h ~= "" then term("ssh " .. vim.fn.shellescape(h)) end end
  if #hosts == 0 then return vim.ui.input({ prompt = "ssh to (user@host): " }, go) end
  hosts[#hosts + 1] = "Other..."
  vim.ui.select(hosts, { prompt = "SSH shell (from ~/.ssh/config)" }, function(c)
    if c == "Other..." then vim.ui.input({ prompt = "ssh to (user@host): " }, go) else go(c) end
  end)
end

function M.edit_remote()
  vim.ui.input({ prompt = "Remote file (user@host:/path/file): " }, function(v)
    if not v or v == "" then return end
    local host, p = v:match("^([^:]+):(.+)$")
    if not host then return vim.notify("Use the form user@host:/path/file", vim.log.levels.WARN) end
    vim.cmd("edit scp://" .. host .. "/" .. (p:sub(1, 1) == "/" and "/" .. p:sub(2) or p))
  end)
end

function M.containers()
  if vim.fn.executable("docker") == 0 and vim.fn.executable("podman") == 0 then return vim.notify("docker / podman not found", vim.log.levels.WARN) end
  local bin = vim.fn.executable("docker") == 1 and "docker" or "podman"
  local out = vim.fn.systemlist({ bin, "ps", "--format", "{{.Names}}\t{{.Image}}" })
  if vim.v.shell_error ~= 0 or #out == 0 then return vim.notify("No running containers (" .. bin .. " ps is empty).") end
  vim.ui.select(out, { prompt = "Shell in container" }, function(c)
    if c then term(bin .. " exec -it " .. vim.fn.shellescape(c:match("^[^\t]+")) .. " sh -c 'exec bash || exec sh'") end
  end)
end

--- Shell in this folder's dev container (needs the `devcontainer` CLI).
function M.devcontainer()
  if vim.uv.fs_stat(vim.fn.getcwd() .. "/.devcontainer/devcontainer.json") == nil and vim.uv.fs_stat(vim.fn.getcwd() .. "/.devcontainer.json") == nil then
    return vim.notify("No .devcontainer/devcontainer.json in this folder.", vim.log.levels.WARN)
  end
  if vim.fn.executable("devcontainer") == 0 then return vim.notify("Install the CLI: npm i -g @devcontainers/cli", vim.log.levels.WARN) end
  term("devcontainer up --workspace-folder . && devcontainer exec --workspace-folder . bash")
end

function M.pick()
  local items = {
    { "SSH shell...", M.ssh }, { "Edit a remote file over scp...", M.edit_remote },
    { "Shell in a running container...", M.containers }, { "Shell in this folder's dev container", M.devcontainer },
  }
  vim.ui.select(items, { prompt = "Remote", format_item = function(i) return i[1] end }, function(c) if c then c[2]() end end)
end

vim.api.nvim_create_user_command("IDERemote", M.pick, { desc = "SSH, remote files, containers" })
vim.api.nvim_create_user_command("IDEContainers", M.containers, {})
return M
