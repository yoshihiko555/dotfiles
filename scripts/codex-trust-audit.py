#!/usr/bin/env python3
"""projects.*.trust_level の読み取り専用監査。Python 3.11+。"""

import sys

if sys.version_info < (3, 11):
    sys.exit("Python 3.11 以上が必要です。mise の Python を使用してください。")

import os
from pathlib import Path

import tomllib


def main():
    config = os.environ.get("CODEX_CONFIG_PATH") or str(
        Path.home() / ".codex/config.toml"
    )
    if not Path(config).is_file():
        print(f"config が見つかりません: {config}")
        return 1
    try:
        with open(config, "rb") as source:
            projects = tomllib.load(source).get("projects", {})
        if not isinstance(projects, dict):
            raise TypeError
        entries = []
        for path, project in projects.items():
            if not isinstance(project, dict):
                raise TypeError
            if "trust_level" in project:
                level = project["trust_level"]
                if not isinstance(level, str):
                    raise TypeError
                entries.append((path, level))
    except (OSError, ValueError, TypeError):
        print(
            "エラー: 設定の TOML または projects の形式を確認してください（値は非表示）",
            file=sys.stderr,
        )
        return 1

    print(f"=== Codex trust audit ===\nconfig: {config}\n")
    if not entries:
        print("projects.*.trust_level は未設定です。")
        return 0
    print(f"{'status':<10} {'level':<8} path")
    print(f"{'----------':<10} {'--------':<8} ------------------------------")
    counts = {"total": len(entries), "trusted": 0, "untrusted": 0, "missing": 0}
    counts["temp-like"] = 0
    for path, level in entries:
        if level in ("trusted", "untrusted"):
            counts[level] += 1
        status = "ok"
        if not os.path.exists(path):
            status = "missing"
        elif (
            path.startswith(("/tmp/", "/private/tmp/", "/var/folders/"))
            or "/Downloads/" in path
        ):
            status = "temp-like"
        if status != "ok":
            counts[status] += 1
        print(f"{status:<10} {level:<8} {path}")
    print("\nsummary:")
    for key, count in counts.items():
        print(f"  {key:<10}: {count}")
    print(
        "\nhint:\n"
        "  - missing の削除候補は trust prune で確認し、trust prune --apply で設定から削除\n"
        "  - temp-like は用途を確認し、信頼が不要なら untrusted に変更\n"
        '  - 変更例: [projects."/path"] の trust_level = "untrusted"'
    )
    return 0


if __name__ == "__main__":
    sys.exit(main())
