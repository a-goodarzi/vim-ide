#!/usr/bin/env bash
# One-shot development script: install the config, link `ide`, sync plugins, install Mason tools,
# run smoke tests and a tmux render check.   Usage: scripts/dev.sh [--name nvim-ide] [--copy] [--skip-mason] [--skip-tmux] [--themes] [--no-run] [--update]
# --update: also git pull (if a git checkout), update all plugins (refreshes lazy-lock.json) and Mason tools.
# Default: ~/.config/<name> is a SYMLINK to assets/template, so edits in the repo are live (restart nvim). --copy installs a copy instead.
# Never uses sudo; missing system packages are printed with the command to install them.
set -uo pipefail
# Plugin repos are public: never let git open a credential dialog (askpass) or prompt.
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS_REQUIRE=never
HERE="$(cd "$(dirname "$0")/.." && pwd)"
THEMES=0; NAME="nvim-ide"; MASON=1; TMUXT=1; COPY=0; RUN=1; UPDATE=0
while [[ $# -gt 0 ]]; do case "$1" in
  --name) NAME="$2"; shift 2;; --copy) COPY=1; shift;; --no-run) RUN=0; shift;; --update) UPDATE=1; shift;; --skip-mason) MASON=0; shift;; --skip-tmux) TMUXT=0; shift;; --themes) THEMES=1; shift;;
  -h|--help) sed -n '2,4p' "$0"; exit 0;; *) echo "unknown option $1"; exit 2;; esac; done
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/$NAME"
export NVIM_APPNAME="$NAME"
step(){ printf '\n\033[1;34m== %s\033[0m\n' "$1"; }
have(){ command -v "$1" >/dev/null 2>&1; }
rc=0

step "1/6 dependencies"
miss=()
for t in nvim git make tree-sitter rg node; do have "$t" || miss+=("$t"); done
have gcc || have cc || miss+=("gcc")
if ((${#miss[@]})); then
  echo "Missing: ${miss[*]}"
  echo "Fedora: sudo dnf install -y neovim git make gcc ripgrep nodejs tree-sitter-cli"
  echo "Debian/Ubuntu: sudo apt install -y neovim git make gcc ripgrep nodejs  (tree-sitter: npm i -g tree-sitter-cli)"
  echo "macOS: brew install neovim git ripgrep node tree-sitter-cli   (the CLI is its own formula; 'tree-sitter' alone is only the library; or: npm i -g tree-sitter-cli)"
  have nvim || { echo "nvim is required; stopping."; exit 1; }
fi
nvim --version | head -1

step "2/6 config -> $TARGET"
TEMPLATE="$HERE/assets/template"
mkdir -p "$(dirname "$TARGET")"      # a fresh account may not have ~/.config yet
if [[ $COPY -eq 0 ]]; then
  if [[ -L "$TARGET" ]]; then ln -sfn "$TEMPLATE" "$TARGET"; echo "symlink refreshed: $TARGET -> $TEMPLATE"
  else
    if [[ -e "$TARGET" ]]; then
      # keep the plugin lockfile (it is written next to the config, i.e. into the repo template)
      [[ -f "$TARGET/lazy-lock.json" && ! -f "$TEMPLATE/lazy-lock.json" ]] && cp "$TARGET/lazy-lock.json" "$TEMPLATE/"
      BAK="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"; mv "$TARGET" "$BAK"; echo "previous config moved to $BAK"
    fi
    ln -s "$TEMPLATE" "$TARGET"; echo "symlink: $TARGET -> $TEMPLATE (edits in the repo are live)"
  fi
elif [[ -f "$TARGET/init.lua" && ! -L "$TARGET" ]]; then cp -R "$TEMPLATE/." "$TARGET/"; echo "copied (updated in place)"
else
  [[ -L "$TARGET" ]] && rm "$TARGET"
  "$HERE/scripts/install.sh" --target "$TARGET" --force --no-sync >/dev/null && echo "installed a copy"
fi
chmod +x "$TEMPLATE/extras/ide"
mkdir -p "$HOME/.local/bin"; ln -sf "$TEMPLATE/extras/ide" "$HOME/.local/bin/ide"; echo "launcher: ~/.local/bin/ide"
case ":$PATH:" in *":$HOME/.local/bin:"*) ;; *) echo "note: add ~/.local/bin to PATH";; esac

if ((UPDATE)); then
  step "2b/6 grab the latest (--update)"
  if git -C "$HERE" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$HERE" pull --ff-only 2>&1 | tail -3 || echo "git pull failed (local changes?) — continuing with what is on disk"
  else echo "repo is not a git checkout: nothing to pull, updating plugins and tools only"; fi
  echo "updating plugins…"; timeout 600 nvim --headless "+Lazy! update" +qa >/tmp/ide-update.log 2>&1 && echo "plugins updated (lazy-lock.json refreshed)" || echo "plugin update problem, see /tmp/ide-update.log"
fi

step "3/6 plugins (lazy.nvim sync)"
timeout 600 nvim --headless "+Lazy! sync" +qa >/tmp/ide-sync.log 2>&1 && echo "synced" || { echo "sync problem, see /tmp/ide-sync.log"; rc=1; }

if ((MASON)); then
  step "4/6 language servers & tools (Mason) — first run downloads a lot"
  cat > /tmp/ide-mason.lua <<'LUA'
vim.cmd("edit /tmp/ide-smoke.py"); vim.cmd("doautocmd User VeryLazy")
local reg = require("mason-registry")
local function busy() for _, p in ipairs(reg.get_all_packages()) do if p:is_installing() then return true end end return false end
vim.wait(8000)
if os.getenv("IDE_UPDATE") == "1" then pcall(vim.cmd, "MasonToolsUpdate") end
vim.wait(900000, function() return not busy() end, 3000)
vim.wait(4000)
print("installed: " .. table.concat(reg.get_installed_package_names(), ", "))
LUA
  export IDE_UPDATE=$UPDATE
  timeout 1000 nvim --headless -c "luafile /tmp/ide-mason.lua" +qa 2>&1 | grep -E "^installed:" || { echo "mason step incomplete"; rc=1; }
else step "4/6 Mason skipped"; fi

step "5/6 smoke tests"
printf 'def f(x):\n    return x + 1\n' > /tmp/ide-smoke.py
timeout 120 nvim --headless -c "luafile $HERE/scripts/smoke.lua" 2>&1 | grep -vE "^\[nvim-treesitter" ; [[ ${PIPESTATUS[0]} -eq 0 ]] || rc=1

if ((THEMES)); then
  step "contrast check of all themes"
  nvim --headless -c "luafile $HERE/scripts/theme_check.lua" 2>&1 | grep -vE "^\[nvim-treesitter" || rc=1
fi

if ((TMUXT)) && have tmux; then
  step "6/6 tmux render check"
  S="idedev$$"; tmux new-session -d -s "$S" -x 150 -y 40 "cd $HERE && IDE_NO_WELCOME=1 NVIM_APPNAME=$NAME nvim /tmp/ide-smoke.py"; for _ in $(seq 1 30); do sleep 1; screen=$(tmux capture-pane -t "$S" -p); grep -q "$(basename "$HERE")" <<<"$screen" && break; done
  sleep 2; screen=$(tmux capture-pane -t "$S" -p)
  grep -q "$(basename "$HERE")" <<<"$screen" && echo "  ok   sidebar (explorer) visible" || { echo "  FAIL sidebar not visible"; rc=1; }
  grep -q "ide-smoke.py" <<<"$screen" && echo "  ok   tab/buffer visible" || { echo "  FAIL buffer not visible"; rc=1; }
  grep -q "NORMAL" <<<"$screen" && echo "  ok   statusline visible" || { echo "  FAIL statusline missing"; rc=1; }
  tmux send-keys -t "$S" ":messages" Enter; sleep 1
  tmux capture-pane -t "$S" -p | grep -E "E[0-9]{3,4}:|Error executing" && { echo "  FAIL errors in :messages"; rc=1; } || echo "  ok   no errors in :messages"
  tmux kill-session -t "$S" 2>/dev/null
else step "6/6 tmux check skipped"; fi

echo; ((rc==0)) && echo "ALL GOOD. Run:  ide   |  ide claude  |  ide settings" || echo "Some steps failed (rc=$rc)."

# Finally: launch the IDE on the repo for development (only in an interactive terminal, and only if the checks passed).
if ((rc==0 && RUN)) && [[ -t 0 && -t 1 ]]; then
  echo "Starting the IDE in $HERE  (edit assets/template/*, then <Space>uR restarts nvim to reload)"
  cd "$HERE" && exec nvim "$TEMPLATE/lua/config/settings.lua"
fi
exit $rc
