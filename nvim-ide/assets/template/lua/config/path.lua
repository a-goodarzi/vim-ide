-- Finding tools that live outside nvim's PATH (nvm, mise, asdf, a custom Homebrew prefix ...).
-- nvim often starts with a shorter PATH than your terminal (launched from tmux, a GUI, or a non-interactive shell). When a tool
-- is missing we ask your login shell where it is, and add that folder to PATH for this nvim.
-- You can also list folders yourself: `extra_path = { "~/my/bin" }` in settings.lua.
local M = {}

local function has_dir(d) return (":" .. (vim.env.PATH or "") .. ":"):find(":" .. d .. ":", 1, true) ~= nil end

--- Append a folder to PATH (never prepended: your own order wins). Returns true when it was added.
function M.add(dir)
  dir = vim.fn.expand(dir)
  if vim.fn.isdirectory(dir) == 1 and not has_dir(dir) then vim.env.PATH = (vim.env.PATH or "") .. ":" .. dir; return true end
  return false
end

--- Absolute path of `tool`, searching nvim's PATH first and then what an interactive login shell sees. Adds its folder to PATH.
--- opts.shell overrides $SHELL (tests).
function M.find(tool, opts)
  local here = vim.fn.exepath(tool)
  if here ~= "" then return here end
  local sh = (opts and opts.shell) or vim.env.SHELL or "/bin/sh"
  local ok, res = pcall(function()
    return vim.system({ sh, "-ilc", "command -v " .. tool }, { text = true, timeout = 5000, stdin = false }):wait()
  end)
  if not (ok and res and res.stdout) then return nil end
  local found
  for line in res.stdout:gmatch("[^\r\n]+") do
    if line:sub(1, 1) == "/" and vim.fn.executable(line) == 1 then found = line end   -- the last absolute path wins (shell banners come first)
  end
  if found then M.add(vim.fn.fnamemodify(found, ":h")) end
  return found
end

--- Folders from the `extra_path` setting.
function M.apply_extra()
  for _, d in ipairs(require("config").settings.extra_path or {}) do M.add(d) end
end

return M
