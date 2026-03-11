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

**動作 (wezモード):**
- WezTerm起動中: ワークスペースを作成して切替
- WezTerm未起動: WezTermを起動し、ワークスペースを作成
- ワークスペース名はディレクトリ名（basename）を使用

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
