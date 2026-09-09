"""実アプリを動かさず、混在アプリの配置と対象外ウィンドウの保護を検証する。"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).resolve().parents[1] / "scripts" / "auto-grid.sh"
MOCK = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

path = Path(os.environ["GRID_TEST_STATE"])
state = json.loads(path.read_text())
args = sys.argv[1:]
command = args[0]

def leaves(node):
    return sum((leaves(child) for child in node), []) if isinstance(node, list) else [node]

def option(name):
    return args[args.index(name) + 1]

if command == "list-windows":
    # 実際の CLI 同様、画面上の順番とは異なる順序で返す。
    for window in reversed(state["windows"]):
        if "--workspace" in args and window["ws"] != option("--workspace"):
            continue
        values = {"window-id": str(window["id"]), "workspace": window["ws"],
                  "window-layout": window["layout"]}
        output = option("--format")
        for key, value in values.items():
            output = output.replace("%{" + key + "}", value)
        print(output)
    sys.exit(0)

state["commands"].append(args)
tree = state["tree"]
if command == "flatten-workspace-tree":
    assert option("--workspace") == "S2"
    state["tree"] = leaves(tree)
elif command == "layout":
    assert args == ["layout", "--workspace", "S2", "--root", "h_tiles"]
elif command == "move":
    assert option("--boundaries") == "workspace" and args[-1] == "left"
    index = tree.index(int(option("--window-id")))
    if index == 0:
        sys.exit(1)
    tree[index - 1], tree[index] = tree[index], tree[index - 1]
elif command == "join-with":
    assert args[-1] == "right"
    index = tree.index(int(option("--window-id")))
    assert index + 1 < len(tree)
    assert isinstance(tree[index + 1], int)
    tree[index:index + 2] = [tree[index:index + 2]]
elif command == "balance-sizes":
    assert option("--workspace") == "S2"
else:
    raise AssertionError("想定外の操作: " + repr(args))
path.write_text(json.dumps(state))
'''


class AutoGridTest(unittest.TestCase):
    def run_grid(self, count, target="10", floating=False, concurrent=False):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            mock = directory / "aerospace"
            mock.write_text(MOCK)
            mock.chmod(0o755)
            windows = [
                {"id": index * 10, "ws": "S2", "layout": "h_tiles",
                 "app": f"example.app{index}"}
                for index in range(1, count + 1)
            ]
            # 別 WS の通常ウィンドウと同じ WS のフローティングは操作しない。
            windows += [
                {"id": 98, "ws": "M1", "layout": "h_tiles"},
                {"id": 99, "ws": "S2", "layout": "floating"},
            ]
            if floating:
                target = "99"
            tree = [window["id"] for window in reversed(windows[:count])]
            # 既存の入れ子も組み直せることを確認する。
            if count >= 3:
                tree = [tree[0], tree[1:]]
            state = {"windows": windows, "tree": tree, "commands": []}
            state_path = directory / "state.json"
            state_path.write_text(json.dumps(state))
            env = dict(os.environ, AEROSPACE_BIN=str(mock),
                       AEROSPACE_WINDOW_ID=target, GRID_TEST_STATE=str(state_path),
                       TMPDIR=str(directory))
            processes = [subprocess.Popen(["/bin/bash", str(SCRIPT)], env=env)
                         for _ in range(2 if concurrent else 1)]
            for process in processes:
                self.assertEqual(process.wait(timeout=15), 0)
            result = json.loads(state_path.read_text())
            self.assertEqual(result["windows"], windows)
            self.assertFalse(list(directory.glob("*.lock")))
            return result

    def test_mixed_apps_grid(self):
        for count, expected in [(2, [10, 20]), (3, [10, [20, 30]]),
                                (4, [[10, 20], [30, 40]])]:
            with self.subTest(count=count):
                result = self.run_grid(count)
                self.assertEqual(result["tree"], expected)
                self.assertEqual(result["commands"][-1][0], "balance-sizes")

    def test_out_of_scope(self):
        for options in [{"count": 1}, {"count": 5}, {"count": 4, "floating": True},
                        {"count": 4, "target": "999"}, {"count": 4, "target": ""}]:
            with self.subTest(options=options):
                self.assertEqual(self.run_grid(**options)["commands"], [])

    def test_concurrent_callbacks(self):
        result = self.run_grid(4, concurrent=True)
        self.assertEqual(result["tree"], [[10, 20], [30, 40]])


if __name__ == "__main__":
    unittest.main()
