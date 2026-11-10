local path = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(path) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", path })
  if vim.v.shell_error ~= 0 then error("Failed to clone lazy.nvim:\n" .. out) end
end
vim.opt.rtp:prepend(path)

local spec = { { import = "plugins" } }
vim.list_extend(spec, require("config").settings.extra_plugins or {})

require("lazy").setup({
  spec = spec,
  lockfile = vim.fn.stdpath("config") .. "/lazy-lock.json", -- commit this for reproducible installs
  install = { colorscheme = { require("config").settings.colorscheme, "habamax" } },
  checker = { enabled = false },
  change_detection = { notify = false },
})
