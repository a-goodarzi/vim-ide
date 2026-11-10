local cfg = require("config")
vim.g.mapleader = cfg.settings.leader or " "
vim.g.maplocalleader = "\\"

local o = vim.opt
o.number = true
o.relativenumber = true
o.signcolumn = "yes"
o.cursorline = true
o.termguicolors = true
o.scrolloff = 8
o.mouse = "a"
o.clipboard = "unnamedplus"
o.ignorecase = true
o.smartcase = true
o.splitright = true
o.splitbelow = true
o.undofile = true
o.updatetime = 200
o.timeoutlen = 400
o.expandtab = true
o.shiftwidth = 2
o.tabstop = 2
o.smartindent = true
o.wrap = false
o.list = true
o.listchars = { tab = "» ", trail = "·", nbsp = "␣" }
o.completeopt = "menu,menuone,noselect"
o.winborder = "rounded"
o.laststatus = 3

for k, v in pairs(cfg.settings.options or {}) do o[k] = v end

-- Window title (tmux shows it in the status bar / pane title)
o.title = true
o.titlestring = "nvim %t"

-- Clipboard inside tmux/ssh with no system tool: fall back to OSC 52 (tmux: set-clipboard on)
if (vim.env.TMUX or vim.env.SSH_TTY) and vim.fn.executable("wl-copy") == 0 and vim.fn.executable("xclip") == 0
  and vim.fn.executable("xsel") == 0 and vim.fn.executable("pbcopy") == 0 then
  local osc = require("vim.ui.clipboard.osc52")
  vim.g.clipboard = { name = "OSC 52", copy = { ["+"] = osc.copy("+"), ["*"] = osc.copy("*") },
    paste = { ["+"] = osc.paste("+"), ["*"] = osc.paste("*") } }
end
