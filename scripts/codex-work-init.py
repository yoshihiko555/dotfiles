#!/usr/bin/env python3
"""会社用 Codex ホームを初期化し、共通ルールとスキルを配線する。"""

import os
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]


def initialize(target: Path) -> None:
    target = target.expanduser().resolve()
    personal = (Path.home() / ".codex").resolve()
    if target.is_relative_to(personal) or target.is_relative_to(ROOT) or target == Path.home():
        raise ValueError("会社用ホームには個人用 ~/.codex、ホーム直下、リポジトリ内を指定できません")

    # 認証・履歴が入るディレクトリを他ユーザーに公開しない。
    target.mkdir(mode=0o700, parents=True, exist_ok=True)
    sources = [ROOT / "shared/skills" / name for name in ("common", "codex-only", "work")]
    skill_dir = target / "skills"
    if skill_dir.is_symlink():
        raise ValueError(f"既存の skills が symlink のため停止します: {skill_dir}")
    skill_dir.mkdir(exist_ok=True)

    config = target / "config.toml"
    links = {
        config: ROOT / "codex-work/config.toml",
        target / "AGENTS.md": ROOT / "codex/AGENTS.md",
    }
    for source in sources:
        for skill in sorted(source.iterdir()):
            if skill.is_dir() and not skill.name.startswith("."):
                links[skill_dir / skill.name] = skill

    # 個別に用意した設定・スキルを上書きしない。変更前に衝突を確認する。
    for destination, source in links.items():
        if destination.exists() or destination.is_symlink():
            # 旧コピー方式からは、内容を repo に回収済みの場合だけリンクへ移行する。
            if destination == config and not destination.is_symlink() and destination.is_file():
                if destination.read_bytes() == source.read_bytes():
                    continue
                raise ValueError(f"既存の会社用設定を {source} に回収してから再実行してください: {config}")
            if not destination.is_symlink() or destination.resolve() != source.resolve():
                raise ValueError(f"既存ファイルと衝突するため停止します: {destination}")

    # このスクリプトで管理するリンクだけを整理する。ローカル追加分は残す。
    for link in skill_dir.iterdir():
        if link.is_symlink() and link not in links:
            if link.readlink().parent in sources:
                link.unlink()
    for destination, source in links.items():
        if not destination.is_symlink():
            if destination == config and destination.exists():
                # 検査後の編集も取りこぼさないよう、切り替え直前に再確認する。
                if destination.read_bytes() != source.read_bytes():
                    raise ValueError(f"会社用設定が変更されたため停止します: {config}")
                destination.unlink()
            destination.symlink_to(source)
    print(f"会社用 Codex ホーム: {target}")


if __name__ == "__main__":
    os.umask(0o077)
    try:
        initialize(Path(os.environ.get("CODEX_WORK_HOME") or Path.home() / ".codex-work"))
    except (OSError, ValueError) as error:
        print(f"codex-work-init: {error}", file=sys.stderr)
        sys.exit(1)
