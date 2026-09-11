#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


ROOT = Path(__file__).resolve().parent.parent
SKILL = ROOT / "SKILL.md"
EXPECTED_NAME = "embedded-performance-optimizer"
EXPECTED_RULE_COUNT = 37


def fail(message: str) -> None:
    print(f"ERROR: {message}", file=sys.stderr)
    raise SystemExit(1)


def main() -> None:
    text = SKILL.read_text(encoding="utf-8")
    if not text.startswith("---\n"):
        fail("SKILL.md must start with YAML frontmatter")

    match = re.match(r"---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        fail("SKILL.md frontmatter is malformed")

    frontmatter = match.group(1)
    name_match = re.search(r"^name:\s*([^\n]+)$", frontmatter, re.MULTILINE)
    description_match = re.search(r"^description:\s*(.+)$", frontmatter, re.MULTILINE)
    if not name_match or name_match.group(1).strip(' \"\'') != EXPECTED_NAME:
        fail(f"name must be {EXPECTED_NAME}")
    if not description_match or not description_match.group(1).strip():
        fail("description is required")

    for link in re.findall(r"\[[^]]+\]\(([^)]+\.md)\)", text):
        if not (ROOT / link).is_file():
            fail(f"missing referenced file: {link}")

    catalog = (ROOT / "references" / "audit-rule-catalog.md").read_text(encoding="utf-8")
    rule_ids = re.findall(r"^###\s+(OPT-[A-Z]+-\d{2})\b", catalog, re.MULTILINE)
    duplicates = sorted({rule_id for rule_id in rule_ids if rule_ids.count(rule_id) > 1})
    if duplicates:
        fail(f"duplicate rule IDs: {', '.join(duplicates)}")
    if len(rule_ids) != EXPECTED_RULE_COUNT:
        fail(f"expected {EXPECTED_RULE_COUNT} rules, found {len(rule_ids)}")

    forbidden = ("Codex must", "Claude must", "Cursor must", "Gemini must", "Copilot must")
    for phrase in forbidden:
        if phrase.lower() in text.lower():
            fail(f"portable core contains platform-specific instruction: {phrase}")

    print(f"OK: {EXPECTED_NAME}; {len(rule_ids)} unique rules; references resolved")


if __name__ == "__main__":
    main()
