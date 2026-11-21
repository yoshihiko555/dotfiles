#!/usr/bin/python3
"""dotfiles の alfred/ にある自作ワークフローのキーワードを Script Filter JSON で返す。

自分のディレクトリ（Alfred からは symlink、実体は repo）の隣を読むので、
ワークフローを足しても一覧の手入れは要らない。
"""

import json
import plistlib
from pathlib import Path

INPUT_TYPES = {
    "alfred.workflow.input.keyword",
    "alfred.workflow.input.listfilter",
    "alfred.workflow.input.scriptfilter",
}
# argumenttype: 0=必須 / 1=任意 / 2=引数なし
NO_ARGUMENT = 2


def entries(self_dir: Path):
    for plist in sorted(self_dir.parent.glob("*/info.plist")):
        wf_dir = plist.parent
        if wf_dir == self_dir:
            continue
        try:
            with plist.open("rb") as f:
                info = plistlib.load(f)
        except (OSError, plistlib.InvalidFileException):
            continue
        if info.get("disabled"):
            continue
        for obj in info.get("objects", []):
            if obj.get("type") not in INPUT_TYPES:
                continue
            config = obj.get("config", {})
            keyword = (config.get("keyword") or "").strip()
            if keyword:
                yield wf_dir, info, config, keyword


def item(wf_dir: Path, info: dict, config: dict, keyword: str) -> dict:
    name = info.get("name") or wf_dir.name
    detail = info.get("description") or config.get("subtext") or config.get("title") or ""
    takes_argument = config.get("argumenttype", 0) != NO_ARGUMENT
    query = keyword + (" " if takes_argument and config.get("withspace", True) else "")
    result = {
        "title": f"{keyword} — {name}",
        "subtitle": detail,
        "arg": query,
        "match": f"{keyword} {name} {detail}",
    }
    icon = wf_dir / "icon.png"
    if icon.is_file():
        result["icon"] = {"path": str(icon)}
    return result


def main() -> None:
    self_dir = Path(__file__).resolve().parent
    items = sorted(
        (item(*e) for e in entries(self_dir)),
        key=lambda i: i["title"].lower(),
    )
    if not items:
        items = [{"title": "自作ワークフローが見つからない", "subtitle": str(self_dir.parent), "valid": False}]
    print(json.dumps({"items": items}, ensure_ascii=False))


if __name__ == "__main__":
    main()
