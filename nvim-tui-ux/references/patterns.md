# Patterns (code you can copy)

## A Page (tab-style screen)
```lua
local ui = require("config.ui")
local page = ui.page({
  name = "About", ft = "ide-about", sections = { "Overview", "Credits" },
  render = function(p, b)
    b:title("About", "Everything about this setup. q closes.")
    b:jumpbar({ "Overview", "Credits" })
    b:head("Overview", 1)
    b:add(b.margin .. ui.g("bullet") .. "Built on config/ui.lua")
    b:head("Credits", 2)
    local first = #b.lines + 1
    b:add(b.margin .. "Open the repo", "IDEAccent", { action = true, first = first, last = first })
  end,
  select = function(p, line) local m = p.meta[line]; if m and m.action then return m.first, m.last end end,
  click = function(p, m, meta) if meta and meta.action then vim.ui.open("https://example.com") end end,
  keys = { ["<CR>"] = function(p) local m = p.meta[p:line()]; if m and m.action then vim.ui.open("https://example.com") end end },
})
vim.api.nvim_create_user_command("IDEAbout", function() page:open() end, {})
```
`ui.page` gives you: tab placement in an editing window, resize re-render, selection bar, number-key section jumps,
`]]`/`[[`, `q`, clamped cursor, standalone quit (`IDE_SETTINGS_ONLY`), and click routing through the global hook.

Section jumps need `sections = {...}` and `b:head(text, index)`; the jump bar needs `b:jumpbar(names)`.

## A setting row (title / description / control)
Three lines per setting, blank line after: title (`IDEAccent`, with `●` if changed and `↻` if restart), description (`IDEMuted`), control (`IDEOn`/`IDEMuted`/`String`).
Compact lists (languages) use one line per entry with a checkbox glyph.

## Sidebar view + activity bar
A 4-column scratch window (`topleft 4vnew`, `winfixwidth`) with one icon per 3 lines; `show(id)` closes the active view, opens the new one,
then `wincmd H` + `vertical resize 4` to keep the bar leftmost. Clicking the active icon hides the sidebar. Register the click via `ui.hooks`.
Give bufferline `offsets` for the bar and each view's filetype.

## Button (always-visible chrome)
`nvim_open_win(buf, false, { relative = "editor", row = 0, col = columns - offset, width = 3, height = 1, style = "minimal", border = "none", focusable = true, zindex = 60 })`;
reposition on `VimResized`; action via `ui.hooks` (a non-focusable float would ignore the mouse).

## Picker
Style Telescope once (see design-tokens.md) and give each picker a human `prompt_title` ("Find files", "Command palette"). Do not hand-roll pickers.

## Live-switchable renderer (statusline)
`vim.o.statusline = "%!v:lua.require'config.statusline'.render()"`; `render()` reads settings each redraw; `apply()` rebuilds highlight groups from the
current colorscheme and calls `redrawstatus!`. Compute powerline arrow colors as fg = this segment's bg, bg = neighbour's bg.

## Standalone mode
`ide settings` = `IDE_SETTINGS_ONLY=1 nvim -c IDESettings`; skip sidebars/dashboard/buttons when that env var is set and quit nvim on page close.
