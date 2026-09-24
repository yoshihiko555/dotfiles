#!/usr/bin/env python3
"""一時ディレクトリと CLI の代替実装で同期の境界を確認する。"""

import argparse
import contextlib
import importlib.util
import io
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from types import SimpleNamespace


ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location("plugin_manage", ROOT / "scripts/plugin-manage.py")
MODULE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(MODULE)


def write(path, data):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(json.dumps(data) + "\n")


class PluginTests(unittest.TestCase):
    def setUp(self):
        self.work = tempfile.TemporaryDirectory()
        self.addCleanup(self.work.cleanup)
        self.root = Path(self.work.name)
        self.args = argparse.Namespace(
            action="sync", name=None, client=None,
            claude_home=self.root / "claude", codex_home=self.root / "codex",
            claude_source=self.root / "source.json", backup_dir=self.root / "backups",
        )
        self.manager = MODULE.Manager(self.args)
        self.entries = {"docs": {"description": "確認用", "clients": {
            client: {"id": "docs@market", "mode": "sync", "marketplace": "owner/repo"}
            for client in ["claude", "codex"]
        }}}
        write(self.args.claude_source, {"model": "keep", "enabledPlugins": {"other@market": False}})
        self.calls = []

    def fake_cli(self, command):
        self.calls.append(command)
        client = command[0]
        home = self.manager.homes[client]
        if command[2] == "marketplace":
            if client == "claude":
                write(home / "plugins/known_marketplaces.json", {"market": {"source": {"source": "github", "repo": "owner/repo"}}})
            else:
                home.mkdir(parents=True, exist_ok=True)
                (home / "config.toml").write_text('[marketplaces.market]\nsource_type = "git"\nsource = "https://github.com/owner/repo.git"\n')
        elif client == "claude":
            if command[2] == "install":
                cache = home / "plugins/cache/market/docs/1"
                cache.mkdir(parents=True, exist_ok=True)
                write(home / "plugins/installed_plugins.json", {"plugins": {"docs@market": [{"scope": "user", "installPath": str(cache)}]}})
            write(home / "settings.json", {"enabledPlugins": {"docs@market": True}})
        else:
            with (home / "config.toml").open("a") as stream:
                stream.write('[plugins."docs@market"]\nenabled = true\n')
            write(home / "plugins/cache/market/docs/1/.codex-plugin/plugin.json", {"name": "docs"})

    def sync(self):
        with patch.object(self.manager, "run", side_effect=self.fake_cli), patch.object(MODULE.shutil, "which", return_value="/fake/cli"), contextlib.redirect_stdout(io.StringIO()):
            self.manager.sync(self.entries)

    def test_plan_is_read_only_and_does_not_execute_cli(self):
        before = self.args.claude_source.read_bytes()
        with patch.object(MODULE.subprocess, "run", side_effect=AssertionError("CLI を呼ばない")):
            rows = self.manager.plan(self.entries)
        self.assertTrue(all(row["status"] == "導入候補" for row in rows))
        self.assertEqual(before, self.args.claude_source.read_bytes())
        self.assertFalse(self.args.backup_dir.exists())

    def test_sync_preserves_unmanaged_source_and_is_idempotent(self):
        target = self.root / "actual.json"
        self.args.claude_source.rename(target)
        self.args.claude_source.symlink_to(target)
        self.sync()
        self.assertTrue(self.args.claude_source.is_symlink())
        data = json.loads(target.read_text())
        self.assertEqual(data["model"], "keep")
        self.assertIs(data["enabledPlugins"]["other@market"], False)
        self.assertIs(data["enabledPlugins"]["docs@market"], True)
        self.assertTrue(list(self.args.backup_dir.glob("sync-*/index.json")))
        self.assertIn(["claude", "plugin", "install", "docs@market", "--scope", "user"], self.calls)
        self.assertIn(["codex", "plugin", "add", "docs@market"], self.calls)
        count = len(self.calls)
        self.sync()
        self.assertEqual(len(self.calls), count)
        self.assertTrue(all(row["status"] == "一致" for row in self.manager.plan(self.entries)))

    def test_candidate_and_remote_are_never_installed(self):
        self.entries["docs"]["clients"]["claude"]["mode"] = "candidate"
        self.entries["docs"]["clients"]["codex"]["mode"] = "remote"
        self.sync()
        self.assertEqual(self.calls, [])
        self.assertEqual(self.manager.plan(self.entries)[1]["status"], "アプリ管理（状態未検証）")

    def test_client_and_name_filters(self):
        self.args.client = "codex"
        self.args.name = "docs"
        self.sync()
        self.assertTrue(all(command[0] == "codex" for command in self.calls))
        self.assertNotIn("docs@market", json.loads(self.args.claude_source.read_text())["enabledPlugins"])

    def test_marketplace_conflict_prevents_all_changes(self):
        write(self.args.claude_home / "plugins/known_marketplaces.json", {"market": {"source": {"source": "github", "repo": "someone/else"}}})
        with self.assertRaises(MODULE.Error):
            self.sync()
        self.assertEqual(self.calls, [])

    def test_project_scope_does_not_satisfy_user_install(self):
        cache = self.root / "cache"
        cache.mkdir()
        write(self.args.claude_home / "plugins/installed_plugins.json", {"plugins": {"docs@market": [{"scope": "project", "installPath": str(cache)}]}})
        commands = self.manager.plan(self.entries)[0]["commands"]
        self.assertTrue(any(command[2] == "install" for command in commands))

    def test_codex_cache_without_registration_is_not_installed(self):
        write(self.args.codex_home / "plugins/cache/market/docs/1/.codex-plugin/plugin.json", {"name": "docs"})
        self.assertEqual(self.manager.plan(self.entries)[1]["status"], "導入候補")

    def test_missing_cache_and_disabled_plugin_are_repaired(self):
        self.sync()
        marker = self.args.codex_home / "plugins/cache/market/docs/1/.orphaned_at"
        marker.touch()
        row = self.manager.plan(self.entries)[1]
        self.assertEqual(row["commands"], [["codex", "plugin", "add", "docs@market"]])
        write(self.args.claude_home / "settings.json", {"enabledPlugins": {"docs@market": False}})
        self.assertEqual(self.manager.plan(self.entries)[0]["commands"], [["claude", "plugin", "enable", "docs@market", "--scope", "user"]])

    def test_failure_stops_before_source_reflection(self):
        before = self.args.claude_source.read_bytes()
        with patch.object(self.manager, "run", side_effect=MODULE.Error("確認用の失敗")), patch.object(MODULE.shutil, "which", return_value="/fake/cli"), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(MODULE.Error):
                self.manager.sync(self.entries)
        self.assertEqual(before, self.args.claude_source.read_bytes())

    def test_cli_success_without_state_change_is_failure(self):
        with patch.object(self.manager, "run"), patch.object(MODULE.shutil, "which", return_value="/fake/cli"), contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaises(MODULE.Error):
                self.manager.sync(self.entries)

    def test_both_configs_are_validated_before_cli(self):
        self.args.codex_home.mkdir()
        (self.args.codex_home / "config.toml").write_text('secret = "TEST_SECRET"\nbroken = [')
        with self.assertRaises(MODULE.Error) as raised:
            self.sync()
        self.assertNotIn("TEST_SECRET", str(raised.exception))
        self.assertEqual(self.calls, [])

    def test_catalog_rejects_duplicate_ids_and_shell_fragments(self):
        path = self.root / "definitions.json"
        write(path, {"version": 1, "plugins": self.entries})
        MODULE.catalog(path)
        self.entries["duplicate"] = self.entries["docs"]
        write(path, {"version": 1, "plugins": self.entries})
        with self.assertRaises(MODULE.Error):
            MODULE.catalog(path)

        del self.entries["duplicate"]
        self.entries["docs"]["clients"]["codex"]["marketplace"] = "owner/repo; echo bad"
        write(path, {"version": 1, "plugins": self.entries})
        with self.assertRaises(MODULE.Error):
            MODULE.catalog(path)

    def remote_entries(self):
        self.entries["docs"]["clients"] = {"codex": {
            "id": "notion@openai-curated-remote", "mode": "sync", "marketplace": "remote",
        }}

    def test_remote_installed_uses_cli_not_cache(self):
        self.remote_entries()
        result = SimpleNamespace(returncode=0, stderr="", stdout=json.dumps({"installed": [{
            "pluginId": "notion@openai-curated-remote", "installed": True, "enabled": True,
        }]}))
        with patch.object(MODULE.subprocess, "run", return_value=result) as run:
            self.assertEqual(self.manager.plan(self.entries)[0]["status"], "一致")
        self.assertEqual(run.call_args.args[0], ["codex", "plugin", "list", "--json"])
        self.assertEqual(run.call_args.kwargs["env"]["CODEX_HOME"], str(self.args.codex_home.resolve()))

    def test_remote_sync_installs_then_verifies_without_git_registration(self):
        self.remote_entries()
        ident = "notion@openai-curated-remote"
        with patch.object(self.manager, "remote_state", side_effect=[{}, {ident: {"installed": True, "enabled": True}}]), \
                patch.object(self.manager, "run") as run, \
                patch.object(MODULE.shutil, "which", return_value="/fake/codex"), \
                contextlib.redirect_stdout(io.StringIO()):
            self.manager.sync(self.entries)
        run.assert_called_once_with(["codex", "plugin", "add", ident])

    def test_remote_missing_does_not_add_git_marketplace(self):
        self.remote_entries()
        with patch.object(self.manager, "remote_state", return_value={}):
            commands = self.manager.plan(self.entries)[0]["commands"]
        self.assertEqual(commands, [["codex", "plugin", "add", "notion@openai-curated-remote"]])

    def test_remote_disabled_is_enabled_and_state_is_refetched(self):
        self.remote_entries()
        ident = "notion@openai-curated-remote"
        with patch.object(self.manager, "remote_state", side_effect=[
            {ident: {"installed": True, "enabled": False}},
            {ident: {"installed": True, "enabled": True}},
        ]):
            self.assertTrue(self.manager.plan(self.entries)[0]["commands"])
            self.assertEqual(self.manager.plan(self.entries)[0]["status"], "一致")

    def test_remote_warning_and_malformed_response_stop_sync(self):
        self.remote_entries()
        for stderr, stdout in [("Warning: failed to list remote marketplace plugins", '{"installed": []}'),
                               ("", '{}'), ("", '{"installed": [{"pluginId": "notion@openai-curated-remote"}]}')]:
            result = SimpleNamespace(returncode=0, stderr=stderr, stdout=stdout)
            with patch.object(MODULE.subprocess, "run", return_value=result), self.assertRaises(MODULE.Error):
                self.manager.plan(self.entries)

    def test_remote_catalog_only_accepts_codex_remote_ids(self):
        self.remote_entries()
        path = self.root / "remote.json"
        write(path, {"version": 1, "plugins": self.entries})
        MODULE.catalog(path)
        self.entries["docs"]["clients"]["codex"]["id"] = "notion@other"
        write(path, {"version": 1, "plugins": self.entries})
        with self.assertRaises(MODULE.Error):
            MODULE.catalog(path)


if __name__ == "__main__":
    unittest.main()
