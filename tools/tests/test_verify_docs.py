import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("verify_docs", ROOT / "tools/verify_docs.py")
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class VerifyDocsTest(unittest.TestCase):
    def test_current_repository_is_valid(self) -> None:
        self.assertEqual(MODULE.collect_errors(ROOT), [])

    def test_broken_internal_link_is_reported(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            (root / "README.md").write_text("[missing](docs/nope.md)", encoding="utf-8")
            errors = MODULE.collect_errors(root)
            self.assertTrue(any("missing first-party README" in error for error in errors))
            self.assertTrue(any("broken Markdown link" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
