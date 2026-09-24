#!/usr/bin/env python3
"""個人用 MCP の一覧・差分・同期。Python 3.11+、標準ライブラリのみ。"""

import sys

if sys.version_info < (3, 11):
    sys.exit("Python 3.11 以上が必要です。mise の Python を使用してください。")

import copy
import json
import math
import os
import re
import stat
import tempfile
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import date, datetime, time, timezone
from pathlib import Path

import tomllib

ROOT = Path(__file__).resolve().parents[1]
JSON_ERROR = "JSON の構文・定義・参照が不正です（値は非表示）"


class ConfigError(Exception):
    """値を含まない利用者向けの診断。"""


def require(condition, message=JSON_ERROR):
    if not condition:
        raise ConfigError(message)


def parse_args(args):
    usage = (
        f"使い方: {sys.argv[0]} {{list|diff|sync}} [サーバー名] "
        "[--definitions DIR] [--claude-config FILE] [--codex-config FILE] [--backup-dir DIR]"
    )
    require(args and args[0] in ("list", "diff", "sync"), usage)
    action, *rest = args
    paths = {
        "--definitions": ROOT / "shared/mcp",
        "--claude-config": Path.home() / ".claude.json",
        "--codex-config": Path.home() / ".codex/config.toml",
        "--backup-dir": Path.home() / ".local/state/dotfiles/mcp-backups",
    }
    selected = ""
    while rest:
        arg, *rest = rest
        if arg in paths:
            require(rest and rest[0], f"{arg} の値が必要です")
            paths[arg] = Path(rest.pop(0))
        elif arg.startswith("-"):
            raise ConfigError(f"未対応のオプション: {arg}")
        else:
            require(not selected, "サーバー名は1件のみ指定できます")
            selected = arg
    return action, selected, paths


def reject_constant(_value):
    raise ConfigError(JSON_ERROR)


def read_json(content):
    try:
        return json.loads(content, parse_constant=reject_constant)
    except (ValueError, UnicodeError) as error:
        raise ConfigError(JSON_ERROR) from error


def read_toml(content):
    try:
        return tomllib.loads(content.decode("utf-8"))
    except (ValueError, UnicodeError) as error:
        raise ConfigError("TOML を解析できません（値は非表示）") from error


def defaulted(value, fallback):
    # jq の // と同様、null / false だけに既定値を使う。空文字等は検証で拒否する。
    return fallback if value is None or value is False else value


def valid_server(server):
    if not isinstance(server, dict):
        return False
    if server.get("type") == "http":
        return (
            set(server) == {"type", "url"}
            and isinstance(server["url"], str)
            and re.match(r"^https?://", server["url"]) is not None
        )
    if server.get("type") != "stdio":
        return False
    args, env = defaulted(server.get("args"), []), defaulted(server.get("env"), {})
    return (
        not (set(server) - {"type", "command", "args", "env"})
        and isinstance(server.get("command"), str)
        and bool(server["command"])
        and isinstance(args, list)
        and all(isinstance(arg, str) for arg in args)
        and isinstance(env, dict)
        and all(isinstance(value, str) for value in env.values())
    )


def definitions(directory, selected):
    clients = read_json((directory / "clients.json").read_bytes())
    require(isinstance(clients, dict) and set(clients) == {"claude", "codex"})
    require(all(isinstance(value, dict) for value in clients.values()))
    files = sorted(
        path
        for path in (directory / "servers").glob("*.json")
        if not path.name.startswith(".")
    )
    require(files, "サーバー定義がありません")
    servers = {}
    for path in files:
        require(re.fullmatch(r"[a-zA-Z0-9_-]+", path.stem), "サーバー名が不正です")
        server = read_json(path.read_bytes())
        require(valid_server(server))
        servers[path.stem] = server
    for config in clients.values():
        for name, override in config.items():
            require(
                name in servers
                and isinstance(override, dict)
                and not (set(override) - {"args"})
            )
            require(valid_server(servers[name] | override))
    require(not selected or any(selected in config for config in clients.values()))
    return clients, servers


@dataclass
class Snapshot:
    client: str
    config: Path
    target: Path
    before: bytes
    mode: int
    present: bool

    @classmethod
    def read(cls, client, config):
        present = config.exists()
        if present:
            target = config.resolve(strict=True)
            require(target.is_file(), f"通常ファイルではありません: {config}")
            before = target.read_bytes()
            mode = stat.S_IMODE(target.stat().st_mode)
        else:
            require(not config.is_symlink(), f"リンク先がありません: {config}")
            target = config.parent.resolve(strict=True) / config.name
            before = b"{}\n" if client == "claude" else b""
            mode = 0o600
        return cls(client, config, target, before, mode, present)

    def verify(self):
        if self.present:
            require(
                self.config.resolve(strict=True) == self.target
                and self.target.read_bytes() == self.before,
                f"実設定が並行して変更されました: {self.client}",
            )
        else:
            require(
                not os.path.lexists(self.config)
                and self.config.parent.resolve(strict=True) / self.config.name
                == self.target
                and not os.path.lexists(self.target),
                f"設定が新しく作成されました。再実行してください: {self.client}",
            )


def normalized(server, client):
    server = copy.deepcopy(server)
    if "command" in server:
        server["args"] = defaulted(server.get("args"), [])
        server["env"] = defaulted(server.get("env"), {})
        if client == "claude":
            server["type"] = defaulted(server.get("type"), "stdio")
    if client == "codex":
        server.setdefault("enabled", True)
    return server


def same_value(left, right):
    # Python の True == 1 を設定の同値と扱わない。TOML の nan も照合する。
    if type(left) is not type(right):
        return False
    if isinstance(left, dict):
        return left.keys() == right.keys() and all(
            same_value(value, right[key]) for key, value in left.items()
        )
    if isinstance(left, list):
        return len(left) == len(right) and all(
            same_value(a, b) for a, b in zip(left, right, strict=True)
        )
    if isinstance(left, float) and math.isnan(left):
        return math.isnan(right)
    return left == right


@dataclass
class Plan:
    snapshot: Snapshot
    expected: dict
    changed: list[str]


def plan(snapshot, clients, servers, selected, action):
    client = snapshot.client
    before = (
        read_json(snapshot.before) if client == "claude" else read_toml(snapshot.before)
    )
    key = "mcpServers" if client == "claude" else "mcp_servers"
    require(isinstance(before, dict))
    current = before.get(key)
    current = {} if current is None else current
    require(
        isinstance(current, dict)
        and all(isinstance(value, dict) for value in current.values())
    )
    expected = copy.deepcopy(before)
    changed = []
    for name in sorted(clients[client]):
        if selected and name != selected:
            continue
        desired = servers[name] | clients[client][name]
        if client == "codex":
            desired.pop("type", None)
        old = current.get(name, {})
        require(
            not (
                ("command" in old and "url" in desired)
                or ("url" in old and "command" in desired)
            )
        )
        new = old | desired
        if "command" in desired:
            old_env, new_env = (
                defaulted(old.get("env"), {}),
                defaulted(desired.get("env"), {}),
            )
            require(isinstance(old_env, dict) and isinstance(new_env, dict))
            new["args"] = defaulted(desired.get("args"), [])
            new["env"] = old_env | new_env
        if client == "codex":
            new["enabled"] = True
        status = (
            "追加候補"
            if name not in current
            else "一致"
            if same_value(normalized(old, client), normalized(new, client))
            else "更新候補"
        )
        if status != "一致":
            changed.append(name)
            if expected.get(key) is None:
                expected[key] = {}
            expected[key][name] = new
        if action == "list" or status != "一致":
            print(f"{client}\t{name}\t{status}")
    print(f"対象外 {client}: {', '.join(sorted(set(current) - set(clients[client])))}")
    return Plan(snapshot, expected, changed)


def toml_value(value):
    if isinstance(value, dict):
        return (
            "{ "
            + ", ".join(
                f"{json.dumps(key, ensure_ascii=False)} = {toml_value(item)}"
                for key, item in value.items()
            )
            + " }"
        )
    if isinstance(value, list):
        return "[" + ", ".join(toml_value(item) for item in value) + "]"
    if isinstance(value, (datetime, date, time)):
        return value.isoformat()
    require(value is not None, "TOML に変換できない値があります（値は非表示）")
    if isinstance(value, float) and not math.isfinite(value):
        return str(value)
    return json.dumps(value, ensure_ascii=False, allow_nan=False)


def render(plan):
    if plan.snapshot.client == "claude":
        return (
            json.dumps(plan.expected, ensure_ascii=False, indent=2, allow_nan=False)
            + "\n"
        ).encode()
    # 通常の bare-key テーブルだけを編集する。文字列内部等を誤認した場合も
    # 再解析と全体比較で拒否し、どちらの実設定にも書き込まない。
    text = plan.snapshot.before.decode("utf-8")
    for name in plan.changed:
        kept, drop = [], False
        for line in text.splitlines(keepends=True):
            if re.match(r"^[ \t]*\[", line):
                header = re.sub(r"[ \t\r]", "", line.split("#", 1)[0].rstrip("\n"))
                drop = header == f"[mcp_servers.{name}]" or header.startswith(
                    f"[mcp_servers.{name}."
                )
            if not drop or re.match(r"^[ \t]*(#|\r?$)", line.rstrip("\n")):
                kept.append(line)
        text = "".join(kept)
        if text and not text.endswith("\n"):
            text += "\n"
        text += f"\n[mcp_servers.{name}]\n"
        text += "".join(
            f"{json.dumps(key, ensure_ascii=False)} = {toml_value(value)}\n"
            for key, value in plan.expected["mcp_servers"][name].items()
        )
    result = text.encode("utf-8")
    require(
        same_value(read_toml(result), plan.expected),
        "未対応の TOML 表記または対象外の変更があるため反映しません（値は非表示）",
    )
    return result


@contextmanager
def sync_lock(backup_root):
    backup_root.mkdir(parents=True, exist_ok=True)
    lock = backup_root / ".sync-lock"
    try:
        lock.mkdir()
    except FileExistsError:
        raise ConfigError(f"別の同期が実行中かロックが残っています: {lock}") from None
    try:
        yield
    finally:
        lock.rmdir()


def stage(snapshot, content):
    fd, name = tempfile.mkstemp(prefix=".mcp-sync.", dir=snapshot.target.parent)
    path = Path(name)
    try:
        with os.fdopen(fd, "wb") as output:
            output.write(content)
            output.flush()
            os.fchmod(output.fileno(), snapshot.mode)
            os.fsync(output.fileno())
    except BaseException:
        path.unlink(missing_ok=True)
        raise
    return path


def sync(plans, backup_root):
    # 全出力の検証・一時ファイル作成・バックアップを反映前に終わらせる。
    outputs = [(item.snapshot, render(item)) for item in plans if item.changed]
    if not outputs:
        print("差分なし。変更しませんでした。")
        return
    staged = []
    backup = None
    try:
        for snapshot, content in outputs:
            snapshot.verify()
            staged.append((snapshot, stage(snapshot, content)))
        backup = Path(
            tempfile.mkdtemp(
                prefix=datetime.now(timezone.utc)
                .astimezone()
                .strftime("%Y%m%d-%H%M%S."),
                dir=backup_root,
            )
        )
        for snapshot, _ in staged:
            (backup / f"{snapshot.client}.before").write_bytes(snapshot.before)
            (backup / f"{snapshot.client}.path").write_text(
                str(snapshot.target) + "\n", encoding="utf-8"
            )
            (backup / f"{snapshot.client}.state").write_text(
                "present\n" if snapshot.present else "missing\n"
            )
        for snapshot, _ in staged:
            snapshot.verify()
        for snapshot, path in staged:
            snapshot.verify()
            os.replace(path, snapshot.target)
            print(f"反映済み: {snapshot.client}（バックアップ: {backup}）", flush=True)
    except (OSError, ConfigError) as error:
        message = (
            str(error)
            if isinstance(error, ConfigError)
            else "反映できません（値は非表示）"
        )
        if backup is not None:
            message += f"。反映状況とバックアップを確認してください: {backup}"
        raise ConfigError(message) from error
    finally:
        for _, path in staged:
            path.unlink(missing_ok=True)


def execute(action, selected, paths):
    clients, servers = definitions(paths["--definitions"], selected)

    def prepare():
        return [
            plan(
                Snapshot.read(client, paths[f"--{client}-config"]),
                clients,
                servers,
                selected,
                action,
            )
            for client in ("claude", "codex")
        ]

    if action == "sync":
        with sync_lock(paths["--backup-dir"]):
            sync(prepare(), paths["--backup-dir"])
    else:
        prepare()
        print(
            "読み取り専用です。プラグイン・対象外の MCP・認証・接続状態は検査しません。"
        )


def main():
    os.umask(0o077)
    try:
        execute(*parse_args(sys.argv[1:]))
        return 0
    except ConfigError as error:
        print(f"エラー: {error}", file=sys.stderr)
    except (OSError, ValueError, RecursionError):
        print("エラー: 設定を読み書きできません（値は非表示）", file=sys.stderr)
    return 1


if __name__ == "__main__":
    sys.exit(main())
