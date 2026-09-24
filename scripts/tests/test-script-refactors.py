"""実設定を使わず、Python / Task / shell 関数の入口を検証する。"""

import importlib.util
import json
import os
import shutil
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[2]
SCRIPTS = Path(os.environ.get("REFACTOR_SCRIPTS_DIR", ROOT / "scripts"))


class ScriptFixture(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="scripts 日本語 ")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.auth = self.root / "auth"
        self.auth.mkdir()
        self.config = self.root / "config.toml"
        self.bin = self.root / "bin"
        self.bin.mkdir()
        brew = self.bin / "brew"
        brew.write_text(
            '#!/bin/sh\nprintf "%s\\n" "$*" >> "$BREW_LOG"\nexit "${BREW_RC:-0}"\n'
        )
        brew.chmod(0o755)
        self.env = dict(
            os.environ,
            CLIPROXY_AUTH_DIR=str(self.auth),
            CODEX_CONFIG_PATH=str(self.config),
            BREW_LOG=str(self.root / "brew.log"),
            PATH=f"{self.bin}:{os.environ['PATH']}",
        )

    def run_script(self, name, *args):
        return subprocess.run(
            [sys.executable, str(SCRIPTS / f"{name}.py"), *args],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )

    def credential(self, name, expired, kind="codex", **extra):
        path = self.auth / name
        path.write_text(json.dumps(dict(expired=expired, type=kind, **extra)))
        return path


class ScriptTests(ScriptFixture):
    def test_auth_dry_run_and_apply(self):
        old = self.credential("old.json", "2000-01-01T00:00:00+00:00")
        alive = self.credential("new.json", "2999-01-01T00:00:00+00:00")
        sole = self.credential("sole.json", "2000-01-01T00:00:00+00:00", "other")
        before = {p: p.read_bytes() for p in self.auth.iterdir()}
        result = self.run_script("cliproxy-auth-prune")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "  削除候補: old.json (2000-01-01 に失効、有効な codex が別にある)\n\n  実際に削除するには: task cliproxy-auth-prune -- --yes\n",
        )
        self.assertEqual(before, {p: p.read_bytes() for p in self.auth.iterdir()})
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(old.exists())
        self.assertTrue(alive.exists() and sole.exists())
        self.assertEqual(
            (self.root / "brew.log").read_text(), "services restart cliproxyapi\n"
        )

    def test_auth_special_filename(self):
        old = self.credential("old space\tline\n末尾.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(old.exists())

    def test_auth_naive_date_does_not_abort_other_candidates(self):
        naive = self.credential("naive.json", "2000-01-01T00:00:00")
        old = self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(naive.exists())
        self.assertFalse(old.exists())

    def test_auth_invalid_shapes_and_naive_dates_are_preserved(self):
        for i, value in enumerate(
            [
                [],
                None,
                {"expired": 123},
                {"expired": "2000-01-01"},
                {"expired": "2999-01-01T00:00:00Z", "type": []},
            ]
        ):
            (self.auth / f"invalid{i}.json").write_text(json.dumps(value))
        (self.auth / "bad.json").write_text('{"secret": "DO_NOT_LOG",')
        old = self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("DO_NOT_LOG", result.stdout + result.stderr)
        self.assertFalse(old.exists())
        self.assertEqual(len(list(self.auth.glob("invalid*.json"))), 5)

    def test_auth_restart_exit_code(self):
        self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        self.env["BREW_RC"] = "7"
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 7)
        self.assertNotIn("✅", result.stdout)

    def test_auth_legacy_unknown_argument_is_dry_run(self):
        old = self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        result = self.run_script("cliproxy-auth-prune", "--unknown")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(old.exists())

    def test_audit_toml_quoting_comments_and_escaped_paths(self):
        path = self.root / 'space "quote"\tline\nend'
        path.mkdir()
        self.config.write_text(
            f'[projects.{json.dumps(str(path))}] # コメント\ntrust_level = "trusted" # コメント\n'
            "[projects.'/missing-literal-key']\ntrust_level = 'untrusted'\n"
        )
        before = self.config.read_bytes()
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 0, result.stderr)
        for expected in [
            "total     : 2",
            "trusted   : 1",
            "untrusted : 1",
            "missing   : 1",
        ]:
            self.assertIn(expected, result.stdout)
        self.assertIn(str(path), result.stdout)
        self.assertEqual(self.config.read_bytes(), before)

    def test_audit_does_not_take_level_from_next_table(self):
        self.config.write_text(
            '[projects."/not-a-project-entry"]\n[unrelated]\ntrust_level = "trusted"\n'
        )
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("projects.*.trust_level は未設定です。", result.stdout)

    def test_audit_invalid_toml_fails_without_values(self):
        self.config.write_text('secret = "DO_NOT_LOG"\nbroken = [\n')
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 1)
        self.assertNotIn("DO_NOT_LOG", result.stdout + result.stderr)

    def test_audit_missing_and_empty_config(self):
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 1)
        self.config.write_text("# 空の設定\n")
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 0)
        self.assertTrue(
            result.stdout.endswith("projects.*.trust_level は未設定です。\n")
        )

    def test_audit_normal_output_and_shell_entry(self):
        self.config.write_text(
            '[projects."/missing-audit-fixture"]\ntrust_level = "trusted"\n'
        )
        result = self.run_script("codex-trust-audit")
        self.assertEqual(result.returncode, 0)
        expected = (
            f"=== Codex trust audit ===\nconfig: {self.config}\n\n"
            "status     level    path\n"
            "---------- -------- ------------------------------\n"
            "missing    trusted  /missing-audit-fixture\n\n"
            "summary:\n  total     : 1\n  trusted   : 1\n  untrusted : 0\n"
            "  missing   : 1\n  temp-like : 0\n\n"
            "hint:\n"
            "  - missing の削除候補は trust prune で確認し、trust prune --apply で設定から削除\n"
            "  - temp-like は用途を確認し、信頼が不要なら untrusted に変更\n"
            '  - 変更例: [projects."/path"] の trust_level = "untrusted"\n'
        )
        self.assertEqual(result.stdout, expected)
        if shutil.which("zsh"):
            result = subprocess.run(
                [
                    "zsh",
                    "-f",
                    "-c",
                    'source "$DOTFILES/shell/zsh/trust.zsh"; trust audit',
                ],
                env=dict(self.env, DOTFILES=str(ROOT)),
                capture_output=True,
                text=True,
                check=False,
            )
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, expected)

    @unittest.skipUnless(shutil.which("task"), "Task が必要")
    def test_task_entry_in_repository_path_with_spaces(self):
        repo = self.root / "repo with spaces"
        (repo / "scripts").mkdir(parents=True)
        (repo / "taskfiles").mkdir()
        for path in SCRIPTS.glob("cliproxy-auth-prune.*"):
            shutil.copy2(path, repo / "scripts" / path.name)
        shutil.copy2(ROOT / "taskfiles/cliproxy.yml", repo / "taskfiles/cliproxy.yml")
        (repo / "Taskfile.yml").write_text(
            'version: "3"\nincludes:\n  cliproxy:\n    taskfile: ./taskfiles/cliproxy.yml\n    flatten: true\n'
        )
        old = self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        result = subprocess.run(
            ["task", "--dir", str(repo), "cliproxy-auth-prune", "--", "--yes"],
            env=self.env,
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse(old.exists())

    def test_auth_missing_directory_and_no_candidates(self):
        self.auth.rmdir()
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0)
        self.assertIn("認証ディレクトリがありません", result.stdout)
        self.auth.mkdir()
        self.credential("sole.json", "2000-01-01T00:00:00Z")
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0)
        self.assertEqual(result.stdout, "  不要な失効ファイルはありません\n")
        self.assertFalse((self.root / "brew.log").exists())


@unittest.skipUnless(
    (SCRIPTS / "cliproxy-auth-prune.py").exists(), "移行後の異常系検証"
)
class AuthFailureTests(ScriptFixture):
    def setUp(self):
        super().setUp()
        spec = importlib.util.spec_from_file_location(
            "auth_prune", SCRIPTS / "cliproxy-auth-prune.py"
        )
        self.module = importlib.util.module_from_spec(spec)
        sys.modules[spec.name] = self.module
        spec.loader.exec_module(self.module)

    def test_concurrent_apply_is_rejected_and_lock_released(self):
        with self.module.apply_lock(self.auth):
            result = self.run_script("cliproxy-auth-prune", "--yes")
            self.assertEqual(result.returncode, 1)
            self.assertIn("別の認証整理が実行中", result.stderr)
        result = self.run_script("cliproxy-auth-prune", "--yes")
        self.assertEqual(result.returncode, 0)

    def test_changed_candidate_or_witness_is_not_deleted(self):
        for changed in ("old.json", "new.json"):
            with self.subTest(changed=changed):
                old = self.credential("old.json", "2000-01-01T00:00:00Z")
                self.credential("new.json", "2999-01-01T00:00:00Z")
                collect = self.module.collect

                def change_after_snapshot(directory, collect=collect, changed=changed):
                    entries = collect(directory)
                    (directory / changed).write_text("{}")
                    return entries

                with (
                    patch.object(
                        self.module, "collect", side_effect=change_after_snapshot
                    ),
                    patch.object(self.module.subprocess, "run") as brew,
                ):
                    with self.assertRaisesRegex(RuntimeError, "変更されました"):
                        self.module.prune(self.auth, True)
                    brew.assert_not_called()
                self.assertTrue(old.exists())

    def test_unlink_failure_does_not_restart_service(self):
        self.credential("old.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        with (
            patch.object(Path, "unlink", side_effect=PermissionError),
            patch.object(self.module.subprocess, "run") as brew,
        ):
            with self.assertRaises(PermissionError):
                self.module.prune(self.auth, True)
            brew.assert_not_called()

    def test_partial_failure_releases_lock_without_claiming_success(self):
        first = self.credential("a.json", "2000-01-01T00:00:00Z")
        second = self.credential("b.json", "2000-01-01T00:00:00Z")
        self.credential("new.json", "2999-01-01T00:00:00Z")
        unlink = Path.unlink

        def fail_second(path):
            if path == second:
                raise PermissionError
            unlink(path)

        with (
            patch.object(Path, "unlink", fail_second),
            patch.object(self.module.subprocess, "run") as brew,
        ):
            with self.assertRaises(PermissionError), self.module.apply_lock(self.auth):
                self.module.prune(self.auth, True)
            brew.assert_not_called()
        self.assertFalse(first.exists())
        self.assertTrue(second.exists())
        with self.module.apply_lock(self.auth):
            pass


if __name__ == "__main__":
    unittest.main()
