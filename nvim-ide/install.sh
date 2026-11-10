#!/usr/bin/env bash
# One-line installer for vim-ide.
#   curl -fsSLO https://raw.githubusercontent.com/a-goodarzi/vim-ide/main/install.sh
#   curl -fsSLO https://raw.githubusercontent.com/a-goodarzi/vim-ide/main/install.sh.sha256
#   sha256sum -c install.sh.sha256 && bash install.sh            # macOS: shasum -a 256 -c install.sh.sha256
# Options: --ref TAG|BRANCH (default: the latest release tag)   --dir DIR (default ~/.local/share/vim-ide)   anything else goes to dev.sh
# What it does: clones the repository into DIR (shallow), then runs nvim-ide/scripts/dev.sh, which links the config to
# ~/.config/nvim-ide, links the `ide` launcher and installs the plugins. Your ~/.config/nvim is never touched. No sudo.
set -euo pipefail
export GIT_TERMINAL_PROMPT=0 GIT_ASKPASS=true SSH_ASKPASS_REQUIRE=never
REPO="${IDE_REPO:-https://github.com/a-goodarzi/vim-ide.git}"   # IDE_REPO overrides it (forks, tests)
DIR="${IDE_HOME:-$HOME/.local/share/vim-ide}"; REF=""; PASS=()
while [[ $# -gt 0 ]]; do case "$1" in
  --ref) REF="$2"; shift 2;; --dir) DIR="$2"; shift 2;; -h|--help) sed -n '2,7p' "$0"; exit 0;; *) PASS+=("$1"); shift;; esac; done
command -v git >/dev/null || { echo "git is required (brew install git / sudo dnf install git / sudo apt install git)"; exit 1; }
if [[ -z "$REF" ]]; then   # newest vX.Y.Z tag, else main
  REF=$(git ls-remote --tags --refs --sort=-v:refname "$REPO" 'v*' 2>/dev/null | head -1 | sed 's|.*refs/tags/||' || true)
  REF="${REF:-main}"
fi
echo "Installing vim-ide $REF into $DIR"
if [[ -d "$DIR/.git" ]]; then
  git -C "$DIR" fetch --depth 1 origin "$REF" && git -C "$DIR" checkout -q FETCH_HEAD
else
  [[ -e "$DIR" ]] && { echo "$DIR exists and is not a vim-ide checkout; use --dir"; exit 1; }
  git clone --depth 1 --branch "$REF" "$REPO" "$DIR"
fi
exec bash "$DIR/nvim-ide/scripts/dev.sh" --skip-tmux --no-run "${PASS[@]+"${PASS[@]}"}"
