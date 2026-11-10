# Lessons learned (living log)

Every entry is a bug we actually hit while building the nvim-ide screens. Read the ones near the thing you are
building. When you hit a new one, add it with `scripts/add_lesson.py` (and a lint rule if it can be checked by a script).

## 1. A buffer-local <LeftMouse> map only fires in the focused window
**Seen:** Clicking the activity bar icons or a Settings control did nothing when the cursor was in another window: key lookup happens in the *current* buffer before the click moves focus.
**Rule:** Keep exactly one global `<LeftMouse>` expr handler (`ui.install_click_handler`) that walks `ui.hooks`; every clickable surface registers a hook. Buffer-local maps are only a bonus for the focused case.
**Lint idea:** R3, a second global `<LeftMouse>` map.

## 2. Floating windows inherit the global 'winborder'
**Seen:** The one-cell top-right buttons rendered as 3x3 boxes after `winborder = "rounded"` was set.
**Rule:** Always pass `border` explicitly: `ui.border` for popups, `"none"` for chrome like buttons. Never rely on the default.
**Lint idea:** R1, `nvim_open_win` without `border`.

## 3. Re-calling a plugin's setup() to restyle live leaves stale state
**Seen:** After switching statusline style the leftmost segment kept the old separator; changes lagged one step behind.
**Rule:** For anything that must switch live, own the renderer (a `%!v:lua` function that reads settings on every redraw) instead of re-running a plugin's setup. See `config/statusline.lua`.
**Lint idea:** R6.

## 4. Slanted bufferline separators clash with most colorschemes
**Seen:** White wedges either side of the active tab.
**Rule:** `separator_style = { "", "" }` and mark the active tab with an underline indicator. Separator colors are not derived from the theme.

## 5. Glyphs: LuaJIT has no `\u{}`; always give an ASCII fallback; never embed glyphs in prose
**Seen:** Help text with an icon in a sentence showed empty boxes without a Nerd Font; `"\u{e0b0}"` is a syntax error.
**Rule:** Write glyphs as UTF-8 byte escapes (`"\xee\x82\xb0"`), route them through `ui.g(name)` with an ASCII pair, and gate by `features.icons`.
**Lint idea:** R4.

## 6. Clamp every cursor move
**Seen:** `E5108: Invalid cursor line: out of range` when clicking in the empty area below the content.
**Rule:** Use `page:setcur(line)` (clamps and pcalls). Check `getmousepos().line >= 1`.
**Lint idea:** R5.

## 7. 'scrolloff' defeats `zt`
**Seen:** Jumping to a section headline left 8 lines of the previous section above it.
**Rule:** Page windows set `scrolloff = 0`.

## 8. Faking lazy.nvim's VeryLazy event races with the real one
**Seen:** Statusline tests failed randomly; the real trigger re-ran plugin setup after the test changed state.
**Rule:** In tests load plugins deterministically with `require("lazy").load({ plugins = {...} })`; do not `doautocmd User VeryLazy`.

## 9. Headless nvim is 80 columns and has no mouse
**Seen:** Labels truncated ("Transparent backgrou…"), `nvim_input_mouse` hit the wrong cell, `getmousepos` empty.
**Rule:** Assert on label prefixes; stub `vim.fn.getmousepos` for click tests; use tmux for true mouse tests (`nvim_input_mouse` is 0-based, row 0 is the tabline).

## 10. Tests must not destroy the user's saved state
**Seen:** A test run reset the user's saved settings file.
**Rule:** Back up and restore any state file a test touches; never `rm` globs; use `mktemp -d` for scratch.

## 11. Live-apply what is cheap; mark what is not
**Rule:** Theme, statusline, wrap, relativenumber apply instantly (`live = fn`). Everything that needs a restart shows a `↻` marker and a footer with "press A to restart" (`:restart` exists in nvim 0.12).

## 12. A wrong plugin repo name makes git ask for credentials
**Seen:** A typo in `owner/name` made GitHub answer "auth required" and the desktop askpass dialog opened.
**Rule:** Verify repos with `git ls-remote` (non-interactively), and run scripted clones with `GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS_REQUIRE=never`.
**Lint idea:** R7.

## 13. Plugins that ship a rockspec make lazy.nvim build Lua from source on every start
**Seen:** `oxocarbon.nvim` retried a hererocks build each launch, failing without readline headers.
**Rule:** Skip such plugins or set `build = false`.

## 14. tmux changes which keys exist
**Rule:** The prefix (`Ctrl-B`) never reaches nvim; `Ctrl-Shift-<key>` and `Ctrl-,` are not delivered by most terminals. Put chrome actions on Alt keys and the command palette on F1. Pair Ctrl-hjkl with vim-tmux-navigator and ship the tmux snippet.

## 15. Third-party popups need the same tokens
**Seen:** lazy.nvim, Mason, Telescope, which-key, blink, dap-ui each had their own frame and title.
**Rule:** One table of tokens (`config/ui.lua`): `border`, title style, highlight roles; map widget highlight groups to roles (`widgets` table) and set each plugin's border/title options. Long-lived screens (plugins, settings, help) become pages, not popups.

## 16. Settings persistence gotchas
**Rule:** Store overrides separately from defaults; `vim.tbl_deep_extend` merges dicts but treat lists as values (replace `languages` explicitly); prune empty tables before `json.encode` (empty table encodes as `[]`).

## 17. Input panels take focus
**Seen:** After opening the Search & Replace panel, following test keystrokes were typed into its input.
**Rule:** In screenshot scripts press `Escape` before sending commands.

## 18. Page hooks must be registered once
**Seen:** Re-opening a page appended another click hook each time, so clicks ran the handler N times.
**Rule:** Guard hook registration with a per-page flag (done in ui.page: self._hooked). Hooks must be idempotent.
**Lint idea:** count table.insert(ui.hooks ...) calls outside ui.lua
*(added 2026-11-10)*

## 19. The kit must not depend on the host project
**Seen:** Both with-skill runs had to create a config/init.lua just to satisfy require('config').icons() inside the copied kit.
**Rule:** Keep ui.lua self-contained: M.icons() asks the host if it can, else reads vim.g.ide_icons. Copying the kit into a fresh config must work with zero other files.
*(added 2026-11-10)*

## 20. Plugin spec files can require the kit
**Seen:** A run left a literal "rounded" in plugins/ui.lua believing specs load before the kit.
**Rule:** lazy.nvim evaluates spec files after the runtimepath is set, so 'local ui = require("config.ui")' at the top of a spec file works; use ui.border everywhere so one token controls every popup.
*(added 2026-11-10)*

## 21. Graders for UI tasks must tolerate indirection
**Seen:** Our own graders mis-scored correct work three times: clicking the footer hint instead of the action row, requiring the literal word rounded instead of a shared border variable, and counting a pre-existing lint warning against the agent.
**Rule:** Test every candidate click row; accept a shared token as well as a literal; compare lint findings against the starting config, not against zero.
*(added 2026-11-10)*

## 22. A focused page's own click map swallows clicks meant for other windows
**Seen:** On the Plugins tab, the page's buffer-local <LeftMouse> handled every click and discarded unhandled ones, so the activity bar icons did nothing while the page had focus.
**Rule:** Never add a buffer-local <LeftMouse> to a page; register a ui.hooks entry that checks m.winid and returns false otherwise, so the global handler passes other clicks through.
**Lint idea:** buffer-local <LeftMouse> keymap with buffer=
*(added 2026-11-10)*

## 23. Test the layout by driving the real UI through screen-crossing sequences
**Seen:** Bugs came from sequences, not single screens: search -> Settings -> :q shrank the activity bar to 1 column; Help opened over a page made a new tab with no sidebar; <leader>e left the bar highlight stale and the explorer left of the bar; Run & Debug opened nothing because dapui was never set up.
**Rule:** Before declaring a UI done, run a tmux session and dump the window layout (ft, width, column) after every combination of: switch view, open page, close page with q and :q, key-driven open/close, resize. Add each failure as a headless regression check.
*(added 2026-11-10)*

## 24. Sidebar state must be derived from the windows that exist
**Seen:** Sidebars are opened by many paths (icon click, keymap, :Neotree, plugin commands), so a stored 'active view' goes stale.
**Rule:** Re-derive the active view from the open windows on WinNew/WinClosed/FileType (scheduled), keep fixed widths with winfixwidth, keep the bar leftmost, and never leave focus on the bar.
*(added 2026-11-10)*

## 25. Page windows: pick the editing window by role, and never quit or tab away when a page closes
**Seen:** editing_window() required buftype=='' so a window holding another page was rejected and tabnew made a sidebar-less tab; :q on the last page left only sidebars.
**Rule:** Treat file and page windows as editing windows, fall back to 'botright vnew' not tabnew, and when the last page closes open an empty editor instead of leaving sidebars stretched or quitting.
*(added 2026-11-10)*

## 26. luajit -bl takes an OUTPUT file as its second argument
**Seen:** A syntax check 'luajit -bl a.lua b.lua >/dev/null' overwrote b.lua with the bytecode listing.
**Rule:** Check syntax with 'luajit -bl file.lua /dev/null', one file per call, and keep a recoverable copy (the packaged .skill) of anything you check in bulk.
*(added 2026-11-10)*

## 27. Restyle third-party panels with the same recipe: options, window chrome, highlight roles
**Seen:** The Search & Replace sidebar (grug-far) was 96 columns wide with 10-line help, long placeholder examples, gutter numbers and its own colors.
**Rule:** For any plugin panel: set its documented layout options (compact/padding/wrap), strip window chrome in a FileType autocmd, shorten placeholders, and link its highlight groups to the ide roles in ui.lua's widgets table. Label every input; screenshot with real results, not just the empty state.
*(added 2026-11-10)*

## 28. Test the whole workflow, not the screen: search, open a result, check where it lands
**Seen:** I redesigned the search panel and only screenshotted the empty state. Opening a result then created a split to the LEFT of the sidebar (grug-far defaults to preferredLocation=left and the sidebar is leftmost).
**Rule:** For every panel that opens things (search, explorer, outline, problems), exercise the full loop with real input and dump the window layout afterwards. Set the plugin's target-window option so results land in the editor area, and exclude sidebars, floats and terminals.
*(added 2026-11-10)*

## 29. Look at the pixels: render the terminal screen to a PNG
**Seen:** Reading tmux text captures hid that the tab strip slid under the sidebars and that tabs were flat; bufferline only supports one offset (first/last window), so stacked sidebars silently broke it.
**Rule:** Render 'tmux capture-pane -e' to an image (Pillow + a Nerd Font) and look at it before and after any visual change. When a plugin cannot express the layout (multiple sidebars), write the widget yourself and drive it from the real window layout.
*(added 2026-11-10)*

## 30. A tab bar must start where the editor starts
**Seen:** Tabs drawn from column 0 overlapped the Explorer/Search columns.
**Rule:** Offset the strip by the width of everything left of the first editing window, show the sidebar's title there, reserve room for top-right buttons, and scroll tabs so the active one always fits.
*(added 2026-11-10)*

## 31. vim.wo[win].opt = v on the CURRENT window also sets the global default
**Seen:** Setting number/signcolumn for a page or sidebar with vim.wo while it was the current window changed the global value; the next file opened in that window had no line numbers or sign column.
**Rule:** Use ui.setwo(win, opts) (nvim_set_option_value with scope local) for every chrome window option; never vim.wo[win][k] = v.
**Lint idea:** vim.wo[...] = assignment in plugin/config code
*(added 2026-11-10)*

## 32. Never let a sidebar view stack: derive exclusivity from the windows
**Seen:** <Space>sw/sf, :Neotree and :AerialToggle opened a second sidebar next to the first (two Search panels, Explorer beside Debug) and the tab-bar title named the wrong one.
**Rule:** In sync() keep only the newest sidebar view and close the others; make search variants close the old panel first; give every view (debug too) a fixed width.
*(added 2026-11-10)*

## 33. Tab strip: truncate in the middle and clip both ends
**Seen:** long_file_name_number_1 vs _12 rendered identically after tail truncation, and tabs after the active one overflowed so Vim cut the tabline from the left and ate the sidebar title.
**Rule:** Middle ellipsis for long names; stop adding tabs when the strip is full and show a chevron.
*(added 2026-11-10)*

## 34. bufhidden=wipe makes pages vanish when another page opens, and :bd closes the editor window
**Seen:** Opening Help over Settings destroyed Settings; :bd on the only editor closed its window and left the sidebars stretched; a hidden page reloaded by a later open hit a stale swap file.
**Rule:** Pages use bufhidden=hide + BufWinEnter re-bind + BufDelete wipe; a WinClosed guard re-creates an editor beside the sidebars (showing the last used buffer); treat the start dashboard as an editing window.
*(added 2026-11-10)*

## 35. A mapping on <C-\> in terminal mode shadows <C-\><C-n>
**Seen:** The floating-terminal toggle on <C-\> in t-mode closed the terminal whenever the user tried to leave terminal mode, and focus could land on the activity bar through Alt-k.
**Rule:** Bind the t-mode toggle to <C-\><C-\>; bounce focus off non-editable chrome (WinEnter).
*(added 2026-11-10)*

## 36. Overlay floats and theme helpers need a second look
**Seen:** mini.map covered the Claude panel; nvim_set_hl in the transparent helper dropped every foreground colour; dapui panels had no titles and F5 failed silently with a broken adapter; snacks notifications cut long text.
**Rule:** Hide right-edge floats while a right panel is open, preserve fg when clearing backgrounds, title dap panels, notify when an adapter command is empty, wrap notifications.
*(added 2026-11-10)*
