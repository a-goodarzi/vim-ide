# Changelog

## 0.17.0 - Theme contrast check

`scripts/theme_check.lua` (or `dev.sh --themes`) measures contrast for all 29 themes. Fixes it found: dark themes no longer inherit the previous light variant, idle tab text is always readable, near-black themes get a visible tab strip, solarized-osaka follows the transparent setting and the Explorer keeps the editor background after a live theme switch.

## 0.16.0 - Guided tour

`:IDETour` (palette, or key t on the welcome page) walks through the activity bar, tabs, editor, command palette and statusline with five short callouts.

## 0.15.0 - Right-click menus

Right-click in the editor or on an Explorer entry opens a context menu (definition, references, rename, format, clipboard, Claude, split; open, new, rename, delete, copy path, terminal here). One shared menu widget now also powers the tab menu. Also fixes a late Source Control refresh overwriting a newer one.

## 0.14.0 - Smarter command palette

The palette lists recently used entries first and adds your project tasks, recent projects, git actions and one entry per theme.

## 0.13.0 - Remote and containers

SSH shell, edit a remote file over scp, shell in a running container or the folder's dev container.

## 0.12.0 - Snippets and Claude on a selection

Snippet browser for the current file type and an action that sends the selection or file to Claude.

## 0.11.0 - Problems panel

The Problems panel groups diagnostics by file with counts and takes focus when opened.

## 0.10.0 - Explorer actions

Terminal in the folder, copy path, open in the system file manager and search inside a folder from the Explorer.

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
