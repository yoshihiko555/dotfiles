# Alfred Workflows

Alfred用のカスタムワークフロー集。

※ AlfredのSync機能でDropbox経由で同期しているため、Dropboxのワークフローディレクトリにシンボリックリンクを作成。

## セットアップ

```bash
sudo darwin-rebuild switch --flake ./config/nix#macbook
```

home-manager が Dropbox 配下のワークフローディレクトリへリンクする。

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

### audio-output

オーディオ出力デバイスを一覧から選んで切り替えるワークフロー。

**キーワード:** `audio`

**使い方:**
1. Alfredで `audio` と入力
2. 全出力デバイスが一覧表示される（現在の出力先は `✓` 付き）
3. 切り替えたいデバイスを選択

**依存:** `switchaudio-osx`（`SwitchAudioSource` コマンド / Nix 管理、`config/nix/hosts/macbook/packages.nix`）

> Proxy Audio Device は出力先選択を driver 内部に保持し CLI から切り替えられないため、
> macOS のデフォルト出力デバイスを直接切り替える `SwitchAudioSource` を採用。

### fast-notion

Notion のタスクDB（`T A S K`）へタスクを素早く追加するワークフロー。

**キーワード:** `fna`

**使い方:**
1. Alfred で `fna タスク名` と入力
2. 下にプロジェクト候補が並ぶので、紐づけたいものを選ぶ（`プロジェクトなしで追加` も先頭にある）
3. `fna タスク名 @cli` のように `@` 以降を書くとプロジェクトを絞り込める
   （プロジェクト名・カテゴリ・管理値が対象）

**動作:**

- タスクは `template_id` 経由で「タスクテンプレート」が適用される。
  アイコン（`checkmark-square`）・ステータス=`待ち`・GTD種別=`INBOX`・優先度=`低` が入る
- **テンプレートの適用は非同期。** 作成レスポンスにはまだ反映されていないため、
  レスポンスだけを見て「効いていない」と判断しないこと（2026-08-30 実測）
- プロジェクト一覧は 10 分キャッシュする（`alfred_workflow_cache`）。
  Script Filter は1打鍵ごとに走るため、キャッシュが無いと毎回 API を叩くことになる
- 取得に失敗した場合は期限切れキャッシュで代替する

**Notion 側の前提:**

- Integration に **タスクDB（`T A S K`）と PROJECT DB の両方**を共有しておく。
  PROJECT DB が未共有だと候補が取得できないうえ、TASK DB の
  `プロジェクト名` リレーションプロパティ自体が API から見えなくなる

**秘匿情報の扱い:**

当リポジトリは public なので、Notion Integration Token は info.plist に置かない。
Alfred の Workflow Configuration（ワークフロー右上の `[x]` ボタン）で設定する。

| 値 | 置き場所 |
|---|---|
| `TOKEN` | Alfred の Configure Workflow（`prefs.plist` に保存。`.gitignore` 済み） |
| `DATABASE_ID` / `PROJECT_DB_ID` / `TEMPLATE_ID` | `info.plist` の `variables`（ID のみで秘匿情報ではない） |

初回セットアップ時、または `prefs.plist` を失った場合は Configure Workflow で
トークンを再入力する。未設定のまま実行するとエラーメッセージが出る。

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
├── audio-output/
│   ├── info.plist
│   └── .uuid
├── fast-notion/
│   ├── info.plist
│   ├── icon.png
│   ├── prefs.plist   # Alfred が生成（TOKEN 保管、.gitignore）
│   └── .uuid
└── README.md
```

## シンボリックリンク

各ワークフローの `.uuid` ファイルに記載された UUID を使い、home-manager で宣言している。

```
~/Dropbox/.../workflows/user.workflow.<UUID>/
  → dotfiles/alfred/<workflow>/
```
