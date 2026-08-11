from __future__ import annotations

import copy
import importlib.util
import tempfile
import unittest
import zipfile
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "verify_release_contract", ROOT / "tools/verify_release_contract.py"
)
assert SPEC is not None and SPEC.loader is not None
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


class ReleaseContractTest(unittest.TestCase):
    def setUp(self) -> None:
        self.contract = MODULE.load_contract(ROOT)

    def test_repository_sources_match_contract(self) -> None:
        self.assertEqual(MODULE.validate_sources(ROOT, self.contract), [])

    def test_version_drift_is_reported(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["app"]["versionName"] = "9.9.9"
        errors = MODULE.validate_sources(ROOT, changed)
        self.assertTrue(any("pubspec versionName" in error for error in errors))

    def test_missing_route_is_reported(self) -> None:
        changed = copy.deepcopy(self.contract)
        changed["routes"]["required"][0]["destination"] = "MissingScreen"
        errors = MODULE.validate_sources(ROOT, changed)
        self.assertTrue(any("missing destination" in error for error in errors))

    def test_git_commit_define_is_part_of_the_release_contract(self) -> None:
        self.assertEqual(
            self.contract["app"]["gitCommitDartDefine"],
            "GIT_COMMIT",
        )
        self.assertEqual(MODULE.validate_sources(ROOT, self.contract), [])

    def test_apk_contract_checks_version_permissions_and_native_engine(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            apk = Path(directory) / "release.apk"
            library = self.contract["android"]["requiredNativeLibraries"][0]
            engine = self.contract["native"]["vision"]["engineVersion"]
            detector = self.contract["native"]["vision"][
                "candidateAlgorithmVersion"
            ]
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr(
                    library,
                    f"binary\0{engine}\0{detector}\0".encode("ascii"),
                )

            def analyzer(_executable: str, _apk: Path, command: str) -> str:
                values = {
                    "application-id": self.contract["app"]["packageName"],
                    "version-name": self.contract["app"]["versionName"],
                    "version-code": str(self.contract["app"]["buildNumber"]),
                    "permissions": "\n".join(
                        self.contract["android"]["requiredPermissions"]
                    ),
                }
                return values[command]

            self.assertEqual(
                MODULE.validate_apk(apk, self.contract, "fake", analyzer), []
            )

    def test_apk_without_opencv_candidate_detector_is_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as directory:
            apk = Path(directory) / "release.apk"
            library = self.contract["android"]["requiredNativeLibraries"][0]
            engine = self.contract["native"]["vision"]["engineVersion"]
            with zipfile.ZipFile(apk, "w") as archive:
                archive.writestr(library, f"binary\0{engine}\0".encode("ascii"))

            def analyzer(_executable: str, _apk: Path, command: str) -> str:
                values = {
                    "application-id": self.contract["app"]["packageName"],
                    "version-name": self.contract["app"]["versionName"],
                    "version-code": str(self.contract["app"]["buildNumber"]),
                    "permissions": "\n".join(
                        self.contract["android"]["requiredPermissions"]
                    ),
                }
                return values[command]

            errors = MODULE.validate_apk(apk, self.contract, "fake", analyzer)
            self.assertTrue(any("candidate detector" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
