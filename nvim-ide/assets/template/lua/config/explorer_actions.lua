-- Extra Explorer (neo-tree) actions, bound in plugins/editor.lua:
--   T terminal in this folder · gy copy path · gY copy relative path · gO open in the system file manager · gs search in this folder
-- Multi-file work uses neo-tree's own clipboard: x cut, c copy, p paste on several files; H toggles hidden files, / filters.
local M = {}

local function dir_of(path)
  if path == nil or path == "" then return vim.fn.getcwd() end
  return vim.fn.isdirectory(path) == 1 and path or vim.fn.fnamemodify(path, ":h")
end

function M.terminal_here(path)
  vim.cmd("ToggleTerm direction=horizontal dir=" .. vim.fn.fnameescape(dir_of(path or vim.api.nvim_buf_get_name(0))))
end
function M.copy_path(path, relative)
  local v = relative and vim.fn.fnamemodify(path, ":.") or path
  vim.fn.setreg("+", v); vim.fn.setreg('"', v); vim.notify("Copied " .. v)
end
function M.open_system(path) local ok, err = pcall(vim.ui.open, path); if not ok then vim.notify(tostring(err), vim.log.levels.WARN) end end
function M.search_in(path)
  local d = vim.fn.fnamemodify(dir_of(path), ":.")
  local ab = require("config.activitybar")
  ab.open_search(function()
    require("grug-far").open({ windowCreationCommand = "topleft 50vsplit", transient = true, prefills = { paths = d == "" and "." or d } })
  end)
end

--- neo-tree command table (each gets (state)).
M.commands = {
  terminal_here = function(state) M.terminal_here(state.tree:get_node().path) end,
  copy_path = function(state) M.copy_path(state.tree:get_node().path, false) end,
  copy_relative_path = function(state) M.copy_path(state.tree:get_node().path, true) end,
  open_system = function(state) M.open_system(state.tree:get_node().path) end,
  search_in_folder = function(state) M.search_in(state.tree:get_node().path) end,
}
M.mappings = { T = "terminal_here", gy = "copy_path", gY = "copy_relative_path", gO = "open_system", gs = "search_in_folder" }
return M
