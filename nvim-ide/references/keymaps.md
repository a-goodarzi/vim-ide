# Default keymaps (leader = Space; press it and pause for which-key)

**Files/search** `<leader><space>` files · `ff` files · `fg` grep · `fb` buffers · `fr` recent · `fs` symbols · `fd` diagnostics · `fk` keymaps · `fh` help · `<leader>e` explorer
**Navigate** `s` flash jump · `<C-h/j/k/l>` windows · `<S-h>/<S-l>` buffers · `<leader>bd` close buffer · `<leader>w` save · `<leader>q` quit
**LSP** `gd` definition · `gD` declaration · `gr` references · `gi` implementation · `gy` type · `K` hover · `<leader>ca` action · `<leader>cr` rename · `<leader>cs` signature · `<leader>cd` line diagnostics · `<leader>cf` format · `<leader>uh` inlay hints
**Diagnostics** `<leader>xx` workspace · `xb` buffer · `xs` symbols (Trouble)
**Completion (blink)** `<C-space>` open · `<C-n>/<C-p>` select · `<C-y>` accept · `<C-e>` close
**Git** `]h`/`[h` hunks · `<leader>gs` stage · `gr` reset · `gp` preview · `gb` blame · `gd` diff · `gv` diffview · `gh` file history · `<leader>tg` lazygit
**Debug** `<leader>db` breakpoint · `dB` conditional · `dc` continue · `di/do/dO` into/over/out · `dr` REPL · `dl` run last · `dt` terminate · `du` UI · `de` eval
**Test** `<leader>tn` nearest · `tf` file · `td` debug nearest · `ts` summary · `to` output
**Terminal** `<C-\>` float · `<leader>tt` split
**Surround** `gsa` add · `gsd` delete · `gsr` replace · built-in `gc` comment

**Added in v2** Claude: `<leader>ac` toggle · `af`/`Alt-c` focus · `ab` add file · `as` send selection (visual) · `ar` resume · `aC` continue · `am` model · `aa`/`ad` accept/deny diff
Tabs: `<S-h>/<S-l>` cycle · `<leader>bb` pick · `bp` pin · `bo` close others · `bd` close · tab pages `<leader><Tab><Tab>` new, `]`/`[` next/prev
Settings/help/plugins: `<leader>us` settings page · `<leader>?` cheat sheet · `<leader>fc` commands · `<leader>pl` Lazy · `pu` update · `pr` restore · `pm` Mason · `ph` health
Terminal windows: `Alt-h/j/k/l` (Ctrl-h/j/k/l also cross into tmux panes inside tmux)

**VS Code layer** (Settings > VS Code layout) `F1`/`<Space>P` command palette · `Ctrl-P` quick open · `Ctrl-S` save · `Ctrl-/` comment · `Alt-b` toggle sidebar · `Alt-e/f/g/d/o/x` Explorer / Search&Replace / Git / Debug / Outline / Plugins · `<Space>sr` project search & replace (`sw` word, `sf` this file) · `Alt-Up/Down` move line · `F2` rename · `F12`/`Shift-F12` definition/references · `F5/F9/F10/F11` debug · `Alt-t` terminal · `Alt-p` problems · `Alt-w`/`Alt-,`/`Alt-.` close/prev/next tab · `<Space>uz` zen · `<Space>um` minimap · `<Space>uR` restart nvim
Top-right buttons: ✳ Claude · ⚙ Settings · ? Help (also `:IDEHelp`, `<Space>?`)
