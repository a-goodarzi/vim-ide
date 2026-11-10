# Adding a language preset

Open `lua/config/languages.lua`, copy a block, then add the key to `languages` in `settings.lua`. All fields are optional.

| Field | Meaning | Where to find the name |
|---|---|---|
| `parsers` | treesitter parsers | `:TSInstallFromGrammar`, nvim-treesitter docs |
| `lsp` | lspconfig server names | `:help lspconfig-all` — these are lspconfig names (`ts_ls`), not Mason names (`typescript-language-server`) |
| `mason` | extra Mason packages (formatters, linters) | `:Mason` — Mason names |
| `formatters` | `{ filetype = { "tool" } }` for conform | `:help conform-formatters` |
| `linters` | `{ filetype = { "tool" } }` for nvim-lint | nvim-lint README |
| `dap` | mason-nvim-dap adapter names | mason-nvim-dap README |
| `neotest` | adapter plugin repo `owner/name` | neotest README adapter list |

Example (Elixir):

```lua
elixir = {
  parsers = { "elixir", "heex", "eex" },
  lsp = { "elixirls" },
  formatters = { elixir = { "mix" } },   -- built into conform, no install needed
},
```

Then `languages = { …, "elixir" }`, restart nvim; Mason installs the server on first launch. Check with `:LspInfo` in an `.ex` file.

Servers needing special setup (jdtls, rust-analyzer via rustaceanvim): add the plugin through `extra_plugins` and leave `lsp` empty for that language so two clients don't attach.
