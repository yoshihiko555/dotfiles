# Alfred Workflows

Alfred用のカスタムワークフロー集。

※ AlfredのSync機能でDropbox経由で同期しているため、Dropboxのワークフローディレクトリにシンボリックリンクを作成。

## セットアップ

```bash
task link-alfred
```

## ワークフロー一覧

### Open-VS-or-IT

お気に入りフォルダをVSCodeまたはWezTermで開くワークフロー。

**キーワード:** `fav`

**使い方:**
1. Alfredで `fav` と入力
2. お気に入りフォルダを選択
3. `vs` (VSCode) または `wez` (WezTerm) を選択

**wezモードの3分割レイアウト:**
```
┌──────┬──────┐
│      │  2   │
│  1   ├──────┤
│      │  3   │
└──────┴──────┘
```

**動作 (wezモード):**
- WezTerm起動中: 新しい3分割タブを作成
- WezTerm未起動: WezTermを起動し、3分割タブを作成

## ディレクトリ構造

```
alfred/
├── Open-VS-or-IT/
│   ├── info.plist
│   └── favorites.json
└── README.md
```

## シンボリックリンク

```
~/Dropbox/.../workflows/user.workflow.C9692AD7-...
  → dotfiles/alfred/Open-VS-or-IT
```
