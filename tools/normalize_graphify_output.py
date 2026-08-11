#!/usr/bin/env python3
"""Normalize Graphify output so it is portable and reproducible in Git."""

from __future__ import annotations

import argparse
import hashlib
import json
from pathlib import Path
from typing import Any


def _write_json(path: Path, value: Any) -> None:
    path.write_bytes(
        (json.dumps(value, ensure_ascii=False, indent=2, sort_keys=True) + "\n").encode(
            "utf-8"
        )
    )


def _portable_source_hash(root: Path, source: str) -> str:
    normalized_source = source.replace("\\", "/")
    path = (root / normalized_source).resolve()
    try:
        path.relative_to(root)
    except ValueError as exc:
        raise ValueError(f"manifest path escapes the repository: {source}") from exc
    if not path.is_file():
        raise FileNotFoundError(f"manifest source does not exist: {source}")

    # Git may materialize text files with CRLF on Windows and LF on Linux.
    # Hash normalized bytes so the durable manifest describes repository
    # content instead of Graphify's platform-specific parser fingerprint.
    data = path.read_bytes().replace(b"\r\n", b"\n").replace(b"\r", b"\n")
    return hashlib.sha256(data).hexdigest()[:32]


def _stable_item_key(value: Any) -> str:
    return json.dumps(
        value, ensure_ascii=False, sort_keys=True, separators=(",", ":")
    )


def normalize(root: Path) -> None:
    root = root.resolve()
    out = root / "graphify-out"
    graph_path = out / "graph.json"
    manifest_path = out / "manifest.json"
    if not graph_path.is_file() or not manifest_path.is_file():
        raise FileNotFoundError(
            "graphify-out/graph.json and manifest.json must exist; run "
            "`graphify extract . --code-only` first"
        )

    graph = json.loads(graph_path.read_text(encoding="utf-8"))
    graph.pop("built_at_commit", None)
    for collection in ("nodes", "links"):
        values = graph.get(collection)
        if isinstance(values, list):
            values.sort(key=_stable_item_key)
    _write_json(graph_path, graph)

    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    for source, record in manifest.items():
        if not isinstance(record, dict):
            continue
        record["mtime"] = 0
        record["ast_hash"] = _portable_source_hash(root, str(source))
        # AST-only updates never use API/LLM semantics. Keeping this empty is
        # both honest and portable across Graphify parser backends.
        record["semantic_hash"] = ""
    _write_json(manifest_path, manifest)

    for name in (".graphify_analysis.json", ".graphify_labels.json"):
        path = out / name
        if path.is_file():
            _write_json(path, json.loads(path.read_text(encoding="utf-8")))

    (out / ".graphify_root").write_bytes(b".\n")


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path.cwd())
    args = parser.parse_args()
    normalize(args.root)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
