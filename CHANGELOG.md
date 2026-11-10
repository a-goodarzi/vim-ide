# Changelog

## 0.31.0 - Customizable shortcuts

A Shortcuts page lists every VS Code-style key. Press Enter on a row and then the new key to change it, d to unbind, r to restore the default. Open it with :IDEShortcuts, <Space>uk, the palette or K on the Settings page. Choices apply at once and are saved in the settings file. A key already in use is refused.
## 0.30.4 - Claude panel opens in insert mode

The panel was opening in normal mode (you had to press i); it now enters insert mode when created and when you move into it. The minimap no longer stays drawn on top of the panel (it is hidden once the panel is recognised).

## 0.30.3 - Typing in the Claude panel

Entering or opening the Claude panel (click, Alt-hjkl, :wincmd, first open) now switches the terminal to insert mode, so typing goes to Claude and is not read as Vim normal-mode keys.

## 0.30.2 - Smoke test fix

The absolute-path check for the Claude command now accepts the shell-quoted path. No behaviour change.

## 0.30.1 - Claude panel starts again

The agent-status wrapper ran a bare `claude` through env, which fails when claude is only an alias or lives in ~/.claude/local (the panel then closed at once). It now resolves the claude binary like claudecode.nvim does (setting, PATH, ~/.claude/local, ~/.local/bin, Homebrew, npm, your login shell) and falls back to the plain panel when it cannot find it.

## 0.30.0 - Claude actions

One key sends the right context to Claude: the problem under the cursor (<Space>ax), an explanation or tests for a line, selection or file (ae, aT), the last terminal output (aL) and the staged diff for review (aR); the prompt is typed into the panel and Enter stays with you. Claude also writes the commit message (the sparkle in the Source Control commit box, or g) and the pull request description in the background with claude -p. Also in the right-click menu and the palette. Verified with the real claude CLI.

## 0.29.0 - Undo agent turns

Before every prompt you send to Claude, the whole working tree is recorded as a hidden git checkpoint (refs/ide-checkpoints, newest 30; your index, branch and stash are untouched). <Space>au undoes the last agent turn (files Claude added are removed, edits and deletions are reverted, with a confirmation), :IDERedoTurn undoes the undo, :IDECheckpoints restores any checkpoint. Verified end to end with the real claude CLI.

## 0.28.0 - Agent status

The statusline shows what Claude Code is doing (working with the tool name, needs you, done) and a toast appears when it needs a permission or has finished. The IDE starts Claude with hooks passed through --settings (your own settings file is untouched); :IDEAgent shows the activity log. Verified against the real claude CLI.

## 0.27.0 - Bigger icons

Settings > Appearance > Icon size (default large): the activity bar uses 4-row tiles with a filled active tile and a colour per view, and icons get room after them in the tab bar so a wide glyph can grow. For the largest icons use a Nerd Font variant without "Mono" in its name (a terminal draws text on a grid, so the font decides the glyph size).

## 0.26.0 - Card-style Settings, Help and Plugins

Every setting is its own rounded card: a coloured title and status tag (changed / needs restart), a switch for on/off, filled option chips for choices (click one to pick it) and an input box for values. Sections get an icon and their own accent colour. Help topics, Plugins actions and the Doctor use the same cards and status chips (new builder helpers: card, span, chips).

## 0.25.1 - Find tools your shell knows

When nvim cannot find a tool (tree-sitter, node, rg ...) it now asks your interactive login shell where it is (nvm, mise, asdf and custom Homebrew prefixes) and adds that folder to its PATH. A new extra_path setting lists folders by hand. The tree-sitter warning is shorter and tells you what to check.

## 0.25.0 - Mac shortcut notation

On macOS (or with Settings > Appearance > Shortcut notation = mac) Help, the command palette, the tour and the welcome page show shortcuts as ⌃ ⌥ ⇧ instead of Ctrl / Alt / Shift, with a note about sending Option as Meta. The tree-sitter hints now also list npm, cargo and release-binary installs in case the Homebrew formula is unavailable.

## 0.24.0 - ide update updates the IDE

`ide update` now updates the IDE itself (latest release from GitHub, with the changelog of what is new), then plugins and tools; `ide update check` only looks, `ide update ide|plugins` does one half, `ide version` shows the version. Local edits block the IDE update. Also: nvim and the launcher append Homebrew, cargo and npm bin folders to PATH, so tools like tree-sitter are found even from a minimal shell, and the doctor shows the tree-sitter version.

## 0.23.2 - macOS tree-sitter fix

On macOS the tree-sitter CLI is the `tree-sitter-cli` Homebrew formula (`tree-sitter` is only the library): README, dev.sh, the doctor and the Homebrew template now say so. Without the CLI, nvim now shows one clear warning instead of an error per language.

## 0.23.1 - Documentation update

README, repository layout, the nvim-ide skill and three new lessons (async sequence checks, theme background, clean-container installs) are brought up to date with 0.14 to 0.23.

## 0.23.0 - Safe updates

`ide update` / :IDEUpdate saves the plugin lockfile first and lists what changed (updated, added, removed); `ide rollback` / :IDERollback puts the saved lockfile back and restores those plugin versions. Verified end to end in a clean container.

## 0.22.0 - Demo GIF

docs/demo.gif shows the palette, search, source control, terminal, tour and settings; `nvim-ide/scripts/make_demo.py` re-records it from a throw-away project and refuses to publish a screen that shows your user or machine name.

## 0.21.0 - Install options

A one-line installer with a checksum (install.sh), a Dockerfile to try the IDE without installing (the image builds and passes all smoke tests on a clean Fedora), and a Homebrew formula template. dev.sh no longer fails on an account that has no ~/.config yet.

## 0.20.0 - Contribution docs

CONTRIBUTING.md, a guide to adding a language, theme or feature, issue and pull request templates.

## 0.19.0 - Small fixes

Clicking the active Plugins icon closes the Plugins page like the other views hide their sidebar, and the minimap steps aside for full-screen pages (Settings, Help, Plugins) instead of drawing over them.

## 0.18.0 - Tab style option

Settings > Appearance > Tab style switches the tab bar between slanted (trapezoids), rounded (pills) and flat (plain blocks), live.

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
