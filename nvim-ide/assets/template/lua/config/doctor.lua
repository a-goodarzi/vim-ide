-- Doctor: checks the tools the IDE needs and prints the exact install command for this system.
--   :IDEDoctor  or  Command palette > Doctor.   r re-run · y copy the install command · q close
local M = {}
local ui = require("config.ui")

local function have(x) return vim.fn.executable(x) == 1 end

local function os_kind()
  local sys = (vim.uv or vim.loop).os_uname().sysname
  if sys == "Darwin" then return "brew" end
  local f = io.open("/etc/os-release", "r")
  local txt = f and f:read("*a") or ""; if f then f:close() end
  local id = (txt:match("\nID=([%w_%-\"]+)") or txt:match("^ID=([%w_%-\"]+)") or ""):gsub('"', "")
  local like = (txt:match("ID_LIKE=([^\n]+)") or ""):gsub('"', "")
  local all = id .. " " .. like
  if all:find("fedora") or all:find("rhel") then return "dnf" end
  if all:find("debian") or all:find("ubuntu") then return "apt" end
  if all:find("arch") then return "pacman" end
  if all:find("suse") then return "zypper" end
  return "other"
end

-- tool -> package per package manager (nil = not in the distro repos, use `npm`)
local PKG = {
  nvim = { brew = "neovim", dnf = "neovim", apt = "neovim", pacman = "neovim", zypper = "neovim" },
  git = { brew = "git", dnf = "git", apt = "git", pacman = "git", zypper = "git" },
  make = { brew = "make", dnf = "make", apt = "make", pacman = "make", zypper = "make" },
  gcc = { brew = "gcc", dnf = "gcc", apt = "gcc", pacman = "gcc", zypper = "gcc" },
  rg = { brew = "ripgrep", dnf = "ripgrep", apt = "ripgrep", pacman = "ripgrep", zypper = "ripgrep" },
  node = { brew = "node", dnf = "nodejs", apt = "nodejs", pacman = "nodejs", zypper = "nodejs" },
  ["tree-sitter"] = { brew = "tree-sitter-cli", dnf = "tree-sitter-cli", pacman = "tree-sitter-cli" },
}
M.packages = PKG   -- exposed for the smoke test
local INSTALL = { brew = "brew install ", dnf = "sudo dnf install -y ", apt = "sudo apt install -y ",
  pacman = "sudo pacman -S --needed ", zypper = "sudo zypper install -y ", other = "" }

--- Returns { { level = "ok"|"warn"|"fail", name, detail, tool? }, ... } and the install command for what is missing.
function M.run()
  local cfg = require("config")
  local res, mgr, pkgs, npm = {}, os_kind(), {}, {}
  local function add(level, name, detail, tool) res[#res + 1] = { level = level, name = name, detail = detail, tool = tool } end
  local function need(tool, name, level)
    if have(tool) then return add("ok", name, "found") end
    add(level, name, "not found", tool)
    local p = PKG[tool] and PKG[tool][mgr]
    if p then pkgs[#pkgs + 1] = p elseif tool == "tree-sitter" then npm[#npm + 1] = "tree-sitter-cli" end
  end
  local v = vim.version()
  if v.major > 0 or v.minor >= 11 then add("ok", "Neovim", ("%d.%d.%d"):format(v.major, v.minor, v.patch))
  else add("fail", "Neovim", ("%d.%d is too old, need 0.11 or newer"):format(v.major, v.minor), "nvim") end
  need("git", "git", "fail"); need("make", "make", "fail")
  if have("gcc") or have("cc") then add("ok", "C compiler", "found") else need("gcc", "C compiler (gcc)", "fail") end
  need("rg", "ripgrep (search)", "fail"); need("node", "Node.js (language servers)", "fail"); need("tree-sitter", "tree-sitter CLI", "warn")
  if cfg.feature("claude") then
    if have("claude") then add("ok", "Claude Code CLI", "found")
    else add("warn", "Claude Code CLI", "not found: the Claude panel stays empty", "claude"); npm[#npm + 1] = "@anthropic-ai/claude-code" end
  end
  if vim.env.TMUX then
    local tf = vim.fn.system({ "tmux", "show", "-sv", "terminal-features" }) .. vim.fn.system({ "tmux", "show", "-sv", "terminal-overrides" })
    if tf:find("RGB") or tf:find("Tc") then add("ok", "tmux true colour", "configured")
    else add("warn", "tmux true colour", "add the lines from extras/tmux.conf, otherwise colours look washed out") end
  end
  if vim.o.termguicolors then add("ok", "True colour", "on") else add("warn", "True colour", "termguicolors is off: use a modern terminal") end
  local cmd = ""
  if #pkgs > 0 and mgr ~= "other" then cmd = INSTALL[mgr] .. table.concat(pkgs, " ") end
  if #npm > 0 then cmd = cmd .. (cmd ~= "" and "  &&  " or "") .. "npm i -g " .. table.concat(npm, " ") end
  return res, cmd
end

--- { fail = n, warn = n, ok = n }
function M.summary(res)
  local c = { ok = 0, warn = 0, fail = 0 }
  for _, r in ipairs(res) do c[r.level] = c[r.level] + 1 end
  return c
end

local last_cmd = ""
local page = ui.page({
  name = "Doctor", ft = "ide-doctor",
  render = function(_, b)
    local res, cmd = M.run(); last_cmd = cmd
    local s = M.summary(res)
    b:title("Doctor", "What the IDE needs. r re-runs the check, y copies the install command, q closes.")
    local sym = { ok = "\xe2\x9c\x93", warn = "!", fail = "\xe2\x9c\x97" }
    local hl = { ok = "IDEOn", warn = "IDEWarn", fail = "DiagnosticError" }
    for _, r in ipairs(res) do b:add(("%s%s  %-30s %s"):format(b.margin, sym[r.level], r.name, r.detail), hl[r.level]) end
    b:blank()
    if cmd ~= "" then
      b:add(b.margin .. "Install what is missing:", "IDEHeading"); b:add(b.margin .. "  " .. cmd, "IDEKey"); b:add(b.margin .. "  (y copies it)", "IDEMuted")
    elseif s.fail + s.warn == 0 then b:add(b.margin .. "Everything is in place.", "IDEOn")
    else b:add(b.margin .. "Install the missing tools with your package manager.", "IDEMuted") end
    b:blank()
    b:add(b.margin .. "Language servers, formatters and debuggers are managed by Mason (:Mason).", "IDEMuted")
  end,
  keys = {
    r = function(p) p:render() end,
    y = function() if last_cmd ~= "" then vim.fn.setreg("+", last_cmd); vim.fn.setreg('"', last_cmd); vim.notify("Install command copied") end end,
  },
})
function M.open() page:open() end
return M
