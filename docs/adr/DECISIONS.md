# 意思決定ログ (DECISIONS)

dotfiles リポジトリ全体の意思決定のうち、**設定領域をまたぐもの**の一覧。詳細は各 ADR ファイルを参照。

領域内で完結する決定（例: Nix の内部構成、Neovim のプラグイン選定、tmux 単体の設定判断）は
この索引ではなく、各 `config/<領域>/docs/adr/` に置く
（例: [config/nix/docs/adr/](../../config/nix/docs/adr/DECISIONS.md)、
[config/nvim/docs/adr/](../../config/nvim/docs/adr/DECISIONS.md)）。
ここに置くのは、複数の領域にまたがる決定、またはリポジトリ全体の運用方針に関わる決定に限る。

| ID | タイトル | ステータス | 決定日 | 主な理由 | タグ |
|---|---|---|---|---|---|
| [ADR-20260922-0001](ADR-20260922-0001-herdr-migration-trial.md) | tmux + baton から herdr へ移行する（試用を経て採用） | 採用 | 2026-09-23 | 効率の伸び/承認待ち検知精度/操作数 | Terminal/Workflow |
