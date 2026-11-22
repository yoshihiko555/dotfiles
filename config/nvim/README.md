# Neovim の設定

Leader キーは `Space`。日常の編集操作は[チートシートの目次](docs/cheatsheet/README.md)から引ける。
手を動かして覚えるときは、[練習ガイド](docs/exercises/README.md)に沿って Neovim で各教材を開く。

## 設定と動作確認

| 目的 | 参照先 |
|---|---|
| 起動時の設定や共通キーを調べる | [init.lua](init.lua)、[基本設定](lua/core/options.lua)、[キーマップ](lua/core/keymaps.lua) |
| プラグインの用途・導入理由・設定場所を調べる | [プラグイン一覧](docs/PLUGINS.md) |
| Go・TypeScript・Python でリンターの診断を確認する | [プロジェクトでのリント確認](docs/cheatsheet/lsp.md#プロジェクトでのリント確認) |
| Go・Python・TypeScript をデバッグする | [操作と再現手順](docs/cheatsheet/debugging.md)、[環境別の確認項目](docs/cheatsheet/debugging.md#環境別の確認項目) |

## 設計判断と移行記録

- [ADR 索引](docs/adr/DECISIONS.md) — プラグインの選定理由や構成を変更した経緯。
- [調査メモ](docs/research/) — 候補の比較と検証結果。メモはフェーズとテーマで命名し、追加時は[テンプレート](docs/research/TEMPLATE.md)を使う。
- [VSCode からの移行記録](ROADMAP.md) — 操作の習熟、プラグインの段階的な導入、当時の拡張候補。
