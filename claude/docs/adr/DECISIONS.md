# 意思決定ログ (DECISIONS)

Claude Code の設定・プラグインに関する意思決定の一覧。詳細は各 ADR ファイルを参照。
領域をまたぐ決定は [docs/adr/](../../../docs/adr/DECISIONS.md) に置く。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20260924-0001](ADR-20260924-0001-turn-receipt-mod.md) | 自作 mod turn-receipt を dotfiles のローカル marketplace で常用する | 採用 | 2026-09-24 | 上流の判定が環境に合わない/直せばすぐ反映される/移行が軽い | Plugin/Mod |
| [ADR-20261121-0002](ADR-20261121-0002-claude-profile-overlay.md) | Claude Code の profile は、設定ディレクトリを分けず、起動時に設定と指示を重ねて切り替える | 採用 | 2026-11-21 | ログイン・履歴を分けない/profile ごとの保守がファイル数個/既定の起動は開発のまま | Profile/Settings |
| [ADR-20261127-0003](ADR-20261127-0003-artifact-export-sync.md) | claude.ai の Artifacts の写しは、正本をクラウドに置き、Claude Code の hook と同期スキルで追従させる | 採用 | 2026-11-27 | Compliance API は個人で使えない/Claude Code の公開・削除は毎回 hook を通る/ローカルの消し間違いをクラウドに及ぼさない/型から作ったものは写さない | Hook/Artifacts |
| [ADR-20261127-0004](ADR-20261127-0004-artifact-export-id.md) | 書き出し先で Artifact を識別する名前に、URL の末尾の ID を使う | 採用 | 2026-11-27 | 一覧と delete には UUID が出ない/対応表が要らない | Hook/Artifacts |
| [ADR-20261127-0005](ADR-20261127-0005-artifact-export-layout.md) | 1 本の Artifact を書き出し先の 1 つのフォルダに置き、公開したファイルをすべて公開パスのまま写す | 採用 | 2026-11-27 | 2 枚目以降のページも検索できる/相対パスの参照が切れない | Hook/Artifacts |
