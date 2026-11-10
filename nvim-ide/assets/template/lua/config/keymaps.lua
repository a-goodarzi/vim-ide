-- Core keymaps. Plugin keymaps live next to their plugin so which-key groups stay in sync.
local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true }) end

map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
if not vim.env.TMUX then -- inside tmux, plugins/tmux.lua handles these so they cross into tmux panes
  map("n", "<C-h>", "<C-w>h", "Window left")
  map("n", "<C-j>", "<C-w>j", "Window down")
  map("n", "<C-k>", "<C-w>k", "Window up")
  map("n", "<C-l>", "<C-w>l", "Window right")
end
map("n", "<S-h>", function() require("config.tabs").step(-1) end, "Prev tab")
map("n", "<S-l>", function() require("config.tabs").step(1) end, "Next tab")
map("n", "<leader>bo", function() require("config.tabs").close_others() end, "Close other tabs")
map("n", "<leader>bd", function() local ok, sn = pcall(require, "snacks"); if ok then sn.bufdelete() else vim.cmd.bdelete() end end, "Close tab/buffer")
map("n", "<leader>w", "<cmd>write<cr>", "Save")
map("n", "<leader>q", "<cmd>quitall<cr>", "Quit all")
map("v", "<", "<gv", "Indent left")
map("v", ">", ">gv", "Indent right")
map("v", "J", ":m '>+1<cr>gv=gv", "Move selection down")
map("v", "K", ":m '<-2<cr>gv=gv", "Move selection up")

-- Diagnostics
map("n", "<leader>cd", vim.diagnostic.open_float, "Line diagnostics")

-- User-defined keymaps from settings.lua: { mode, lhs, rhs, desc }
for _, k in ipairs(require("config").settings.keymaps or {}) do map(k[1], k[2], k[3], k[4]) end

-- ── Settings, help, plugin manager ──────────────────────────────────────────
map("n", "<leader>us", function() require("config.settings_ui").open() end, "Settings page")
map("n", "<leader>?", function() require("config.cheatsheet").open() end, "Commands & shortcuts")
map("n", "<leader>uk", function() require("config.shortcuts").open() end, "Customize shortcuts")
map("n", "<leader>pl", function() require("config.plugins_ui").open() end, "Plugins tab")
map("n", "<leader>pL", "<cmd>Lazy<cr>", "Full lazy.nvim UI (advanced)")
vim.api.nvim_create_user_command("IDEPlugins", function() require("config.plugins_ui").open() end, {})
map("n", "<leader>pu", "<cmd>Lazy update<cr>", "Update plugins")
map("n", "<leader>pr", "<cmd>Lazy restore<cr>", "Restore plugins from lockfile")
map("n", "<leader>pm", "<cmd>Mason<cr>", "Language servers & tools (Mason)")
map("n", "<leader>ph", "<cmd>checkhealth<cr>", "Health check")
-- Commands exist even before their modules are loaded:
vim.api.nvim_create_user_command("IDESettings", function() require("config.settings_ui").open() end, {})
vim.api.nvim_create_user_command("IDEShortcuts", function() require("config.shortcuts").open() end, { desc = "Customize shortcuts" })
vim.api.nvim_create_user_command("IDEHelp", function() require("config.cheatsheet").open() end, {})

-- ── Tab pages and terminal-friendly navigation ──────────────────────────────
map("n", "<leader><tab><tab>", "<cmd>tabnew<cr>", "New tab page")
map("n", "<leader><tab>]", "<cmd>tabnext<cr>", "Next tab page")
map("n", "<leader><tab>[", "<cmd>tabprevious<cr>", "Previous tab page")
map("n", "<leader><tab>d", "<cmd>tabclose<cr>", "Close tab page")
-- Alt-hjkl moves between windows from terminals (Claude panel) too; Esc stays with Claude.
for _, k in ipairs({ "h", "j", "k", "l" }) do
  vim.keymap.set({ "n", "t", "i" }, "<A-" .. k .. ">", "<Cmd>wincmd " .. k .. "<CR>", { desc = "Window " .. k })
end

-- Dev convenience: restart nvim in place to reload the config (nvim 0.12+).
map("n", "<leader>uR", function()
  if vim.fn.exists(":restart") == 2 then vim.cmd("restart") else vim.notify("Quit and reopen nvim (in-place restart needs nvim 0.12)") end
end, "Restart nvim (reload config)")

-- Update everything: plugins (lazy.nvim) + Mason tools. Also `:IDEUpdate`, or `ide update` from the shell.
local function update_all() require("config.updater").update_all() end   -- saves the lockfile first, lists the changes after
vim.api.nvim_create_user_command("IDEUpdate", update_all, { desc = "Update plugins and language tools" })
map("n", "<leader>pU", update_all, "Update plugins + tools")

-- Splits & layout, tasks, snippets, Claude on the selection
map("n", "<leader>sv", function() require("config.layout").split("right") end, "Split right")
map("n", "<leader>sh", function() require("config.layout").split("below") end, "Split below")
map("n", "<leader>sx", function() require("config.layout").close_split() end, "Close split")
map("n", "<leader>sm", function() require("config.layout").maximize() end, "Maximize / restore split")
map("n", "<leader>se", function() require("config.layout").equalize() end, "Equalize splits")
map("n", "<leader>rt", "<cmd>IDETasks<cr>", "Run task...")
map("n", "<leader>rr", "<cmd>IDETaskLast<cr>", "Run last task again")
map("n", "<leader>cS", "<cmd>IDESnippets<cr>", "Browse snippets")
map("n", "<leader>ax", "<cmd>IDEClaudeFix<cr>", "Claude: fix the problem here")
map("n", "<leader>ae", "<cmd>IDEClaudeExplain<cr>", "Claude: explain this line"); map("v", "<leader>ae", ":IDEClaudeExplain<cr>", "Claude: explain the selection")
map("n", "<leader>aT", "<cmd>IDEClaudeTests<cr>", "Claude: write tests for this file"); map("v", "<leader>aT", ":IDEClaudeTests<cr>", "Claude: write tests for the selection")
map("n", "<leader>aL", "<cmd>IDEClaudeTerminal<cr>", "Claude: send the last terminal output")
map("n", "<leader>aR", "<cmd>IDEClaudeReview<cr>", "Claude: review the staged diff")
map("n", "<leader>ag", "<cmd>IDECommitMessage<cr>", "Claude: write a commit message")
map("n", "<leader>aP", "<cmd>IDEPRDescription<cr>", "Claude: write the pull request description")
map("n", "<leader>au", "<cmd>IDEUndoTurn<cr>", "Undo the last Claude turn")
map({ "n", "v" }, "<leader>aq", function() require("config.assist").ask_selection() end, "Ask Claude about selection / file")

-- VS Code-style shortcuts
if require("config").feature("vscode_keys") then require("config.vscode_keys") end
