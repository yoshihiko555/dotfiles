"""会社用 pi の settings.json 管理と、起動時のアカウント分離を確認する。"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
PRESERVED = ("deviceId", "lastChangelogVersion")


class PiWorkTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name).resolve()
        self.work = self.home / ".pi/agent-work"
        self.personal = self.home / ".pi/agent"
        self.personal.mkdir(parents=True)
        (self.personal / "auth.json").write_text("個人用の認証を模した値")
        (self.personal / "settings.json").write_text('{"defaultModel": "個人用"}\n')
        self.env = dict(os.environ, HOME=str(self.home))
        self.env.pop("PI_CODING_AGENT_DIR", None)
        # 回収をテストしても、本物の dotfiles を変更しない。
        self.repo = self.home / "dotfiles"
        for directory in ("scripts", "pi", "pi-work"):
            (self.repo / directory).mkdir(parents=True)
        for script in ("apply-managed-settings.sh", "adopt-managed-settings.sh"):
            shutil.copyfile(ROOT / "scripts" / script, self.repo / "scripts" / script)
        shutil.copyfile(ROOT / "pi-work/settings.json", self.repo / "pi-work/settings.json")
        shutil.copyfile(ROOT / "pi/settings.json", self.repo / "pi/settings.json")

    def settings(self, action):
        return subprocess.run(
            ["bash", str(self.repo / f"scripts/{action}-managed-settings.sh"), "pi-work"],
            env=self.env, capture_output=True, text=True,
        )

    def test_settings_are_generated_and_runtime_keys_are_kept(self):
        result = self.settings("apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        target = self.work / "settings.json"
        self.assertEqual(json.loads(target.read_text()), json.loads((self.repo / "pi-work/settings.json").read_text()))
        self.assertFalse((self.work / "auth.json").exists())
        # pi が書き足す端末固有の値は drift 扱いせず、再反映でも消さない。
        data = json.loads(target.read_text())
        data.update({key: "端末固有の値" for key in PRESERVED})
        target.write_text(json.dumps(data))
        result = self.settings("apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("drift", result.stderr)
        for key in PRESERVED:
            self.assertEqual(json.loads(target.read_text())[key], "端末固有の値")
        self.assertEqual((self.personal / "settings.json").read_text(), '{"defaultModel": "個人用"}\n')

    def test_drift_is_kept_until_adopted_into_work_settings(self):
        self.assertEqual(self.settings("apply").returncode, 0)
        target = self.work / "settings.json"
        data = json.loads(target.read_text())
        data.update(defaultModel="会社用で選んだモデル", deviceId="端末固有の値")
        target.write_text(json.dumps(data))
        result = self.settings("apply")
        self.assertIn("drift", result.stderr)
        self.assertEqual(json.loads(target.read_text())["defaultModel"], "会社用で選んだモデル")
        personal_source = (self.repo / "pi/settings.json").read_text()
        result = self.settings("adopt")
        self.assertEqual(result.returncode, 0, result.stderr)
        adopted = json.loads((self.repo / "pi-work/settings.json").read_text())
        self.assertEqual(adopted["defaultModel"], "会社用で選んだモデル")
        self.assertNotIn("deviceId", adopted)
        self.assertEqual((self.repo / "pi/settings.json").read_text(), personal_source)
        result = self.settings("apply")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("drift", result.stderr)

    def prepare_work_dir(self):
        (self.work / "pi-harness").mkdir(parents=True)
        (self.work / "settings.json").write_text("{}")
        (self.work / "pi-harness/gate.json").write_text("{}")

    def launch(self, command='piw -p "空白 あり"'):
        return subprocess.run(
            ["zsh", "-f", "-c", 'source "$1"; ' + command, "test", str(ROOT / "shell/zsh/pi.zsh")],
            env=self.env, capture_output=True, text=True,
        )

    def install_stub(self):
        binary = self.home / "bin"
        binary.mkdir()
        stub = binary / "pi"
        stub.write_text(
            f"#!{sys.executable}\nimport os, sys, json\n"
            'print(json.dumps({"args": sys.argv[1:], "env": dict(os.environ)}))\n'
            "sys.exit(37)\n"
        )
        stub.chmod(0o755)
        self.env["PATH"] = f"{binary}:{os.environ['PATH']}"

    def test_launch_isolates_environment(self):
        self.prepare_work_dir()
        self.install_stub()
        excluded = (
            "OPENAI_API_KEY", "ANTHROPIC_API_KEY", "ANTHROPIC_AUTH_TOKEN", "ANTHROPIC_OAUTH_TOKEN",
            "OPENCODE_API_KEY", "TYPESAFE_API_KEY", "PI_CODING_AGENT_SESSION_DIR",
        )
        self.env.update({key: "個人用を模した値" for key in excluded})
        self.env["PI_CODING_AGENT_DIR"] = str(self.personal)
        result = self.launch()
        self.assertEqual(result.returncode, 37, result.stderr)
        invocation = json.loads(result.stdout)
        self.assertEqual(invocation["env"]["PI_CODING_AGENT_DIR"], str(self.work))
        self.assertTrue(set(excluded).isdisjoint(invocation["env"]))
        self.assertEqual(invocation["args"], ["-p", "空白 あり"])
        # サブシェルで動くので、呼び出し元のシェルの値は変わらない。
        result = self.launch('piw >/dev/null; print -r -- "$PI_CODING_AGENT_DIR|$OPENAI_API_KEY"')
        self.assertEqual(result.stdout.strip(), f"{self.personal}|個人用を模した値")

    def test_launch_requires_settings_and_gate(self):
        self.install_stub()
        result = self.launch()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")
        self.prepare_work_dir()
        (self.work / "pi-harness/gate.json").unlink()
        result = self.launch()
        self.assertEqual(result.returncode, 1)
        self.assertEqual(result.stdout, "")


if __name__ == "__main__":
    unittest.main()
