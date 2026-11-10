---
name: nvim-ide
description: Build, extend, debug and maintain a full IDE on Neovim (Lua, lazy.nvim, built-in LSP, treesitter, completion, formatting, DAP debugging, tests, git) driven by one settings file. Includes an embedded Claude Code panel, tabs, file browser, in-editor settings page, shortcut cheat sheet, plugin manager UI and tmux support. Use whenever the user wants to set up or turn Neovim/vim into an IDE, write or fix an init.lua / nvim config, add a language (LSP, formatter, debugger), fix LSP/treesitter/Mason/completion problems, migrate from vimrc/coc/packer/LazyVim, or make an editor setup easier to configure. Trigger even if they only say "vim IDE", "nvim config", "my neovim is broken", or "add Rust to my nvim".
---

# nvim-ide

Gives the user a working Neovim IDE that is easy to use (sane defaults, which-key discoverability, `<leader>` groups), easy to configure (one file, `lua/config/settings.lua`), and easy to maintain (one plugin per concern, languages as data, pinned lockfile, a doctor script).

The design choice that matters: **configuration is data, plumbing is code.** Users toggle languages/features/theme in `settings.lua`; presets in `languages.lua` expand each language into parser + LSP + formatter + linter + debugger + test adapter; the plugin files read those lists. Adding Go is one word, not five edits across five files. Preserve this when changing anything — do not hardcode a language into a plugin file.

## What the IDE has out of the box

- **Look:** colorscheme choice, 29 colorschemes (tokyonight, catppuccin, vscode, github, dracula, nightfox family, everforest, kanagawa, rose-pine, monokai-pro, ayu, ... all switchable live) and a self-written statusline (`config/statusline.lua`, no lualine: `rounded` powerlevel10k-style pills / `powerline` arrows with correct color transitions / `plain`), welcome dashboard with shortcuts. (Real powerlevel10k is a zsh prompt, so it shows in nvim's terminals via the user's own zsh, not as a plugin; the statusline is the nvim counterpart.)
- **VS Code layout:** `config/activitybar.lua` icon column (Explorer, Search & Replace via grug-far, Source Control, Run & Debug, Outline, Plugins; click to switch, click again to hide), breadcrumbs (dropbar), outline (aerial), zen mode, optional minimap, bottom terminal/problems panel, command palette (F1), and VS Code keys in `config/vscode_keys.lua` (F5/F9/F10/F11, Ctrl-P, Ctrl-S, Alt-arrows, Alt-b). Not replicable in a terminal: extension marketplace, pixel-accurate minimap, true multi-cursor, GUI chrome. Buffer-local mouse maps only fire in a focused window, so clicks on non-focused UI go through the global hook in `config/ui_button.lua` (`hooks`).
- **Layout:** self-written tab bar (`config/tabs.lua`: slanted / rounded / flat tabs, pin, move, right-click menu, per-theme colors with enforced contrast), neo-tree file browser sidebar (opens at start), Claude Code side panel via `coder/claudecode.nvim` (needs the `claude` CLI; `<leader>a…`).
- **Discoverability:** which-key popup after `<Space>`, `:IDEHelp` / `<leader>?` cheat sheet (edit `lua/config/cheatsheet.lua` when keymaps change), `<leader>fk` / `<leader>fc` live keymap/command search.
- **Newer modules (one per feature, each with a smoke test):** `config/scm.lua` Source Control sidebar (async git, sequence-checked refresh), `config/doctor.lua` + `config/welcome.lua` first-run check, `config/session.lua` sessions and recent projects, `config/layout.lua` splits and named layouts, `config/tasks.lua` task runner, `config/explorer_actions.lua` and `config/context_menu.lua` (right-click, built on `ui.menu`), `config/tour.lua`, `config/assist.lua` (snippets, Claude on a selection), `config/remote.lua`, `config/palette.lua` (recents plus dynamic entries), `config/updater.lua` (lockfile snapshot, diff, rollback), and the agentic layer: `config/agent.lua` (Claude Code hooks via `--settings` -> spool file -> statusline and toasts), `config/checkpoints.lua` + `extras/ide-checkpoint` (hidden git checkpoints before each prompt, undo/redo a turn), `config/claude_actions.lua` (send context with one key, `claude -p` commit message and PR description). Test the hook layer against the real `claude` CLI, not only stubs. Commands of lazily loaded modules get a stub in `config/autocmds.lua` (`lazycmd`).
- **Checks:** `scripts/dev.sh --skip-mason --no-run` (155 smoke tests + tmux render), `--themes` adds `scripts/theme_check.lua` (contrast of all 29 themes), `nvim-tui-ux/scripts/ui_lint.py --strict`. Test in a clean container (`Dockerfile`) when touching install steps.
- **Settings tab (VS Code style):** a normal buffer named Settings with a headline per section, title+description+control per setting, ● for changed values, ↻ for restart-needed; `:IDESettings` / `<leader>us` / click the gear in the top-right corner (`config/ui_button.lua`) toggles features, edits options, switches theme and language presets; values persist to `stdpath("data")/ide-settings.json` and override `settings.lua`. To expose a new option, add a row to `schema` in `lua/config/settings_ui.lua`.
- **Plugin manager:** lazy.nvim UI on `<leader>pl` (update `pu`, restore `pr`), Mason on `<leader>pm`.
- **Launcher + TUI:** `extras/ide` (install with `scripts/install.sh --link-bin`): `ide`, `ide claude` (Claude panel open), `ide settings` (full-screen settings TUI, same schema as `<leader>us`), `ide help`, `ide sync`. `claude.autostart` opens the panel on every start.
- **tmux:** works inside tmux; see `references/tmux.md` and `assets/template/extras/tmux.conf`.
- **Default languages:** Python, Go, HTML/CSS, JavaScript, Terraform, Bash, Markdown (+ Lua, JSON, YAML).

## UI design system

Every full-screen view (Settings, Help, Plugins) is a *page* built on `lua/config/ui.lua`: shared tokens (rounded borders, `IDE*` highlight roles, `ui.g()` glyphs with ASCII fallbacks), one global click handler (`ui.hooks`), and the page lifecycle. Third-party popups (Telescope, which-key, blink, lazy, Mason) are mapped to the same tokens. When adding or changing any screen, use the companion skill **nvim-tui-ux** (`../nvim-tui-ux`): its `scripts/ui_lint.py <lua-dir> --strict` must pass, and `references/lessons.md` lists the UI bugs already solved.

## Targets and assumptions

Neovim **0.11+** (uses `vim.lsp.config` / `vim.lsp.enable`, `vim.hl`, `winborder`), lazy.nvim, Mason, nvim-treesitter `main` branch, blink.cmp, conform, nvim-lint, nvim-dap, neotest. Vim-only or 0.9/0.10 users: say the template needs a newer nvim and offer to install it rather than backporting.

## Workflow

1. **Detect the situation** (don't ask what you can check):
   - `command -v nvim && nvim --version | head -1`, existing `~/.config/nvim`, OS/package manager, which languages appear in the cwd (look for `pyproject.toml`, `go.mod`, `Cargo.toml`, `package.json`, `CMakeLists.txt`…).
   - If an existing config exists, read it before touching it. Offer to keep their keymaps/options by moving them into `settings.lua` (`options`, `keymaps`, `extra_plugins`) instead of discarding.
2. **Install** with `scripts/install.sh [--target DIR] [--langs a,b,c]`. It backs up any existing config (never deletes), copies `assets/template/`, sets languages, syncs plugins headless if nvim exists, and runs the doctor. Use `--target` to try it side-by-side (`NVIM_APPNAME=<dirname> nvim`).
3. **Verify** with `scripts/doctor.sh [dir]`. Fix what it reports (missing nvim ≥0.11, no C compiler/`tree-sitter` CLI, no Nerd Font → `features.icons=false`). If nvim is available also run `nvim --headless "+checkhealth vim.lsp" "+qa"` or open a file of each language and check `:LspInfo` / `:checkhealth`. If nvim isn't installed, say plainly that runtime behaviour is unverified and only syntax (`luajit -bl`) was checked.
4. **Customize** by editing `settings.lua` first. Only touch plugin files when settings can't express the change; if you find yourself doing that twice, add a setting.
5. **Hand over a short cheat sheet**: leader is `<Space>`, press it and wait for which-key; `<leader><space>` find file, `<leader>e` explorer, `gd/gr/K` LSP, `<leader>cf` format, `<leader>d…` debug, `<leader>t…` test/terminal. Full list: `references/keymaps.md`.

## Making changes (the common requests)

| Request | Do this |
|---|---|
| Add/remove a language | Add its name to `languages` in `settings.lua`. If no preset exists, add one block to `languages.lua` (see `references/adding-language.md`). |
| Different theme | `colorscheme = "catppuccin"` etc. Add new themes to `M.themes` and `M.names` in `lua/config/theme.lua`; verify each with `:colorscheme <name>` (avoid plugins that ship a rockspec: lazy tries to build them with hererocks). |
| Tweak an LSP server | `lsp_overrides = { pyright = { settings = … } }` in `settings.lua`. |
| Turn off debug/test/git/format-on-save | `features.<name> = false`. |
| Extra plugin | Append a normal lazy spec to `extra_plugins`. |
| Custom keymap | `keymaps = { { "n", "<leader>xx", "<cmd>…<cr>", "Desc" } }`. |
| Expose a new option in the Settings page | Add a row to `schema` in `lua/config/settings_ui.lua` (and a default in `settings.lua`). |
| tmux problems (lag on Esc, colors, Ctrl-hjkl, clipboard) | `references/tmux.md`; `scripts/doctor.sh` checks the tmux settings. |
| Something broke | `references/troubleshooting.md`, starting from `:checkhealth`, `:Lazy`, `:Mason`, `:LspInfo`, `:ConformInfo`. |
| Reproducible installs | Commit `lazy-lock.json`; update deliberately with `:Lazy update`, roll back with `:Lazy restore`. |

## Conventions to keep (they are what makes it maintainable)

- One concern per file in `lua/plugins/`; file names say what they do (`lsp.lua`, `debug.lua`).
- Every `desc` on a keymap, and a which-key group for each `<leader>x` prefix, so the user can discover instead of memorize.
- Gate optional subsystems with `cfg.feature("name")` so turning them off removes the plugins entirely.
- Prefer built-in Neovim features (LSP client, `vim.hl.on_yank`, native commenting `gc`, `vim.lsp.config`) over plugins. Fewer plugins = fewer breakages on upgrade.
- Plugin APIs churn (treesitter `main`, mason-lspconfig v2, blink.cmp). Before changing plugin setup code from memory, check the plugin's README or current docs; a stale snippet is the most common way these configs break.
- When switching a feature off, grep for things that depend on it (e.g. a test key that starts the debugger) so no keymap is left pointing at a plugin that isn't loaded.
- Never run destructive commands against the user's real config without the backup the installer makes. When experimenting, use `--target` and `NVIM_APPNAME`.
- Mention external dependencies a feature needs (ripgrep for grep, lazygit, a Nerd Font, `tree-sitter` CLI) at the moment you enable it, not after it fails.

## Bundled files

- `assets/template/` — the complete config copied by the installer. Entry `init.lua`; settings `lua/config/settings.lua`; presets `lua/config/languages.lua`; helpers `lua/config/init.lua`; plugins `lua/plugins/*.lua`.
- `scripts/install.sh`, `scripts/doctor.sh` — install with backup; dependency/syntax/startup check.
- `references/keymaps.md` — every default binding.
- `references/adding-language.md` — preset schema and a worked example.
- `references/troubleshooting.md` — symptom → cause → fix.
- `references/tmux.md` — tmux setup and why each setting matters.
- `assets/template/extras/tmux.conf` — snippet for `~/.tmux.conf`.
