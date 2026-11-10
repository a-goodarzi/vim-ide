#!/usr/bin/env python3
"""Record docs/demo.gif: drives the real IDE in a tmux session and renders the screen to frames (needs tmux, Pillow and a Nerd Font).

    python3 nvim-ide/scripts/make_demo.py [--font /path/to/NerdFontMono-Regular.ttf] [--out docs/demo.gif] [--keep]

It builds a small throw-away project (Python, Go, HTML) in a temp folder, starts `NVIM_APPNAME=nvim-ide nvim` on it and walks through the
palette, Search & Replace, Source Control, the terminal, the tour and Settings. Your own files are never touched.
"""
import argparse, glob, os, re, shutil, socket, subprocess, sys, tempfile, time

try:
    from PIL import Image, ImageDraw, ImageFont
except ImportError:
    sys.exit("Pillow is required: pip install pillow")

ap = argparse.ArgumentParser()
ap.add_argument("--font"); ap.add_argument("--out", default="docs/demo.gif"); ap.add_argument("--keep", action="store_true")
ap.add_argument("--cols", type=int, default=150); ap.add_argument("--rows", type=int, default=40)
args = ap.parse_args()
COLS, ROWS, CW, CH = args.cols, args.rows, 10, 22
SESSION = "ide-demo"

def find_font():
    if args.font: return args.font
    pats = ["~/.local/share/fonts/**/*Nerd*Mono*Regular*.ttf", "~/.local/share/fonts/**/*NerdFontMono-Regular*.ttf", "~/Library/Fonts/*Nerd*Mono*Regular*.ttf",
            "/usr/share/fonts/**/*Nerd*Mono*Regular*.ttf", "/Library/Fonts/*Nerd*Mono*Regular*.ttf"]
    for p in pats:
        hits = glob.glob(os.path.expanduser(p), recursive=True)
        if hits: return hits[0]
    sys.exit("No Nerd Font found: pass --font /path/to/SomeNerdFontMono-Regular.ttf")
font = ImageFont.truetype(find_font(), 18)

def tmux(*a): return subprocess.run(["tmux", *a], capture_output=True, text=True)
def keys(*k, wait=0.8): tmux("send-keys", "-t", SESSION, *k); time.sleep(wait)
def text(s, wait=0.8): tmux("send-keys", "-t", SESSION, "-l", s); time.sleep(wait)
def ex(cmd, wait=1.2): keys("Escape", wait=0.2); keys(f":{cmd}", "Enter", wait=wait)

PRIVATE = [x for x in {os.environ.get("USER", ""), os.environ.get("LOGNAME", ""), socket.gethostname().split(".")[0]} if len(x) > 2]

def grab():
    raw = tmux("capture-pane", "-t", SESSION, "-p", "-e").stdout
    for word in PRIVATE:      # never publish the account or machine name that a shell prompt may show
        if word in re.sub(r"\x1b\[[0-9;]*m", "", raw): sys.exit(f"The screen shows '{word}'; use a plain shell prompt (PS1) and try again")
    cap = raw.split("\n")[:ROWS]
    img = Image.new("RGB", (COLS * CW, ROWS * CH), (0, 0, 0)); d = ImageDraw.Draw(img)
    for r, line in enumerate(cap):
        fg, bg, x = (200, 200, 200), (0, 0, 0), 0
        for m in re.finditer(r"\x1b\[([0-9;]*)m|([^\x1b]+)", line):
            if m.group(2) is not None:
                for ch in m.group(2):
                    d.rectangle([x * CW, r * CH, (x + 1) * CW, (r + 1) * CH], fill=bg); d.text((x * CW, r * CH), ch, font=font, fill=fg); x += 1
            else:
                p = [int(v) if v else 0 for v in m.group(1).split(";")]; i = 0
                while i < len(p):
                    if p[i] == 0: fg, bg = (200, 200, 200), (0, 0, 0)
                    elif p[i] == 38 and p[i + 1] == 2: fg = tuple(p[i + 2:i + 5]); i += 4
                    elif p[i] == 48 and p[i + 1] == 2: bg = tuple(p[i + 2:i + 5]); i += 4
                    elif p[i] == 49: bg = (0, 0, 0)
                    elif p[i] == 39: fg = (200, 200, 200)
                    i += 1
    return img

frames = []
def snap(hold=1):
    frames.append((grab().resize((COLS * CW * 3 // 4, ROWS * CH * 3 // 4), Image.LANCZOS), hold))

# ── demo project ───────────────────────────────────────────────────────────────────────────────────
base = tempfile.mkdtemp(prefix="demo-")
proj = os.path.join(base, "myapp"); os.makedirs(proj + "/api"); os.makedirs(proj + "/web")
open(proj + "/api/server.py", "w").write('''"""Tiny inventory API."""
from dataclasses import dataclass


@dataclass
class Item:
    name: str
    qty: int = 0
    price: float = 0.0


class Inventory:
    def __init__(self) -> None:
        self.items: dict[str, Item] = {}

    def add(self, item: Item) -> None:
        self.items[item.name] = item

    def total_value(self) -> float:
        return sum(i.qty * i.price for i in self.items.values())


def main() -> None:
    inv = Inventory()
    inv.add(Item("widget", 10, 2.5))
    print(f"total: {inv.total_value():.2f}")


if __name__ == "__main__":
    main()
''')
open(proj + "/api/main.go", "w").write('package main\n\nimport "net/http"\n\nfunc main() {\n\thttp.ListenAndServe(":8080", nil)\n}\n')
open(proj + "/web/index.html", "w").write('<!doctype html>\n<title>Inventory</title>\n<h1>Inventory</h1>\n')
open(proj + "/README.md", "w").write("# myapp\n\nA small inventory demo.\n")
g = lambda *a: subprocess.run(["git", "-C", proj, "-c", "user.name=demo", "-c", "user.email=demo@example.com", *a], capture_output=True)
g("init", "-q"); g("add", "-A"); g("commit", "-qm", "init")
open(proj + "/README.md", "a").write("\nEdited.\n"); open(proj + "/notes.txt", "w").write("todo\n")

try:
    tmux("kill-session", "-t", SESSION)
    env = "PS1='$ ' IDE_NO_WELCOME=1 IDE_NO_SESSION=1 GIT_TERMINAL_PROMPT=0 NVIM_APPNAME=nvim-ide"
    tmux("new-session", "-d", "-s", SESSION, "-x", str(COLS), "-y", str(ROWS), "-c", proj, f"cd {proj} && {env} nvim api/server.py")
    time.sleep(12)
    ex("set shell=sh", 0.5); ex("e api/main.go"); ex("e web/index.html"); ex("e api/server.py", 1.8)
    snap(3)
    keys("F1", wait=1.5); snap(2); text("git", 1.0); snap(2); keys("Escape", wait=0.4); keys("Escape", wait=0.6)
    keys("M-f", wait=1.5); text("Item", 1.0); keys("Escape", wait=3.0); snap(3)
    keys("M-g", wait=2.5); snap(3)
    keys("M-e", wait=1.5)
    keys("M-t", wait=2.5); text("python3 api/server.py\r", 2.0); snap(3)
    keys("C-\\", "C-n", wait=0.5); ex("ToggleTermToggleAll", 1)
    ex("IDETour", 1.5); snap(3); keys("Enter", wait=0.8); keys("Enter", wait=0.8); snap(2); keys("q", wait=0.5)
    ex("IDESettings", 2.0); snap(3)
finally:
    tmux("kill-session", "-t", SESSION)
    if not args.keep: shutil.rmtree(base, ignore_errors=True)

os.makedirs(os.path.dirname(os.path.abspath(args.out)), exist_ok=True)
pal = [f[0].convert("P", palette=Image.ADAPTIVE, colors=128) for f in frames]
pal[0].save(args.out, save_all=True, append_images=pal[1:], duration=[int(h * 1000) for _, h in frames], loop=0, optimize=True)
print(f"wrote {args.out}: {len(frames)} frames, {os.path.getsize(args.out) // 1024} KB")
