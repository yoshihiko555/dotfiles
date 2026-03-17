# 設計思想

## コンセプト: tmux-first ターミナル環境

WezTerm の Lua カスタマイズに依存した環境から、tmux をセッション/ペイン管理の中心に据えた環境へ移行する。

### 目標

- **ターミナルエミュレータ非依存**: WezTerm, Alacritty, iTerm2 など、どのターミナルでも同じ操作体験を提供
- **tmux の中で生活する**: セッション管理、ペイン分割、コピーモード、ポップアップを全て tmux で完結
- **WezTerm は GUI レンダラーに限定**: 背景画像、透過、フォント、カラースキームのみ担当

### 設計原則

1. **モジュール分割**: 単一ファイルではなく、関心事ごとに conf ファイルを分離
2. **シェルスクリプト駆動**: Lua の代わりにシェルスクリプトで拡張。移植性と透明性を重視
3. **fzf 統合**: プロジェクト選択・セッション管理・コマンドパレットを fzf ベースで統一
4. **段階的移行**: WezTerm を壊さず、tmux ブランチで並行開発。ロールバック可能

### レイヤー構成

```
┌─────────────────────────────┐
│  WezTerm (GUI レンダラー)     │  背景画像, 透過, フォント
├─────────────────────────────┤
│  tmux (セッション管理)         │  セッション, ウィンドウ, ペイン, ステータスバー
├─────────────────────────────┤
│  シェルスクリプト (bin/)       │  statusbar 補助, pane snapshot, Claude 監視
├─────────────────────────────┤
│  Neovim / Claude Code / etc  │  エディタ, AI ツール
└─────────────────────────────┘
```

### WezTerm との機能対応

| WezTerm 機能 | tmux 移行先 |
|-------------|-------------|
| ワークスペース管理 | tmux セッション |
| プロジェクト picker (select_project) | tmux-sessionizer (fzf popup, repo/worktree アイコン付き) |
| ペイン分割/移動 | tmux pane + smart-splits |
| タブバー | tmux ステータスバー (中央ウィンドウ一覧 + 右側セッション名/日時) |
| コマンドパレット | tmux-command-menu (fzf popup) |
| QuickSelect | tmux-fingers プラグイン |
| セッション復元 | tmux-resurrect + tmux-continuum |
| overlay pane | tmux display-popup |
| Leader キー | tmux Prefix (`Ctrl+Q`) |

### 現在のステータスバー構成

- 左: モードバッジ (`COPY` / `PANE` / `RESIZE` / `PREFIX`)
- 中央: tmux ネイティブのウィンドウ一覧
- 右: セッション名 + 日時
- Powerline グリフは `tmux-apply-statusbar` が `window-status-format` を上書きして適用する

### プロジェクト picker の視覚デザイン

WezTerm の `select_project` が提供していた repo/worktree の視覚的区別を tmux-sessionizer でも再現する:

```
  ○ 🖥 repo-name           通常リポジトリ
  ● 🔀 repo-name:branch    worktree (親リポジトリ:ブランチ形式)
```

- `repo-list.sh` (既存の共有スクリプト) の TYPE フィールドでアイコンを分岐
- 現在アクティブなセッションには `(current)` マーカーを付与
- fzf の `--tmux` オプションで tmux popup 内にネイティブ表示

### モーダル操作

Vim の思想を踏襲し、tmux にもモード概念を導入:

- **Normal (root)**: 通常操作。Alt+hjkl でペイン移動 (smart-splits)
- **Pane mode (Prefix+p)**: ペイン操作に特化。hjkl 移動、r/d 分割、x 削除、数字でジャンプ
- **Resize mode (Prefix+e)**: リサイズに特化。hjkl で 5 セル、HJKL で 1 セル単位
- **Copy mode (Prefix+[)**: vi キーバインドでスクロール/コピー

### テーマ: Tokyo Night Moon

全ツール (Neovim, tmux, WezTerm, lazygit) で Tokyo Night Moon を統一使用。

主要カラー:
- 背景: `default` (WezTerm の透過を活用)
- 前景: `#c8d3f5`
- アクセント (青): `#82aaff`
- アクセント (シアン): `#3BC1A8`
- モード背景 (青紫): `#3654a7`
- 非アクティブ: `#828bb8`
- UI 背景: `#394270`, `#005461`

実装上の注意:
- ペイン背景は `bg=default` を維持し、WezTerm の背景画像と透過を殺さない
- アクティブ/非アクティブの差は主に境界線色 (`#82aaff` / `#394270`) とステータスバーで表現する
