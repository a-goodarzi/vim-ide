# Changelog

## 0.9.0 - Test runner

Run all / last / stop keys and palette entries for neotest, with pass and fail marks in the gutter.

## 0.8.0 - Task runner

Finds Makefile targets, npm scripts, go, pytest, cargo, terraform, justfile and .vscode tasks and runs them in the terminal panel (`<Space>rt`, `<Space>rr`).

## 0.7.0 - Splits and layouts

Split right / below, close, maximize and equalize editor windows; save and load named layouts.

## 0.6.0 - Tab features

Right-click a tab for pin, move, close others / to the right, copy path and reveal in Explorer. Alt-< / Alt-> move a tab; Shift-h / Shift-l follow the tab order.

## 0.5.0 - Session restore and recent projects

Quitting saves the open files per folder and `ide` reopens them. Palette > Recent projects (and the dashboard `o` key) switches folders.

## 0.4.0 - First-run welcome and doctor

A welcome page on the first start (icon check, tool check, first keys) and `:IDEDoctor`, which lists missing tools with the exact install command for your system.

## 0.3.0 - Source Control sidebar

A real Git panel: branch, commit box, staged / changed / untracked files, click for the diff, + - x to stage, unstage or discard, buttons for commit, pull and push, branch switching.

## 0.2.0 - Debugger option

Settings > Features > Debugger switches Run & Debug on or off: the activity-bar icon, F5/F9/F10/F11, the palette entries and the debug plugins all follow it.

## 0.1.0

First public release: VS Code-style Neovim IDE (activity bar, tab bar, Search & Replace, terminal, Claude Code panel,
Settings and Help pages, curated command palette, 29 themes, nine language presets), the `dev.sh` / `install.sh` /
`doctor.sh` scripts, 98 smoke tests, and the `nvim-ide` and `nvim-tui-ux` Claude skills.
