local group = vim.api.nvim_create_augroup("ide", { clear = true })
local au = function(ev, opts) opts.group = group; vim.api.nvim_create_autocmd(ev, opts) end

au("TextYankPost", { callback = function() vim.hl.on_yank() end })

-- Reopen at last cursor position
au("BufReadPost", {
  callback = function(a)
    local m = vim.api.nvim_buf_get_mark(a.buf, '"')
    if m[1] > 0 and m[1] <= vim.api.nvim_buf_line_count(a.buf) then pcall(vim.api.nvim_win_set_cursor, 0, m) end
  end,
})

-- Reload files changed outside nvim
au({ "FocusGained", "BufEnter" }, { command = "checktime" })

-- Wrap + spell for prose
au("FileType", { pattern = { "markdown", "gitcommit", "text" }, callback = function()
  vim.opt_local.wrap = true; vim.opt_local.spell = true
end })

-- Per-language indentation (Go/C/Rust/Python conventions)
au("FileType", { pattern = { "go" }, callback = function() vim.opt_local.expandtab = false; vim.opt_local.tabstop = 4; vim.opt_local.shiftwidth = 4 end })
au("FileType", { pattern = { "python", "rust", "c", "cpp", "java" }, callback = function() vim.opt_local.shiftwidth = 4; vim.opt_local.tabstop = 4 end })
