-- Entry point. Keep this tiny: real settings live in lua/config/settings.lua.
vim.loader.enable()
require("config.options")
require("config.keymaps")
require("config.autocmds")
require("config.lazy")
