-- Curated command palette (F1 · <Space>P). A short, labelled list of IDE actions; the raw
-- Neovim command list stays one entry away ("All Vim commands...").
local M = {}

local function cmd(c) return function() vim.cmd(c) end end
local function ab(id) return function() require("config.activitybar").show(id) end end
local function tele(n, o) return function() require("telescope.builtin")[n](o) end end
local function feed(k) return function() vim.api.nvim_feedkeys(vim.keycode(k), "m", false) end end

-- { group, label, key hint, action }
M.items = {
  { "File", "Quick open file", "Ctrl-P", tele("find_files") },
  { "File", "Recent files", "<Space>fr", tele("oldfiles") },
  { "File", "Save", "Ctrl-S", cmd("write") },
  { "File", "Save all", "", cmd("wall") },
  { "File", "New file", "", cmd("enew") },
  { "File", "Close tab", "<Space>bd", cmd("bdelete") },
  { "File", "Close other tabs", "<Space>bo", function() require("config.tabs").close_others() end },
  { "File", "Quit", "", cmd("qa") },
  { "File", "Recent projects...", "", cmd("IDEProjects") },
  { "File", "Save session now", "", cmd("IDESessionSave") },
  { "Tab", "Pin / unpin tab", "<Space>bp", function() require("config.tabs").toggle_pin() end },
  { "Tab", "Move tab left", "Alt-<", function() require("config.tabs").move(nil, -1) end },
  { "Tab", "Move tab right", "Alt->", function() require("config.tabs").move(nil, 1) end },
  { "Layout", "Split right", "<Space>sv", function() require("config.layout").split("right") end },
  { "Layout", "Split below", "<Space>sh", function() require("config.layout").split("below") end },
  { "Layout", "Close split", "<Space>sx", function() require("config.layout").close_split() end },
  { "Layout", "Maximize / restore split", "<Space>sm", function() require("config.layout").maximize() end },
  { "Layout", "Equalize splits", "<Space>se", function() require("config.layout").equalize() end },
  { "Layout", "Save current layout...", "", function() require("config.layout").ask_save() end },
  { "Layout", "Load a saved layout...", "", function() require("config.layout").pick_load() end },
  { "Run", "Run task...", "<Space>rt", cmd("IDETasks") },
  { "Run", "Run the last task again", "<Space>rr", cmd("IDETaskLast") },
  { "Search", "Search text in files", "<Space>fg", tele("live_grep") },
  { "Search", "Search & Replace sidebar", "Alt-f", ab("search") },
  { "Search", "Go to symbol in file", "<Space>o", tele("lsp_document_symbols") },
  { "Search", "Go to symbol in project", "Ctrl-T", tele("lsp_dynamic_workspace_symbols") },
  { "Search", "Help tags", "", tele("help_tags") },
  { "View", "Explorer", "Alt-e", ab("explorer") },
  { "View", "Source Control", "Alt-g", ab("git") },
  { "View", "Run & Debug", "Alt-d", ab("debug") },
  { "View", "Outline", "Alt-o", ab("outline") },
  { "View", "Plugins", "Alt-x", ab("plugins") },
  { "View", "Toggle sidebar", "Alt-b", function() require("config.activitybar").toggle() end },
  { "View", "Problems panel", "Alt-p", cmd("Trouble diagnostics toggle") },
  { "View", "Zen mode", "", cmd("ZenMode") },
  { "View", "Change colour theme", "<Space>uC", tele("colorscheme", { enable_preview = true }) },
  { "Tools", "Open terminal panel", "Alt-t", cmd("ToggleTerm direction=horizontal") },
  { "Tools", "Claude Code panel", "Alt-c", cmd("ClaudeCode") },
  { "Tools", "Settings", "<Space>us", cmd("IDESettings") },
  { "Tools", "Doctor (check required tools)", "", cmd("IDEDoctor") },
  { "Tools", "Welcome / first-run check", "", cmd("IDEWelcome") },
  { "Tools", "Help and shortcuts", "<Space>?", cmd("IDEHelp") },
  { "Tools", "Mason (language servers)", "", cmd("Mason") },
  { "Tools", "Plugin manager (Lazy)", "", cmd("Lazy") },
  { "Code", "Rename symbol", "F2", function() vim.lsp.buf.rename() end },
  { "Code", "Go to definition", "F12", function() vim.lsp.buf.definition() end },
  { "Code", "Find references", "Shift-F12", function() vim.lsp.buf.references() end },
  { "Code", "Code action", "<Space>ca", function() vim.lsp.buf.code_action() end },
  { "Code", "Format file", "<Space>cf", function() require("conform").format({ lsp_format = "fallback" }) end },
  { "Debug", "Start / continue", "F5", feed("<F5>") },
  { "Debug", "Toggle breakpoint", "F9", feed("<F9>") },
  { "Git", "Source Control sidebar", "Alt-g", ab("git") },
  { "Git", "Commit...", "", function() require("config.scm").commit() end },
  { "Git", "Stage all changes", "", function() require("config.scm").stage_all() end },
  { "Git", "Push", "", function() require("config.scm").push() end },
  { "Git", "Pull", "", function() require("config.scm").pull() end },
  { "Git", "Switch or create branch...", "", function() require("config.scm").branches() end },
  { "", "All Vim commands...", "", tele("commands") },
}
if not require("config").feature("debug") then   -- Debugger switched off in Settings: no debug entries
  local keep = {}
  for _, it in ipairs(M.items) do if it[1] ~= "Debug" and it[2] ~= "Run & Debug" then keep[#keep + 1] = it end end
  M.items = keep
end

function M.open()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then return tele("commands")() end
  local finders, conf = require("telescope.finders"), require("telescope.config").values
  local actions, state = require("telescope.actions"), require("telescope.actions.state")
  local displayer = require("telescope.pickers.entry_display").create({
    separator = "  ", items = { { width = 8 }, { width = 30 }, { remaining = true } },
  })
  pickers.new({}, {
    prompt_title = "Command Palette",
    finder = finders.new_table({
      results = M.items,
      entry_maker = function(it)
        return {
          value = it, ordinal = it[1] .. " " .. it[2],
          display = function() return displayer({ { it[1], "Comment" }, it[2], { it[3], "Comment" } }) end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local e = state.get_selected_entry()
        actions.close(bufnr)
        if e then vim.schedule(function() pcall(e.value[4]) end) end
      end)
      return true
    end,
  }):find()
end

return M
