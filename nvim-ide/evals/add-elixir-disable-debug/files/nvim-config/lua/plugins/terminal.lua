return {
  { "akinsho/toggleterm.nvim", version = "*", enabled = require("config").feature("terminal"),
    keys = {
      { "<C-\\>", "<cmd>ToggleTerm direction=float<cr>", mode = { "n", "t" }, desc = "Floating terminal" },
      { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (split)" },
      { "<leader>tg", function()
          local Terminal = require("toggleterm.terminal").Terminal
          if vim.fn.executable("lazygit") == 0 then return vim.notify("lazygit not installed", vim.log.levels.WARN) end
          Terminal:new({ cmd = "lazygit", direction = "float", hidden = true }):toggle()
        end, desc = "Lazygit" },
    },
    opts = { size = 15, float_opts = { border = "rounded" } } },
}
