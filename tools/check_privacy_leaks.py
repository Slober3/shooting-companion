#!/usr/bin/env python3
"""Reject private range media, backups and local validation data from Git."""

from __future__ import annotations

import re
import subprocess
import sys
from pathlib import Path, PurePosixPath


FORBIDDEN_ROOTS = (
    ".local/vision-validation/",
    "data/private/",
    "datasets/private/",
    "validation/private/",
)
FORBIDDEN_SUFFIXES = (
    ".apk",
    ".aab",
    ".scbackup",
    ".scvision",
    ".keystore",
    ".jks",
)
PRIVATE_MEDIA_SUFFIXES = (
    ".jpg",
    ".jpeg",
    ".heic",
    ".dng",
    ".wav",
    ".pcm",
    ".m4a",
    ".aac",
    ".mp3",
    ".mp4",
    ".mov",
)
CAMERA_FILENAME = re.compile(
    r"(?:AISelect_|IMG_|PXL_|WIN_)?\d{8}[_-]?\d{6}", re.IGNORECASE
)
# Build the platform directory name separately so this checker does not match
# the literal regular-expression source in its own tracked file.
_HOME_DIRECTORY = "Users"
HOME_PATH = re.compile(
    rf"(?:[A-Za-z]:[\\/]{_HOME_DIRECTORY}[\\/][^\\/\s]+|"
    rf"/{_HOME_DIRECTORY}/[^/\s]+)"
)
TEXT_SUFFIXES = {
    ".dart",
    ".json",
    ".md",
    ".py",
    ".ps1",
    ".txt",
    ".yaml",
    ".yml",
    ".xml",
}


def _normalise(path: str) -> str:
    normalised = PurePosixPath(path.replace("\\", "/")).as_posix()
    while normalised.startswith("./"):
        normalised = normalised[2:]
    return normalised


def find_path_leaks(paths: list[str]) -> list[str]:
    normalised = [_normalise(path) for path in paths]
    tracked = set(normalised)
    leaks: list[str] = []
    for path in normalised:
        lowered = path.lower()
        name = PurePosixPath(path).name
        if any(lowered.startswith(root) for root in FORBIDDEN_ROOTS):
            leaks.append(f"private validation path is tracked: {path}")
        if lowered.endswith(FORBIDDEN_SUFFIXES):
            leaks.append(f"private or generated release artifact is tracked: {path}")
        if CAMERA_FILENAME.search(name):
            leaks.append(f"camera-style personal filename is tracked: {path}")
        if lowered.endswith(PRIVATE_MEDIA_SUFFIXES):
            if lowered.startswith("apps/mobile/android/app/src/main/res/"):
                continue
            fixture_manifest = f"{path}.fixture.json"
            if "/test/fixtures/" not in lowered or fixture_manifest not in tracked:
                leaks.append(
                    "tracked photo/audio/video requires an adjacent "
                    f"privacy-reviewed fixture manifest: {path}"
                )
    return leaks


def find_content_leaks(root: Path, paths: list[str]) -> list[str]:
    leaks: list[str] = []
    for relative in paths:
        path = root / relative
        if path.suffix.lower() not in TEXT_SUFFIXES or not path.is_file():
            continue
        if path.stat().st_size > 2_000_000:
            continue
        text = path.read_text(encoding="utf-8", errors="ignore")
        if HOME_PATH.search(text):
            leaks.append(f"local user-home path found in tracked text: {relative}")
    return leaks


def tracked_files(root: Path) -> list[str]:
    completed = subprocess.run(
        [
            "git",
            "-c",
            f"safe.directory={root.as_posix()}",
            "ls-files",
            "-z",
        ],
        cwd=root,
        check=True,
        capture_output=True,
    )
    return [
        item.decode("utf-8")
        for item in completed.stdout.split(b"\0")
        if item
    ]


def main() -> int:
    root = Path(__file__).resolve().parents[1]
    try:
        paths = tracked_files(root)
        leaks = find_path_leaks(paths) + find_content_leaks(root, paths)
    except (OSError, subprocess.CalledProcessError) as error:
        print(f"Privacy leak check could not run: {error}", file=sys.stderr)
        return 1
    if leaks:
        print("Privacy leak prevention failed:", file=sys.stderr)
        for leak in sorted(set(leaks)):
            print(f"- {leak}", file=sys.stderr)
        return 1
    print("No private validation media or release artifacts are tracked.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
