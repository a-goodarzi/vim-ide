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
  { "Test", "Run nearest test", "<Space>tn", function() require("neotest").run.run() end },
  { "Test", "Run tests in file", "<Space>tf", function() require("neotest").run.run(vim.fn.expand("%")) end },
  { "Test", "Run all tests", "<Space>tA", function() require("neotest").run.run(vim.fn.getcwd()) end },
  { "Test", "Run last test again", "<Space>tl", function() require("neotest").run.run_last() end },
  { "Test", "Test summary", "<Space>ts", function() require("neotest").summary.toggle() end },
  { "Code", "Snippets...", "<Space>cS", cmd("IDESnippets") },
  { "Claude", "Ask Claude about selection / file", "<Space>aq", function() require("config.assist").ask_selection() end },
  { "Remote", "SSH, remote files, containers...", "", cmd("IDERemote") },
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
  { "View", "Explorer: open terminal here", "T", function() require("config.explorer_actions").terminal_here() end },
  { "View", "Zen mode", "", cmd("ZenMode") },
  { "View", "Change colour theme", "<Space>uC", tele("colorscheme", { enable_preview = true }) },
  { "Tools", "Open terminal panel", "Alt-t", cmd("ToggleTerm direction=horizontal") },
  { "Tools", "Claude Code panel", "Alt-c", cmd("ClaudeCode") },
  { "Tools", "Settings", "<Space>us", cmd("IDESettings") },
  { "Tools", "Doctor (check required tools)", "", cmd("IDEDoctor") },
  { "Tools", "Take the tour", "", cmd("IDETour") },
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
if not require("config").feature("test") then
  local keep = {}
  for _, it in ipairs(M.items) do if it[1] ~= "Test" then keep[#keep + 1] = it end end
  M.items = keep
end
if not require("config").feature("debug") then   -- Debugger switched off in Settings: no debug entries
  local keep = {}
  for _, it in ipairs(M.items) do if it[1] ~= "Debug" and it[2] ~= "Run & Debug" then keep[#keep + 1] = it end end
  M.items = keep
end

-- ── recents and dynamic entries ──────────────────────────────────────────────────────────────────
local recent_path = vim.fn.stdpath("data") .. "/ide-palette-recent.json"
local function read_recent()
  local f = io.open(recent_path, "r"); if not f then return {} end
  local ok, d = pcall(vim.json.decode, f:read("*a")); f:close()
  return ok and type(d) == "table" and d or {}
end
local function remember(key)
  local list = { key }
  for _, k in ipairs(read_recent()) do if k ~= key and #list < 8 then list[#list + 1] = k end end
  local f = io.open(recent_path, "w"); if f then f:write(vim.json.encode(list)); f:close() end
end
local function key_of(it) return it[1] .. "|" .. it[2] end

--- Entries that depend on the folder and the machine: project tasks, recent projects, one per theme.
local function dynamic()
  local out = {}
  local okt, tasks = pcall(function() return require("config.tasks").collect() end)
  if okt then
    for _, t in ipairs(tasks) do out[#out + 1] = { "Run", t.src .. ": " .. t.label, "", function() require("config.tasks").run(t) end } end
  end
  local okp, projs = pcall(function() return require("config.session").list() end)
  if okp then
    for i, c in ipairs(projs) do
      if i > 1 and c ~= vim.fn.getcwd() then
        out[#out + 1] = { "Project", vim.fn.fnamemodify(c, ":t") .. "  " .. vim.fn.fnamemodify(c, ":~"), "", function() require("config.session").switch(c) end }
      end
    end
  end
  local cfg = require("config")
  for _, n in ipairs(require("config.theme").names) do
    out[#out + 1] = { "Theme", n, n == cfg.settings.colorscheme and "current" or "", function()
      require("config.theme").apply(n)
      local o = cfg.load_overrides(); o.colorscheme = n; cfg.save_overrides(o); cfg.settings.colorscheme = n
    end }
  end
  return out
end

--- All entries, most recently used first (shown under the group "Recent"), then the rest.
function M.entries()
  local all = vim.list_extend(vim.deepcopy(M.items), dynamic())
  local by_key = {}
  for _, it in ipairs(all) do by_key[key_of(it)] = it end
  local head, used = {}, {}
  for _, k in ipairs(read_recent()) do
    local it = by_key[k]
    if it then head[#head + 1] = { "Recent", it[2], it[3], it[4], _orig = k }; used[k] = true end
  end
  local rest = {}
  for _, it in ipairs(all) do if not used[key_of(it)] then rest[#rest + 1] = it end end
  -- the raw Vim command list stays last
  for i, it in ipairs(rest) do
    if it[2] == "All Vim commands..." then table.remove(rest, i); rest[#rest + 1] = it; break end
  end
  return vim.list_extend(head, rest)
end

function M.open()
  local ok, pickers = pcall(require, "telescope.pickers")
  if not ok then return tele("commands")() end
  local finders, conf = require("telescope.finders"), require("telescope.config").values
  local actions, state = require("telescope.actions"), require("telescope.actions.state")
  local displayer = require("telescope.pickers.entry_display").create({
    separator = "  ", items = { { width = 8 }, { width = 42 }, { remaining = true } },
  })
  pickers.new({}, {
    prompt_title = "Command Palette",
    finder = finders.new_table({
      results = M.entries(),
      entry_maker = function(it)
        return {
          value = it, ordinal = it[1] .. " " .. it[2],
          display = function() return displayer({ { it[1], it[1] == "Recent" and "IDEKey" or "Comment" }, it[2], { it[3], "Comment" } }) end,
        }
      end,
    }),
    sorter = conf.generic_sorter({}),
    attach_mappings = function(bufnr)
      actions.select_default:replace(function()
        local e = state.get_selected_entry()
        actions.close(bufnr)
        if e then
          local it = e.value
          if it[2] ~= "All Vim commands..." then remember(it._orig or key_of(it)) end
          vim.schedule(function() pcall(it[4]) end)
        end
      end)
      return true
    end,
  }):find()
end

return M
