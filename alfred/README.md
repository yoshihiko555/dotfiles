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

### post

コンテンツ投稿サイトを一括で開くワークフロー。

**キーワード:** `post`

**使い方:**
1. Alfredで `post` と入力
2. 全サイトが一括で開く

**登録サイト:**
- Adobe Firefly — AI画像生成
- Contentful — ヘッドレスCMS
- Zenn — 技術記事投稿
- Note — コンテンツ投稿
- YouTube Studio — 動画管理

## ディレクトリ構造

```
alfred/
├── post/
│   ├── info.plist
│   └── .uuid
├── Open-VS-or-IT/
│   ├── info.plist
│   ├── favorites.json
│   └── .uuid
└── README.md
```

## シンボリックリンク

各ワークフローの `.uuid` ファイルに記載された UUID を使い、`task link-alfred` で自動リンク。

```
~/Dropbox/.../workflows/user.workflow.<UUID>/
  → dotfiles/alfred/<workflow>/
```
