#!/usr/bin/env bash
# Start Neovim in a detached tmux session, send keys, print the screen. The way to *see* a TUI change.
# Usage: tui_shot.sh [--app NAME] [--file PATH] [--keys "Space u s"] [--cmd ":lua ..."] [--wait SECS] [--size 150x44] [--color]
#   --keys  tmux key names, space separated (Space, Enter, Escape, Tab, C-p, ...). Literal text: use --cmd or put it in quotes.
#   --cmd   an Ex command / lua line typed then Enter (use it for synthetic mouse clicks: nvim_input_mouse is 0-based row,col)
# Tip: press Escape before --cmd if a panel with an insert-mode input (grug-far) took focus.
set -uo pipefail
APP="${NVIM_APPNAME:-nvim}"; FILE=""; KEYS=""; CMD=""; WAIT=12; SIZE="150x44"; COLOR=0
while [[ $# -gt 0 ]]; do case "$1" in
  --app) APP="$2"; shift 2;; --file) FILE="$2"; shift 2;; --keys) KEYS="$2"; shift 2;; --cmd) CMD="$2"; shift 2;;
  --wait) WAIT="$2"; shift 2;; --size) SIZE="$2"; shift 2;; --color) COLOR=1; shift;; *) echo "unknown $1"; exit 2;; esac; done
command -v tmux >/dev/null || { echo "tmux not installed"; exit 1; }
S="tuishot$$"; W="${SIZE%x*}"; H="${SIZE#*x}"
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS_REQUIRE=never
tmux new-session -d -s "$S" -x "$W" -y "$H" "NVIM_APPNAME=$APP nvim $FILE"
sleep "$WAIT"
[[ -n "$KEYS" ]] && { for k in $KEYS; do tmux send-keys -t "$S" "$k"; sleep 0.4; done; sleep 1.5; }
[[ -n "$CMD" ]] && { tmux send-keys -t "$S" "$CMD" Enter; sleep 2; }
if ((COLOR)); then tmux capture-pane -t "$S" -p -e; else tmux capture-pane -t "$S" -p; fi
tmux kill-session -t "$S" 2>/dev/null
