local cfg = require("config")
local adapters = cfg.collect("neotest")
local deps = { "nvim-lua/plenary.nvim", "nvim-neotest/nvim-nio", "antoinemadec/FixCursorHold.nvim", "nvim-treesitter/nvim-treesitter" }
vim.list_extend(deps, adapters)

return {
  { "nvim-neotest/neotest", enabled = cfg.feature("test"), dependencies = deps,
    keys = vim.list_extend({
      { "<leader>tn", function() require("neotest").run.run() end, desc = "Run nearest test" },
      { "<leader>tf", function() require("neotest").run.run(vim.fn.expand("%")) end, desc = "Run file tests" },
      { "<leader>ts", function() require("neotest").summary.toggle() end, desc = "Test summary" },
      { "<leader>to", function() require("neotest").output_panel.toggle() end, desc = "Test output" },
    }, cfg.feature("debug") and { -- only bind when the debugger is enabled
      { "<leader>td", function() require("neotest").run.run({ strategy = "dap" }) end, desc = "Debug nearest test" },
    } or {}),
    config = function()
      local loaded = {}
      for _, repo in ipairs(adapters) do
        local mod = repo:match("/(.+)$")
        local ok, adapter = pcall(require, mod)
        if ok then loaded[#loaded + 1] = adapter else vim.notify("neotest adapter failed: " .. mod, vim.log.levels.WARN) end
      end
      require("neotest").setup({ adapters = loaded, floating = { border = "rounded" } })
    end },
}
