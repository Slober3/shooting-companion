#!/usr/bin/env python3
"""Fail a release when versioned release facts drift apart.

The bundled JSON contract is canonical. This script compares it with Dart,
Android, native and documentation sources and, when supplied, the built APK.
It deliberately uses only Python's standard library so it can run before any
project dependency installation.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
import zipfile
from pathlib import Path
from typing import Any, Callable
from xml.etree import ElementTree


ANDROID_NS = "http://schemas.android.com/apk/res/android"
TOOLS_NS = "http://schemas.android.com/tools"
DEFAULT_CONTRACT = Path("apps/mobile/assets/release_contract.json")


def _read(root: Path, relative: str) -> str:
    path = root / relative
    if not path.is_file():
        raise ValueError(f"Missing release source: {relative}")
    return path.read_text(encoding="utf-8")


def _capture(pattern: str, text: str, label: str) -> str:
    match = re.search(pattern, text, flags=re.MULTILINE)
    if match is None:
        raise ValueError(f"Could not read {label} from its source")
    return match.group(1)


def load_contract(root: Path, relative: Path = DEFAULT_CONTRACT) -> dict[str, Any]:
    path = root / relative
    data = json.loads(path.read_text(encoding="utf-8"))
    required = {"contractVersion", "app", "data", "routes", "android", "native"}
    missing = required.difference(data)
    if missing:
        raise ValueError(f"Release contract is missing: {', '.join(sorted(missing))}")
    return data


def _expect(errors: list[str], actual: Any, expected: Any, label: str) -> None:
    if actual != expected:
        errors.append(f"{label}: expected {expected!r}, found {actual!r}")


def _manifest_permissions(root: Path) -> set[str]:
    manifest = root / "apps/mobile/android/app/src/main/AndroidManifest.xml"
    tree = ElementTree.parse(manifest)
    permissions: set[str] = set()
    for item in tree.getroot().findall("uses-permission"):
        if item.get(f"{{{TOOLS_NS}}}node") == "remove":
            continue
        name = item.get(f"{{{ANDROID_NS}}}name")
        if name:
            permissions.add(name)
    return permissions


def validate_sources(root: Path, contract: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    app = contract["app"]
    data = contract["data"]
    android = contract["android"]
    vision = contract["native"]["vision"]
    timer = contract["native"]["shotTimer"]

    pubspec = _read(root, "apps/mobile/pubspec.yaml")
    version = _capture(r"^version:\s*([^+\s]+)\+(\d+)\s*$", pubspec, "app version")
    version_match = re.search(r"^version:\s*([^+\s]+)\+(\d+)\s*$", pubspec, re.MULTILINE)
    assert version_match is not None
    _expect(errors, version, app["versionName"], "pubspec versionName")
    _expect(errors, int(version_match.group(2)), app["buildNumber"], "pubspec buildNumber")
    if "- assets/release_contract.json" not in pubspec:
        errors.append("pubspec does not bundle assets/release_contract.json")

    gradle = _read(root, "apps/mobile/android/app/build.gradle.kts")
    package_name = _capture(r'applicationId\s*=\s*"([^"]+)"', gradle, "applicationId")
    _expect(errors, package_name, app["packageName"], "Android applicationId")

    database = _read(root, "apps/mobile/lib/data/app_database.dart")
    database_schema = int(
        _capture(r"int get schemaVersion\s*=>\s*(\d+)\s*;", database, "database schema")
    )
    _expect(errors, database_schema, data["databaseSchema"], "database schema")

    backup = _read(root, "apps/mobile/lib/services/backup_service.dart")
    backup_manifest = int(
        _capture(
            r"static const currentFormatVersion\s*=\s*(\d+)\s*;",
            backup,
            "backup manifest",
        )
    )
    _expect(errors, backup_manifest, data["backupManifest"], "backup manifest")
    if data["backupMagic"] not in backup:
        errors.append(f"backup magic {data['backupMagic']!r} is absent from backup_service.dart")

    for route in contract["routes"]["required"]:
        source = _read(root, route["source"])
        if route["label"] not in source:
            errors.append(f"route {route['id']} is missing label {route['label']!r}")
        if route["destination"] not in source:
            errors.append(
                f"route {route['id']} is missing destination {route['destination']!r}"
            )

    source_permissions = _manifest_permissions(root)
    for permission in android["requiredPermissions"]:
        if permission not in source_permissions:
            errors.append(f"required Android permission is absent: {permission}")
    for permission in android["forbiddenPermissions"]:
        if permission in source_permissions:
            errors.append(f"forbidden Android permission is active: {permission}")

    vision_header = _read(root, "native/vision_core/include/vision_core/vision_core.hpp")
    c_header = _read(root, "native/vision_core/include/vision_core/vision_core_c.h")
    engine_version = _capture(
        r'kEngineVersion\s*=\s*"([^"]+)"', vision_header, "vision engine version"
    )
    cpp_abi = int(_capture(r"kAbiVersion\s*=\s*(\d+)", vision_header, "C++ vision ABI"))
    c_abi = int(_capture(r"SC_VISION_ABI_VERSION\s+(\d+)u", c_header, "C vision ABI"))
    _expect(errors, engine_version, vision["engineVersion"], "vision engine version")
    _expect(errors, cpp_abi, vision["abiVersion"], "C++ vision ABI")
    _expect(errors, c_abi, vision["abiVersion"], "C vision ABI")

    backend = _read(root, "native/vision_core/src/opencv_backend.cpp")
    candidate_algorithm = _capture(
        r'\{"candidates",\s*"([^"]+)"\}',
        backend,
        "candidate detector algorithm",
    )
    _expect(
        errors,
        candidate_algorithm,
        vision["candidateAlgorithmVersion"],
        "candidate detector algorithm",
    )

    setup = _read(root, "tools/setup_opencv_android.ps1")
    setup_version = _capture(r"\$version\s*=\s*'([^']+)'", setup, "OpenCV version")
    setup_sha = _capture(
        r"\$expectedSha256\s*=\s*'([0-9a-fA-F]+)'", setup, "OpenCV checksum"
    ).lower()
    _expect(errors, setup_version, vision["openCvVersion"], "OpenCV version")
    _expect(errors, setup_sha, vision["openCvSha256"].lower(), "OpenCV checksum")

    timer_source = _read(
        root,
        "packages/shot_timer/android/src/main/kotlin/app/shootingcompanion/shot_timer/AcousticShotTimerEngine.kt",
    )
    detector = _capture(
        r'DETECTOR_VERSION\s*=\s*"([^"]+)"', timer_source, "shot-timer detector"
    )
    _expect(errors, detector, timer["detectorVersion"], "shot-timer detector")

    docs = {
        "README version": (
            "README.md",
            f"Versie `{app['versionName']}+{app['buildNumber']}`",
        ),
        "privacy build": (
            "PRIVACY.md",
            f"Version `{app['versionName']}+{app['buildNumber']}`",
        ),
        "changelog version": ("CHANGELOG.md", f"## {app['versionName']}"),
    }
    for label, (path, marker) in docs.items():
        if marker not in _read(root, path):
            errors.append(f"{label} is stale; expected marker {marker!r}")

    ci = _read(root, ".github/workflows/ci.yml")
    release_contract_source = _read(
        root, "apps/mobile/lib/release/release_contract.dart"
    )
    git_commit_define = app["gitCommitDartDefine"]
    if f"String.fromEnvironment(\n    '{git_commit_define}'" not in release_contract_source:
        errors.append(
            f"release contract Dart source does not read {git_commit_define!r}"
        )
    if f"--dart-define={git_commit_define}=${{{{ github.sha }}}}" not in ci:
        errors.append(
            f"CI release build does not inject {git_commit_define!r}"
        )
    for command in (
        "python tools/verify_release_contract.py",
        "python tools/check_privacy_leaks.py",
        "python tools/verify_release_contract.py --apk",
    ):
        if command not in ci:
            errors.append(f"CI is missing release gate: {command}")
    return errors


def _run_apkanalyzer(executable: str, apk: Path, command: str) -> str:
    completed = subprocess.run(
        [executable, "manifest", command, str(apk)],
        check=True,
        capture_output=True,
        text=True,
    )
    return completed.stdout.strip()


def validate_apk(
    apk: Path,
    contract: dict[str, Any],
    apkanalyzer: str,
    analyzer: Callable[[str, Path, str], str] = _run_apkanalyzer,
) -> list[str]:
    errors: list[str] = []
    app = contract["app"]
    android = contract["android"]
    vision = contract["native"]["vision"]
    if not apk.is_file():
        return [f"release APK does not exist: {apk}"]

    try:
        _expect(
            errors,
            analyzer(apkanalyzer, apk, "application-id"),
            app["packageName"],
            "APK applicationId",
        )
        _expect(
            errors,
            analyzer(apkanalyzer, apk, "version-name"),
            app["versionName"],
            "APK versionName",
        )
        _expect(
            errors,
            int(analyzer(apkanalyzer, apk, "version-code")),
            app["buildNumber"],
            "APK versionCode",
        )
        permission_output = analyzer(apkanalyzer, apk, "permissions")
    except (OSError, subprocess.CalledProcessError, ValueError) as error:
        return [f"apkanalyzer failed: {error}"]

    permissions = set(re.findall(r"android\.permission\.[A-Z0-9_]+", permission_output))
    for permission in android["requiredPermissions"]:
        if permission not in permissions:
            errors.append(f"APK is missing required permission: {permission}")
    for permission in android["forbiddenPermissions"]:
        if permission in permissions:
            errors.append(f"APK contains forbidden permission: {permission}")

    try:
        with zipfile.ZipFile(apk) as archive:
            names = set(archive.namelist())
            for library in android["requiredNativeLibraries"]:
                if library not in names:
                    errors.append(f"APK is missing native library: {library}")
                    continue
                binary = archive.read(library)
                if vision["engineVersion"].encode("ascii") not in binary:
                    errors.append(
                        f"{library} does not expose engine {vision['engineVersion']}"
                    )
                if vision["candidateAlgorithmVersion"].encode("ascii") not in binary:
                    errors.append(
                        f"{library} does not contain OpenCV candidate detector "
                        f"{vision['candidateAlgorithmVersion']}"
                    )
    except (OSError, zipfile.BadZipFile) as error:
        errors.append(f"could not inspect APK archive: {error}")
    return errors


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--root", type=Path, default=Path(__file__).resolve().parents[1])
    parser.add_argument("--contract", type=Path, default=DEFAULT_CONTRACT)
    parser.add_argument("--apk", type=Path)
    parser.add_argument("--apkanalyzer", default="apkanalyzer")
    args = parser.parse_args(argv)

    root = args.root.resolve()
    try:
        contract = load_contract(root, args.contract)
        errors = validate_sources(root, contract)
        if args.apk is not None:
            errors.extend(validate_apk(args.apk.resolve(), contract, args.apkanalyzer))
    except (OSError, ValueError, json.JSONDecodeError) as error:
        errors = [str(error)]

    if errors:
        print("Release contract validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    suffix = " and APK" if args.apk is not None else ""
    print(f"Release contract matches source{suffix}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
