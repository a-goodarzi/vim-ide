-- top-right button that opens the settings popup
local buf = vim.api.nvim_create_buf(false, true)
vim.api.nvim_buf_set_lines(buf, 0, -1, false, { " \xef\x80\x93 " })
local btn
vim.api.nvim_create_autocmd("VimEnter", { callback = function()
  btn = vim.api.nvim_open_win(buf, false, { relative = "editor", row = 0, col = vim.o.columns - 3, width = 3, height = 1, style = "minimal" })
end })
vim.keymap.set({ "n", "i" }, "<LeftMouse>", function()
  local m = vim.fn.getmousepos()
  if btn and m.winid == btn then require("settings_screen").open(); return "" end
  return "<LeftMouse>"
end, { expr = true })
