# 現行設定の動作確認メモ

現行の `config/.config/tmux/` 実装に対する確認観点。

- チェック状態は過去の手動確認メモを含む
- 今回のドキュメント更新では、説明文を現行実装に合わせて補正している

## 環境

- tmux: 3.6a
- 設定パス: `~/.config/tmux/tmux.conf`
- stow: worktree (tmux ブランチ) の config パッケージを適用中

## 基本設定 (general.conf)

- [x] True Color が正常に表示される
- [ ] マウス操作が有効
- [x] ウィンドウ番号が 1 から開始
- [x] ウィンドウ名が `#{pane_current_command}` で自動更新される

## キーバインド (keybinds.conf)

- [x] Prefix (Ctrl+T) が機能する
- [x] Prefix+r で横分割
- [x] Prefix+d で縦分割
- [x] Prefix+x でペイン閉じ
- [x] Prefix+z でペインズーム (スナップショット保存付き)
- [x] Prefix+h/j/k/l でペイン移動
- [x] Prefix+c で新しいウィンドウ
- [x] Prefix+n / Prefix+P でウィンドウ切替
- [x] Prefix+R で設定リロード + "Reloaded!" メッセージ

## ペインモード (pane-mode.conf)

- [x] Prefix+p でペインモードに入る (ステータスバーに PANE バッジ)
- [x] h/j/k/l でペイン移動 (Prefix 不要で連続操作)
- [x] r で横分割 / d で縦分割
- [x] x でペイン閉じ
- [x] 1-5 でペイン番号ジャンプ
- [x] e でリサイズモードに切替
- [x] Escape / Enter / q でモード終了

## リサイズモード (pane-mode.conf)

- [x] Prefix+e でリサイズモードに入る (ステータスバーに RESIZE バッジ)
- [x] h/j/k/l で 5 セル単位リサイズ
- [x] H/J/K/L で 1 セル単位リサイズ
- [x] Escape / Enter / q でモード終了

## コピーモード (copy-mode.conf)

- [x] Prefix+[ でコピーモード開始 (ステータスバーに COPY バッジ)
- [x] vi キーバインドでスクロール/検索
- [x] マウスドラッグで選択 → コピー (コピーモード維持)
- [x] 通常状態からのマウスドラッグで `copy-mode -M` に入れる
- [x] ドラッグ終了時に `copy-selection` のみ実行され、モードが維持される
- [x] Prefix+V でペインスナップショット表示

## smart-splits (smart-splits.conf)

- [ ] Alt+h/j/k/l でペイン移動 (Prefix 不要)
- [ ] Neovim 内では Neovim のペイン移動として動作

## display-popup (popup.conf)

- [x] Prefix+g で lazygit (80x80%)
- [x] Prefix+t で一時シェル (80x80%)
- [ ] Prefix+C で Claude Code (90x90%)
- [ ] Prefix+a で AI サブエージェント履歴 (90x90%)
- [ ] Prefix+A で AI 監視ペイン トグル
- [x] Prefix+s でセッション一覧 (fzf)

## ウィンドウ直通切替 (session.conf)

- [x] Alt+1-9 で N 番目のウィンドウに切替

## ステータスバー (statusbar.conf)

- [x] ステータスバーが上部に表示
- [x] 左側: モードバッジ (`COPY` / `PANE` / `RESIZE` / `PREFIX`)
- [x] 中央: tmux ネイティブのウィンドウ一覧
- [x] 右側: セッション名 + 日時
- [x] Powerline 風のウィンドウハイライトが適用される

## 見た目 (appearance.conf)

- [x] ペイン境界線が表示される
- [x] アクティブ / 非アクティブで境界線色が変わる
- [x] `pane-border-indicators colour` が効く
- [x] 非アクティブペインが明確に暗転する
- [x] コピーモードの選択ハイライトが見やすい
- [x] メッセージ表示の色が正常

## 課題・気づき

| # | 内容 | 重要度 | 対応 |
|---|------|--------|------|
| 1 | `.zshrc` での tmux 自動起動は WezTerm タブ追加/分割時に全て同じセッションに接続してしまう | 中 | `gui-startup` 方式に変更済み。将来的に tmux-first 運用に移行するか検討 |
| 2 | WezTerm が `Alt+h/j/k/l` を smart-splits 用に捕捉しており、tmux の smart-splits.conf が機能しない | 高 | Phase 6 で WezTerm の `split_nav` バインド (keybinds.lua L52-60) を削除して tmux にパススルー |
| 3 | `Alt+1-9` は現状ウィンドウ切替。セッションの direct switch は popup (`Prefix+s`) のみ | 中 | Phase 2 の sessionizer / kill-session 導入時に再設計 |

## 検討課題 (将来)

- **tmux 自動起動方式の最終決定**: `.zshrc` vs `gui-startup` vs tmux-continuum (Phase 3)
  - tmux-first で WezTerm のタブ/分割を完全に使わない運用にするなら `.zshrc` で OK
  - 併用するなら `gui-startup` が安全
  - tmux-continuum にはターミナルアプリ別の自動起動機能あり

- **セッション作成の仕様策定**
  - `default` セッションの役割が未定義
    - 汎用作業用？ダッシュボード (baton 等) 用？一時的なシェル用？
    - WezTerm の `gui-startup` が `tmux new-session -A -s default` で作成している
  - sessionizer で作成するセッションの初期レイアウト
    - Phase 4 の `tmux-init-panes` と関連 (ペイン数に応じて nvim/claude/codex を自動起動)
  - セッション復元のポリシー
    - Phase 3 の tmux-resurrect/continuum と関連
    - どこまで自動復元するか (ウィンドウ構成のみ？プロセスも？)
