#!/usr/bin/env bash
# Report what is missing for the IDE to work. Exit 1 if a required item is absent.
# Usage: doctor.sh [config-dir]
TARGET="${1:-${XDG_CONFIG_HOME:-$HOME/.config}/nvim}"
bad=0
ok()   { printf '  \033[32m✓\033[0m %s\n' "$1"; }
warn() { printf '  \033[33m!\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✗\033[0m %s\n' "$1"; bad=1; }
have() { command -v "$1" >/dev/null 2>&1; }

echo "Required"
if have nvim; then
  v=$(nvim --version | head -1 | sed -E 's/.*v([0-9]+)\.([0-9]+).*/\1 \2/'); set -- $v
  if [[ $1 -gt 0 || $2 -ge 11 ]]; then ok "nvim $1.$2 (>= 0.11)"; else fail "nvim $1.$2 is too old; need >= 0.11"; fi
else fail "nvim not found (install: brew/dnf/apt install neovim, or the AppImage from GitHub releases)"; fi
have git && ok git || fail "git"
have gcc || have cc || have clang && ok "C compiler" || fail "C compiler (needed to build treesitter parsers)"
have tree-sitter && ok tree-sitter-cli || warn "tree-sitter CLI missing (needed by nvim-treesitter 'main'; npm i -g tree-sitter-cli or cargo install tree-sitter-cli)"

echo "Recommended"
have rg && ok ripgrep || warn "ripgrep (live grep)"
have fd || have fdfind && ok fd || warn "fd (faster file finding)"
have make && ok make || warn "make (telescope-fzf-native)"
have node && ok node || warn "node (many LSP servers are npm packages)"
have lazygit && ok lazygit || warn "lazygit (optional, <leader>tg)"
fc-list 2>/dev/null | grep -qi "nerd" && ok "Nerd Font" || warn "no Nerd Font detected; set features.icons=false in settings.lua if icons look broken"

echo "tmux (only checked when tmux is installed)"
if have tmux; then
  et=$(tmux show -sv escape-time 2>/dev/null || true)
  if [[ -n "$et" && "$et" -gt 50 ]]; then warn "tmux escape-time is ${et}ms (laggy <Esc>); set -sg escape-time 10"; elif [[ -n "$et" ]]; then ok "tmux escape-time ${et}ms"; else warn "tmux not running; see assets/template/extras/tmux.conf for recommended settings"; fi
  tmux show -gv focus-events 2>/dev/null | grep -q on && ok "tmux focus-events on" || warn "tmux focus-events off (set -g focus-events on)"
  tmux show -sv terminal-features 2>/dev/null | grep -qi "RGB" || tmux show -sv terminal-overrides 2>/dev/null | grep -qiE "RGB|Tc" && ok "tmux true color" || warn "tmux true-color not configured (see extras/tmux.conf)"
else warn "tmux not installed (fine if you do not use it)"; fi
have claude && ok "claude CLI (for the embedded Claude Code panel)" || warn "claude CLI not found; install Claude Code or set claude.terminal_cmd in settings"

echo "Config"
[[ -f "$TARGET/init.lua" ]] && ok "$TARGET/init.lua" || fail "no init.lua in $TARGET"
if have luajit; then
  for f in $(find "$TARGET" -name '*.lua' 2>/dev/null); do luajit -bl "$f" >/dev/null 2>&1 || fail "syntax error: $f"; done
  ok "lua syntax checked"
fi
if have nvim && [[ -f "$TARGET/init.lua" ]]; then
  out=$(nvim --headless "+lua print('boot-ok')" +qa 2>&1)
  [[ "$out" == *boot-ok* ]] && ok "headless startup" || fail "headless startup failed: $out"
fi
exit $bad
