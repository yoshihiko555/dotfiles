"""会社用 Codex の初期化と起動時のアカウント分離を確認する。"""

import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]


class CodexWorkTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.home = Path(self.tmp.name).resolve()
        self.work = self.home / "work codex"
        self.personal = self.home / ".codex"
        self.personal.mkdir()
        (self.personal / "auth.json").write_text("個人用の認証を模した値")
        (self.personal / "config.toml").write_text("# 個人用設定\n")
        self.env = dict(os.environ, HOME=str(self.home), CODEX_WORK_HOME=str(self.work))
        # リンク先への書き戻しをテストしても、本物の dotfiles を変更しない。
        self.repo = self.home / "dotfiles"
        for directory in ("scripts", "codex", "codex-work"):
            (self.repo / directory).mkdir(parents=True)
        shutil.copyfile(ROOT / "scripts/codex-work-init.py", self.repo / "scripts/codex-work-init.py")
        shutil.copyfile(ROOT / "codex-work/config.toml", self.repo / "codex-work/config.toml")
        (self.repo / "codex/AGENTS.md").write_text("共通ルール")
        for name in ("common", "codex-only", "work"):
            (self.repo / "shared/skills" / name / f"sample-{name}").mkdir(parents=True)

    def initialize(self):
        return subprocess.run(
            [sys.executable, str(self.repo / "scripts/codex-work-init.py")],
            env=self.env, capture_output=True, text=True,
        )

    def test_initialization_and_repeat_preserve_separate_state(self):
        self.assertEqual(self.initialize().returncode, 0)
        self.assertEqual(self.work.stat().st_mode & 0o777, 0o700)
        self.assertTrue((self.work / "config.toml").is_symlink())
        self.assertEqual((self.work / "config.toml").resolve(), self.repo / "codex-work/config.toml")
        self.assertFalse((self.work / "auth.json").exists())
        self.assertEqual((self.work / "AGENTS.md").resolve(), self.repo / "codex/AGENTS.md")
        (self.work / "config.toml").write_text("# 会社用の独自設定\n")
        self.assertEqual((self.repo / "codex-work/config.toml").read_text(), "# 会社用の独自設定\n")
        (self.work / "auth.json").write_text("会社用の認証を模した値")
        (self.work / "skills/local-skill").mkdir()
        (self.work / "skills/removed").symlink_to(self.repo / "shared/skills/common/removed")
        self.assertEqual(self.initialize().returncode, 0)
        self.assertEqual((self.work / "config.toml").read_text(), "# 会社用の独自設定\n")
        self.assertEqual((self.work / "auth.json").read_text(), "会社用の認証を模した値")
        self.assertEqual((self.personal / "auth.json").read_text(), "個人用の認証を模した値")
        self.assertTrue((self.work / "skills/local-skill").is_dir())
        self.assertFalse((self.work / "skills/removed").is_symlink())

    def test_rejects_personal_home_and_symlink_alias(self):
        alias = self.home / "personal-alias"
        alias.symlink_to(self.personal)
        for target in (self.personal, alias, self.personal / "work", self.repo / "codex-work"):
            with self.subTest(target=target):
                self.env["CODEX_WORK_HOME"] = str(target)
                self.assertNotEqual(self.initialize().returncode, 0)
        self.assertEqual((self.personal / "config.toml").read_text(), "# 個人用設定\n")

    def test_existing_local_guidance_is_not_overwritten(self):
        self.work.mkdir()
        (self.work / "AGENTS.md").write_text("既存の会社用ルール")
        self.assertNotEqual(self.initialize().returncode, 0)
        self.assertEqual((self.work / "AGENTS.md").read_text(), "既存の会社用ルール")
        self.assertFalse((self.work / "config.toml").exists())

    def test_rejects_shared_config_or_skills(self):
        self.work.mkdir()
        for name in ("skills", "config.toml"):
            with self.subTest(name=name):
                link = self.work / name
                link.symlink_to(self.personal / name)
                self.assertNotEqual(self.initialize().returncode, 0)
                link.unlink()

    def test_migrates_identical_copy_to_symlink(self):
        self.work.mkdir()
        shutil.copyfile(self.repo / "codex-work/config.toml", self.work / "config.toml")
        self.assertEqual(self.initialize().returncode, 0)
        self.assertTrue((self.work / "config.toml").is_symlink())

    def test_preserves_uncollected_config_changes(self):
        self.work.mkdir()
        config = self.work / "config.toml"
        config.write_text("# 未回収の設定\n")
        original = (self.repo / "codex-work/config.toml").read_bytes()
        self.assertNotEqual(self.initialize().returncode, 0)
        self.assertFalse(config.is_symlink())
        self.assertEqual(config.read_text(), "# 未回収の設定\n")
        self.assertEqual((self.repo / "codex-work/config.toml").read_bytes(), original)

    def launch(self, command='cxw exec "空白 あり"'):
        return subprocess.run(
            ["zsh", "-f", "-c", 'source "$1"; source "$2"; ' + command, "test",
             str(ROOT / "shell/zsh/aliases.zsh"), str(ROOT / "shell/zsh/codex.zsh")],
            env=self.env, capture_output=True, text=True,
        )

    def test_launch_isolates_environment_and_preserves_existing_wrapper(self):
        self.assertEqual(self.initialize().returncode, 0)
        binary = self.home / "bin"
        binary.mkdir()
        stub = binary / "codex"
        stub.write_text(
            f"#!{sys.executable}\nimport os, sys, json\n"
            'print(json.dumps({"args": sys.argv[1:], "env": dict(os.environ)}))\n'
            "sys.exit(37)\n"
        )
        stub.chmod(0o755)
        excluded = (
            "CODEX_API_KEY", "CODEX_ACCESS_TOKEN", "OPENAI_API_KEY", "CODEX_SQLITE_HOME",
            "OPENAI_FEDERATION_RULE_ID", "OPENAI_IDENTITY_TOKEN_FILE", "OPENAI_WORKLOAD_IDENTITY_CONTEXT",
        )
        self.env.update({key: "個人用を模した値" for key in excluded})
        self.env.update(PATH=f"{binary}:{os.environ['PATH']}", CODEX_HOME=str(self.personal), HERDR_ENV="1")
        result = self.launch()
        self.assertEqual(result.returncode, 37, result.stderr)
        invocation = json.loads(result.stdout)
        self.assertEqual(invocation["env"]["CODEX_HOME"], str(self.work.resolve()))
        self.assertTrue(set(excluded).isdisjoint(invocation["env"]))
        self.assertEqual(invocation["args"][-2:], ["exec", "空白 あり"])
        self.assertIn("--no-daemon", invocation["args"])
        result = self.launch('cxw --version >/dev/null; print -r -- "$CODEX_HOME|$CODEX_API_KEY"')
        self.assertEqual(result.stdout.strip(), f"{self.personal}|個人用を模した値")

    def test_launch_requires_initialization_and_rejects_personal_home(self):
        self.assertNotEqual(self.launch().returncode, 0)
        self.env["CODEX_WORK_HOME"] = str(self.personal)
        self.assertNotEqual(self.launch().returncode, 0)


if __name__ == "__main__":
    unittest.main()
