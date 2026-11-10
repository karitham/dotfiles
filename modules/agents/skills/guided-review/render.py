#!/usr/bin/env python3
"""Render a guide JSON into one HTML page, after checking it against its diffs.

usage: render.py guide.json out.html [--diff CHAPTER_ID=path.diff ...]

Checks (printed, non-fatal): every excerpt line is verbatim in its chapter's
diff, and every changed file is either named by a step or listed as skipped.
"""
import json
import re
import sys
from pathlib import Path


def changed_files(diff: str) -> list[str]:
    return re.findall(r"^diff --git a/\S+ b/(\S+)", diff, re.M)


def check(guide: dict, diffs: dict[str, str]) -> list[str]:
    problems = []
    for ch in guide.get("chapters", []):
        diff = diffs.get(ch["id"])
        if diff is None:
            continue
        body = {line[1:].strip() for line in diff.splitlines() if line[:1] in "+- "}
        for i, step in enumerate(ch.get("steps", []), 1):
            for c in step.get("code", []):
                for line in c["excerpt"].splitlines():
                    text = line[1:].strip() if line[:1] in "+- " else line.strip()
                    if text and text not in body and not text.startswith("@@") and text != "...":
                        problems.append(f"{ch['id']} step {i}: not in the diff: {line[:90]}")
                        break
        named = {f for s in ch.get("steps", []) for f in s.get("files", [])}
        named |= {s["path"] for s in ch.get("skipped", [])}
        for f in changed_files(diff):
            if f not in named and not any(f.startswith(n.rstrip("*")) for n in named if n.endswith("*")):
                problems.append(f"{ch['id']}: {f} is in no step and not skipped")
        if len(ch.get("steps", [])) > 7:
            problems.append(f"{ch['id']}: {len(ch['steps'])} steps; aim for 3-6")
        for d in ch.get("diagrams", []):
            if len(d.get("lines", [])) > 14:
                problems.append(f"{ch['id']}: a diagram has {len(d['lines'])} lines; aim for <= 12")
    return problems


def main(argv: list[str]) -> None:
    guide = json.loads(Path(argv[1]).read_text())
    diffs = {}
    for arg in argv[3:]:
        if arg == "--diff":
            continue
        key, path = arg.split("=", 1)
        diffs[key] = Path(path).read_text()
    for problem in check(guide, diffs):
        print("check:", problem)
    template = (Path(__file__).parent / "template.html").read_text()
    data = json.dumps(guide).replace("</", "<\\/")
    title = guide.get("title", "guided review").replace("<", "&lt;")
    Path(argv[2]).write_text(template.replace("__TITLE__", title).replace("__DATA__", data))
    print("wrote", argv[2])


if __name__ == "__main__":
    main(sys.argv)
