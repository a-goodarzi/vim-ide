# Design tokens and third-party mapping

## Highlight roles (defined in ui.lua, all `default = true` links so a theme can override)
| Role | Links to | Used for |
|---|---|---|
| IDEHeading | Title | page title, section headlines, picker titles |
| IDERule | FloatBorder | rules, frames |
| IDEMuted | Comment | descriptions, hints, idle items |
| IDEKey | String | key/command column |
| IDEAccent | Function | setting titles, group names |
| IDEOn | DiagnosticOk | enabled state |
| IDEWarn | DiagnosticWarn | restart-needed, warnings |
| IDEInfo / IDEBar | DiagnosticInfo | selection bar, changed markers |

Never call `nvim_set_hl` with a literal color in a screen. If a role is missing, add it to `roles` in ui.lua.

## Mapping third-party widgets (the `widgets` table in ui.lua links highlight groups to roles)
| Widget | Border / title option | Highlight links |
|---|---|---|
| Telescope | `borderchars` rounded, `prompt_title/results_title/preview_title`, `prompt_prefix = ui.g("search")`, `selection_caret = ui.g("bar")`, forced preview title via `file_previewer` | TelescopeBorder/PromptBorder/ResultsBorder/PreviewBorder -> IDERule; *Title -> IDEHeading; SelectionCaret -> IDEBar; Matching -> IDEKey |
| which-key | `win = { border = "rounded", title = true }` | WhichKeyTitle -> IDEHeading |
| blink.cmp | `completion.menu.border`, `documentation.window.border`, `signature.window.border` = "rounded" | BlinkCmp*Border -> IDERule |
| lazy.nvim | `ui = { border = "rounded", title = ..., size = {width = 0.85, height = 0.85}, backdrop = 100 }` | LazyH1 -> IDEHeading |
| Mason | `ui = { border = "rounded", width = 0.85, height = 0.85 }` | - |
| neo-tree | `popup_border_style = "rounded"`, `window.width = 34` | - |
| nvim-dap-ui / neotest | `floating = { border = "rounded" }` | - |
| dropbar | `menu.win_configs.border = "rounded"` | - |
| bufferline | `separator_style = {"", ""}`, `indicator.style = "underline"`, `offsets` for sidebars | - |

Everyday plugin UIs (plugins, settings, help) are Pages, not popups. Keep the third-party popup only as an "advanced" escape hatch (`<Space>pL` opens full lazy.nvim).

## Sizes
- Page content width: `min(window width - 8, 100)`, min 40. Left margin 3 spaces.
- Pickers: 88% x 80%, preview 55%. Popups: 85% x 85% when they hold lists.
- Activity bar: 4 columns, 3 lines per icon. Sidebar views: 34-50 columns. Buttons: 3 columns x 1 row.
