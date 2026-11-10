#!/usr/bin/env python3
"""Record a TUI/UX lesson so the skill keeps learning.
Usage: add_lesson.py "Title" "What went wrong / what we saw" "The rule to follow next time" [--lint "regex or idea"]
Appends to references/lessons.md. If the mistake is machine-checkable, also add a rule to scripts/ui_lint.py
(the --lint note is stored with the lesson so the next person knows what to implement).
"""
import sys, pathlib, re, datetime
p = pathlib.Path(__file__).resolve().parent.parent / "references" / "lessons.md"
args = [a for a in sys.argv[1:] if not a.startswith("--")]
if len(args) < 3:
    print(__doc__); sys.exit(2)
title, what, rule = args[:3]
lint = sys.argv[sys.argv.index("--lint") + 1] if "--lint" in sys.argv else ""
text = p.read_text()
n = max([int(x) for x in re.findall(r"^## (\d+)\.", text, re.M)] + [0]) + 1
entry = f"\n## {n}. {title}\n**Seen:** {what}\n**Rule:** {rule}\n" + (f"**Lint idea:** {lint}\n" if lint else "") + f"*(added {datetime.date.today()})*\n"
p.write_text(text.rstrip() + "\n" + entry)
print(f"added lesson {n}: {title}")
