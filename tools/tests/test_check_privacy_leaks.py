from __future__ import annotations

import importlib.util
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "check_privacy_leaks", ROOT / "tools/check_privacy_leaks.py"
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class PrivacyLeakCheckTest(unittest.TestCase):
    def test_rejects_local_validation_tree(self) -> None:
        leaks = MODULE.find_path_leaks(
            [".local/vision-validation/incoming/private-target.jpg"]
        )
        self.assertTrue(any("private validation path" in leak for leak in leaks))

    def test_rejects_backup_and_camera_filename(self) -> None:
        leaks = MODULE.find_path_leaks(
            ["fixtures/user.scbackup", "docs/IMG_20260809_123456.jpg"]
        )
        self.assertTrue(any("release artifact" in leak for leak in leaks))
        self.assertTrue(any("camera-style" in leak for leak in leaks))

    def test_allows_android_icons(self) -> None:
        leaks = MODULE.find_path_leaks(
            ["apps/mobile/android/app/src/main/res/mipmap-hdpi/ic_launcher.png"]
        )
        self.assertEqual(leaks, [])

    def test_fixture_media_requires_privacy_manifest(self) -> None:
        fixture = "native/vision_core/test/fixtures/licensed/target.jpg"
        self.assertTrue(MODULE.find_path_leaks([fixture]))
        self.assertEqual(
            MODULE.find_path_leaks([fixture, f"{fixture}.fixture.json"]), []
        )


if __name__ == "__main__":
    unittest.main()
