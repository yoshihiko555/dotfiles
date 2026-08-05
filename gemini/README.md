# Gemini / Antigravity CLI

Gemini CLI と Antigravity CLI（`agy`）の設定。stow で `~/.gemini` に配線する。

```bash
task link-gemini
```

## ファイル構成

| パス | 用途 |
|---|---|
| `.gemini/settings.json` | Gemini CLI 本体の設定 |
| `.gemini/AGENTS.md` | エージェント向けコンテキスト（`shared/agents/` から同期） |
| `.gemini/antigravity-cli/settings.json` | Antigravity CLI の設定（**下記の権限設計あり**） |
| `.gemini/antigravity-cli/keybindings.json` | Antigravity CLI のキーバインド |
| `.gemini/antigravity/mcp_config.json` | Antigravity の MCP サーバ定義 |
| `.gemini/config/skills/` | スキル群（`sync-skills` で配布） |

## Antigravity CLI の権限設計（2026-08-06 決定）

`agy -p`（ヘッドレス実行）でターミナルコマンドを使わせるための設定。
JSON にコメントを書けないため、意図と根拠をここに残す。

### 採用した方式: ブラックリスト + サンドボックス

```json
"toolPermission": "proceed-in-sandbox",
"permissions": { "allow": [], "deny": [ ... ] }
```

- `toolPermission: proceed-in-sandbox` … サンドボックス内であればコマンドを自動実行する
- `permissions.deny` … 危険なコマンドと秘密情報へのアクセスを**ハードブロック**する
- 実行時は **`--sandbox` を明示的に付ける**（付けないと自動実行されない。後述）

```bash
agy -p "..." --sandbox
```

### なぜホワイトリスト（allow）にしなかったか

当初は「読み取り系のコマンドだけ `permissions.allow` で許可する」方針だったが、
**1.1.8 / 1.1.11 のヘッドレスモードでは `permissions.allow` が機能しない**ことを実測で確認した。

| 設定 | ヘッドレスでの実際の挙動 |
|---|---|
| `permissions.allow` | **効かない**。`command(git status)` が読み込まれた状態でも `git status --short` が拒否される。`command(*)` でも同じ |
| `permissions.deny` | **効く**。「ユーザー定義の拒否ルールにより拒否されました」と応答が返る |
| `toolPermission: request-review`（デフォルト） | 全コマンドが soft-deny（出力ゼロで exit 0） |
| `toolPermission: proceed-in-sandbox` + `--sandbox` | **deny 以外の全コマンドが自動実行**される |

`allow` に無い `whoami` が `--sandbox` 付きで実行できたため、allow リストは参照されていない。
公式ドキュメントには `permissions.allow` で事前許可できると書かれており、CHANGELOG でも
1.1.4 で「headless が settings.json の permissions を尊重するようになった」とされているが、
実装が追いついていない（または回帰している）。

`allow` は**空配列のまま残す**。将来 allow が機能するようになった場合、空配列なら
全コマンドが Ask（＝ヘッドレスでは soft-deny）に戻り、気づける形で失敗するため。
効かない許可ルールを書き置くと「効いている」と誤認する（調査中に実際に誤認した）。

### deny の設計方針

`deny` は**対話モードにも効くハードブロック**（プロンプトすら出ない）。
そのため「取り返しがつかない」「外部に漏れる」「サンドボックスを抜ける」ものに絞っている。

| 分類 | 例 | 理由 |
|---|---|---|
| 権限昇格 | `sudo` `su` `doas` | サンドボックスの前提が崩れる |
| 破壊的操作 | `rm` `shred` `dd` `diskutil` `chmod` `chown` | 復旧できない。agy に消させる必要がない |
| サンドボックス脱出・任意コード実行 | `osascript` `open` `xargs` `eval` `nohup` `crontab` `at` `launchctl` | AppleScript や常駐化で制限を迂回できる。シェル本体は**入れられない**（後述） |
| 外部送信・取得 | `curl` `wget` `nc` `ssh` `scp` `rsync` | 情報漏洩とサプライチェーン |
| git / gh の公開・破壊系 | `git push` `git reset --hard` `git clean` `git config` `gh` | 外部公開と履歴破壊。`git config` はエイリアス経由の任意実行が可能 |
| 環境変更 | `brew` `nix` `darwin-rebuild` `npm install` `pip install` 等 | 宣言管理の外で環境が汚れる |
| 読み取りツールの exec 抜け穴 | `rg --pre` `fd -x` `fd --exec` | 読み取り系コマンドが任意実行に化ける |
| 秘密情報 | `~/.ssh` `~/.gnupg` `~/.aws` `~/.config/gh` `Library/Keychains` `antigravity-oauth-token` | 鍵と認証情報 |

**マッチングは「空白区切りトークンごとのアンカー付き正規表現」**で、パターンより長いコマンドには
前方一致する。つまり `command(rm)` は `rm -rf x` にもマッチする。
正規表現グループ（`command(git (status|log))` 形式）が現行バージョンで解釈されるかは未検証のため、
**単純な前方一致の形で列挙している**。

優先順位は **Deny > Ask > Allow**。

### シェル系コマンドを deny してはいけない

`command(sh)` / `command(bash)` / `command(zsh)` / `command(env)` を deny に入れると、
**サンドボックス実行そのものが成立しなくなり**、`git status` のような無害なコマンドまで

```
jetski: no output produced — a tool required the "unsandboxed" permission ...
```

で失敗する（2026-08-06 実測）。サンドボックス内でのコマンド実行がシェル経由で行われており、
シェルを塞ぐとサンドボックス経路が使えず `unsandboxed` へフォールバックするためと推測される。

そのため**シェル系は deny に入れていない**。任意コード実行の経路として残るが、
サンドボックスによる制限が最後の防御層になる。

> **未検証**: シェル系を除外した現在の deny 53 件の構成で、実際にコマンドが通るところまでは
> 未確認（2026-08-06 時点）。次の 1 コマンドで確認できる。
>
> ```bash
> agy -p "git status --short を実行して、変更されているファイルの数だけを数字で答えてください。" --sandbox
> ```
>
> 数字が返れば成功。`unsandboxed` を要求されたら、deny のどれかがまだサンドボックス経路を
> 塞いでいるので、`xargs` / `nohup` / `chmod` あたりを順に外して切り分ける。

### 既知の限界

- `find -exec` のようにオプション位置が可変なものは前方一致で塞ぎきれない
- deny の列挙漏れはそのまま穴になる（ホワイトリストではないため）
- サンドボックスは macOS では `sandbox-exec` によるファイルシステム制限とネットワーク制限。
  これが最後の防御層になっている

### 再検証の手順

`agy` を更新したら、`permissions.allow` が機能するようになったかを確認する。
機能していればホワイトリスト方式へ戻せる。

```bash
# allow に command(git status) だけを入れ、toolPermission を消した状態で
agy -p "git status --short を実行して、変更されているファイルの数だけを数字で答えてください。"
```

`jetski: no output produced` が出れば、まだ allow は効いていない。
設定が実際に読み込まれたかは以下で確認する（**編集した内容が届いているかを必ず確認すること**。後述の symlink 破壊で届かないことがある）。

```bash
grep -a "CLI settings initialized" "$(ls -t ~/.gemini/antigravity-cli/log/*.log | head -1)"
```

## settings.json の symlink 破壊問題

**Antigravity CLI は起動のたびに `~/.gemini/antigravity-cli/settings.json` を実ファイルとして
書き戻すため、stow の symlink が壊れる。**

当初は `trustedWorkspaces` 追記時に限る問題と考えていたが（コミット `ca7e49b` / `7189397`）、
2026-08-06 の調査で**追記が無くても `agy` を起動しただけで実体化する**ことを確認した。
このとき repo 側の編集は home 側に届かなくなり、気づかないまま古い設定で動き続ける
（実際に調査中、複数回のテストが古い設定のまま走っていた）。

`keybindings.json` も同じ挙動をする既知ファイル。

### 暫定の復旧

```bash
task restow-gemini-adopt   # home の内容を repo に取り込んでリンクを張り直す
```

### 恒久対策: mozumasu 方式の適用を検討する

symlink 配線をやめ、**repo の JSON を正とし、`home.activation` で書き込み可能な実ファイルとして
生成する**方式へ移行する。同時に参照コピー（`.nix-managed`）を保存し、アプリの UI 書き込みによる
drift を検知して、drift がある間は switch が上書きを拒否する（警告方式。どちらの変更も消えない）。

これは Claude Code の `settings.json` と同じ対策で、
「stow を段階移行で廃止し home-manager に一本化する」タスクの **Phase C** に含まれる。
agy はフック機構を持たないため、Claude Code のような Stop hook による即時検知は組めず、
**switch 時チェック止まり**になる。

実装参照:
[claude-code.nix](https://github.com/mozumasu/dotfiles/blob/main/.config/nix/home-manager/claude-code.nix)

なお `agy` は起動のたびに書き戻すため、Claude Code より drift の発生頻度が高い。
Phase C ではこのファイルを**除外リストの必須対象**として扱う。
