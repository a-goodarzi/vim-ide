return {
  { "akinsho/toggleterm.nvim", version = "*", enabled = require("config").feature("terminal"),
    cmd = { "ToggleTerm", "TermExec" },
    keys = {
      -- In terminal mode a bare <C-\> mapping would shadow Neovim's <C-\><C-n> (leave terminal mode), so the
      -- terminal-mode toggle is <C-\><C-\>.
      { "<C-\\>", "<cmd>ToggleTerm direction=float<cr>", desc = "Floating terminal" },
      { "<C-\\><C-\\>", "<cmd>ToggleTerm direction=float<cr>", mode = "t", desc = "Close floating terminal" },
      { "<leader>tt", "<cmd>ToggleTerm direction=horizontal<cr>", desc = "Terminal (split)" },
      { "<leader>tf", "<cmd>ToggleTerm direction=float<cr>", desc = "Terminal (float)" },
      { "<leader>tg", function()
          local Terminal = require("toggleterm.terminal").Terminal
          if vim.fn.executable("lazygit") == 0 then return vim.notify("lazygit not installed", vim.log.levels.WARN) end
          Terminal:new({ cmd = "lazygit", direction = "float", hidden = true }):toggle()
        end, desc = "Lazygit" },
    },
    opts = { size = 15, float_opts = { border = "rounded" } } },
}
