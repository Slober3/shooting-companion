#!/usr/bin/env python3
"""Validate first-party Markdown links and coupled release facts."""

from __future__ import annotations

import argparse
import json
import re
from pathlib import Path
from urllib.parse import unquote


LINK_RE = re.compile(r"!?\[[^\]]*\]\(([^)]+)\)")
EXPECTED_READMES = (
    "README.md",
    "apps/mobile/README.md",
    "packages/vision_research/README.md",
    "native/vision_core/test/fixtures/README.md",
)


def _markdown_files(root: Path) -> list[Path]:
    candidates = [root / name for name in ("README.md", "CHANGELOG.md", "PRIVACY.md")]
    candidates.extend((root / "docs").glob("**/*.md"))
    candidates.extend(root.glob("apps/**/README*.md"))
    candidates.extend(root.glob("packages/**/README*.md"))
    candidates.extend(root.glob("native/**/README*.md"))
    return sorted(
        path
        for path in set(candidates)
        if path.is_file()
        and "third_party" not in path.parts
        and not any(part.startswith(".") for part in path.relative_to(root).parts)
    )


def _link_target(raw: str) -> str:
    raw = raw.strip()
    if raw.startswith("<") and ">" in raw:
        return raw[1 : raw.index(">")]
    return raw.split(maxsplit=1)[0]


def collect_errors(root: Path) -> list[str]:
    root = root.resolve()
    errors: list[str] = []

    def read_required(relative: str) -> str:
        path = root / relative
        if not path.is_file():
            errors.append(f"missing required documentation source: {relative}")
            return ""
        return path.read_text(encoding="utf-8")

    for relative in EXPECTED_READMES:
        if not (root / relative).is_file():
            errors.append(f"missing first-party README: {relative}")

    markdown = _markdown_files(root)
    for path in markdown:
        text = path.read_text(encoding="utf-8")
        for match in LINK_RE.finditer(text):
            target = unquote(_link_target(match.group(1)))
            if not target or target.startswith(("http://", "https://", "mailto:", "#")):
                continue
            file_target = target.split("#", 1)[0].replace("/", str(Path("/"))[-1])
            if file_target and not (path.parent / file_target).resolve().exists():
                rel = path.relative_to(root).as_posix()
                errors.append(f"broken Markdown link in {rel}: {target}")

    pubspec = read_required("apps/mobile/pubspec.yaml")
    contract_text = read_required("apps/mobile/assets/release_contract.json")
    contract = json.loads(contract_text) if contract_text else {}
    database = read_required("apps/mobile/lib/data/app_database.dart")
    backup = read_required("apps/mobile/lib/services/backup_service.dart")
    readme = read_required("README.md")
    release_doc = read_required("docs/release.md")
    facts = {
        "pubspec version": ("version: 0.8.0+1", pubspec),
        "database schema": ("int get schemaVersion => 8;", database),
        "backup manifest": ("static const currentFormatVersion = 8;", backup),
        "root README version": ("0.8.0+1", readme),
        "release documentation version": ("0.8.0+1", release_doc),
        "Graphify documentation link": ("docs/graphify.md", readme),
    }
    for name, (needle, haystack) in facts.items():
        if needle not in haystack:
            errors.append(f"stale or missing {name}: expected {needle!r}")

    app_contract = contract.get("app", {})
    data_contract = contract.get("data", {})
    if app_contract.get("versionName") != "0.8.0" or app_contract.get("buildNumber") != 1:
        errors.append("release contract app version must be 0.8.0 build 1")
    if data_contract.get("databaseSchema") != 8 or data_contract.get("backupManifest") != 8:
        errors.append("release contract database and backup versions must both be 8")

    content_root = root / "packages/training/assets/content/v2"
    try:
        counts = {
            "lessons": len(json.loads((content_root / "techniques.nl-BE.json").read_text(encoding="utf-8"))["lessons"]),
            "drills": len(json.loads((content_root / "drills.nl-BE.json").read_text(encoding="utf-8"))["drills"]),
            "learning paths": len(json.loads((content_root / "learning_paths.nl-BE.json").read_text(encoding="utf-8"))["learningPaths"]),
        }
    except (OSError, KeyError, json.JSONDecodeError) as exc:
        errors.append(f"training catalog cannot be validated: {exc}")
        counts = {}
    expected = {"lessons": 18, "drills": 12, "learning paths": 4}
    if counts != expected:
        errors.append(f"training catalog counts differ: expected {expected}, found {counts}")
    if "0.5.1+3" in release_doc:
        errors.append("docs/release.md still describes 0.5.1+3")
    return sorted(set(errors))


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    errors = collect_errors(args.root)
    if errors:
        for error in errors:
            print(f"ERROR: {error}")
        return 1
    print("First-party documentation links and release facts are current.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
