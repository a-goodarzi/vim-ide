# Using the IDE inside tmux

Append `assets/template/extras/tmux.conf` (copied to `~/.config/nvim/extras/tmux.conf` by the installer) to `~/.tmux.conf`, then `tmux source-file ~/.tmux.conf`. Restart nvim.

| Setting | Why |
|---|---|
| `escape-time 10` | Default 500ms makes `<Esc>` feel laggy in nvim and delays interrupting Claude Code. |
| `focus-events on` | nvim reloads files that Claude or git changed while you were in another pane. |
| `terminal-features ",*:RGB"` + `tmux-256color` | True-color themes; otherwise colors look washed out or wrong. Tmux < 3.2: use `terminal-overrides ",*:Tc"`. |
| `set-clipboard on` | Yanks reach the system clipboard, including over ssh (nvim falls back to OSC 52 when no clipboard tool exists). |
| `allow-passthrough on` | Lets escape sequences from nvim/Claude through (tmux >= 3.3). |
| `is_vim` bindings | Ctrl-h/j/k/l move across nvim splits and tmux panes seamlessly (vim-tmux-navigator, loaded only when `$TMUX` is set). |

In terminal buffers (the Claude panel) Ctrl-h/j/k/l belong to the program inside, so use **Alt-h/j/k/l** to leave. `Esc` is passed to Claude Code; `Ctrl-\ Ctrl-n` leaves terminal mode.

Prefix conflicts: if your tmux prefix is `C-b`/`C-a` nothing collides. Alt-bindings in `~/.tmux.conf` (`bind -n M-h ...`) would shadow the Alt-hjkl window keys; rebind one side.
