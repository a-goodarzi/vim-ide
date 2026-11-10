#!/usr/bin/env python3
"""Lint a Neovim Lua config for TUI/UX design-rule violations.
Usage: ui_lint.py <lua-dir> [--strict]      (exit 1 if any ERROR; --strict also fails on WARN)
Add `-- ui-lint: ok` to a line to silence it (say why in the same comment).
Rules come from references/lessons.md: each one is a bug we actually hit.
"""
import re, sys, pathlib

KIT_FILES = {"ui.lua"}                      # the kit itself may define glyphs/colors
GLYPH = re.compile(r'\\x(ee|ef|f3)\\x[0-9a-f]{2}\\x[0-9a-f]{2}', re.I)
HEX = re.compile(r'["\']#[0-9a-fA-F]{6}["\']')

def lint(path):
    out = []
    text = path.read_text()
    lines = text.splitlines()
    is_kit = path.name in KIT_FILES
    uses_page = "ui.page(" in text
    for i, line in enumerate(lines, 1):
        if "ui-lint: ok" in line: continue
        code = line.split("--")[0] if "--" in line and '"' not in line.split("--")[0][-1:] else line
        # R1: floats must set a border (the global 'winborder' is not guaranteed on older nvim / other plugins)
        if "nvim_open_win(" in line and not is_kit:
            window = " ".join(lines[i - 1:i + 6])
            if "border" not in window:
                out.append((i, "ERROR", "R1", "nvim_open_win without a border: use rounded (ui.border) so popups match"))
        # R2: raw colors in screens built on the kit (use highlight roles so themes keep working)
        if HEX.search(line) and not is_kit and ("nvim_set_hl" in line or uses_page):
            out.append((i, "WARN", "R2", "raw hex color in a UI screen: link to a highlight role (IDE*/theme groups) so every colorscheme works"))
        # R3: a second global <LeftMouse> handler fights the shared one
        if re.search(r'keymap\.set\(\s*\{[^}]*\}\s*,\s*"<LeftMouse>"', line) and "buffer" not in line and not is_kit:
            out.append((i, "ERROR", "R3", "global <LeftMouse> map: register a hook in ui.hooks instead (only one global handler may exist)"))
        # R4: hard-coded Nerd Font glyph bytes without an ASCII fallback
        if GLYPH.search(line) and "ui.g(" not in line and "icons" not in line and "ascii" not in line and not is_kit:
            out.append((i, "WARN", "R4", "glyph literal without an ASCII fallback: add it to ui.g() or guard with cfg.icons()"))
        # R5: direct cursor moves can raise 'Invalid cursor line' (clicks below content, stale lines)
        if ("nvim_win_set_cursor" in line and "pcall" not in line and not is_kit
                and (uses_page or "getmousepos" in text)):
            out.append((i, "ERROR", "R5", "unclamped nvim_win_set_cursor: use page:setcur()"))
        # R6: live-switching a statusline/plugin by calling setup() twice leaves stale state
        if re.search(r'\bsetup\(.*\)\s*$', line) and "apply" in "".join(lines[max(0, i - 6):i]) and "lualine" in line:
            out.append((i, "WARN", "R6", "re-calling a plugin's setup() to restyle live: prefer a self-contained renderer"))
        # R7: lazy plugin spec naming a repo that may not exist triggers git credential prompts
        m = re.search(r'"([A-Za-z0-9_.-]+/[A-Za-z0-9_.-]+)"', line)
        if m and "EdenEoN" in m.group(1):
            out.append((i, "ERROR", "R7", "wrong repo owner (a missing GitHub repo makes git ask for credentials)"))
    return out

def main():
    if len(sys.argv) < 2:
        print(__doc__); return 2
    root = pathlib.Path(sys.argv[1]); strict = "--strict" in sys.argv
    errs = warns = 0
    for f in sorted(root.rglob("*.lua")):
        for ln, sev, rule, msg in lint(f):
            print(f"{f}:{ln}: {sev} {rule} {msg}")
            errs += sev == "ERROR"; warns += sev == "WARN"
    print(f"\n{errs} error(s), {warns} warning(s)")
    return 1 if errs or (strict and warns) else 0

if __name__ == "__main__":
    sys.exit(main())
