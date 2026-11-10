#!/usr/bin/env bash
# Install the nvim-ide template into a config dir (default ~/.config/nvim).
# Usage: install.sh [--target DIR] [--langs lua,python,go] [--force] [--no-sync] [--link-bin]
# Safe by default: an existing config is moved to <target>.bak-<timestamp>, never deleted.
set -euo pipefail

HERE="$(cd "$(dirname "$0")/.." && pwd)"
TARGET="${XDG_CONFIG_HOME:-$HOME/.config}/nvim"
LANGS="" ; SYNC=1 ; FORCE=0 ; LINKBIN=0

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target) TARGET="$2"; shift 2;;
    --langs)  LANGS="$2"; shift 2;;
    --force)  FORCE=1; shift;;
    --no-sync) SYNC=0; shift;;
    --link-bin) LINKBIN=1; shift;;
    -h|--help) sed -n '2,5p' "$0"; exit 0;;
    *) echo "unknown option: $1" >&2; exit 2;;
  esac
done

if [[ -e "$TARGET" ]] && [[ -n "$(ls -A "$TARGET" 2>/dev/null)" ]]; then
  BAK="$TARGET.bak-$(date +%Y%m%d-%H%M%S)"
  if [[ $FORCE -eq 0 && -t 0 ]]; then
    read -r -p "$TARGET exists. Move it to $BAK and continue? [y/N] " a
    [[ "$a" =~ ^[Yy]$ ]] || { echo "aborted"; exit 1; }
  fi
  mv "$TARGET" "$BAK"; echo "backed up -> $BAK"
fi

mkdir -p "$TARGET"
cp -R "$HERE/assets/template/." "$TARGET/"

if [[ -n "$LANGS" ]]; then
  # rewrite the `languages = { ... }` line in settings.lua
  list=$(printf '"%s", ' ${LANGS//,/ } | sed 's/, $//')
  sed -E "s|^(  languages = \{).*(\},)$|\1 ${list} \2|" "$TARGET/lua/config/settings.lua" > "$TARGET/lua/config/settings.lua.new" && mv "$TARGET/lua/config/settings.lua.new" "$TARGET/lua/config/settings.lua"   # portable (BSD sed has no plain -i)
fi
echo "installed -> $TARGET"
chmod +x "$TARGET/extras/ide"
if [[ $LINKBIN -eq 1 ]]; then mkdir -p "$HOME/.local/bin"; ln -sf "$TARGET/extras/ide" "$HOME/.local/bin/ide"; echo "launcher -> ~/.local/bin/ide (make sure ~/.local/bin is on PATH)"; fi

if [[ $SYNC -eq 1 ]] && command -v nvim >/dev/null; then
  echo "syncing plugins (headless)…"
  NVIM_APPNAME="$(basename "$TARGET")" nvim --headless "+Lazy! sync" +qa 2>&1 | tail -5 || true
fi
"$HERE/scripts/doctor.sh" "$TARGET" || true
echo "Next: open nvim, run :Mason, and edit lua/config/settings.lua to taste."
