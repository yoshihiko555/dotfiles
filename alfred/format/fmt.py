#!/usr/bin/python3
"""クリップボードのテキストを各種フォーマットへ変換する。

使い方:
    fmt.py list           変換可能な候補を Alfred の Script Filter JSON で出力
    fmt.py apply <name>   変換結果を stdout へ出力

入力は環境変数 FMT_INPUT があればそれ、無ければ pbpaste。
"""

import base64
import binascii
import json
import os
import subprocess
import sys
import urllib.parse
import xml.dom.minidom


def read_input():
    value = os.environ.get("FMT_INPUT")
    if value is not None:
        return value
    return subprocess.run(
        ["/usr/bin/pbpaste"], capture_output=True, encoding="utf-8", check=True
    ).stdout


def dumps(obj, **kwargs):
    return json.dumps(obj, ensure_ascii=False, **kwargs)


def json_pretty(text):
    return dumps(json.loads(text), indent=2)


def json_minify(text):
    return dumps(json.loads(text), separators=(",", ":"))


def json_sort(text):
    return dumps(json.loads(text), indent=2, sort_keys=True)


def base64_encode(text):
    return base64.b64encode(text.encode("utf-8")).decode("ascii")


BASE64_CHARS = set(
    "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/-_="
)


def base64_decode(text):
    stripped = "".join(text.split())
    # urlsafe_b64decode は不正な文字を黙って捨てるため、先に文字集合を検証する
    if not stripped or not set(stripped) <= BASE64_CHARS:
        raise ValueError("not base64")
    padded = stripped + "=" * (-len(stripped) % 4)
    # 標準 / URL-safe の両方を受け付ける
    try:
        raw = base64.b64decode(padded, validate=True)
    except binascii.Error:
        raw = base64.urlsafe_b64decode(padded)
    return raw.decode("utf-8")


def url_encode(text):
    return urllib.parse.quote(text, safe="")


def url_decode(text):
    decoded = urllib.parse.unquote(text)
    if decoded == text:
        raise ValueError("no change")
    return decoded


def b64url_decode(segment):
    return base64.urlsafe_b64decode(segment + "=" * (-len(segment) % 4))


def jwt_decode(text):
    token = text.strip()
    parts = token.split(".")
    if len(parts) != 3:
        raise ValueError("not a JWT")
    header = json.loads(b64url_decode(parts[0]))
    payload = json.loads(b64url_decode(parts[1]))
    # 署名の検証は行わない（デコード表示のみ）
    return dumps({"header": header, "payload": payload}, indent=2)


def xml_pretty(text):
    stripped = text.strip()
    if not stripped.startswith("<"):
        raise ValueError("not XML")
    dom = xml.dom.minidom.parseString(stripped)
    pretty = dom.toprettyxml(indent="  ")
    lines = [line for line in pretty.splitlines() if line.strip()]
    return "\n".join(lines)


def xml_minify(text):
    stripped = text.strip()
    if not stripped.startswith("<"):
        raise ValueError("not XML")
    dom = xml.dom.minidom.parseString(stripped)
    return "".join(
        line.strip() for line in dom.toxml().splitlines() if line.strip()
    )


CONVERTERS = [
    ("json-pretty", "JSON を整形", json_pretty),
    ("json-minify", "JSON を 1 行化", json_minify),
    ("json-sort", "JSON を整形（キーをソート）", json_sort),
    ("jwt-decode", "JWT をデコード（署名は未検証）", jwt_decode),
    ("xml-pretty", "XML を整形", xml_pretty),
    ("xml-minify", "XML を 1 行化", xml_minify),
    ("base64-decode", "Base64 をデコード", base64_decode),
    ("base64-encode", "Base64 にエンコード", base64_encode),
    ("url-decode", "URL デコード", url_decode),
    ("url-encode", "URL エンコード", url_encode),
]


def preview(text, limit=80):
    single = " ".join(text.split())
    if len(single) > limit:
        return single[:limit] + "…"
    return single


def cmd_list():
    text = read_input()
    items = []
    if not text.strip():
        items.append(
            {
                "title": "クリップボードが空です",
                "subtitle": "変換したいテキストをコピーしてから実行してください",
                "valid": False,
            }
        )
    else:
        for name, title, func in CONVERTERS:
            try:
                result = func(text)
            except Exception:
                continue
            if result == text:
                continue
            items.append(
                {
                    "uid": name,
                    "title": title,
                    "subtitle": preview(result),
                    "arg": name,
                    "match": name.replace("-", " ") + " " + title,
                    "text": {"copy": result, "largetype": result},
                }
            )
        if not items:
            items.append(
                {
                    "title": "変換できる形式が見つかりません",
                    "subtitle": preview(text),
                    "valid": False,
                }
            )
    sys.stdout.write(dumps({"items": items}))


def cmd_apply(name):
    text = read_input()
    for key, _title, func in CONVERTERS:
        if key == name:
            sys.stdout.write(func(text))
            return
    raise SystemExit("unknown converter: {}".format(name))


def main(argv):
    if len(argv) >= 2 and argv[1] == "list":
        cmd_list()
    elif len(argv) >= 3 and argv[1] == "apply":
        cmd_apply(argv[2])
    else:
        raise SystemExit(__doc__)


if __name__ == "__main__":
    main(sys.argv)
