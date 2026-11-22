# tmux の設定

WezTerm を使うときのセッション・ウィンドウ・ペインを tmux で管理する。
Prefix は `Ctrl+Q`。`Prefix+.` で[キーバインドのチートシート](docs/CHEATSHEET.md)を開ける。
WezTerm の通常起動時は baton 用の `default` セッションに接続し、別セッションからは `Prefix+b` で戻れる。

## 設定の保守

| 変更したいもの | 見る場所 |
|---|---|
| 背景・フォント・Cmd キーの割り当て | [WezTerm の設定](../wezterm/README.md) |
| tmux のキー・表示・プラグイン | [tmux.conf](tmux.conf) が用途別に分けた [conf/](conf/) の設定を読み込む |
| プロジェクト選択・ペイン初期化など | [bin/](bin/) のシェルスクリプト。[スクリプト一覧](docs/SCRIPTS.md)に呼び出し元と用途を記載 |
| 設定変更後の確認 | [動作確認手順](docs/VERIFICATION.md) |

セッション操作を tmux に置くことで、SSH 先でも同じキーで作業できる。
ペインの移動・サイズ変更・コピーには vi 風のキーを使い、Neovim の分割と tmux のペインは
`Alt+h/j/k/l` で行き来できる。プロジェクト選択には fzf を使い、リポジトリと worktree をアイコンで見分ける。

配色は Tokyo Night Moon。WezTerm の背景を活かすためペインの背景色は `default` とし、
アクティブなペインは境界線で、操作モードはステータスバー左端のバッジで示す。

## 設計判断と移行記録

- [ADR 索引](docs/adr/DECISIONS.md) — tmux にセッション管理を集約した理由、Prefix の選定、smart-splits の採用など。
- [WezTerm からの移行記録](docs/MIGRATION.md) — 段階的に切り替えた経緯、移行時の手動確認結果、当時の保留事項。
