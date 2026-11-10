# Troubleshooting

Start with `scripts/doctor.sh`, then `:checkhealth` in nvim.

| Symptom | Likely cause | Fix |
|---|---|---|
| Error mentioning `vim.lsp.config` / `vim.lsp.enable` nil | nvim < 0.11 | Upgrade nvim (AppImage / package manager / bob). |
| No LSP in a file | Server not installed or filetype not covered | `:Mason` (is it installed?), `:LspInfo`, `:set ft?`; confirm the language is in `settings.languages`. |
| Server installed but never attaches | Root not found (no `.git`/project file) | Open nvim from the project root; check `:LspInfo` for root dir. |
| Treesitter errors / no highlighting | Missing `tree-sitter` CLI or C compiler (`main` branch builds parsers locally) | Install both, then `:TSUpdate`. |
| `unknown language preset` warning | Typo in `settings.languages` | Names must match keys in `languages.lua`. |
| Garbled icons | No Nerd Font | Install one and select it in the terminal, or `features.icons = false`. |
| Live grep does nothing | ripgrep missing | Install `ripgrep`. |
| Format on save does nothing | Formatter not installed | `:ConformInfo`; add the tool to the preset's `mason` list; `:Mason`. |
| Slow startup | A plugin loading eagerly | `:Lazy profile`; add `event`/`cmd`/`keys` to the offender. |
| Plugin update broke things | Upstream API change | `:Lazy restore` (uses `lazy-lock.json`), then update one plugin at a time. |
| blink.cmp "no fuzzy library" | `version = "1.*"` didn't fetch prebuilt binary (offline/no git tags) | `:Lazy build blink.cmp` or install Rust nightly to build. |
| Debug adapter missing | Not installed | `:Mason` → install adapter (e.g. `debugpy`, `codelldb`, `delve`, `js-debug-adapter`). |
| Claude panel opens but says command not found | `claude` CLI missing from nvim's PATH | Install Claude Code, or set `claude.terminal_cmd` in the Settings page / `settings.lua`. Run `:ClaudeCode` once, then `:checkhealth claudecode` (the plugin is lazy-loaded, so the health check does not exist until it loads). |
| Settings page change did nothing | Marked "Restart nvim to apply" | Most feature toggles are read at startup; restart. Theme/options marked live apply immediately. |
| Ctrl-hjkl do nothing in tmux | tmux bindings missing | Add `extras/tmux.conf`; see `references/tmux.md`. |
| Statusline looks wrong (no arrows/pills) | Icons off or no Nerd Font | `features.icons` must be on and the terminal font must be a Nerd Font; otherwise the statusline is plain by design. |
| A git credential dialog appears while installing plugins | A plugin repo address is wrong (GitHub answers "auth required" for repos that do not exist) | Cancel it, fix the `owner/name` in the spec, re-run. `scripts/dev.sh` and `ide sync/update` run git non-interactively so no dialog can open. |
