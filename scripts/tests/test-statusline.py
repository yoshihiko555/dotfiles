#!/usr/bin/env python3
"""claude/statusline.py のアカウント表示と経過時間を、標準入力と環境変数だけで確認する。"""

import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "claude/statusline.py"

PERSONAL = "\033[48;2;152;195;121m"
WORK = "\033[48;2;229;140;60m"
PROXY = "\033[48;2;92;99;112m"
UNKNOWN = "\033[48;2;224;108;117m"
BADGES = [PERSONAL, WORK, PROXY, UNKNOWN]


class StatuslineTests(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.config_dir = Path(self.work.name)

    def render(self, data=None, org_type=None, proxy=False):
        if org_type is not None:
            account = {"oauthAccount": {"organizationType": org_type}}
            (self.config_dir / ".claude.json").write_text(json.dumps(account))
        env = {k: v for k, v in os.environ.items() if k not in ("ANTHROPIC_BASE_URL", "CLAUDE_CONFIG_DIR")}
        env["CLAUDE_CONFIG_DIR"] = str(self.config_dir)
        if proxy:
            env["ANTHROPIC_BASE_URL"] = "http://127.0.0.1:8317"
        result = subprocess.run(
            ["python3", str(SCRIPT)],
            input=json.dumps(data or {"model": {"display_name": "Opus"}}),
            capture_output=True, text=True, env=env, check=True,
        )
        return result.stdout.split("\n")

    def badges(self, line):
        return [b for b in BADGES if b in line]

    def test_account_badge(self):
        cases = {
            "claude_max": [PERSONAL],
            "claude_pro": [PERSONAL],
            "claude_team": [WORK],
            "claude_enterprise": [WORK],
            "something_new": [UNKNOWN],
        }
        for org_type, expected in cases.items():
            with self.subTest(org_type=org_type):
                self.assertEqual(self.badges(self.render(org_type=org_type)[0]), expected)

    def test_unreadable_account_is_not_personal(self):
        self.assertEqual(self.badges(self.render()[0]), [UNKNOWN])

    def test_proxy_adds_badge(self):
        line = self.render(org_type="claude_max", proxy=True)[0]
        self.assertEqual(self.badges(line), [PERSONAL, PROXY])
        self.assertLess(line.index(PERSONAL), line.index(PROXY))

    def test_elapsed_time(self):
        cases = {30_000: None, 60_000: "1m", 1_380_000: "23m", 4_980_000: "1h23m", 90_000_000: "1d1h"}
        for ms, expected in cases.items():
            with self.subTest(ms=ms):
                data = {"model": {"display_name": "Opus"}, "cost": {"total_duration_ms": ms}}
                last = self.render(data, org_type="claude_max")[2]
                if expected is None:
                    self.assertNotIn("⏱", last)
                else:
                    self.assertIn("⏱", last)
                    self.assertIn(f"{expected}\033[0m", last)


if __name__ == "__main__":
    unittest.main()
