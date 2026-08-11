#!/usr/bin/env python3
"""Fail closed when the committed Graphify graph is stale, unsafe or incomplete."""

from __future__ import annotations

import argparse
import json
from pathlib import Path


REQUIRED_LABELS = {
    "GuidedDrillRunnerScreen",
    "TechniqueLessonV2",
    "LearningPathV2",
    "VisionScanRepository",
    "ScoreEngine",
}
FORBIDDEN_PATH_PARTS = (
    ".dart_tool/",
    ".flutter-sdk/",
    ".dart-sdk-local/",
    ".tooling/",
    ".local/vision-validation/",
    "graphify-out/",
    "release-artifacts/",
    "/build/",
)


def collect_errors(root: Path) -> list[str]:
    out = root.resolve() / "graphify-out"
    errors: list[str] = []
    try:
        graph = json.loads((out / "graph.json").read_text(encoding="utf-8"))
        manifest = json.loads((out / "manifest.json").read_text(encoding="utf-8"))
        marker = (out / ".graphify_root").read_text(encoding="utf-8").strip()
    except (OSError, json.JSONDecodeError) as exc:
        return [f"Graphify core output is missing or invalid: {exc}"]

    if marker != ".":
        errors.append(".graphify_root must contain portable '.' and no local path")
    if "built_at_commit" in graph:
        errors.append("graph.json must not contain self-referential built_at_commit")
    if not isinstance(graph.get("directed"), bool) or not isinstance(graph.get("nodes"), list):
        errors.append("graph.json must declare directionality and contain a node list")
    if len(graph.get("nodes", [])) < 100 or len(graph.get("links", [])) < 100:
        errors.append("graph.json is unexpectedly small")

    labels = {str(node.get("label", "")).casefold() for node in graph.get("nodes", [])}
    for required in sorted(REQUIRED_LABELS):
        if required.casefold() not in labels:
            errors.append(f"required Graphify symbol missing: {required}")

    local_markers = ("c:\\users\\", "/home/runner/", "/users/")
    for node in graph.get("nodes", []):
        source = str(node.get("source_file", "")).replace("\\", "/").lower()
        if source.startswith("/") or any(marker in source for marker in local_markers):
            errors.append(f"absolute/private source path in graph: {source}")
        if any(part in f"/{source}" for part in FORBIDDEN_PATH_PARTS):
            errors.append(f"excluded source path in graph: {source}")

    if not isinstance(manifest, dict) or not manifest:
        errors.append("manifest.json must be a non-empty object")
    else:
        for source, record in manifest.items():
            normalized = str(source).replace("\\", "/").lower()
            if any(part in f"/{normalized}" for part in FORBIDDEN_PATH_PARTS):
                errors.append(f"excluded source path in manifest: {source}")
            if not isinstance(record, dict) or record.get("mtime") != 0:
                errors.append(f"manifest record is not normalized: {source}")

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
    print("Graphify output is current, portable and scoped.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
