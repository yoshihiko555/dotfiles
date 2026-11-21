# 意思決定ログ (DECISIONS)

Claude Code の設定・プラグインに関する意思決定の一覧。詳細は各 ADR ファイルを参照。
領域をまたぐ決定は [docs/adr/](../../../docs/adr/DECISIONS.md) に置く。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20260924-0001](ADR-20260924-0001-turn-receipt-mod.md) | 自作 mod turn-receipt を dotfiles のローカル marketplace で常用する | 採用 | 2026-09-24 | 上流の判定が環境に合わない/直せばすぐ反映される/移行が軽い | Plugin/Mod |
| [ADR-20261121-0002](ADR-20261121-0002-claude-profile-overlay.md) | Claude Code の profile は、設定ディレクトリを分けず、起動時に設定と指示を重ねて切り替える | 採用 | 2026-11-21 | ログイン・履歴を分けない/profile ごとの保守がファイル数個/既定の起動は開発のまま | Profile/Settings |
