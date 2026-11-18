#!/usr/bin/env python3
"""Verify release ZIP contents, SHA256 manifest, and local Markdown links."""
from __future__ import annotations
import hashlib
import re
import sys
import zipfile
from pathlib import Path
from urllib.parse import unquote

ROOT = Path(__file__).resolve().parents[1]
errors: list[str] = []

def assert_ok(ok: bool, message: str) -> None:
    if not ok:
        errors.append(message)

for item in ("README.md", "LICENSE", "SHA256SUMS.txt"):
    assert_ok((ROOT / item).is_file(), f"Missing required file {item}")

archives = sorted(ROOT.glob("*-v*.zip"))
assert_ok(len(archives) == 1, f"Expected one tagged ZIP; found {len(archives)}")
for ext in (".mq4", ".mq5"):
    assert_ok(len(list(ROOT.glob("*" + ext))) == 1,
              f"Expected exactly one root {ext} source")

manifest = ROOT / "SHA256SUMS.txt"
if len(archives) == 1 and manifest.is_file():
    with zipfile.ZipFile(archives[0]) as archive:
        entries = {name.replace(chr(92), "/"): name for name in archive.namelist()}
        names = set(entries)
        assert_ok(not any(n.startswith("/") or ".." in Path(n).parts for n in names),
                  "Unsafe ZIP path")
        for prefix in ("MQL4/Indicators/", "MQL5/Indicators/", "bin/MT4/", "bin/MT5/"):
            assert_ok(any(n.startswith(prefix) and not n.endswith("/") for n in names),
                      f"Missing {prefix} in archive")
        for suffix in (".mq4", ".mq5", ".ex4", ".ex5"):
            assert_ok(any(n.endswith(suffix) for n in names), f"No {suffix} in ZIP")
        for line in manifest.read_text(encoding="utf-8-sig").splitlines():
            if not line.strip():
                continue
            match = re.fullmatch(r"([a-fA-F0-9]{64})\s+(.+)", line.strip())
            if not match:
                errors.append(f"Malformed SHA256SUMS entry: {line[:80]}")
                continue
            digest, name = match.groups()
            if name not in names:
                errors.append(f"Manifest path not present: {name}")
                continue
            actual = hashlib.sha256(archive.read(entries[name])).hexdigest()
            assert_ok(actual.lower() == digest.lower(), f"SHA256 mismatch: {name}")
        for source in list(ROOT.glob("*.mq4")) + list(ROOT.glob("*.mq5")):
            prefix = "MQL4/Indicators/" if source.suffix == ".mq4" else "MQL5/Indicators/"
            name = prefix + source.name
            assert_ok(name in names, f"Source missing from release: {name}")
            if name in names:
                assert_ok(source.read_text(encoding="utf-8-sig").splitlines() ==
                          archive.read(entries[name]).decode("utf-8-sig").splitlines(),
                          f"Root source differs in content from packaged source: {name}")

pattern = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
docs = [ROOT / p for p in ("README.md", "CHANGELOG.md", "CONTRIBUTING.md",
                           "SUPPORT.md", "SECURITY.md")]
docs += list((ROOT / "docs").glob("*.md"))
docs += list((ROOT / ".github" / "ISSUE_TEMPLATE").glob("*.md"))
count = 0
for doc in docs:
    if not doc.is_file():
        continue
    for raw in pattern.findall(doc.read_text(encoding="utf-8-sig")):
        target = unquote(raw.strip().split("#", 1)[0].split(" ", 1)[0])
        if not target or target.startswith(("http://", "https://", "mailto:", "data:", "//")):
            continue
        resolved = (doc.parent / target).resolve()
        assert_ok(resolved.is_relative_to(ROOT.resolve()), f"Link escapes repository: {doc}: {raw}")
        if resolved.is_relative_to(ROOT.resolve()):
            assert_ok(resolved.exists(), f"Broken local link in {doc.relative_to(ROOT)}: {raw}")
        count += 1

if errors:
    print(f"FAILED ({len(errors)} issues)")
    for issue in errors:
        print("  -", issue)
    sys.exit(1)
print(f"PASS: {ROOT.name}; ZIP/manifest/source verified, {count} internal links checked")
