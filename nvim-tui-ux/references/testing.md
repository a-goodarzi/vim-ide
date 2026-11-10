# Testing TUI work

## 1. Look at it (tmux)
```bash
scripts/tui_shot.sh --app nvim-ide --file x.py --keys "Space u s"              # a screen
scripts/tui_shot.sh --app nvim-ide --keys "Space p l" --size 100x30            # narrow window
scripts/tui_shot.sh --app nvim-ide --cmd ":lua vim.api.nvim_input_mouse('left','press','',0,5,2)"   # real mouse event
scripts/tui_shot.sh --app nvim-ide --color --keys "Space u s"                  # escape codes: verify theme colors / transitions
```
Rows for `nvim_input_mouse` are 0-based and row 0 is the tabline. Compute coordinates from buffer text (`nvim_win_get_position` + line index), never guess.
Press `Escape` before `--cmd` when a panel with an insert-mode input holds focus.

## 2. Headless smoke tests (deterministic, run in CI)
`nvim --headless -c "luafile smoke.lua"` with a `check(name, cond)` helper. Patterns that worked:
- open a page, assert headlines/descriptions are in the buffer text;
- toggle by key: place the cursor on a row, `nvim_feedkeys("<CR>", "x", false)`, assert the setting and the JSON file;
- click: stub `vim.fn.getmousepos`, call `vim.fn.maparg("<LeftMouse>","n",false,true).callback()`;
- search: stub `vim.ui.input = function(_, cb) cb("term") end`, press `/`;
- clicking below the content and line 0 must not raise;
- statusline styles: assert glyph bytes per style from `render()`;
- load plugins with `require("lazy").load` (lesson 8);
- assert on label prefixes (80-column window truncates, lesson 9);
- back up and restore state files (lesson 10).

## 3. Variations to always check
Narrow window (80 cols), `features.icons = false` (ASCII fallbacks), a light colorscheme, transparent background, inside tmux, `ide settings` standalone mode.

## 4. Lint
`python3 scripts/ui_lint.py <lua-dir> --strict` before declaring done.
