"""MCP 同期の公開入口・保存範囲・失敗時の状態を一時設定で検証する。"""

import contextlib
import importlib.util
import io
import json
import os
import shutil
import stat
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

import tomllib

ROOT = Path(__file__).resolve().parents[2]
SCRIPT = ROOT / "scripts/mcp-manage.py"
SPEC = importlib.util.spec_from_file_location("mcp_manage", SCRIPT)
MCP = importlib.util.module_from_spec(SPEC)
sys.modules[SPEC.name] = MCP
SPEC.loader.exec_module(MCP)


class McpTests(unittest.TestCase):
    def setUp(self):
        temp = tempfile.TemporaryDirectory(prefix="mcp 日本語 ")
        self.addCleanup(temp.cleanup)
        self.root = Path(temp.name)
        self.defs = self.root / "defs"
        (self.defs / "servers").mkdir(parents=True)
        self.clients = {"claude": {"sample": {}}, "codex": {"sample": {}}}
        self.write_json(self.defs / "clients.json", self.clients)
        self.write_json(
            self.defs / "servers/sample.json",
            {"type": "http", "url": "https://new.example/mcp"},
        )
        self.claude = self.root / "claude.json"
        self.codex = self.root / "config.toml"
        self.claude.write_text(
            '{"history":{"keep":1},"mcpServers":{"other":{"command":"keep"}}}\n'
        )
        self.codex.write_text(
            '# コメント\nmodel = "keep"\n[mcp_servers.other]\ncommand = "keep"\n'
        )
        self.backups = self.root / "backups"
        self.paths = {
            "--definitions": self.defs,
            "--claude-config": self.claude,
            "--codex-config": self.codex,
            "--backup-dir": self.backups,
        }

    def write_json(self, path, data):
        path.write_text(json.dumps(data, ensure_ascii=False), encoding="utf-8")

    def run_cli(self, *args):
        options = [
            item for key, value in self.paths.items() for item in (key, str(value))
        ]
        return subprocess.run(
            [sys.executable, str(SCRIPT), *args, *options],
            capture_output=True,
            text=True,
            check=False,
        )

    def before(self):
        return self.claude.read_bytes(), self.codex.read_bytes()

    def execute(self):
        # CLI と同じ umask。実際のホームや環境変数を変更しない。
        mask = os.umask(0o077)
        try:
            with contextlib.redirect_stdout(io.StringIO()):
                MCP.execute("sync", "", self.paths)
        finally:
            os.umask(mask)

    def test_list_diff_output_and_no_writes(self):
        before = self.before()
        expected = (
            "claude\tsample\t追加候補\n対象外 claude: other\n"
            "codex\tsample\t追加候補\n対象外 codex: other\n"
            "読み取り専用です。プラグイン・対象外の MCP・認証・接続状態は検査しません。\n"
        )
        for action in ("list", "diff"):
            result = self.run_cli(action)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(result.stdout, expected)
            self.assertEqual(self.before(), before)
            self.assertFalse(self.backups.exists())

    def test_sync_backup_modes_and_idempotence(self):
        before = self.before()
        self.codex.chmod(0o640)
        link = self.root / "link.toml"
        link.symlink_to(self.codex)
        self.paths["--codex-config"] = link
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(link.is_symlink())
        self.assertEqual(stat.S_IMODE(self.codex.stat().st_mode), 0o640)
        backups = list(self.backups.iterdir())
        self.assertEqual(len(backups), 1)
        backup = backups[0]
        self.assertEqual(stat.S_IMODE(backup.stat().st_mode), 0o700)
        for i, client in enumerate(("claude", "codex")):
            self.assertEqual((backup / f"{client}.before").read_bytes(), before[i])
            self.assertEqual((backup / f"{client}.state").read_text(), "present\n")
        for path in backup.iterdir():
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)
        self.assertEqual(
            (backup / "codex.path").read_text(), str(self.codex.resolve()) + "\n"
        )
        after = self.before()
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            result.stdout,
            "対象外 claude: other\n対象外 codex: other\n差分なし。変更しませんでした。\n",
        )
        self.assertEqual(self.before(), after)
        self.assertEqual(list(self.backups.iterdir()), backups)

    def test_stdio_merge_overrides_and_secret_preservation(self):
        self.write_json(
            self.defs / "servers/sample.json",
            {
                "type": "stdio",
                "command": "tool",
                "args": ["shared"],
                "env": {"NEW": "value"},
            },
        )
        self.clients["codex"]["sample"] = {"args": ["codex"]}
        self.write_json(self.defs / "clients.json", self.clients)
        self.write_json(
            self.claude,
            {
                "mcpServers": {
                    "sample": {
                        "command": "old",
                        "env": {"SECRET": "DO_NOT_LOG"},
                        "timeout": 9,
                    }
                }
            },
        )
        self.codex.write_text(
            '[mcp_servers.sample]\ncommand = "old"\nenabled = false\ntool_timeout_sec = 99\n[mcp_servers.sample.env]\nSECRET = "DO_NOT_LOG"\n'
        )
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertNotIn("DO_NOT_LOG", result.stdout + result.stderr)
        claude = json.loads(self.claude.read_text())["mcpServers"]["sample"]
        codex = tomllib.loads(self.codex.read_text())["mcp_servers"]["sample"]
        for server in (claude, codex):
            self.assertEqual(server["command"], "tool")
            self.assertEqual(server["env"], {"SECRET": "DO_NOT_LOG", "NEW": "value"})
        self.assertEqual(claude["args"], ["shared"])
        self.assertEqual(codex["args"], ["codex"])
        self.assertEqual(claude["timeout"], 9)
        self.assertEqual(codex["tool_timeout_sec"], 99)
        self.assertIs(codex["enabled"], True)

    def test_unchanged_defaults_keep_original_bytes(self):
        self.write_json(
            self.defs / "servers/sample.json", {"type": "stdio", "command": "tool"}
        )
        self.claude.write_text('{"mcpServers": {"sample": {"command":"tool"}}}')
        self.codex.write_text('# 保持\n[mcp_servers.sample]\ncommand="tool" # 保持\n')
        before = self.before()
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(self.before(), before)
        self.assertIn("差分なし", result.stdout)

    def test_unsupported_toml_is_refused_before_either_write(self):
        for text in (
            '[mcp_servers."sample"]\nurl="https://old.example"\n',
            'mcp_servers = {sample = {url="https://old.example"}}\n',
            'mcp_servers.sample.url="https://old.example"\n',
            'note = """\n[mcp_servers.sample]\nnot a table\n"""\n',
        ):
            with self.subTest(text=text):
                self.codex.write_text(text)
                before = self.before()
                result = self.run_cli("sync")
                self.assertEqual(result.returncode, 1)
                self.assertEqual(self.before(), before)
                self.assertFalse((self.backups / ".sync-lock").exists())

    def test_invalid_inputs_and_transport_change_are_redacted(self):
        for path, text in (
            (self.defs / "clients.json", '{"secret":"DO_NOT_LOG", broken}'),
            (
                self.defs / "servers/sample.json",
                '{"type":"stdio","command":"DO_NOT_LOG","args":[1]}',
            ),
            (self.claude, '{"secret":"DO_NOT_LOG", broken}'),
            (self.claude, '{"mcpServers":{"sample":{"command":"DO_NOT_LOG"}}}'),
            (self.codex, 'secret="DO_NOT_LOG"\nbroken=['),
        ):
            with self.subTest(path=path):
                original = path.read_bytes()
                path.write_text(text)
                before = self.before()
                result = self.run_cli("sync")
                self.assertEqual(result.returncode, 1)
                self.assertNotIn("DO_NOT_LOG", result.stdout + result.stderr)
                self.assertEqual(self.before(), before)
                path.write_bytes(original)

    def test_invalid_arguments(self):
        for args in (
            (),
            ("unknown",),
            ("sync", "unknown"),
            ("sync", "a", "b"),
            ("sync", "--unknown"),
        ):
            with self.subTest(args=args):
                result = self.run_cli(*args)
                self.assertEqual(result.returncode, 1)

    def test_new_configs_in_directory_ending_with_newline(self):
        directory = self.root / "設定\t末尾\n"
        directory.mkdir()
        self.paths["--claude-config"] = directory / "new.json"
        self.paths["--codex-config"] = directory / "new.toml"
        result = self.run_cli("sync", "sample")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(
            json.loads((directory / "new.json").read_text())["mcpServers"]["sample"][
                "url"
            ],
            "https://new.example/mcp",
        )
        self.assertEqual(
            tomllib.loads((directory / "new.toml").read_text())["mcp_servers"][
                "sample"
            ]["url"],
            "https://new.example/mcp",
        )
        for path in directory.iterdir():
            self.assertEqual(stat.S_IMODE(path.stat().st_mode), 0o600)

    def test_lock_rejects_concurrent_sync(self):
        before = self.before()
        with MCP.sync_lock(self.backups):
            result = self.run_cli("sync")
            self.assertEqual(result.returncode, 1)
            self.assertIn("別の同期", result.stderr)
            self.assertEqual(self.before(), before)

    def test_changed_file_or_symlink_is_not_overwritten(self):
        for kind in ("content", "link"):
            with self.subTest(kind=kind):
                link = self.root / "claude-link.json"
                link.unlink(missing_ok=True)
                link.symlink_to(self.claude)
                self.paths["--claude-config"] = link
                other = self.root / "other.json"
                other.write_text('{"external":true}')
                before_codex = self.codex.read_bytes()
                original_stage = MCP.stage

                def change_after_stage(
                    snapshot,
                    content,
                    kind=kind,
                    original_stage=original_stage,
                    link=link,
                    other=other,
                ):
                    result = original_stage(snapshot, content)
                    if snapshot.client == "codex":
                        if kind == "content":
                            self.claude.write_text('{"external":true}')
                        else:
                            link.unlink()
                            link.symlink_to(other)
                    return result

                with (
                    patch.object(MCP, "stage", side_effect=change_after_stage),
                    self.assertRaises(MCP.ConfigError),
                ):
                    self.execute()
                self.assertEqual(self.codex.read_bytes(), before_codex)
                self.assertEqual(link.read_text(), '{"external":true}')
                self.assertFalse(list(self.root.glob(".mcp-sync.*")))

    def test_stage_failure_leaves_both_configs_unchanged(self):
        before = self.before()
        stage = MCP.stage

        def fail_second(snapshot, content):
            if snapshot.client == "codex":
                raise PermissionError("DO_NOT_LOG")
            return stage(snapshot, content)

        with (
            patch.object(MCP, "stage", side_effect=fail_second),
            self.assertRaises(MCP.ConfigError) as raised,
        ):
            self.execute()
        self.assertNotIn("DO_NOT_LOG", str(raised.exception))
        self.assertEqual(self.before(), before)
        self.assertFalse(list(self.root.glob(".mcp-sync.*")))

    def test_second_replace_failure_has_both_backups(self):
        before = self.before()
        replace = os.replace

        def fail_second(source, target):
            if target == self.codex.resolve():
                raise PermissionError("DO_NOT_LOG")
            replace(source, target)

        with (
            patch.object(MCP.os, "replace", side_effect=fail_second),
            self.assertRaises(MCP.ConfigError) as raised,
        ):
            self.execute()
        self.assertNotIn("DO_NOT_LOG", str(raised.exception))
        self.assertNotEqual(self.claude.read_bytes(), before[0])
        self.assertEqual(self.codex.read_bytes(), before[1])
        (backup,) = self.backups.iterdir()
        self.assertEqual((backup / "claude.before").read_bytes(), before[0])
        self.assertEqual((backup / "codex.before").read_bytes(), before[1])
        self.assertFalse(list(self.root.glob(".mcp-sync.*")))

    @unittest.skipUnless(shutil.which("task"), "Task が必要")
    def test_task_entry(self):
        options = [
            item for key, value in self.paths.items() for item in (key, str(value))
        ]
        result = subprocess.run(
            ["task", "--dir", str(ROOT), "mcp-diff", "--", *options],
            capture_output=True,
            text=True,
            check=False,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("追加候補", result.stdout)

    def test_invalid_empty_container_types_are_not_defaulted(self):
        for field, value in (("args", {}), ("args", ""), ("env", []), ("env", "")):
            with self.subTest(field=field, value=value):
                self.write_json(
                    self.defs / "servers/sample.json",
                    {"type": "stdio", "command": "tool", field: value},
                )
                before = self.before()
                result = self.run_cli("sync")
                self.assertEqual(result.returncode, 1)
                self.assertEqual(self.before(), before)

    def test_toml_serialization_roundtrips_special_strings(self):
        value = '日本語 "quote" \\path\tline\nnext\b\f'
        self.write_json(
            self.defs / "servers/sample.json",
            {
                "type": "stdio",
                "command": "tool",
                "args": [value],
                "env": {"KEY": value},
            },
        )
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        actual = tomllib.loads(self.codex.read_text())["mcp_servers"]["sample"]
        self.assertEqual(actual["args"], [value])
        self.assertEqual(actual["env"], {"KEY": value})
        self.assertNotIn(value, result.stdout + result.stderr)

    def test_backup_failure_happens_before_either_write(self):
        before = self.before()
        write_bytes = Path.write_bytes

        def fail_backup(path, content):
            if path.name == "codex.before":
                raise PermissionError("DO_NOT_LOG")
            return write_bytes(path, content)

        with (
            patch.object(Path, "write_bytes", fail_backup),
            self.assertRaises(MCP.ConfigError) as raised,
        ):
            self.execute()
        self.assertNotIn("DO_NOT_LOG", str(raised.exception))
        self.assertEqual(self.before(), before)
        self.assertFalse(list(self.root.glob(".mcp-sync.*")))

    def test_unchanged_managed_table_keeps_comments_when_other_table_changes(self):
        self.write_json(
            self.defs / "servers/unchanged.json", {"type": "stdio", "command": "tool"}
        )
        self.clients["codex"]["unchanged"] = {}
        self.write_json(self.defs / "clients.json", self.clients)
        unchanged = '[mcp_servers.unchanged]\ncommand="tool" # 保持するコメント\n'
        self.codex.write_text(unchanged)
        result = self.run_cli("sync")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertTrue(self.codex.read_text().startswith(unchanged))
        self.assertEqual(
            tomllib.loads(self.codex.read_text())["mcp_servers"]["unchanged"],
            {"command": "tool"},
        )


if __name__ == "__main__":
    unittest.main()
