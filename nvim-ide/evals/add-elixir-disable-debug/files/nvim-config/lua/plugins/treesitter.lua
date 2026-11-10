-- Uses the `main` branch API (Neovim 0.11+). Needs `tree-sitter` CLI + a C compiler to build parsers.
local cfg = require("config")
return {
  { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()
      local parsers = cfg.collect("parsers")
      vim.list_extend(parsers, { "regex", "diff", "gitcommit", "query" })
      pcall(function() ts.install(parsers) end)

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(a)
          if pcall(vim.treesitter.start, a.buf) then
            vim.bo[a.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end },
}
