#!/usr/bin/env python3
"""個人用プラグインの共通対応表を、各 CLI の導入状態と照合する。"""

import argparse
import fcntl
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import sys
import tempfile
import tomllib


ROOT = Path(__file__).resolve().parent.parent
NAME = r"[A-Za-z0-9_-]+(?:\.[A-Za-z0-9_-]+)*"


class Error(Exception):
    pass


def read(path, *, toml=False):
    if not path.exists():
        if path.is_symlink():
            raise Error(f"リンク先がありません: {path}")
        return {}
    try:
        value = tomllib.loads(path.read_text()) if toml else json.loads(path.read_text())
        if not isinstance(value, dict):
            raise ValueError
        return value
    except (ValueError, OSError):
        raise Error(f"設定を読み取れません（値は非表示）: {path}") from None


def mapping(value):
    if not isinstance(value, dict):
        raise Error("設定のオブジェクト形式が不正です（値は非表示）")
    return value


def catalog(path):
    data = read(path)
    if set(data) != {"version", "plugins"} or data["version"] != 1:
        raise Error("共通定義の version / plugins が不正です")
    entries = mapping(data["plugins"])
    seen = set()
    markets = {}
    for name, plugin in entries.items():
        if not re.fullmatch(NAME, name) or set(mapping(plugin)) != {"description", "clients"}:
            raise Error("プラグイン定義の名前・フィールドが不正です")
        clients = mapping(plugin["clients"])
        if not clients or set(clients) - {"claude", "codex"}:
            raise Error("クライアント名が不正です")
        for client, target in clients.items():
            if set(mapping(target)) - {"id", "mode", "marketplace", "note"}:
                raise Error("未対応のプラグイン定義フィールドです")
            ident = target.get("id", "")
            if not isinstance(ident, str) or not re.fullmatch(NAME + "@" + NAME, ident):
                raise Error("プラグイン ID が不正です")
            if (client, ident) in seen:
                raise Error("同じクライアントのプラグイン ID が重複しています")
            seen.add((client, ident))
            if target.get("mode") not in {"sync", "candidate", "remote"}:
                raise Error("mode は sync / candidate / remote のいずれかです")
            source = target.get("marketplace")
            if target["mode"] != "remote":
                if source == "remote":
                    if client != "codex" or not ident.endswith("@openai-curated-remote"):
                        raise Error("remote 配布元は Codex の openai-curated-remote 専用です")
                    continue
                if not isinstance(source, str) or not re.fullmatch(NAME + "/" + NAME, source):
                    raise Error("配布元は GitHub の owner/repo 形式で指定してください")
                key = (client, ident.split("@")[1])
                if key in markets and markets[key] != source:
                    raise Error("同名の配布元に異なるリポジトリが指定されています")
                markets[key] = source
    return entries


def repo_name(source):
    if not isinstance(source, str):
        return None
    return source.removeprefix("https://github.com/").removesuffix(".git").rstrip("/")


class Manager:
    def __init__(self, args):
        self.args = args
        self.homes = {"claude": args.claude_home, "codex": args.codex_home}
        self.paths = {
            "claude": args.claude_home / "settings.json",
            "codex": args.codex_home / "config.toml",
        }

    def cli_env(self):
        env = os.environ.copy()
        env["CLAUDE_CONFIG_DIR"] = str(self.args.claude_home.resolve())
        env["CODEX_HOME"] = str(self.args.codex_home.resolve())
        return env

    def remote_state(self):
        try:
            result = subprocess.run(
                ["codex", "plugin", "list", "--json"], env=self.cli_env(), cwd=ROOT,
                capture_output=True, text=True, timeout=60, check=False,
            )
            # リモート取得失敗でも CLI は成功終了し、ローカル分だけ返すことがある。
            if result.returncode or "failed" in result.stderr.lower():
                raise ValueError
            data = json.loads(result.stdout)
            rows = data["installed"]
            if not isinstance(rows, list):
                raise ValueError
            remote = {}
            for row in rows:
                if not isinstance(row, dict) or not isinstance(row.get("pluginId"), str):
                    raise ValueError
                if row["pluginId"].endswith("@openai-curated-remote"):
                    if type(row.get("installed")) is not bool or type(row.get("enabled")) is not bool:
                        raise ValueError
                    remote[row["pluginId"]] = row
            return remote
        except (OSError, ValueError, KeyError, TypeError, subprocess.TimeoutExpired):
            raise Error("Codex のリモート導入状態を確認できません。ネットワーク・ログインを確認してください（未導入とは判定しません）。") from None

    def state(self, client):
        home = self.homes[client]
        data = read(self.paths[client], toml=client == "codex")
        if client == "claude":
            enabled = mapping(data.get("enabledPlugins", {}))
            installed = mapping(read(home / "plugins/installed_plugins.json").get("plugins", {}))
            markets = read(home / "plugins/known_marketplaces.json")
        else:
            enabled = mapping(data.get("plugins", {}))
            installed = {}
            markets = mapping(data.get("marketplaces", {}))
        return enabled, installed, markets

    def inspect(self, client, target, state):
        ident = target["id"]
        name, market = ident.split("@")
        enabled, installed, markets = state
        if target["mode"] == "remote":
            return "アプリ管理（状態未検証）", []
        if target["mode"] == "candidate":
            return "候補（同期対象外）", []

        if target["marketplace"] == "remote":
            if self.remote is None:
                self.remote = self.remote_state()
            row = self.remote.get(ident, {})
            if row.get("installed") is True and row.get("enabled") is True:
                return "一致", []
            return "導入・有効化候補", [["codex", "plugin", "add", ident]]

        commands = []
        source = target["marketplace"]
        if market in markets:
            registered = mapping(markets[market])
            if client == "claude":
                location = mapping(registered.get("source", {}))
                actual = location.get("repo") if location.get("source") == "github" else None
            else:
                actual = registered.get("source") if registered.get("source_type") == "git" else None
            if repo_name(actual) != source:
                raise Error(f"配布元が共通定義と異なります: {client} / {market}")
        else:
            commands.append([client, "plugin", "marketplace", "add", source])

        if client == "claude":
            rows = installed.get(ident, [])
            if not isinstance(rows, list) or not all(isinstance(row, dict) for row in rows):
                raise Error("Claude の導入登録簿が不正です（値は非表示）")
            present = any(
                row.get("scope") == "user"
                and isinstance(row.get("installPath"), str)
                and Path(row["installPath"]).is_dir()
                for row in rows
            )
            active = enabled.get(ident) is True
            if not present:
                commands.append([client, "plugin", "install", ident, "--scope", "user"])
            if not active:
                commands.append([client, "plugin", "enable", ident, "--scope", "user"])
        else:
            setting = mapping(enabled.get(ident, {}))
            cache = self.homes[client] / "plugins/cache" / market / name
            present = ident in enabled and any(
                version.is_dir()
                and not (version / ".orphaned_at").exists()
                and ((version / ".codex-plugin/plugin.json").is_file() or (version / "plugin.json").is_file())
                for version in cache.glob("*")
            )
            active = setting.get("enabled") is True
            if not present or not active:
                commands.append([client, "plugin", "add", ident])
        status = "一致" if not commands else "導入候補" if not present else "更新候補"
        return status, commands

    def plan(self, entries):
        self.remote = None
        states = {}
        rows = []
        source = read(self.args.claude_source)
        source_enabled = mapping(source.get("enabledPlugins", {}))
        for name, plugin in entries.items():
            if self.args.name and self.args.name != name:
                continue
            for client, target in plugin["clients"].items():
                if self.args.client and self.args.client != client:
                    continue
                if client not in states:
                    states[client] = self.state(client)
                status, commands = self.inspect(client, target, states[client])
                reflect = client == "claude" and target["mode"] == "sync" and source_enabled.get(target["id"]) is not True
                if reflect and status == "一致":
                    status = "配布用設定の更新候補"
                rows.append({"name": name, "client": client, "target": target, "status": status,
                             "commands": commands, "reflect": reflect})
        return rows

    def show(self, rows):
        seen = set()
        for row in rows:
            if self.args.action == "diff" and row["status"] == "一致":
                continue
            print(f'{row["client"]}\t{row["name"]}\t{row["status"]}\t{row["target"]["id"]}')
            for command in row["commands"]:
                key = tuple(command)
                if key not in seen:
                    print("  " + shlex.join(command))
                    seen.add(key)
            if row["reflect"]:
                print("  Claude の配布用 settings.json に有効化状態を反映")

    def run(self, command):
        print("実行: " + shlex.join(command), flush=True)
        # シェルを介さず実行。認証や CLI の確認プロンプトは通常どおり表示する。
        result = subprocess.run(command, env=self.cli_env(), cwd=ROOT, check=False)
        if result.returncode:
            raise Error("CLI が失敗したため停止しました。部分反映の可能性があります。再度 diff で確認してください。")

    def backup(self):
        folder = Path(tempfile.mkdtemp(prefix="sync-", dir=self.args.backup_dir))
        paths = [*self.paths.values(), self.args.claude_source,
                 self.args.claude_home / "plugins/installed_plugins.json",
                 self.args.claude_home / "plugins/known_marketplaces.json"]
        index = []
        for i, path in enumerate(paths):
            target = path.resolve()
            filename = f"{i}.before"
            if target.exists():
                shutil.copyfile(target, folder / filename)
            index.append({"path": str(target), "present": target.exists(), "backup": filename})
        (folder / "index.json").write_text(json.dumps(index, ensure_ascii=False, indent=2) + "\n")
        print(f"設定のバックアップ: {folder}")

    def reflect(self, rows):
        path = self.args.claude_source.resolve()
        before = path.read_bytes() if path.exists() else None
        data = read(path)
        enabled = mapping(data.setdefault("enabledPlugins", {}))
        for row in rows:
            if row["client"] == "claude" and row["target"]["mode"] == "sync":
                enabled[row["target"]["id"]] = True
        if before is not None and json.loads(before) == data:
            return
        # CLI から独立した配布用設定のみを置換する。リンクと対象外の値は維持する。
        with tempfile.NamedTemporaryFile(mode="w", dir=path.parent, delete=False) as stream:
            temporary = Path(stream.name)
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.write("\n")
        try:
            if (path.read_bytes() if path.exists() else None) != before:
                raise Error("配布用設定が並行変更されたため停止しました")
            if path.exists():
                shutil.copymode(path, temporary)
            temporary.replace(path)
        finally:
            temporary.unlink(missing_ok=True)

    def sync(self, entries):
        self.args.backup_dir.mkdir(parents=True, exist_ok=True)
        with (self.args.backup_dir / ".sync-lock").open("w") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                raise Error("別のプラグイン同期が実行中です") from None
            rows = self.plan(entries)
            commands = list(dict.fromkeys(tuple(c) for row in rows for c in row["commands"]))
            if not commands and not any(row["reflect"] for row in rows):
                print("同期対象の差分はありません。アプリ管理・候補は同期対象外です。")
                return
            for command in commands:
                if not shutil.which(command[0]):
                    raise Error(f"CLI が見つかりません: {command[0]}")
            self.backup()
            for command in commands:
                self.run(list(command))
            # 成功終了でも未登録なら完了扱いにしない。
            if any(row["commands"] for row in self.plan(entries)):
                raise Error("CLI 実行後も導入状態に差分があります。diff で確認してください。")
            if any(row["reflect"] for row in rows):
                self.reflect(rows)
            print("同期対象の登録・キャッシュを確認しました。認証とツール動作は新しいセッションで確認してください。")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=["list", "diff", "sync"])
    parser.add_argument("name", nargs="?")
    parser.add_argument("--client", choices=["claude", "codex"])
    parser.add_argument("--definitions", type=Path, default=ROOT / "shared/plugins/plugins.json")
    parser.add_argument("--claude-home", type=Path, default=Path.home() / ".claude")
    parser.add_argument("--codex-home", type=Path, default=Path.home() / ".codex")
    parser.add_argument("--claude-source", type=Path, default=ROOT / "claude/settings.json")
    parser.add_argument("--backup-dir", type=Path, default=Path.home() / ".local/state/dotfiles/plugin-backups")
    args = parser.parse_args()
    os.umask(0o077)
    try:
        entries = catalog(args.definitions)
        if args.name and args.name not in entries:
            raise Error("共通定義にないプラグイン名です")
        manager = Manager(args)
        rows = manager.plan(entries)
        manager.show(rows)
        if args.action == "sync":
            manager.sync(entries)
        else:
            print("読み取り専用。sync の対象は有効化・導入のみ。アプリ管理・認証・接続状態は未検証です。")
    except (Error, OSError) as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
