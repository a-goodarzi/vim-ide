-- Language presets. To add a language: copy a block, change the names, add it to
-- `languages` in settings.lua. Names are Mason package names (:Mason to browse).
--   parsers    treesitter parsers          lsp        lspconfig server names
--   mason      extra Mason packages (formatters/linters)
--   formatters conform.nvim by filetype    linters    nvim-lint by filetype
--   dap        mason-nvim-dap adapters     neotest    neotest adapter plugin repo
return {
  lua = {
    parsers = { "lua", "luadoc", "vim", "vimdoc" },
    lsp = { "lua_ls" },
    mason = { "stylua" },
    formatters = { lua = { "stylua" } },
  },
  python = {
    parsers = { "python" },
    lsp = { "basedpyright", "ruff" },
    mason = {},
    formatters = { python = { "ruff_format", "ruff_organize_imports" } },
    dap = { "python" },
    neotest = "nvim-neotest/neotest-python",
  },
  typescript = {
    parsers = { "typescript", "tsx", "javascript" },
    lsp = { "ts_ls", "eslint" },
    mason = { "prettierd" },
    formatters = {
      typescript = { "prettierd" }, typescriptreact = { "prettierd" },
      javascript = { "prettierd" }, javascriptreact = { "prettierd" },
    },
    dap = { "js" },
    neotest = "nvim-neotest/neotest-jest",
  },
  go = {
    parsers = { "go", "gomod", "gosum" },
    lsp = { "gopls" },
    mason = { "goimports", "gofumpt" },
    formatters = { go = { "goimports", "gofumpt" } },
    dap = { "delve" },
    neotest = "fredrikaverpil/neotest-golang",
  },
  rust = {
    parsers = { "rust", "toml" },
    lsp = { "rust_analyzer" },
    formatters = { rust = { "rustfmt" } }, -- rustfmt ships with rustup
    dap = { "codelldb" },
    neotest = "rouge8/neotest-rust",
  },
  c = {
    parsers = { "c", "cpp", "cmake", "make" },
    lsp = { "clangd" },
    mason = { "clang-format" },
    formatters = { c = { "clang-format" }, cpp = { "clang-format" } },
    dap = { "codelldb" },
  },
  bash = {
    parsers = { "bash" },
    lsp = { "bashls" },
    mason = { "shfmt", "shellcheck" },
    formatters = { sh = { "shfmt" }, bash = { "shfmt" } },
    linters = { sh = { "shellcheck" }, bash = { "shellcheck" } },
  },
  json = {
    parsers = { "json" },
    lsp = { "jsonls" },
    mason = { "prettierd" },
    formatters = { json = { "prettierd" }, jsonc = { "prettierd" } },
  },
  yaml = {
    parsers = { "yaml" },
    lsp = { "yamlls" },
    mason = { "prettierd" },
    formatters = { yaml = { "prettierd" } },
  },
  markdown = {
    parsers = { "markdown", "markdown_inline" },
    lsp = { "marksman" },
    mason = { "prettierd" },
    formatters = { markdown = { "prettierd" } },
  },
  html_css = {
    parsers = { "html", "css", "scss" },
    lsp = { "html", "cssls" },
    mason = { "prettierd" },
    formatters = { html = { "prettierd" }, css = { "prettierd" }, scss = { "prettierd" } },
  },
  javascript = {
    parsers = { "javascript", "jsdoc" },
    lsp = { "ts_ls", "eslint" },
    mason = { "prettierd" },
    formatters = { javascript = { "prettierd" }, javascriptreact = { "prettierd" } },
    dap = { "js" },
    neotest = "nvim-neotest/neotest-jest",
  },
  terraform = {
    parsers = { "terraform", "hcl" },
    lsp = { "terraformls", "tflint" },
    mason = { "tflint" },
    formatters = { terraform = { "terraform_fmt" }, ["terraform-vars"] = { "terraform_fmt" } }, -- needs `terraform` (or swap for tofu_fmt)
  },
  java = {
    parsers = { "java" },
    lsp = { "jdtls" },
    dap = { "javadbg" },
  },
  php = { parsers = { "php" }, lsp = { "intelephense" } },
  ruby = { parsers = { "ruby" }, lsp = { "ruby_lsp" } },
  zig = { parsers = { "zig" }, lsp = { "zls" } },
  nix = { parsers = { "nix" }, lsp = { "nil_ls" }, mason = { "nixpkgs-fmt" }, formatters = { nix = { "nixpkgs-fmt" } } },
  elixir = {
    parsers = { "elixir", "heex", "eex" },
    lsp = { "elixirls" },
    formatters = { elixir = { "mix" }, eelixir = { "mix" }, heex = { "mix" } }, -- needs `mix` on PATH
    neotest = "jfpedroza/neotest-elixir",
  },
  docker = { parsers = { "dockerfile" }, lsp = { "dockerls" } },
  toml = { parsers = { "toml" }, lsp = { "taplo" } },
  sql = { parsers = { "sql" }, mason = { "sqlfluff" }, formatters = { sql = { "sqlfluff" } } },
}
