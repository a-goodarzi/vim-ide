local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
  vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", "https://github.com/folke/lazy.nvim.git", path })
end
vim.opt.rtp:prepend(path)
require("lazy").setup({ { import = "plugins" } })
