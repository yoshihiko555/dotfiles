# クリップボードのテキストを変換する（`fmt`）

クリップボードのテキストを各種フォーマットへ変換するワークフロー。

## 使い方

1. 変換したいテキストをコピー
2. Alfred で `fmt` と入力
3. 適用できる変換だけが一覧に出る（サブタイトルに変換結果のプレビュー）
4. 選択すると変換結果がクリップボードに入る

## 対応する変換

| 名前 | 内容 |
| --- | --- |
| `json-pretty` | JSON を整形（インデント 2） |
| `json-minify` | JSON を 1 行化 |
| `json-sort` | JSON を整形してキーをソート |
| `jwt-decode` | JWT の header / payload をデコード |
| `xml-pretty` | XML を整形 |
| `xml-minify` | XML を 1 行化 |
| `base64-encode` / `base64-decode` | Base64 変換 |
| `url-encode` / `url-decode` | パーセントエンコード変換 |

## 実装

- 変換ロジックは `alfred/format/fmt.py` に集約。Script Filter が `fmt.py list`、
  アクションが `fmt.py apply <名前>` を呼ぶ。
- 実行時のクリップボードを対象にするため、アクション側で再度 `pbpaste` から変換する
  （候補列挙時の結果を `arg` で引き回すと巨大な JSON で切り詰められるため）。
- 依存を増やさないよう **Python 標準ライブラリのみ**で実装し、`/usr/bin/python3`
  （macOS 同梱）を明示的に使う。Alfred の PATH には Nix / mise の python が入らない。
- 日本語が `\uXXXX` にならないよう JSON 出力は `ensure_ascii=False` 固定。
- JWT は署名を検証しない（デコード表示のみ）。
- 変換結果が入力と同じになるものは候補から除外する。
- テスト時は `FMT_INPUT` 環境変数で入力を差し替えられる（クリップボードを壊さない）。

  ```bash
  FMT_INPUT='{"a":1}' /usr/bin/python3 alfred/format/fmt.py list
  ```

**YAML / SQL 非対応:** どちらも標準ライブラリに無く、対応するには Nix 側へ
`pyyaml` / `sqlparse` の追加が必要なため今回は見送り。

[Alfred のワークフロー一覧](../README.md)
