local cfg = require("config")
return {
  { "stevearc/conform.nvim", event = "BufWritePre", cmd = "ConformInfo",
    keys = { { "<leader>cf", function() require("conform").format({ async = true, lsp_format = "fallback" }) end, mode = { "n", "v" }, desc = "Format" } },
    opts = function()
      return {
        formatters_by_ft = cfg.collect_map("formatters"),
        -- read the setting at save time so the Settings page can toggle it live
        format_on_save = function(buf)
          if not cfg.feature("format_on_save") or vim.g.disable_autoformat or vim.b[buf].disable_autoformat then return end
          return { timeout_ms = 1500, lsp_format = "fallback" }
        end,
      }
    end,
    init = function()
      vim.api.nvim_create_user_command("FormatToggle", function()
        vim.g.disable_autoformat = not vim.g.disable_autoformat
        vim.notify("Autoformat " .. (vim.g.disable_autoformat and "off" or "on"))
      end, {})
    end },

  { "mfussenegger/nvim-lint", enabled = cfg.feature("lint"), event = { "BufReadPost", "BufWritePost" },
    config = function()
      local lint = require("lint")
      lint.linters_by_ft = cfg.collect_map("linters")
      vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost" }, { callback = function()
        local ft = vim.bo.filetype
        if lint.linters_by_ft[ft] then lint.try_lint() end
      end })
    end },
}
