#!/usr/bin/env python3
"""同じ type に有効な認証がある失効ファイルだけを整理する。Python 3.11+。"""

import sys

if sys.version_info < (3, 11):
    sys.exit("Python 3.11 以上が必要です。mise の Python を使用してください。")

import fcntl
import glob
import json
import os
import subprocess
from contextlib import contextmanager
from dataclasses import dataclass
from datetime import datetime, timezone
from pathlib import Path


@dataclass(frozen=True)
class Entry:
    path: Path
    kind: str
    when: datetime
    day: str
    content: bytes


def read_entry(path):
    try:
        content = path.read_bytes()
        data = json.loads(content)
        if not isinstance(data, dict):
            return None
        expired = data.get("expired")
        kind = data.get("type", "?")
        if not isinstance(expired, str) or not isinstance(kind, str):
            return None
        when = datetime.fromisoformat(expired)
        # タイムゾーンを推測して削除しない。判定できない認証は残す。
        if when.tzinfo is None:
            return None
        return Entry(path, kind, when, expired[:10], content)
    except (OSError, ValueError, UnicodeError):
        # 認証内容や JSON パーサーの診断をログへ出さない。
        return None


def collect(directory):
    # 旧 glob と同様、隠しファイルとサブディレクトリは走査しない。
    paths = sorted(glob.glob(os.path.join(glob.escape(str(directory)), "*.json")))
    return [entry for path in paths if (entry := read_entry(Path(path))) is not None]


def candidates(entries, now):
    alive = {entry.kind for entry in entries if entry.when > now}
    return [entry for entry in entries if entry.when <= now and entry.kind in alive]


@contextmanager
def apply_lock(directory):
    # ロックファイルは残す。同じ inode を使い、終了・強制終了時は OS が解放する。
    fd = os.open(directory / ".auth-prune.lock", os.O_CREAT | os.O_RDWR, 0o600)
    try:
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise RuntimeError("別の認証整理が実行中です") from None
        yield
    finally:
        os.close(fd)


def prune(directory, apply):
    entries = collect(directory)
    now = datetime.now(timezone.utc)
    selected = candidates(entries, now)
    witnesses = {}
    for entry in entries:
        if entry.when > now:
            witnesses.setdefault(entry.kind, []).append(entry.path)
    if not selected:
        print("  不要な失効ファイルはありません")
        return 0
    for entry in selected:
        if apply:
            # 自身の並行実行以外（再認証・サービス更新）も直前に照合する。
            now = datetime.now(timezone.utc)
            if (
                read_entry(entry.path) != entry
                or entry.when > now
                or not any(
                    (live := read_entry(path)) is not None
                    and live.kind == entry.kind
                    and live.when > now
                    for path in witnesses[entry.kind]
                )
            ):
                raise RuntimeError(
                    "認証ファイルが変更されました。候補を確認し直してください"
                )
            entry.path.unlink()
        verb = "削除" if apply else "削除候補"
        print(
            f"  {verb}: {entry.path.name} ({entry.day} に失効、有効な {entry.kind} が別にある)",
            flush=True,
        )
    if apply:
        result = subprocess.run(
            ["brew", "services", "restart", "cliproxyapi"], check=False
        )
        if result.returncode:
            return (
                result.returncode if result.returncode > 0 else 128 - result.returncode
            )
        print("✅ サービス再起動完了")
    else:
        print("\n  実際に削除するには: task cliproxy-auth-prune -- --yes")
    return 0


def main():
    directory_text = os.environ.get("CLIPROXY_AUTH_DIR") or str(
        Path.home() / ".cli-proxy-api"
    )
    directory = Path(directory_text)
    # 既存入口と同様、先頭の --yes だけが反映を有効にする。
    apply = sys.argv[1:2] == ["--yes"]
    if not directory.is_dir():
        print(f"  認証ディレクトリがありません: {directory_text}")
        return 0
    try:
        if apply:
            with apply_lock(directory):
                return prune(directory, True)
        return prune(directory, False)
    except RuntimeError as error:
        print(f"エラー: {error}", file=sys.stderr)
        return 1
    except FileNotFoundError as error:
        if error.filename == "brew":
            print("brew が見つかりません", file=sys.stderr)
            return 127
        print("エラー: 認証ファイルを操作できません（内容は非表示）", file=sys.stderr)
        return 1
    except OSError:
        print("エラー: 認証ファイルを操作できません（内容は非表示）", file=sys.stderr)
        return 1


if __name__ == "__main__":
    sys.exit(main())
