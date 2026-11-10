---
name: nvim-tui-ux
description: Design and build a uniform, polished terminal UI/UX inside Neovim - settings screens, help pages, plugin managers, sidebars/activity bars, pickers, popups, buttons, statuslines, tab bars - with one shared design system, mouse support, Nerd Font fallbacks and live-apply settings. Use whenever the user wants Neovim to "look and feel like VS Code/an IDE", asks for a consistent design, a settings page, a TUI, a better popup/picker/search UI, clickable buttons, tabs, or says a plugin popup, search or find UI looks inconsistent or ugly, even if they never say "design system". Also use to review or lint an existing nvim UI for consistency, and to verify TUI changes with tmux screenshots.
---

# nvim-tui-ux

One design language for every screen in a Neovim IDE. The reason this matters: users judge an editor by how consistent
it feels. A settings tab, a plugin list and a search picker that each invent their own frame, colors and keys feel like
three different programs, and every inconsistency is also a place where mouse/keyboard behavior diverges and bugs hide.
The fix is structural: **one kit that owns tokens and lifecycle, and screens that only describe their content.**

This skill was distilled from building the `nvim-ide` project. The kit it describes is bundled in
`assets/ui_kit/ui.lua`; `references/lessons.md` records every UI bug that taught us a rule.

## The design system (summary)

| Token | Rule |
|---|---|
| Frame | `ui.border = "rounded"` on every float; `"none"` only for chrome (buttons, activity bar). Always pass it explicitly. |
| Roles | Highlight *roles*, never raw colors: `IDEHeading`, `IDERule`, `IDEMuted`, `IDEKey`, `IDEAccent`, `IDEOn`, `IDEWarn`, `IDEInfo`, `IDEBar`. They link to the colorscheme so every theme works. Third-party widgets (Telescope, which-key, blink, lazy) are mapped to the same roles. |
| Rules | Thin `─` under a jump bar, thick `═` under a section headline. |
| Selection | A `▎` bar in the left margin marks the current block (not a full-row color fill). |
| Status marks | `●` changed from default, `↻` needs restart, `[x]`/checkbox glyph for booleans, `‹ value ›` for enums. |
| Glyphs | Only through `ui.g(name)` which returns a Nerd Font glyph or an ASCII fallback (`features.icons`). Never put glyphs inside prose. |
| Voice | Sentence case, one-line descriptions, key hints in the muted role, verbs first ("Update all plugins"). |

## Choose the pattern by lifetime

| The thing is... | Use | Example |
|---|---|---|
| Long-lived, read or configured over minutes | **Page**: a listed scratch buffer in the editing window (shows up as a tab) built with `ui.page` | Settings, Help, Plugins |
| Navigation that coexists with editing | **Sidebar view** switched by an activity bar | Explorer, Search & Replace, Outline |
| Quick choose-and-go | **Picker** (Telescope) styled with tokens, titled panes | Find files, Command palette |
| Transient message or confirm | **Float** (`border = ui.border`) or `vim.ui.select/input` | Reset-all confirmation |
| Always-visible chrome | **Button / bar** (`border = "none"`, 1 row) | top-right gear, statusline |

Prefer a Page over a popup for anything the user will scroll, search or come back to: pages get tabs, search (`/`),
mouse, resize, and consistent keys for free.

## Workflow

1. **Inventory** every screen the user sees (including third-party popups) and name its pattern from the table.
2. **Build on the kit.** Copy `assets/ui_kit/ui.lua` into the project (`lua/config/ui.lua`) if absent; it is self-contained (icons: `vim.g.ide_icons = false` switches to ASCII). Spec files for lazy.nvim can `require` it at the top, so use `ui.border` instead of repeating `"rounded"`. A page is a `render(p, b)` function that
   calls `b:title`, `b:jumpbar`, `b:head`, `b:add`, plus `keys`, `select`, `click`. See `references/patterns.md` for a complete example.
3. **Map third-party UIs** to the tokens: set each plugin's border/title options and link its highlight groups to roles (`references/design-tokens.md`).
4. **Lint**: `python3 scripts/ui_lint.py <lua-dir> --strict` catches missing borders, raw colors, a second global click handler, unclamped cursors, glyph literals without fallback.
5. **Look at it.** `scripts/tui_shot.sh --app <appname> --file x.py --keys "Space u s"` runs the real editor in tmux and prints the screen. Check at least: default view, one interaction, a narrow window, icons off.
6. **Test behavior deterministically** in headless smoke tests (see `references/testing.md`): content, key toggles, a stubbed mouse click, search filter, no errors.
7. **Converting is optional, consistency is not.** If a long-lived screen exists as a popup and the user did not ask to restructure it, give it the tokens (border, title, roles, `ui.g`, one click hook) and say it could become a Page; do not silently leave it unthemed.
8. **Record the lesson.** If anything surprised you, `scripts/add_lesson.py "Title" "what we saw" "rule"` (add a lint rule if checkable). The skill gets better only if you do this.

## Interaction rules

- **Mouse and keyboard are equals.** Everything clickable has a key, and every key is discoverable (footer hints, Help tab, which-key groups).
- **One global click handler** (`ui.install_click_handler`) walks `ui.hooks`; buffer-local `<LeftMouse>` alone fails when another window has focus (lesson 1).
- **Live-apply what is cheap** (theme, statusline style, wrap); mark the rest `↻` and offer "apply + restart" (`:restart`, nvim 0.12+).
- **Show what changed**: `●` marker per setting and an easy reset (`r`, `R`).
- **Search is native** where possible (`/` + `n` in Help); filter in place where the list is the product (Settings).
- **Number keys jump to sections**, `]]`/`[[` move between headlines, `q` closes, `Esc` clears a filter before closing.
- **Never raise on stale input**: clamp cursors, check `getmousepos().line >= 1`, `pcall` UI callbacks from clicks.
- **tmux-safe keys**: no `Ctrl-B`, no `Ctrl-Shift-*`; chrome on Alt keys, palette on F1 (lesson 14).

## When working in an existing project

Read `references/lessons.md` first: most "why doesn't my UI work" questions are already answered there. Then run
`scripts/ui_lint.py` to see which screens already deviate before adding new ones. Do not restyle by editing a screen's
colors; change the token or the role link so everything moves together.

## Bundled files

- `assets/ui_kit/ui.lua` - the kit: tokens, `ui.g`, highlight roles, click hooks, builder, page framework.
- `references/design-tokens.md` - token table plus how to map Telescope, which-key, blink.cmp, lazy.nvim, Mason, neo-tree, dap-ui.
- `references/patterns.md` - a complete page example, sidebar view, activity bar, button, picker styling, standalone mode.
- `references/testing.md` - headless smoke patterns, tmux screenshots, mouse tests, narrow/ASCII checks.
- `references/lessons.md` - the living log of UI bugs and rules (append with `scripts/add_lesson.py`).
- `scripts/ui_lint.py`, `scripts/tui_shot.sh`, `scripts/add_lesson.py`.
