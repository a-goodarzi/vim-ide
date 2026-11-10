-- Shortcut data for the Help tab (:IDEHelp or <leader>?). Edit `sections` when you add keymaps.
-- Edit `sections` to keep it in sync when you add keymaps. Live, searchable lists:
--   <leader>fk (all keymaps)   <leader>fc (all commands)   <Space> then wait (which-key)
local M = {}

local sections = {
  { "Files & search", {
    { "<Space><Space>", "Find file" }, { "<Space>fg", "Grep in project" }, { "<Space>fb", "Open buffers" },
    { "<Space>fr", "Recent files" }, { "<Space>e", "Toggle file browser" }, { "<Space>fk", "Search all keymaps" },
    { "<Space>fc", "Search all commands" } } },
  { "Tabs & windows", {
    { "Shift-h / Shift-l", "Previous / next tab" }, { "Right-click a tab", "Menu: pin, move, close others / right, copy path, reveal" }, { "<Space>bp", "Pin / unpin tab" }, { "Alt-< / Alt->", "Move tab left / right" },
    { "<Space>bd", "Close tab" }, { "<Space>bo", "Close other tabs" }, { "Ctrl-h/j/k/l", "Move between windows (and tmux panes inside tmux)" },
    { "Alt-h/j/k/l", "Move between windows (also from terminals)" }, { "<Space><Tab><Tab>", "New tab page" },
    { "<Space><Tab>]  /  [", "Next / previous tab page" } } },
  { "VS Code layout & keys", {
    { "F1 / <Space>P", "Command palette" }, { "Ctrl-P", "Quick open file" }, { "Ctrl-S", "Save" },
    { "Alt-b", "Show / hide sidebar" }, { "Alt-e / f / g / d / o / x", "Explorer / Search&Replace / Git / Debug / Outline / Plugins" },
    { "<Space>sr / sw / sf", "Search & Replace: project / word / this file" }, { "Alt-Up / Alt-Down", "Move line (Shift-Alt = duplicate)" },
    { "Ctrl-/", "Toggle comment" }, { "F2 / F12 / Shift-F12", "Rename / definition / references" },
    { "F5 / F9 / F10 / F11", "Debug start / breakpoint / step over / step into" }, { "Alt-t / Alt-p", "Terminal panel / Problems panel" },
    { "Alt-w / Alt-, / Alt-.", "Close tab / previous tab / next tab" }, { "<Space>uz / um", "Zen mode / minimap" } } },
  { "Claude Code", {
    { "<Space>ac / click the Claude button top-right", "Toggle Claude panel" }, { "<Space>af  /  Alt-c", "Focus Claude" }, { "<Space>ab", "Add current file to Claude" },
    { "<Space>as (visual)", "Send selection to Claude" }, { "<Space>ar", "Resume a conversation" },
    { "<Space>aC", "Continue last conversation" }, { "<Space>am", "Pick model" },
    { "<Space>aa / ad", "Accept / deny Claude's diff" }, { "Ctrl-\\ Ctrl-n", "Leave terminal mode (Esc goes to Claude)" } } },
  { "Code (LSP)", {
    { "gd / gD / gr / gi", "Definition / declaration / references / implementation" }, { "K", "Hover docs" },
    { "<Space>ca", "Code action" }, { "<Space>cr", "Rename" }, { "<Space>cf", "Format" },
    { "<Space>cd", "Line diagnostics" }, { "<Space>xx", "Diagnostics list" }, { "<Space>uh", "Toggle inlay hints" } } },
  { "Completion", { { "Ctrl-Space", "Open menu" }, { "Ctrl-n / Ctrl-p", "Next / previous" }, { "Ctrl-y", "Accept" }, { "Ctrl-e", "Close" } } },
  { "Git", {
    { "]h / [h", "Next / previous hunk" }, { "<Space>gs / gr / gp", "Stage / reset / preview hunk" },
    { "<Space>gb", "Blame line" }, { "<Space>gv", "Diff view" }, { "<Space>tg", "Lazygit" } } },
  { "Debug & test", {
    { "<Space>db", "Breakpoint" }, { "<Space>dc", "Continue / start" }, { "<Space>di / do / dO", "Step into / over / out" },
    { "<Space>du", "Debug UI" }, { "<Space>tn / tf", "Run nearest / file tests" }, { "<Space>ts", "Test summary" } } },
  { "Splits & layout", {
    { "<Space>sv / sh", "Split right / below" }, { "<Space>sx", "Close split" }, { "<Space>sm", "Maximize / restore split" },
    { "<Space>se", "Equalize splits" }, { "palette: Layout", "Save / load named layouts (:IDELayoutSave, :IDELayoutLoad)" } } },
  { "Tasks", { { "<Space>rt / rr", "Run a project task / run the last one again" } } },
  { "Sessions & projects", { { "palette: Recent projects", "Switch project (files reopen on start)" }, { ":IDESessionSave", "Save the session now" } } },
  { "Terminal", { { "Ctrl-\\", "Floating terminal" }, { "Alt-t / <Space>tt", "Terminal panel (also the top-right button)" } } },
  { "Settings & plugins", {
    { "<Space>us / click ⚙ top-right", "Settings tab (headlines, toggles, search with /)" }, { "<Space>?", "This help" },
    { "<Space>pl", "Plugin manager (lazy.nvim)" }, { "<Space>pu / pU", "Update plugins / plugins + tools (:IDEUpdate)" }, { "<Space>pm", "Language servers & tools (Mason)" },
    { "<Space>ph", "Health check" }, { "<Space>uR", "Restart nvim (reload config)" } } },
  { "From the shell (ide launcher)", {
    { "ide [files]", "Open the IDE" }, { "ide claude", "Open the IDE with the Claude panel" },
    { "ide settings", "Full-screen settings TUI (q quits)" }, { "ide help", "Full-screen shortcuts" }, { "ide sync", "Install plugins" }, { "ide update", "Update plugins + tools to latest" } } },
  { "Handy built-ins", {
    { "gc", "Comment line / selection" }, { "gsa / gsd / gsr", "Surround add / delete / replace" },
    { "s", "Flash: jump anywhere" }, { ":w  :q  :wa", "Save / quit / save all" } } },
}

M.sections = sections

--- Opens the Help tab (see config/help.lua).
function M.open() require("config.help").open() end

vim.api.nvim_create_user_command("IDEHelp", M.open, { desc = "Open the Help tab (features, commands, shortcuts)" })
return M
