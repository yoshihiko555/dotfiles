# Phase 1 動作検証

Phase 1 (設定ファイル分割 + XDG 移行) の動作確認チェックリスト。

## 環境

- tmux: 3.6a
- 設定パス: `~/.config/tmux/tmux.conf`
- stow: worktree (tmux ブランチ) の config パッケージを適用中

## 基本設定 (general.conf)

- [x] True Color が正常に表示される
- [ ] マウス操作が有効
- [ ] ウィンドウ番号が 1 から開始
- [ ] ウィンドウ名が自動でカレントディレクトリ名になる

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
- [ ] Prefix+V でペインスナップショット表示

## smart-splits (smart-splits.conf)

- [ ] Alt+h/j/k/l でペイン移動 (Prefix 不要)
- [ ] Neovim 内では Neovim のペイン移動として動作

## display-popup (popup.conf)

- [ ] Prefix+g で lazygit (80x80%)
- [ ] Prefix+t で一時シェル (80x80%)
- [ ] Prefix+C で Claude Code (90x90%)
- [ ] Prefix+a で AI サブエージェント履歴 (90x90%)
- [ ] Prefix+A で Claude 監視ペイン トグル
- [ ] Prefix+s でセッション一覧 (fzf)

## セッション切替 (session.conf)

- [ ] Alt+1-9 で N 番目のセッションに切替

## ステータスバー (statusbar.conf)

- [ ] ステータスバーが上部に表示
- [ ] 左側: モードバッジ + セッションタブ
- [ ] 右側: プロセス名 | プロジェクト名 | 日時
- [ ] セッションタブのハイライト (アクティブ: シアン)

## 見た目 (appearance.conf)

- [ ] ペイン境界線が表示される
- [ ] 非アクティブペインが暗転する
- [ ] コピーモードの選択ハイライトが見やすい
- [ ] メッセージ表示の色が正常

## 課題・気づき

| # | 内容 | 重要度 | 対応 |
|---|------|--------|------|
| 1 | `.zshrc` での tmux 自動起動は WezTerm タブ追加/分割時に全て同じセッションに接続してしまう | 中 | `gui-startup` 方式に変更済み。将来的に tmux-first 運用に移行するか検討 |
| 2 | WezTerm が `Alt+h/j/k/l` を smart-splits 用に捕捉しており、tmux の smart-splits.conf が機能しない | 高 | Phase 6 で WezTerm の `split_nav` バインド (keybinds.lua L52-60) を削除して tmux にパススルー |

## 検討課題 (将来)

- **tmux 自動起動方式の最終決定**: `.zshrc` vs `gui-startup` vs tmux-continuum (Phase 3)
  - tmux-first で WezTerm のタブ/分割を完全に使わない運用にするなら `.zshrc` で OK
  - 併用するなら `gui-startup` が安全
  - tmux-continuum にはターミナルアプリ別の自動起動機能あり
