# 意思決定ログ (DECISIONS)

takt の起動・設定に関する意思決定の一覧。詳細は各 ADR ファイルを参照。
領域をまたぐ決定は [docs/adr/](../../../docs/adr/DECISIONS.md) に置く。
書き方の規約は decision-log スキルの `references/GUIDELINE.md` に従う。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20261123-0001](ADR-20261123-0001-takt-account-select.md) | takt のアカウントは、起動時に Claude・Codex それぞれ個人か会社かを対話で選んで切り替える | 採用 | 2026-11-23 | Codex も会社と個人を切り替えたい/入口を 1 つにする/環境変数だけで切り替わる | Account/Launch |
