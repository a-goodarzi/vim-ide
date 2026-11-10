# Adding a language, a theme or a feature

## A language

Languages are presets in `nvim-ide/assets/template/lua/config/languages.lua`. A preset lists the language server, formatter, linter,
tree-sitter parser and debug adapter. Add a table there, then add its name to `languages` in `config/settings.lua` (or tick it in
Settings > Languages). Mason installs the tools on the next start. Check with `:checkhealth`, `:LspInfo` and `:Mason`.

## A colour theme

1. Add the plugin to `M.themes` in `lua/config/theme.lua`: `["name"] = { "owner/repo", "colorscheme-name", "lazy-plugin-name (optional)" }`,
   and the name to `M.names`.
2. If the theme itself is light, add it to `M.light` in the same file.
3. Run `bash nvim-ide/scripts/dev.sh --skip-mason --skip-tmux --themes --no-run`. The contrast check lists any theme whose tabs or text are hard to read.

## A feature

1. Write the module in `lua/config/<name>.lua`. Use `config/ui.lua` for borders, highlight roles, `ui.page` (full-screen pages) and `ui.menu` (context menus).
2. Commands that should exist before the module loads get a stub in `config/autocmds.lua` (`lazycmd`).
3. Optional features get a switch: `features.<name>` in `config/settings.lua` and a row in `config/settings_ui.lua`.
4. Add a palette entry (`config/palette.lua`), Help text (`config/help.lua`, `config/cheatsheet.lua`) and a README line.
5. Add a `do ... end` block to `scripts/smoke.lua` and run the checks listed in `CONTRIBUTING.md`.
6. Add a line to `CHANGELOG.md` and bump `VERSION`.
