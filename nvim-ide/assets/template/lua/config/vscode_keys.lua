-- VS Code-style shortcuts (feature: vscode_keys). Loaded from keymaps.lua.
-- Notes for terminal users: Ctrl-B is the tmux prefix and Ctrl-Shift-<key> is not delivered by most terminals,
-- so sidebar views are on Alt-<key>, and F1 opens the command palette. Everything also works from the <Space> menu.
local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true }) end
local ab = function(id) return function() require("config.activitybar").show(id) end end
local function tele(name) return function() require("telescope.builtin")[name]() end end

-- Command palette & quick open
local palette = function() require("config.palette").open() end
map({ "n", "i", "v" }, "<F1>", palette, "Command palette")
map({ "n", "i", "v" }, "<C-S-p>", palette, "Command palette")
map("n", "<leader>P", palette, "Command palette")
map({ "n", "i" }, "<C-p>", tele("find_files"), "Quick open file")
map("n", "<C-t>", tele("lsp_dynamic_workspace_symbols"), "Go to symbol in workspace")
map("n", "<leader>o", tele("lsp_document_symbols"), "Go to symbol in file")

-- Sidebar views (activity bar)
map("n", "<A-b>", function() require("config.activitybar").toggle() end, "Toggle sidebar")
map("n", "<A-e>", ab("explorer"), "Explorer"); map("n", "<A-f>", ab("search"), "Search & Replace")
map("n", "<A-g>", ab("git"), "Source Control"); map("n", "<A-d>", ab("debug"), "Run & Debug")
map("n", "<A-o>", ab("outline"), "Outline"); map("n", "<A-x>", ab("plugins"), "Plugins")
map({ "n", "v" }, "<C-S-f>", ab("search"), "Search & Replace in files")
map("n", "<C-S-e>", ab("explorer"), "Explorer")

-- File & editing
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<cr><esc>", "Save")
map({ "n", "v" }, "<C-_>", "gc", "Toggle comment"); map("n", "<C-_>", "gcc", "Toggle comment line")
map({ "n", "v" }, "<C-/>", "gc", "Toggle comment"); map("n", "<C-/>", "gcc", "Toggle comment line")
map("n", "<A-Down>", "<cmd>m .+1<cr>==", "Move line down"); map("n", "<A-Up>", "<cmd>m .-2<cr>==", "Move line up")
map("v", "<A-Down>", ":m '>+1<cr>gv=gv", "Move selection down"); map("v", "<A-Up>", ":m '<-2<cr>gv=gv", "Move selection up")
map("n", "<S-A-Down>", "<cmd>t.<cr>", "Duplicate line down"); map("n", "<S-A-Up>", "<cmd>t-1<cr>", "Duplicate line up")
map("n", "<A-z>", function() vim.wo.wrap = not vim.wo.wrap end, "Toggle word wrap")

-- Tabs
map("n", "<A-w>", function() local ok, sn = pcall(require, "snacks"); if ok then sn.bufdelete() else vim.cmd.bdelete() end end, "Close tab")
map("n", "<C-PageDown>", "<cmd>bnext<cr>", "Next tab"); map("n", "<C-PageUp>", "<cmd>bprevious<cr>", "Previous tab")
map("n", "<A-.>", function() require("config.tabs").step(1) end, "Next tab"); map("n", "<A-,>", function() require("config.tabs").step(-1) end, "Previous tab")

-- Code navigation
map("n", "<F2>", vim.lsp.buf.rename, "Rename symbol")
map("n", "<F12>", vim.lsp.buf.definition, "Go to definition"); map("n", "<S-F12>", vim.lsp.buf.references, "Find references")

-- Run & Debug (same keys as VS Code)
local function dap(fn) return function() local ok, d = pcall(require, "dap"); if ok then d[fn]() end end end
-- A package that Mason half-installed leaves an adapter with an empty command and F5 then does nothing at all; say so.
local function start_debug()
  local ok, d = pcall(require, "dap"); if not ok then return vim.notify("Debugger is disabled in Settings > Features", vim.log.levels.WARN) end
  if not d.session() then
    for _, c in ipairs(d.configurations[vim.bo.filetype] or {}) do
      local a = d.adapters[c.type]
      if type(a) == "table" and a.type == "executable" and (a.command == nil or a.command == "") then
        return vim.notify(("Debug adapter '%s' is not installed (or its Mason package is broken): open :Mason"):format(c.type), vim.log.levels.WARN)
      end
    end
  end
  d.continue()
end
map("n", "<F5>", start_debug, "Start / continue"); map("n", "<S-F5>", dap("terminate"), "Stop")
map("n", "<F9>", dap("toggle_breakpoint"), "Toggle breakpoint")
map("n", "<F10>", dap("step_over"), "Step over"); map("n", "<F11>", dap("step_into"), "Step into"); map("n", "<S-F11>", dap("step_out"), "Step out")

-- Bottom panel (terminal / problems)
map({ "n", "t" }, "<A-t>", "<cmd>ToggleTerm direction=horizontal<cr>", "Terminal panel")
map("n", "<A-p>", "<cmd>Trouble diagnostics toggle<cr>", "Problems panel")
