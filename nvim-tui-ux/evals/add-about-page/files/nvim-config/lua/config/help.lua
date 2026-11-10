-- Help tab:  :IDEHelp · <leader>? · click the ? button (top-right) · `ide help`
-- A normal buffer named "Help" with a headline per section: Getting started, Features, Commands, Shortcuts, Tips.
-- j/k scroll · 1-5 jump to a section · ]] / [[ next/prev section · / search (native, n/N repeat) · q close
-- Edit `features` and `commands` below when you add something; shortcuts come from config/cheatsheet.lua.
local M = {}

local features = {
  { "File browser", "Sidebar tree of your project. Opens at start (Settings > Layout).",
    "<Space>e toggle · in the tree: a add · d delete · r rename · c copy · m move · H show hidden · ? tree help" },
  { "Activity bar (VS Code layout)", "Icon column on the far left switches the sidebar: Explorer, Search & Replace, Source Control, Run & Debug, Outline, Plugins.",
    "Click an icon (click it again to hide the sidebar) · Alt-e explorer · Alt-f search · Alt-g git · Alt-d debug · Alt-o outline · Alt-x plugins · Alt-b toggle" },
  { "Search & Replace in files", "Find text across the project and replace it, with a live preview (the VS Code Search view).",
    "Alt-f or <Space>sr · <Space>sw word under cursor · <Space>sf this file only · in the panel: type search / replace / paths / flags, <Space>r replace all" },
  { "Breadcrumbs, outline, minimap, zen", "Path of the current symbol above the editor (clickable), a symbol outline, optional minimap, distraction-free mode.",
    "Click the breadcrumbs · Alt-o outline · <Space>um minimap (enable in Settings) · <Space>uz zen mode" },
  { "Command palette", "Search and run any command, like Ctrl+Shift+P.",
    "F1 · <Space>P · Ctrl-P quick open file · <Space>o symbols in file · Ctrl-T symbols in project" },
  { "Tabs", "Every open file is a tab; the active tab is underlined.",
    "Shift-h / Shift-l switch · <Space>bb pick by letter · bp pin · bd close · bo close others" },
  { "Claude Code panel", "Claude Code embedded in a side panel; it sees your file and selection, and its edits open as diffs.",
    "<Space>ac toggle (or click the ✳ button) · ab add file · as send selection · aa / ad accept / deny diff · ar resume" },
  { "Fuzzy finder", "Find files, text, buffers, keymaps and commands with Telescope.",
    "<Space><Space> files · fg grep · fb buffers · fr recent · fk keymaps · fc commands · in a picker: Ctrl-n/p move, Enter open" },
  { "Code intelligence (LSP)", "Go to definition, references, hover docs, rename, code actions, live diagnostics.",
    "gd definition · gr references · K hover · <Space>ca action · cr rename · cd line diagnostics · xx diagnostics list" },
  { "Language servers & tools", "Servers, formatters, linters and debuggers install automatically through Mason.",
    "<Space>pm opens Mason · languages are presets: enable them in Settings > Languages" },
  { "Completion", "Autocomplete from the language server, snippets, paths and the buffer.",
    "Ctrl-Space open · Ctrl-n / Ctrl-p select · Ctrl-y accept · Ctrl-e close" },
  { "Formatting & linting", "Format on save with the right tool per language; linters run in the background.",
    "<Space>cf format now · :FormatToggle turn format-on-save off/on · :ConformInfo shows the formatter in use" },
  { "Git", "Change marks in the gutter, hunk staging, blame, diff view, lazygit.",
    "]h / [h next/prev hunk · <Space>gs stage · gr reset · gp preview · gb blame · gv diff view · tg lazygit" },
  { "Debugger", "Breakpoints, stepping and a variables panel (nvim-dap).",
    "<Space>db breakpoint · dc continue/start · di / do / dO step in/over/out · du toggle UI · dt stop" },
  { "Tests", "Run the nearest test or a whole file and see results inline (neotest).",
    "<Space>tn nearest · tf file · ts summary · to output · td debug nearest (when the debugger is on)" },
  { "Terminal", "Floating terminal and a split terminal.",
    "Ctrl-\\ floating · <Space>tt split · Ctrl-\\ Ctrl-n leaves terminal mode (Esc goes to the program)" },
  { "Themes & statusline", "30 colorschemes and 3 statusline styles (rounded pills, powerline arrows, plain), all switch live.",
    "Settings > Appearance. Icons off forces the plain statusline." },
  { "Settings tab", "Every option with a description. ● marks values you changed, ↻ marks ones that need a restart.",
    "<Space>us or the ⚙ button · Enter/click changes · / search · r reset one · R reset all · A restart now" },
  { "Plugin manager", "lazy.nvim installs and updates all plugins; lazy-lock.json pins versions.",
    "<Space>pl Plugins tab (actions, every plugin, tools) · pu update · pU update plugins + tools · pr restore · pL full lazy.nvim UI · ph health" },
  { "tmux", "Works inside tmux. Ctrl-h/j/k/l move across Neovim splits and tmux panes; Alt-h/j/k/l from terminal buffers.",
    "Add extras/tmux.conf to ~/.tmux.conf (see references/tmux.md in the skill)" },
  { "Languages", "Python, Go, HTML/CSS, JavaScript, Terraform, Bash, Markdown, Lua, JSON, YAML out of the box (more presets in languages.lua).",
    "Settings > Languages toggles each preset (needs a restart) · add your own block in lua/config/languages.lua" },
}

local commands = {
  { ":IDESettings", "Open the Settings tab" },
  { ":IDEHelp", "Open this Help tab" },
  { ":IDEUpdate", "Update all plugins and language tools" },
  { ":ClaudeCode", "Toggle the Claude Code panel (:ClaudeCodeAdd %, :ClaudeCodeSend, :ClaudeCodeSelectModel)" },
  { ":IDEPlugins", "Plugins tab" },
  { ":Lazy", "Full lazy.nvim UI (advanced: :Lazy update, :Lazy restore, :Lazy profile)" },
  { ":Mason", "Install and update language servers, formatters, debuggers" },
  { ":FormatToggle", "Turn format-on-save off and on" },
  { ":ConformInfo", "Which formatter runs for this file" },
  { ":Telescope <picker>", "find_files, live_grep, buffers, oldfiles, keymaps, commands, help_tags, diagnostics ..." },
  { ":Neotree toggle", "File browser" },
  { ":Trouble diagnostics toggle", "Diagnostics list" },
  { ":checkhealth", "Check the setup (:checkhealth vim.lsp, :checkhealth claudecode after opening Claude once)" },
  { ":LspInfo / :LspRestart", "Language server status / restart" },
  { ":restart", "Restart Neovim in place (also <Space>uR)" },
  { "ide", "From the shell: open the IDE" },
  { "ide claude", "From the shell: open the IDE with the Claude panel" },
  { "ide settings", "From the shell: full-screen settings" },
  { "ide help", "From the shell: this help" },
  { "ide sync / ide update", "Install plugins / update plugins and tools" },
}

local tips = {
  "Press <Space> and wait: a menu lists everything under that key (which-key). Same for g, z, [ and ].",
  "Search a keymap by what it does: <Space>fk. Search any command: <Space>fc.",
  "gc comments a line or selection · gsa/gsd/gsr surround · s jumps anywhere on screen · . repeats the last change.",
  "Inside the Claude panel Esc goes to Claude; use Ctrl-\\ Ctrl-n to get back to Neovim keys, or Alt-h/j/k/l to change window.",
  "Something looks off? Settings > Appearance > Icons (needs a Nerd Font); then :checkhealth.",
  "Changed your mind about a setting? r resets it in the Settings tab; the ● marker shows what you changed.",
}

local sections = { "Getting started", "Features", "Commands", "Shortcuts", "Tips" }
local ui = require("config.ui")

local page = ui.page({
  name = "Help", ft = "ide-help", sections = sections,
  render = function(_, b)
    b:title("Help", "Features, commands and shortcuts. Search with /  (n = next match). q closes this tab.")
    b:jumpbar(sections)
    b:head(sections[1], 1)
    for _, l in ipairs({
      "Leader key is <Space>. Press it and pause: a menu shows every shortcut under it.",
      "Top-right buttons: Claude Code, Settings and Help (click them, or <Space>ac, <Space>us, <Space>?).",
      "Left bar: Explorer, Search & Replace, Source Control, Run & Debug, Outline, Plugins (click, or Alt-e/f/g/d/o/x).",
      "From the shell: `ide` opens the IDE, `ide claude` with Claude, `ide settings` / `ide help` those screens.",
      "Your settings are saved separately from the config files and survive updates (Settings tab, \xe2\x97\x8f = changed).",
    }) do b:add(b.margin .. ui.g("bullet") .. l) end

    b:head(sections[2], 2)
    for _, f in ipairs(features) do
      b:add(b.margin .. f[1], "IDEAccent"); b:add(b.margin .. "  " .. f[2]); b:add(b.margin .. "  " .. f[3], "IDEMuted"); b:blank()
    end

    b:head(sections[3], 3)
    for _, c in ipairs(commands) do b:add(b.margin .. string.format("%-30s %s", c[1], c[2]), nil, { keycol = true }) end

    b:head(sections[4], 4)
    for _, sec in ipairs(require("config.cheatsheet").sections) do
      b:add(b.margin .. sec[1], "IDEAccent")
      for _, row in ipairs(sec[2]) do b:add(b.margin .. string.format("   %-28s %s", row[1], row[2]), nil, { keycol = true }) end
      b:blank()
    end

    b:head(sections[5], 5)
    for _, t in ipairs(tips) do b:add(b.margin .. ui.g("bullet") .. t) end
    b:blank()
  end,
})

-- highlight the key/command column after each render
local render = page.render
function page:render()
  local b = render(self)
  if b then for l, m in pairs(b.meta) do if m and m.keycol then vim.api.nvim_buf_add_highlight(self.buf, self.ns, "IDEKey", l - 1, 3, 34) end end end
  return b
end

function M.open() page:open() end

return M
