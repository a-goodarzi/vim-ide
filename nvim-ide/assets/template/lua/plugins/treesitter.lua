-- Uses the `main` branch API (Neovim 0.11+). Needs `tree-sitter` CLI + a C compiler to build parsers.
local cfg = require("config")
return {
  { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()
      local parsers = cfg.collect("parsers")
      vim.list_extend(parsers, { "regex", "diff", "gitcommit", "query" })
      if vim.fn.executable("tree-sitter") == 0 then
        -- Parsers are built with the tree-sitter CLI. Say so once instead of failing for every language.
        vim.schedule(function()
          vim.notify("The tree-sitter CLI is not installed, so syntax parsers cannot be built.\nmacOS: brew install tree-sitter-cli   Linux: see :IDEDoctor (or npm i -g tree-sitter-cli)\nThen restart nvim.", vim.log.levels.WARN, { title = "Treesitter" })
        end)
      else
        pcall(function() ts.install(parsers) end)
      end

      vim.api.nvim_create_autocmd("FileType", {
        callback = function(a)
          if pcall(vim.treesitter.start, a.buf) then
            vim.bo[a.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
          end
        end,
      })
    end },
}
