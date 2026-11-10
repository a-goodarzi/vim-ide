-- Uses the `main` branch API (Neovim 0.11+). Needs `tree-sitter` CLI + a C compiler to build parsers.
local cfg = require("config")
return {
  { "nvim-treesitter/nvim-treesitter", branch = "main", lazy = false, build = ":TSUpdate",
    config = function()
      local ts = require("nvim-treesitter")
      ts.setup()
      local parsers = cfg.collect("parsers")
      vim.list_extend(parsers, { "regex", "diff", "gitcommit", "query" })
      -- nvim may start with a shorter PATH than your terminal: ask the login shell before giving up
      if vim.fn.executable("tree-sitter") == 0 then pcall(function() require("config.path").find("tree-sitter") end) end
      if vim.fn.executable("tree-sitter") == 0 then
        -- Parsers are built with the tree-sitter CLI. Say so once instead of failing for every language.
        vim.schedule(function()
          vim.notify("nvim cannot find the tree-sitter CLI (it is not on nvim's PATH, and your login shell did not report it), so syntax parsers cannot be built.\nRun `which tree-sitter` in a terminal. If it prints a folder, add it to extra_path in settings.lua (:IDEDoctor shows the rest).\nNot installed: macOS brew install tree-sitter-cli (or npm i -g tree-sitter-cli, or cargo install --locked tree-sitter-cli); Linux see :IDEDoctor.", vim.log.levels.WARN, { title = "Treesitter" })
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
