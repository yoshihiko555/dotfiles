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

### github-repo

GitHub のリポジトリを検索してブラウザで開くワークフロー。

**キーワード:** `gh`

**使い方:**
1. Alfred で `gh` と入力すると、リポジトリが最終 push 順に並ぶ
2. `gh dotfiles` のようにリポジトリ名・オーナー名で絞り込む
3. 選択すると GitHub のリポジトリページがブラウザで開く

**動作:**

- 対象は gh CLI の認証ユーザーがアクセスできる全リポジトリ
  （`/user/repos` の `owner,collaborator,organization_member`）
- 絞り込みは Alfred 側で行う（`alfredfiltersresults`）。
  スクリプトはキーワード起動時に一度だけ走り、打鍵ごとには走らない
- 一覧は 10 分キャッシュする（`alfred_workflow_cache`）。取得に失敗した場合は
  期限切れキャッシュで代替する
- private / archived / fork はサブタイトルにバッジで表示する

**依存:** `gh`（Nix 管理）。事前に `gh auth login` を済ませておくこと。

**秘匿情報の扱い:**

認証は gh CLI の keyring を使うため、ワークフロー側にトークンを保存しない。
`prefs.plist` も生成されない。

> Alfred の Script Filter は最小 PATH で起動するため、`gh` は絶対パス候補
> （Nix profile / Homebrew / `/usr/local`）から探す。見つからない環境では
> Configure Workflow の `GH_BIN` に絶対パスを設定する。

### dia-chat

Dia の AI チャットを新規に開き、そのまま質問を送るワークフロー。

**キーワード:** `dia`

**使い方:**
1. Alfred で `dia 質問文` と入力
2. Dia が前面に出て新規チャットが開き、質問がそのまま送信される

**動作:**

- Dia には prompt を渡す URL スキームが無い（`dia://assistant/<UUID>` は
  既存会話の参照のみで、新規チャットを作る入口ではない）。
  そのため AppleScript の UI 操作で入力する
- 手順は「新規タブを開く → 検索バーに質問を貼り付け → `ctrl+cmd+Enter`」。
  直前に見ていたページを文脈に含めない「まっさらなチャット」にするため、
  先に新規タブを開いている
- **素の Enter は Google 検索になる。** Dia の検索バーは候補に
  `… — Google`（`shift+cmd+Enter`）と `… — Chat`（`ctrl+cmd+Enter`）を出すので、
  チャット側のショートカットを明示的に叩く
- 質問文はクリップボード経由で貼り付ける。`keystroke` で直接打つと
  日本語が IME を経由して壊れるため。実行後に元のクリップボードへ戻す
- Dia が前面になるまで待ってからキー入力する。待たないと未起動時や
  別アプリ作業中にキー入力が他アプリへ飛ぶ
- File メニューの `Chat…` / `New Chat` は使わない。`Chat…` はトグルで
  状態に依存し、`New Chat` はチャットを開いている時しかメニューに現れない

**依存:** Alfred にアクセシビリティ権限（システム設定 > プライバシーとセキュリティ >
アクセシビリティ）。未許可だとメニュー操作とキー入力が失敗する。

### free-slots

カレンダーの予定から稼働時間内の空き時間を洗い出し、日程調整に貼れる形でコピーする
ワークフロー。

**キーワード:** `free`

**使い方:**
1. Alfred で `free` と入力すると、今日から 7 日間の空き枠が並ぶ
2. 先頭の `全部コピー` を選ぶと全日分の整形済みテキストがクリップボードへ入る
3. 個別の枠を選ぶと、その 1 枠だけがコピーされる

**引数:**

| 入力 | 対象期間 |
|---|---|
| （空欄） | 今日から `DEFAULT_DAYS` 日間 |
| `9/20` / `9-20` | 今年の 9/20 のみ（過ぎていれば翌年） |
| `20` | 当月 20 日のみ（過ぎていれば翌月） |
| `2026-09-20` | その日のみ |
| `14d` | 今日から 14 日間 |

**コピーされる形式:**

```
9/17(木) 10:00-12:00 / 13:00-19:00
9/18(金) 10:00-12:00 / 13:00-19:00
9/19(土) 10:00-19:00
```

**動作:**

- Notion Calendar には公開 API が無いため、**macOS の Calendar.app 経由**で読む。
  Calendar.app に登録済みの Google / Exchange(Office365) / iCloud のアカウントを
  EventKit でまとめて扱えるので、プロバイダごとに OAuth を組む必要がない
- 実装は JXA（`osascript -l JavaScript`）。Alfred の Script Filter は最小 PATH で
  起動するため、`/usr/bin/osascript` だけで完結する言語を選んでいる
- **JXA は ObjC の enum を文字列で返す。** `availability` や `participantStatus` を
  `===` で数値と比較すると常に偽になり、全予定がすり抜けて「全部空き」になる。
  比較前に `Number()` で数値化すること
- `EKAuthorizationStatusFullAccess` は JXA のブリッジに存在しないため、数値 `3` で持つ
- 埋まっている判定から外すもの: 終日の予定（設定で変更可）、`availability` が
  `free` の予定（祝日・誕生日）、キャンセル済み、自分が「不参加」で返答した予定
- 重複する予定は区間マージで吸収される（connpass と Google カレンダーに同じ勉強会が
  入っていても二重に数えない）
- 今日の枠は稼働開始ではなく **現在時刻を 15 分単位で切り上げた時刻**から始まる

**設定（Configure Workflow）:**

| 変数 | 既定値 | 内容 |
|---|---|---|
| `WORK_START` | `10:00` | 稼働開始 |
| `WORK_END` | `19:00` | 稼働終了 |
| `MIN_SLOT_MIN` | `30` | これ未満の細切れな空きは出さない（分） |
| `DEFAULT_DAYS` | `7` | 引数なしで見る日数 |
| `EXCLUDE_CALENDARS` | `日本の祝日,日本の休日,誕生日,connpass参加イベント,Google` | 埋まり判定に使わないカレンダー名 |
| `SKIP_ALLDAY` | オン | 終日の予定を無視して空き扱いにする |
| `SKIP_WEEKENDS` | オフ | 土日を対象から外す |

> `EXCLUDE_CALENDARS` はカレンダー名で照合する。同名のカレンダーが複数アカウントに
> ある場合（`日本の祝日` など）はまとめて除外される。

**依存:** Alfred にカレンダーへのアクセス許可（システム設定 > プライバシーとセキュリティ >
カレンダー）。初回実行時にダイアログが出る。未許可のまま実行すると、空き一覧の代わりに
許可を促すメッセージが表示される。

**前提:** Calendar.app 側でアカウントのカレンダーが有効になっていること。
Notion Calendar に繋いでいても Calendar.app 側で無効だと EventKit からは見えず、
埋まっているはずの時間が空きとして出てしまう。

### format

クリップボードのテキストを各種フォーマットへ変換するワークフロー。

**キーワード:** `fmt`

**使い方:**
1. 変換したいテキストをコピー
2. Alfred で `fmt` と入力
3. 適用できる変換だけが一覧に出る（サブタイトルに変換結果のプレビュー）
4. 選択すると変換結果がクリップボードに入る

**対応する変換:**

| 名前 | 内容 |
| --- | --- |
| `json-pretty` | JSON を整形（インデント 2） |
| `json-minify` | JSON を 1 行化 |
| `json-sort` | JSON を整形してキーをソート |
| `jwt-decode` | JWT の header / payload をデコード |
| `xml-pretty` | XML を整形 |
| `xml-minify` | XML を 1 行化 |
| `base64-encode` / `base64-decode` | Base64 変換 |
| `url-encode` / `url-decode` | パーセントエンコード変換 |

**実装:**

- 変換ロジックは `alfred/format/fmt.py` に集約。Script Filter が `fmt.py list`、
  アクションが `fmt.py apply <名前>` を呼ぶ。
- 実行時のクリップボードを対象にするため、アクション側で再度 `pbpaste` から変換する
  （候補列挙時の結果を `arg` で引き回すと巨大な JSON で切り詰められるため）。
- 依存を増やさないよう **Python 標準ライブラリのみ**で実装し、`/usr/bin/python3`
  （macOS 同梱）を明示的に使う。Alfred の PATH には Nix / mise の python が入らない。
- 日本語が `\uXXXX` にならないよう JSON 出力は `ensure_ascii=False` 固定。
- JWT は署名を検証しない（デコード表示のみ）。
- 変換結果が入力と同じになるものは候補から除外する。
- テスト時は `FMT_INPUT` 環境変数で入力を差し替えられる（クリップボードを壊さない）。

  ```bash
  FMT_INPUT='{"a":1}' /usr/bin/python3 alfred/format/fmt.py list
  ```

**YAML / SQL 非対応:** どちらも標準ライブラリに無く、対応するには Nix 側へ
`pyyaml` / `sqlparse` の追加が必要なため今回は見送り。

### cleaning

Notion の清掃DB（`C L E A N I N G`）から、次にやるべき清掃を一覧するワークフロー。

**キーワード:** `clean`

**使い方:**
1. Alfred で `clean` と入力すると、未着手・進行中のエリアが
   次回清掃予定日の早い順に並ぶ
2. 続けて文字を打つとエリア名・清掃箇所で絞り込める
3. **表示専用。** 選択しても何も起きない（全項目 `valid: false`）

**表示内容:**

| 位置 | 内容 |
|---|---|
| タイトル | エリア名 ＋ `あと3日` / `今日` / `2日超過`（超過は先頭に `●`） |
| サブタイトル | 清掃箇所 ／ 最終清掃完了日 ／ ステータス |

**動作:**

- 次回清掃予定日は Notion 側の formula。API では **`2026年09月11日` という
  文字列**で返ってくる（date 型ではない）ため、和暦表記と ISO 形式の両方を
  パースする。どちらでも読めなければ「清掃完了日 + 清掃間隔(週)」で代替計算する
- 並び替えは formula 相手だと API 側が弾く場合があるためローカルで行う
  （予定日なしは末尾）
- `alfredfiltersresults` を有効にしているため、スクリプトは1回だけ走り
  以降の絞り込みは Alfred 側で行う。キャッシュは持たない（Notion で
  完了にした直後に開き直したとき古い行が出ないようにするため）

**Notion 側の前提:**

- 清掃DB を Integration（`Alfred API`）に共有しておく。
  未共有だと `object_not_found` で 404 になる

**秘匿情報の扱い:**

fast-notion と同様、Token は `info.plist` に置かず Alfred の
Workflow Configuration で設定する（`prefs.plist` は `.gitignore` 済み）。
**prefs.plist はワークフローごとに独立**しているため、fast-notion で
設定済みでも本ワークフローには改めて入力が必要。

### stock-add

Notion の欲しいものリスト（`W I S H - L I S T`）から、優先度=高 の在庫を補充するワークフロー。

**キーワード:** `stock`

**使い方:**
1. Alfred で `stock` と入力すると、優先度=高 の商品が一覧表示される
2. 補充した商品を選択すると在庫が加算される
3. `stock 洗濯` のように商品名・カテゴリで絞り込める

**対象:**

`購入状況=再購入` かつ `発注点≠0` かつ `優先度=高`。
Notion のビュー「在庫管理（取扱中）」に `優先度=高` を足した条件と一致する
（`発注点` 未設定の行も `does_not_equal 0` に該当し、ビューと同じ結果になる。2026-09-15 実測）。

**動作:**

Notion の `在庫追加` ボタン（button プロパティ）と同じ処理を Notion API で再現する。

1. `S T O C K - R E P L E N I S H` に `{商品名, 購入日=今日}` を作成
2. `W I S H - L I S T` を更新（`実在庫 += 入数` / `優先度=低` / `_在庫履歴` に追記）

> **button プロパティは API から押すことも読むこともできない。**
> このため本家ボタンの内容を再現している。ボタン本体は 1. の部分を
> GAS の Webhook（`stockRelation`）へ投げているが、当ワークフローは
> Webhook を経由せず Notion API へ直接書き込む。
> 本家の実装は `yoshihiko555/google-apps-scripts` の
> `apps/notion/Db/inventory.js` にある。

**壊れやすい点:**

- `_在庫履歴` は**一方向リレーション**なので、商品ページ側を PATCH するしかない。
  PATCH はリレーション配列を**置換**するため、既存 ID を読んで追記して書き戻している
- ページ取得のリレーションは 25 件で打ち切られる（`has_more`）。
  打ち切られたまま書き戻すと履歴が消えるので、その場合は
  `GET /pages/{id}/properties/{prop_id}` でページングして全件取得する
- 補充後は `優先度=低` になり一覧から外れるため、実行時にキャッシュを削除する
- 一覧は 10 分キャッシュする（`alfred_workflow_cache`）

**Notion 側の前提:**

- Integration に **`W I S H - L I S T` と `S T O C K - R E P L E N I S H` の両方**を
  共有しておく。在庫履歴DB が未共有だと履歴ページを作れないうえ、
  `_在庫履歴` リレーションが**空で返る**（＝書き戻しで既存履歴が消える）。
  破壊的な更新に入る前に在庫履歴DB へアクセスできるか検査して中断している

**秘匿情報の扱い:**

| 値 | 置き場所 |
|---|---|
| `TOKEN` | Alfred の Configure Workflow（`prefs.plist` に保存。`.gitignore` 済み） |
| `WISHLIST_DB_ID` / `STOCK_DB_ID` | `info.plist` の `variables`（ID のみで秘匿情報ではない） |

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
├── github-repo/
│   ├── info.plist
│   └── .uuid
├── dia-chat/
│   ├── info.plist
│   ├── icon.png
│   └── .uuid
├── free-slots/
│   ├── info.plist
│   ├── icon.png
│   └── .uuid
├── format/
│   ├── info.plist
│   ├── fmt.py
│   └── .uuid
├── cleaning/
│   ├── info.plist
│   ├── icon.png
│   ├── prefs.plist   # Alfred が生成（TOKEN 保管、.gitignore）
│   └── .uuid
├── stock-add/
│   ├── info.plist
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
