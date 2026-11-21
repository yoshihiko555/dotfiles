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
| [ADR-20260928-0006](ADR-20260928-0006-zsh-startup-tuning.md) | 対話 zsh を /bin/zsh に揃え、起動処理をキャッシュと遅延ロードで短縮する | 採用 | 2026-09-28 | 補完キャッシュの取り合い解消/外部コマンドの起動削減/安全な範囲だけ遅延 | Shell/Performance |
| [ADR-20261013-0007](ADR-20261013-0007-pi-harness-separate-repo.md) | pi の設定は dotfiles、拡張は専用リポジトリ pi-harness で管理する | 採用 | 2026-10-13 | 共通ルールの生成に乗る/拡張は Node プロジェクトとして完結/認証情報を配らない | Agent/Structure |
| [ADR-20261026-0008](ADR-20261026-0008-pi-settings-mutable-copy.md) | pi の settings.json を実ファイル + adopt 方式で管理し、端末固有の値は載せない | 採用 | 2026-10-26 | 端末 ID を公開しない/既存の apply・adopt に乗る/更新ごとに反映が止まらない | Agent/Nix |
| [ADR-20261119-0009](ADR-20261119-0009-agent-relay-skill.md) | 別エージェントへの引き継ぎ・並列依頼は agent-relay スキルが担い、herdr の操作は全 CLI に配る付属スキルに任せる | 採用 | 2026-11-19 | 再生成する付属スキルに手を入れない/コマンドの正典を 1 か所に/口頭の引き継ぎをなくす | Agent/Terminal |
| [ADR-20261119-0010](ADR-20261119-0010-external-skills-via-gh-skill.md) | GitHub で配布されている外部スキルは gh skill で共通スキルに取り込み、gh skill の更新機能で版を上げる | 採用 | 2026-11-19 | 全 CLI に既存のリンクで届く/出典と更新を gh skill に任せる/差分を読んでから取り込める | Agent/Skills |
| [ADR-20261121-0011](ADR-20261121-0011-zsh-prompt-stay-sync.md) | プロンプトは starship の同期描画のまま使い、Enter ごとの待ちを減らす変更は入れない | 採用 | 2026-11-21 | 普段の待ちは 30ms 前後/縮める手段は表示を失うか未成熟か保守が細い | Shell/Performance |
| [ADR-20261121-0012](ADR-20261121-0012-agent-rules-dev-split.md) | 開発向けの規則を共通の規則から別ファイルに分け、既定ではすべての CLI に読ませる | 採用 | 2026-11-21 | 除外はファイル単位/profile を通らない起動から規則を消さない/各 CLI の規則は変わらない | Agent/Context |
