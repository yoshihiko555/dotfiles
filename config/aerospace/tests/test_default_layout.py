"""実アプリを動かさず、default.sh が aerospace.toml のルールどおりに移動するかを検証する。"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
SCRIPT = ROOT / "layouts" / "default.sh"
CONFIG = ROOT / "aerospace.toml"
MOCK = r'''#!/usr/bin/env python3
import json
import os
from pathlib import Path
import sys

path = Path(os.environ["LAYOUT_TEST_STATE"])
state = json.loads(path.read_text())
args = sys.argv[1:]
if args[0] == "list-windows":
    for window in state["windows"]:
        print(f'{window["id"]}|{window["app"]}|{window["ws"]}')
    sys.exit(0)
state["commands"].append(args)
path.write_text(json.dumps(state))
'''


class DefaultLayoutTest(unittest.TestCase):
    def run_layout(self, windows, config=CONFIG):
        with tempfile.TemporaryDirectory() as directory:
            directory = Path(directory)
            mock = directory / "aerospace"
            mock.write_text(MOCK)
            mock.chmod(0o755)
            state_path = directory / "state.json"
            state_path.write_text(json.dumps({"windows": windows, "commands": []}))
            env = dict(os.environ, AEROSPACE_BIN=str(mock), AEROSPACE_CONFIG=str(config),
                       LAYOUT_TEST_STATE=str(state_path))
            subprocess.run(["/bin/bash", str(SCRIPT)], env=env, check=True, timeout=15)
            return json.loads(state_path.read_text())["commands"]

    def test_real_config(self):
        windows = [
            {"id": 1, "app": "com.google.Chrome", "ws": "S2"},
            {"id": 2, "app": "com.apple.finder", "ws": "S2"},
            {"id": 3, "app": "dev.kdrag0n.MacVirt", "ws": "B2"},
            {"id": 4, "app": "com.apple.systempreferences", "ws": "M1"},
            # 既に正しい WS にいるウィンドウは動かさない。
            {"id": 5, "app": "com.mitchellh.ghostty", "ws": "M3"},
            # ルールの無いアプリ・floating 化だけのルールは対象外。
            {"id": 6, "app": "com.anthropic.claudefordesktop", "ws": "S2"},
            {"id": 7, "app": "com.electron.aqua-voice", "ws": "S2"},
            # 前方一致する別アプリを巻き込まない（旧実装の grep -F 対策）。
            {"id": 8, "app": "com.apple.mail.extra", "ws": "S2"},
        ]
        self.assertEqual(self.run_layout(windows), [
            ["move-node-to-workspace", "--window-id", "1", "M1"],
            ["move-node-to-workspace", "--window-id", "2", "S3"],
            ["move-node-to-workspace", "--window-id", "3", "B3"],
            ["move-node-to-workspace", "--window-id", "4", "S4"],
            ["workspace", "M1"],
        ])

    def test_rule_selection(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / "aerospace.toml"
            config.write_text("""
[[on-window-detected]]
if.app-id = 'example.first'
run = ['move-node-to-workspace S1']

[[on-window-detected]]
if.app-id = 'example.first'
run = ['move-node-to-workspace S2']

[[on-window-detected]]
if.app-id = 'example.titled'
if.window-title-regex-substring = 'foo'
run = ['move-node-to-workspace S3']

[workspace-to-monitor-force-assignment]
S1 = 3
""")
            windows = [
                {"id": 1, "app": "example.first", "ws": "M1"},
                {"id": 2, "app": "example.titled", "ws": "M1"},
            ]
            # 先に書いたルールを採用し、app-id 以外の条件を持つルールは適用しない。
            self.assertEqual(self.run_layout(windows, config), [
                ["move-node-to-workspace", "--window-id", "1", "S1"],
                ["workspace", "M1"],
            ])


if __name__ == "__main__":
    unittest.main()
