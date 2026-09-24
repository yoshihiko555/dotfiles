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
| [ADR-20260923-0002](ADR-20260923-0002-terminal-browser-element-to-agent.md) | ブラウザの要素を AI に渡す経路を terminal-browser に寄せる | 採用 | 2026-09-23 | 組み込み機能で足りる/ブラウザ切替が不要 | Browser/Workflow |
| [ADR-20260924-0003](ADR-20260924-0003-agent-notifications-to-herdr.md) | エージェントの完了・承認待ちの通知を herdr に一本化する | 採用 | 2026-09-24 | 二重通知の解消/herdr はフォーカスを見て抑止する | Terminal/Notification |
| [ADR-20260924-0004](ADR-20260924-0004-formatters-linters-via-nix.md) | フォーマッタ・リンタの基準版を Nix に集約する | 採用 | 2026-09-24 | CLI は Nix の境界どおり/エディタ・hook で同じ版を使う | Editor/Nix |
| [ADR-20260925-0005](ADR-20260925-0005-lsp-via-nix.md) | LSP サーバーを mason から Nix に移す | 採用 | 2026-09-25 | 版の固定と再現/Claude Code の LSP プラグインと共有 | Editor/Nix |
