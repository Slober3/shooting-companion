import importlib.util
import json
import tempfile
import unittest
from pathlib import Path


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location(
    "verify_graphify", ROOT / "tools/verify_graphify.py"
)
MODULE = importlib.util.module_from_spec(SPEC)
assert SPEC.loader is not None
SPEC.loader.exec_module(MODULE)


class VerifyGraphifyTest(unittest.TestCase):
    def _fixture(self, root: Path) -> None:
        out = root / "graphify-out"
        out.mkdir()
        labels = sorted(MODULE.REQUIRED_LABELS)
        nodes = [
            {"id": f"node-{index}", "label": label, "source_file": f"lib/{index}.dart"}
            for index, label in enumerate(labels)
        ]
        nodes.extend(
            {"id": f"extra-{index}", "label": f"Extra{index}", "source_file": f"lib/e{index}.dart"}
            for index in range(100)
        )
        links = [
            {"source": nodes[index]["id"], "target": nodes[(index + 1) % len(nodes)]["id"]}
            for index in range(len(nodes))
        ]
        (out / "graph.json").write_text(
            json.dumps({"directed": True, "nodes": nodes, "links": links}),
            encoding="utf-8",
        )
        (out / "manifest.json").write_text(
            json.dumps({"lib/a.dart": {"mtime": 0, "ast_hash": "abc"}}),
            encoding="utf-8",
        )
        (out / ".graphify_root").write_text(".\n", encoding="utf-8")

    def test_portable_graph_is_accepted(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self._fixture(root)
            self.assertEqual(MODULE.collect_errors(root), [])

    def test_private_path_and_commit_metadata_are_rejected(self) -> None:
        with tempfile.TemporaryDirectory() as temp:
            root = Path(temp)
            self._fixture(root)
            path = root / "graphify-out/graph.json"
            graph = json.loads(path.read_text(encoding="utf-8"))
            graph["built_at_commit"] = "deadbeef"
            graph["nodes"][0]["source_file"] = "C:\\Users\\person\\private.dart"
            path.write_text(json.dumps(graph), encoding="utf-8")
            errors = MODULE.collect_errors(root)
            self.assertTrue(any("built_at_commit" in error for error in errors))
            self.assertTrue(any("absolute/private" in error for error in errors))


if __name__ == "__main__":
    unittest.main()
