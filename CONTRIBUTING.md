# Contributing

Thanks for helping. This is a Neovim configuration, so most changes are small Lua edits. The rules below keep it that way.

## Set up

```sh
git clone https://github.com/a-goodarzi/vim-ide.git
cd vim-ide/nvim-ide
bash scripts/dev.sh --skip-mason          # installs into ~/.config/nvim-ide (symlink: edits are live) and runs the checks
```

It uses `NVIM_APPNAME=nvim-ide`, so your own `~/.config/nvim` is never touched. Start the IDE with `ide`.

## Before you open a pull request

```sh
bash nvim-ide/scripts/dev.sh --skip-mason --no-run          # smoke tests + tmux render check
bash nvim-ide/scripts/dev.sh --skip-mason --skip-tmux --themes --no-run   # also the contrast check of all themes
python3 nvim-tui-ux/scripts/ui_lint.py --strict nvim-ide/assets/template/lua     # UI rules: expect 0 errors, 0 warnings
```

- Add a smoke test (`nvim-ide/scripts/smoke.lua`) for new behaviour. Each feature has its own `do ... end` block.
- Check Lua syntax of a file with `luajit -bl FILE /dev/null` (one file at a time).
- Run the real UI in tmux when you change layout: sidebars, tabs, pages and menus are easy to break in ways headless tests miss.
- Keep the design uniform: use `config/ui.lua` (borders, `IDE*` highlight roles, the page and menu helpers) instead of new colours or custom windows. `nvim-tui-ux/references/lessons.md` explains why.

## Conventions

- New feature: a module in `lua/config/` (or a plugin spec in `lua/plugins/`), a switch under `features` in `config/settings.lua` and `config/settings_ui.lua` when it should be optional, an entry in the palette (`config/palette.lua`), the Help page (`config/help.lua`, `config/cheatsheet.lua`) and the README.
- Defaults live in `config/settings.lua`; a user's choices are saved separately and must keep working after updates.
- One feature per pull request. Releases are tagged `vMAJOR.MINOR.PATCH` and listed in `CHANGELOG.md`.
- Never commit secrets, tokens or personal paths. The repository is public.

## Reporting a problem

Use the issue templates. Please include `nvim --version`, your terminal and font, whether you use tmux, and the output of `:checkhealth` or `:messages` when something errors.

## License

By contributing you agree that your work is released under the GPL-3.0-or-later license of this project.
