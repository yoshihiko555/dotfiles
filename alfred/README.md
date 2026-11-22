# Alfred ワークフロー

Alfred でキーワードを入力すると、自作ワークフローを呼び出せる。キーワードを思い出したいときは `wf` を使う。

| キーワード | 用途 | 手順 |
|---|---|---|
| `audio` | 音声の出力先を一覧から選んで切り替える | [出力デバイスの選択](#audio) |
| `clean` | Notion の清掃予定を期限順に確認する | [表示項目と DB の設定](docs/cleaning.md) |
| `ctr` | コンテナや Compose プロジェクトを操作する | [状態別の操作とシェルの開き方](docs/container.md) |
| `dia 質問文` | Dia の新規チャットに質問を送る | [操作と必要な権限](docs/dia-chat.md) |
| `fav` | ghq リポジトリやお気に入りのフォルダを VS Code・Zed・herdr で開く | [開き方とお気に入り設定](#fav) |
| `fmt` | コピーしたテキストを整形・変換してクリップボードに戻す | [対応する変換の一覧](docs/format.md) |
| `fna タスク名` | プロジェクトを選んで Notion にタスクを追加する | [入力例と初期設定](docs/fast-notion.md) |
| `free` | カレンダーの空き時間を日程調整用にコピーする | [期間指定と除外条件](docs/free-slots.md) |
| `gh` | GitHub リポジトリを検索しブラウザで開く | [検索と gh CLI の認証](docs/github-repo.md) |
| `post` | 投稿に使う 5 サイトを一括で開く | [登録サイト](#post) |
| `stock` | Notion の一覧から補充した商品を選び、在庫と履歴を更新する | [対象商品と DB の設定](docs/stock-add.md) |
| `tk` | プロジェクトとタスクを選んで go-task を実行する | [引数・実行方法・ログ](docs/taskfile.md) |
| `wf` | 自作ワークフローを検索し、そのキーワードで Alfred を開き直す | [一覧の使い方](#wf) |

## 共通セットアップ

MacBook で Alfred の設定を Dropbox に同期し、同期先に `Alfred.alfredpreferences/workflows/` があることを確認する。dotfiles のルートで次を実行する。

```sh
sudo darwin-rebuild switch --flake ./config/nix#macbook
```

Home Manager は `home.activation.alfredWorkflowLinks` の登録表から UUID と名前をリンク用スクリプトに渡す。各ワークフローのディレクトリにも同じ UUID を `.uuid` として記録している。[MacBook の登録表](../config/nix/hosts/macbook/dotfiles.nix)・[リンク処理](../scripts/alfred-workflow-links.sh)

- `switch` は Dropbox の `workflows/user.workflow.<UUID>` から dotfiles の `alfred/<名前>/` へのリンクを確認する。リンクが欠けていれば作成し、別の場所を指していれば張り替える。リンク先が一致していればそのまま使う。同名の実ファイルや実ディレクトリがあると処理は停止する。
- 登録表から削除した項目は、前回の適用記録を使って片付ける。削除対象は現在もこのリポジトリの `alfred/` 配下を指すリンクに限る。
- Dropbox の File Provider に書き込みを拒否されたら、Ghostty で `ls ~/Library/CloudStorage/Dropbox` を実行してアクセスを許可し、再度 `switch` する。許可ダイアログが出ない場合は `tccutil reset FileProviderDomain com.mitchellh.ghostty` で Ghostty の許可をリセットしてからやり直す。
- リンクを張り替えた後にワークフローが見えなければ、Alfred を再起動する。

## 短い操作手順

### audio

`audio` で出力デバイスを一覧し、切り替え先を選ぶ。現在の出力先には `✓` が付く。
Proxy Audio Device がドライバー内に持つ出力先は CLI から変更できないため、Nix 管理の `SwitchAudioSource`（switchaudio-osx）で macOS の既定出力を切り替える。[ワークフロー定義](audio-output/info.plist)

### fav

`fav` でフォルダを選び、`vs`（VS Code）、`zed`（Zed）、`wez`（Ghostty の herdr）から開き先を選ぶ。
`wez` はディレクトリ名をワークスペース名に使い、リポジトリのルートなら `herdr worktree open` で開く。herdr が起動していなければ先に Ghostty を起動する。候補の追加・除外・表示名は [favorites.json](Open-VS-or-IT/favorites.json) で設定する。

### post

`post` を実行すると Adobe Firefly、Contentful、Zenn、Note、YouTube Studio を一括で開く。[登録先の定義](post/info.plist)

### wf

`wf` に続けて入力すると候補が絞られる。選んで Enter を押すと、たとえば `fna ` が入力された状態で Alfred が開き直す。
一覧は毎回 `alfred/*/info.plist` の Keyword・Script Filter・List Filter から生成する。キーワードが空の項目、無効なワークフロー、`wf` 自身は除外する。説明にはワークフローの description を使い、空なら入力欄の subtext または title を使う。組み込みや外部ワークフローも調べるときは `?keywords` で選ぶと設定画面が開く。[一覧の実装](workflow-list/list.py)

## 外部ワークフローの設定メモ

リポジトリ管理外（Alfred Gallery からインストール）のワークフローのうち、
再セットアップ時に手で入れ直す必要がある設定を記録する。

### 1Password（by Vítor Galvão）

`Configure Workflow…` から修飾キーの動作を変更できる。デフォルトの `↩` は
「Open and Fill」で該当ページをブラウザで開いてしまうため、以下に組み替える。

| キー | 割り当て |
| --- | --- |
| `↩` | Copy Password |
| `⇧↩` | Copy One-Time Password |
| `⌥↩` | Copy Username |
| `⌘↩` | View in 1Password |
| `⌃↩` | Open and Fill |

**メモ:**

- 設定は Alfred がワークフローフォルダ内の `prefs.plist` に書き込む。Alfred 側が
  書き換えるファイルなので nix symlink 管理はせず、Dropbox 同期に任せる。
- 前提として 1Password アプリの 設定 → 開発者 → 「1Password CLI と連携」が必要。
  OFF だとワークフローが起動時のサニティチェックで停止する。
- パスワードのコピーは `org.nspasteboard.ConcealedType` を立てているため、
  対応するクリップボードマネージャの履歴には残らない。
- 任意のカスタムフィールドを選んでコピーする操作は用意されていない
  （割り当てられるのは上記 5 アクションのみ）。
