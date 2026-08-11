import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "normalize_graphify_output", ROOT / "tools/normalize_graphify_output.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class NormalizeGraphifyOutputTest(unittest.TestCase):
    def _fixture(self, root: Path, line_ending: bytes) -> Path:
        source = root / "lib/example.dart"
        source.parent.mkdir(parents=True)
        source.write_bytes(line_ending.join((b"void main() {", b"}", b"")))

        out = root / "graphify-out"
        out.mkdir()
        (out / "graph.json").write_text(
            json.dumps(
                {
                    "built_at_commit": "local",
                    "nodes": [{"id": "z"}, {"id": "a"}],
                    "links": [
                        {"source": "z", "target": "a"},
                        {"source": "a", "target": "z"},
                    ],
                }
            ),
            encoding="utf-8",
        )
        (out / "manifest.json").write_text(
            json.dumps(
                {
                    "lib/example.dart": {
                        "mtime": 123,
                        "ast_hash": "platform-specific",
                        "semantic_hash": "platform-specific",
                    }
                }
            ),
            encoding="utf-8",
        )
        return source

    def test_manifest_is_identical_for_crlf_and_lf_checkouts(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            source = self._fixture(root, b"\r\n")
            MODULE.normalize(root)
            first = (root / "graphify-out/manifest.json").read_bytes()

            source.write_bytes(b"void main() {\n}\n")
            manifest_path = root / "graphify-out/manifest.json"
            manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
            manifest["lib/example.dart"].update(
                mtime=999,
                ast_hash="different-linux-parser-hash",
                semantic_hash="different-linux-semantic-hash",
            )
            manifest_path.write_text(json.dumps(manifest), encoding="utf-8")
            MODULE.normalize(root)

            self.assertEqual(manifest_path.read_bytes(), first)
            record = json.loads(first)["lib/example.dart"]
            self.assertEqual(record["mtime"], 0)
            self.assertEqual(record["semantic_hash"], "")
            self.assertRegex(record["ast_hash"], r"^[0-9a-f]{32}$")
            graph = json.loads((root / "graphify-out/graph.json").read_bytes())
            self.assertNotIn("built_at_commit", graph)
            self.assertEqual([node["id"] for node in graph["nodes"]], ["a", "z"])
            self.assertEqual(graph["links"][0]["source"], "a")

    def test_manifest_path_cannot_escape_repository(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self._fixture(root, b"\n")
            manifest_path = root / "graphify-out/manifest.json"
            manifest_path.write_text(
                json.dumps({"../private.txt": {"mtime": 1}}), encoding="utf-8"
            )

            with self.assertRaisesRegex(ValueError, "escapes the repository"):
                MODULE.normalize(root)


if __name__ == "__main__":
    unittest.main()
