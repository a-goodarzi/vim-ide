-- Core keymaps. Plugin keymaps live next to their plugin so which-key groups stay in sync.
local map = function(mode, lhs, rhs, desc) vim.keymap.set(mode, lhs, rhs, { desc = desc, silent = true }) end

map("n", "<Esc>", "<cmd>nohlsearch<cr>", "Clear search highlight")
map("n", "<C-h>", "<C-w>h", "Window left")
map("n", "<C-j>", "<C-w>j", "Window down")
map("n", "<C-k>", "<C-w>k", "Window up")
map("n", "<C-l>", "<C-w>l", "Window right")
map("n", "<S-h>", "<cmd>bprevious<cr>", "Prev buffer")
map("n", "<S-l>", "<cmd>bnext<cr>", "Next buffer")
map("n", "<leader>bd", "<cmd>bdelete<cr>", "Delete buffer")
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
