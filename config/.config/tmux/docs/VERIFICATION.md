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
- [x] マウス操作が有効
- [x] ウィンドウ番号が 1 から開始
- [x] ウィンドウ名が `#{pane_current_command}` で自動更新される

## キーバインド (keybinds.conf)

- [x] Prefix (Ctrl+Q) が機能する
- [x] Prefix+r で横分割
- [x] Prefix+d で縦分割
- [x] Prefix+x でペイン閉じ
- [x] Prefix+z でペインズーム (スナップショット保存付き)
- [ ] Alt+; でペインズーム (Prefix 不要)
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

- [x] Alt+h/j/k/l でペイン移動 (Prefix 不要)
- [x] Neovim 内では Neovim のペイン移動として動作

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

## WezTerm → tmux 移行検証 (機能対比)

WezTerm バックアップ (`config/.config/wezterm.bak/`) と現行 tmux 設定を照合。

### ペインレイアウト分割 (Prefix+2~8)

- [ ] 新規ウィンドウ → Prefix+2 で左右2分割される
- [ ] 新規ウィンドウ → Prefix+3 で左1:右上下の3分割になる
- [ ] 新規ウィンドウ → Prefix+4 で2x2グリッドになる
- [ ] 既にペインがあるウィンドウでは拒否メッセージが出る

### ペイン初期化 (Prefix+0)

- [ ] 2ペイン: pane1=nvim, pane2=free で起動する
- [ ] 3ペイン: pane1=nvim, pane2=claude, pane3=free で起動する
- [ ] 4ペイン: pane1=claude, pane2=codex, pane3=free, pane4=free で起動する
- [ ] GHQ リポジトリ外では拒否メッセージが出る
- [ ] TUI プロセス実行中のペインがあると拒否される
- [ ] **既知バグ**: `tmux-init-panes` に `tmux-split-layout` と同じターゲット未指定バグあり (要修正)

### WezTerm Cmd→tmux 変換 (keybinds.lua)

- [ ] Cmd+1-8 でウィンドウ切替 (WezTerm が Alt+1-8 に変換)
- [ ] Cmd+T で新規ウィンドウ (Prefix+c に変換)
- [ ] Cmd+D でペイン横分割 (Prefix+r に変換)
- [ ] Cmd+Shift+D でペイン縦分割 (Prefix+d に変換)
- [ ] Cmd+W でペイン閉じ (Prefix+x に変換)

### セッション管理

- [ ] Prefix+f でプロジェクト picker が開く (WezTerm の Leader+f 相当)
- [ ] picker でリポジトリ選択 → セッション作成/切替される
- [ ] picker で worktree 選択 → `repo:branch` 形式のセッションになる
- [ ] Prefix+w でセッション一覧切替 (WezTerm の Leader+w 相当)
- [ ] Prefix+W でセッション削除 (WezTerm の Leader+W 相当)
- [ ] 現在のセッションと claude-* セッションは削除候補から除外される

### ポップアップ / オーバーレイ

- [ ] Prefix+g で lazygit が起動する (WezTerm の overlay_lazygit 相当)
- [ ] Prefix+t で一時シェルが開く (WezTerm の open_bottom_shell 相当)
- [ ] Prefix+C で Claude Code が開く
- [ ] Prefix+b で Claude Code pane ダッシュボードが開く
- [ ] Prefix+? でチートシート (fzf + glow) が開く

### smart-splits.nvim 連携

- [ ] Alt+h/j/k/l で tmux ペイン移動する (WezTerm を経由してパススルーされる)
- [ ] Neovim 内では Neovim の split 移動として動作する
- [ ] Alt+Shift+H/J/K/L でペインリサイズする

### プラグイン

- [ ] Prefix+F で tmux-fingers が起動する (WezTerm の QuickSelect 相当)
- [ ] URL/UUID/パス等にラベルが表示され、キーで選択・コピーできる
- [ ] コピーモードで `o` でブラウザを開く (tmux-open)
- [ ] コピーモードで `S` で Google 検索 (tmux-open)

### WezTerm 側で失われた機能 (意図的な削除 or 代替あり)

| WezTerm 機能 | 状態 | tmux 代替 |
|---|---|---|
| QuickSelect (Leader+/) | 削除 | tmux-fingers (Prefix+F) |
| yazi オーバーレイ (Leader+y) | 保留 | WezTerm クラッシュ問題あり |
| baton オーバーレイ (Leader+B) | 削除 | Claude Code pane ダッシュボード (Prefix+b) に置換 |
| ワークスペース復元 (Leader+r) | 保留 | tmux-resurrect (Phase 3 で検討) |
| Alfred 外部トリガー | 削除 | tmux-sessionizer で代替 |
| 画面クリア (Ctrl+L 拡張) | 削除 | tmux 標準のスクロールバック動作に依存 |
| Cmd+Click で URL を開く | 維持 | WezTerm 側で引き続き動作 |

## 課題・気づき

| # | 内容 | 重要度 | 対応 |
|---|------|--------|------|
| 1 | `.zshrc` での tmux 自動起動は WezTerm タブ追加/分割時に全て同じセッションに接続してしまう | 中 | `gui-startup` 方式に変更済み。tmux-first 運用で解消 |
| 2 | ~~WezTerm が `Alt+h/j/k/l` を smart-splits 用に捕捉~~ | ~~高~~ | **解決済み**: Phase 6 で WezTerm の `split_nav` を削除、tmux にパススルー |
| 3 | `Alt+1-9` は現状ウィンドウ切替。セッションの direct switch は popup (`Prefix+w`) のみ | 低 | 現行の運用で十分。必要になれば追加 |
| 4 | ~~claude-squad の detach キー衝突~~ | ~~高~~ | **解決済み**: claude-squad → claude-tmux に移行 (ADR-007) |
| 5 | ~~claude-squad の popup スタック問題~~ | ~~高~~ | **解決済み**: claude-squad 廃止 |
| 6 | `tmux-init-panes` に `tmux-split-layout` と同じターゲット未指定バグ | 高 | `list-panes` / `display-message -t` / `send-keys -t` / `select-pane -t` が全てターゲット未指定。`#{pane_id}` を渡す修正が必要 |
| 7 | Claude Code pane ダッシュボードの status 判定が一部 UI 変更に追従できない可能性 | 低 | 実ペイン末尾のパターン依存。必要なら判定語彙を追加 |

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
