-- Right-click menus (feature: context_menu): one in the editor, one in the Explorer. (The tab bar has its own, see tabs.lua.)
-- The menus are plain lists built by `editor_items` / `explorer_items`: add a row there to extend them.
local M = {}
local ui = require("config.ui")

local function lsp(fn) return function() pcall(fn) end end

function M.editor_items(visual)
  local items = {}
  local function add(label, fn) items[#items + 1] = { label, fn } end
  add("Go to definition", lsp(vim.lsp.buf.definition))
  add("Find references", lsp(vim.lsp.buf.references))
  add("Rename symbol", lsp(vim.lsp.buf.rename))
  add("Code action", lsp(vim.lsp.buf.code_action))
  add("Format file", function() pcall(function() require("conform").format({ lsp_format = "fallback" }) end) end)
  items[#items + 1] = "-"
  if visual then
    add("Cut", function() vim.cmd('normal! gv"+d') end)
    add("Copy", function() vim.cmd('normal! gv"+y') end)
  end
  add("Paste", function() vim.cmd('normal! "+p') end)
  add("Toggle comment", function() vim.cmd(visual and "normal gvgc" or "normal gcc") end)
  items[#items + 1] = "-"
  if require("config").feature("claude") then
    add(visual and "Send selection to Claude" or "Ask Claude about this file", function() require("config.assist").ask_selection() end)
  end
  add("Split right", function() require("config.layout").split("right") end)
  add("Copy file path", function() local p = vim.api.nvim_buf_get_name(0); vim.fn.setreg("+", p); vim.notify("Copied " .. p) end)
  return items
end

--- Explorer rows act on the line under the mouse: the neo-tree keys do the work.
function M.explorer_items(win)
  local function key(k) return function() if vim.api.nvim_win_is_valid(win) then vim.api.nvim_set_current_win(win) end vim.api.nvim_feedkeys(vim.keycode(k), "m", false) end end
  local function path()
    local ok, st = pcall(function() return require("neo-tree.sources.manager").get_state("filesystem") end)
    local node = ok and st and st.tree and st.tree:get_node()
    return node and node.path or nil
  end
  local ea = require("config.explorer_actions")
  local function with_path(fn) return function() local p = path(); if p then fn(p) end end end
  return {
    { "Open", key("<CR>") }, "-",
    { "New file / folder", key("a") }, { "Rename", key("r") }, { "Delete", key("d") }, "-",
    { "Cut", key("x") }, { "Copy", key("c") }, { "Paste", key("p") }, "-",
    { "Copy path", with_path(function(p) ea.copy_path(p, false) end) },
    { "Copy relative path", with_path(function(p) ea.copy_path(p, true) end) },
    { "Terminal here", with_path(ea.terminal_here) },
    { "Search in folder", with_path(ea.search_in) },
    { "Open in file manager", with_path(ea.open_system) },
  }
end

local function on_right_click()
  local m = vim.fn.getmousepos()
  if not (m.winid and m.winid > 0 and vim.api.nvim_win_is_valid(m.winid)) then return end
  local buf = vim.api.nvim_win_get_buf(m.winid)
  local ft, bt = vim.bo[buf].filetype, vim.bo[buf].buftype
  local was_visual = vim.fn.mode():find("[vV\22]") ~= nil
  if ft == "neo-tree" then
    vim.api.nvim_set_current_win(m.winid)
    pcall(vim.api.nvim_win_set_cursor, m.winid, { m.line, 0 })
    return ui.menu(M.explorer_items(m.winid))
  end
  if bt == "" and ft ~= "ide-activity" and not ft:find("^ide%-") and ft ~= "idescm" and vim.api.nvim_win_get_config(m.winid).relative == "" then
    if was_visual then vim.cmd("normal! \27") else
      vim.api.nvim_set_current_win(m.winid)
      pcall(vim.api.nvim_win_set_cursor, m.winid, { m.line, math.max(m.column - 1, 0) })
    end
    return ui.menu(M.editor_items(was_visual))
  end
  vim.api.nvim_feedkeys(vim.keycode("<RightMouse>"), "n", false)
end

function M.setup()
  vim.keymap.set({ "n", "v" }, "<RightMouse>", on_right_click, { desc = "Context menu" })
end
return M
