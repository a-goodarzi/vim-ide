-- Guided tour: five callouts, one per area of the screen.   :IDETour · palette > "Take the tour" · welcome page key t
--   Enter / l / click next · h back · Esc / q end
local M = {}
local ui = require("config.ui")

local function steps()
  local cols, lines = vim.o.columns, vim.o.lines
  local left = 6
  local ab = require("config.activitybar")
  if ab.win and vim.api.nvim_win_is_valid(ab.win) then
    for _, w in ipairs(vim.api.nvim_tabpage_list_wins(0)) do
      local ft = vim.bo[vim.api.nvim_win_get_buf(w)].filetype
      if ft == "neo-tree" or ft == "idescm" or ft == "grug-far" or ft == "aerial" then left = vim.api.nvim_win_get_position(w)[2] + vim.api.nvim_win_get_width(w) + 2 end
    end
  end
  local W = 46
  return {
    { title = "Activity bar", row = 4, col = 6,
      text = { "\xe2\x97\x80 The icon column on the far left.", "", "Explorer, Search & Replace, Source Control,", "Outline, Plugins (and Run & Debug when the", "debugger is on). Click an icon to switch the", "sidebar, click it again to hide it.", "", "Keys: Alt-e  f  g  d  o  x   (Alt-b hides)" } },
    { title = "Tabs", row = 3, col = math.min(left + 4, cols - W - 2),
      text = { "\xe2\x96\xb2 Every open file is a tab.", "", "Click to switch, middle-click or x to close.", "Right-click for pin, move, close others,", "copy path, reveal in Explorer.", "", "Keys: Shift-h / Shift-l switch tabs" } },
    { title = "Editor", row = math.floor(lines / 2) - 4, col = math.max(left, math.floor(cols / 2) - W / 2),
      text = { "Your code, with LSP, completion and formatting.", "", "Right-click: definition, references, rename,", "format, clipboard, Claude.", "", "Keys: Ctrl-P open a file by name,", "Ctrl-S save, K hover, gd definition" } },
    { title = "Command palette", row = 5, col = math.max(left, math.floor(cols / 2) - W / 2),
      text = { "Everything the IDE can do, in one list.", "", "F1 opens it. Recent entries come first; it also", "lists your project tasks, recent projects,", "git actions and every colour theme.", "", "Try it now: press F1 after the tour." } },
    { title = "Statusline and panels", row = lines - 14, col = math.max(left, math.floor(cols / 2) - W / 2),
      text = { "\xe2\x96\xbc Mode, branch, file, language server, position.", "", "Alt-t terminal panel, Alt-c Claude Code,", "Alt-p problems. The top-right buttons open", "Claude, the terminal, Settings and Help.", "", "<Space> then pause shows every shortcut." } },
  }
end

local state = {}
local function close()
  if state.win and vim.api.nvim_win_is_valid(state.win) then vim.api.nvim_win_close(state.win, true) end
  state = {}
end

local function show(i)
  local list = steps()
  local s = list[i]
  if not s then return close() end
  close()
  local lines = { "" }
  for _, l in ipairs(s.text) do lines[#lines + 1] = "  " .. l end
  lines[#lines + 1] = ""
  lines[#lines + 1] = "  " .. (i < #list and "Enter next" or "Enter finish") .. "   h back   q quit"
  local w = 0
  for _, l in ipairs(lines) do w = math.max(w, vim.fn.strdisplaywidth(l) + 2) end
  local b = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(b, 0, -1, false, lines)
  vim.bo[b].bufhidden = "wipe"
  local win = vim.api.nvim_open_win(b, true, { relative = "editor", row = math.max(0, s.row), col = math.max(0, s.col), width = w, height = #lines,
    style = "minimal", border = ui.border, zindex = 90, title = (" %s  %d/%d "):format(s.title, i, #list), title_pos = "center" })
  ui.setwo(win, { winhighlight = "FloatBorder:IDEBar,FloatTitle:IDEHeading", cursorline = false })
  vim.api.nvim_buf_add_highlight(b, -1, "IDEMuted", #lines - 1, 0, -1)
  state = { win = win, i = i }
  local k = function(lhs, fn) vim.keymap.set("n", lhs, fn, { buffer = b, nowait = true, silent = true }) end
  local nxt = function() show(i + 1) end
  k("<CR>", nxt); k("l", nxt); k("<Right>", nxt); k("<Space>", nxt); k("<LeftMouse>", nxt)
  k("h", function() show(math.max(i - 1, 1)) end); k("<Left>", function() show(math.max(i - 1, 1)) end)
  k("q", close); k("<Esc>", close)
end

function M.start() show(1) end
function M.is_open() return state.win ~= nil and vim.api.nvim_win_is_valid(state.win) end
function M.step() return state.i end
M.next = function() if state.i then show(state.i + 1) end end

vim.api.nvim_create_user_command("IDETour", M.start, { desc = "Guided tour of the IDE" })
return M
