-- A hand-rolled settings popup (written before there was any design system)
local M = {}
local buf, win

function M.open()
  buf = vim.api.nvim_create_buf(false, true)
  vim.api.nvim_buf_set_lines(buf, 0, -1, false, {
    " Settings",
    " \xef\x80\x93  Theme: tokyonight",
    " [x] Format on save",
    " [ ] Relative numbers",
  })
  win = vim.api.nvim_open_win(buf, true, { relative = "editor", width = 40, height = 8, row = 3, col = 10, style = "minimal" })
  vim.api.nvim_set_hl(0, "SettingsTitle", { fg = "#ff8800", bold = true })
  vim.api.nvim_set_hl(0, "SettingsOn", { fg = "#00ff00" })
  vim.api.nvim_buf_add_highlight(buf, -1, "SettingsTitle", 0, 0, -1)
  vim.keymap.set("n", "<LeftMouse>", function()
    local m = vim.fn.getmousepos()
    vim.api.nvim_win_set_cursor(win, { m.line, 0 })
  end, { buffer = buf })
  vim.keymap.set("n", "q", function() vim.api.nvim_win_close(win, true) end, { buffer = buf })
end

vim.api.nvim_create_user_command("MySettings", M.open, {})
return M
