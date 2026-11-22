# zsh の自作コマンドと補助スクリプト

端末でよく使うコマンドの早見表を開くには、`cheat` を実行する。

`~/.zsh/` に配置するファイルの一覧。通常の関数とエイリアスは対話時に `.zshrc` が読み込む。
略語は sheldon が遅延読み込みし、プレビュー用スクリプトは fzf が必要なときに実行する。
起動ファイルの役割と読み込み順は [zsh の起動設定](../README.md)（手元では `$DOTFILES/shell/README.md`）を参照。

| ファイル | 内容 |
|---|---|
| `aliases.zsh` | エイリアス定義 |
| `abbreviations.zsh` | 略語（zsh-abbr）の宣言。zshrc ではなく sheldon が zsh-abbr の後に遅延で読む（gs, gd, dc 等） |
| `functions.zsh` | 早見表（`cheat`）、[Yazi の終了場所へ移動](../../config/yazi/README.md)（`y`）、Homebrew の一括更新（`brewup`）、その他の汎用関数（lazygit, mdopen, mde, mkcd, port, fh, fb, fkill, fe） |
| `tmux.zsh` | tmux 操作 (tss, tk, tp) |
| `docker.zsh` | Docker 操作 (dex, dcf) |
| `wt.zsh` | git worktree 操作 (wt) |
| `repo.zsh` | `repo` で ghq のリポジトリと `.worktrees/` 直下のディレクトリから移動先を fzf で選ぶ |
| `trust.zsh` | Codex trust 管理 (trust) |
| `cc-interrupt.zsh` | Claude Code 中断証跡ロガー (cc_interrupt) |
| `claude.zsh` | Claude Code の会社アカウント（`ccw`）、プロファイル起動（`ccp`）、[CLIProxyAPI 経由の起動](../../shared/cliproxyapi/README.md)（`ccx` / `ccx -f`）、サブエージェントへの委譲（`ccf`）、[claude-swap の認証更新](../../config/nix/docs/CLAUDE-SWAP.md#認証の更新)（`cswap-relogin`） |
| `codex.zsh` | Codex CLI 会社アカウント切替 (cxw) |
| `ccusage.zsh` | Claude Code・Codex の使用量を個人と仕事のアカウント別に表示 (ccu) |
| `takt.zsh` | takt のアカウントを選んで起動 (takts) |
| `nix.zsh` | nix-darwin 反映コマンド (nxb, nxs, nxg 等) / Homebrew 更新 (bxu) / hermes リモート反映 (hxb, hxs, hxg 等) |
| `screenpipe.zsh` | screenpipe の一時停止 / 再開 / 状態確認 / 実体の復旧 (spoff, spon, sps, spfix) |
| `awake.zsh` | macOS のアイドルスリープ防止と解除 (awake) |
| `herdr.zsh` | herdr-automatic-rename のシェルフック（コマンド実行でタブ名を追従） |
| `terminal-browser.zsh` | terminal-browser の起動ショートカット (tb) |
| `prompt-marks.zsh` | OSC 133 の semantic prompt マーク（Ctrl+L でスクロールバックを失わない） |
| `fzf-preview.sh` | Ctrl+T、fzf-tab、`mdopen`、`mde`、`fe` の候補選択時に、ファイルの内容やディレクトリの一覧を表示 |

## Codex の会社アカウント (`cxw`)

個人用は `codex` / `cx`、会社用は `cxw` で起動する。初期設定・ログイン・スキルの同期は [Codex CLI の会社アカウント](../../codex-work/README.md) を参照。

- `cxw` も `aliases.zsh` の `codex` 関数を使い、Herdr 用の環境変数調整と nice を引き継ぐ。
- 親シェルの API キー・アクセストークン・workload identity・SQLite 保存先の指定は、会社用の起動時だけ解除する。

## アカウント別の使用量 (`ccu`)

[ccusage](https://github.com/ccusage/ccusage) の表を、次の順に見出しつきで 4 つ出す。
ccusage は複数のディレクトリを渡すと合算するため、1 つずつ渡して別々に集計する。

1. Claude Code・個人（`~/.claude`）
2. Claude Code・仕事（`CLAUDE_WORK_CONFIG_DIR`、既定 `~/.claude-work`）
3. Codex・個人（`~/.codex`）
4. Codex・仕事（`CODEX_WORK_HOME`、既定 `~/.codex-work`）

```sh
ccu                     # 今月だけ（monthly --last 1 --compact）
ccu daily --last 7      # 引数は ccusage claude / codex の後ろにそのまま渡す
ccu --breakdown         # 先頭がオプションなら monthly を補う（既定の --last 1 --compact は付かない）
ccu monthly --since 20261101 -z Asia/Tokyo
ccu help                # チートシート（-h / --help も同じ）
```

- ccusage 本体は Nix（`config/nix/home/packages.nix`）で入れる。
- 個人側は `CLAUDE_CONFIG_DIR` / `CODEX_HOME` を外して呼ぶ。Claude Code のセッション内から呼んでも仕事側の値に引きずられない。
- Codex に無いサブコマンド（`weekly` / `blocks` / `statusline`）では Codex の表を飛ばす。
- ディレクトリが無いアカウント（hermes の仕事側など）は 1 行出して飛ばす。
- 1 つが失敗しても残りは出し、最後に非 0 で終わる。
- `--offline` は既定で付けない。付けると内蔵の価格表だけになり、新しいモデルのコストが抜ける。外しても取りに行くのは価格表だけで、使用量は送らない。
- `--compact` で列が減るのは Claude の表だけ（キャッシュの列と合計トークンの列が隠れ、金額にはキャッシュ分が入ったまま）。Codex の表は全列のまま出る。

## Codex の trust 設定 (`trust`)

```sh
trust audit          # 登録されたパスの状態を確認
trust prune          # 存在しないパスの削除候補を表示（変更なし）
trust prune --apply  # 候補のプロジェクト設定をバックアップ付きで削除
```

- `prune` は実在するパスと symlink を残す。一時ディレクトリも存在していれば削除しない。
- パスそのものやファイルは削除せず、Codex 設定内の対応するプロジェクト項目だけを削除する。
- jq / taplo を使用し、対象外の設定が変わらないことを検証する。未対応の TOML 表記は書き込み前に停止する。
- バックアップは `~/.local/state/dotfiles/trust-backups/` に保存する。
  復旧時は表示された `.before` を設定の実体へ戻す（その後の変更まで戻るので事前に差分を確認する）。
- `CODEX_CONFIG_PATH` で対象設定、`TRUST_BACKUP_DIR` でバックアップ先を変更できる。
- 新しいターミナル、または `source "$DOTFILES/shell/zsh/trust.zsh"` で追加したサブコマンドを利用できる。

## 外出時のスリープ防止 (`awake`、macOS 専用)

`awake.zsh` の関数で macOS 標準の `caffeinate -i` を操作する。

```sh
awake on 4   # 今から4時間、アイドルスリープを防止（1〜168時間）
awake on     # 手動停止まで防止
awake status # このコマンドで起動した防止処理の状態（引数省略も同じ）
awake off    # このコマンドで起動した防止処理だけ解除
```

- 外出前に電源接続・蓋を開いた状態で開始し、画面をロックする。画面消灯は可能。
- launchd に一時的なジョブとして預けるのでターミナルを閉じても継続する。
- `on` を再実行すると指定時間をリセットする。ログアウト・再起動後は自動起動しない。
- 蓋を閉じる操作や明示的なスリープを防ぐものではない。
- `off` は他のアプリのスリープ防止を解除しない。全体の確認は `pmset -g assertions`。
- 再読み込みは `source ~/.zsh/awake.zsh`。新しいターミナルでは自動で読み込まれる。

## Worktree 補助コマンド (`wt`)

`git gtr` をそのまま使いつつ、よく使う作成・削除だけ `wt` で短縮する（`wt.zsh`）。

```bash
wt new nvim lsp
# => 例: task/nvim-lsp を自動生成して git gtr new

wt new fix hook tweak -- --from-current -e
# => ブランチ名は自動生成しつつ、gtr のオプションをそのまま渡す

wt rm
# => fzf で今の repo の worktree/branch を選んで削除

wt rm task/nvim-lsp --yes
wt done task/nvim-lsp --yes
# => どちらも確認を省いて worktree を削除。ブランチには既定の保持判定を適用

wt rm task/nvim-lsp --delete-branch
# => push していなくてもブランチを消す
```

基本形:

```bash
wt new [topic...]
wt new [topic...] -- [git gtr new options...]
wt rm <branch...> [git gtr rm options...]
wt rm [--yes|--force]
wt done <branch...> [git gtr rm options...]
wt <git gtr command...>
```

- `wt new` は既定で `task/<slug>` 形式のブランチ名を生成します。
- `topic` の先頭が `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`, `task` などの既知 prefix なら、その値をブランチ種別として使います。
- `topic` を省略した場合だけ `task/worktree-YYYYMMDD-HHMMSS` を使います。
- 同じブランチ名が既に存在する場合は `-2`, `-3` を末尾に付けて衝突を避けます。
- `wt new` で `git gtr new` のオプションも渡したい場合は、`--` 以降をそのまま `gtr` に渡します。
- `wt rm` と `wt done` は、worktree を削除するときにブランチを残すか判定します。削除対象以外のローカルブランチやリモート追跡ブランチから辿れないコミットがあれば、そのブランチを残します。それ以外はブランチも削除します。
- 例外として、設定済みの upstream が消えているブランチは、push 済みとみなして削除します。
- `--delete-branch` を明示すると、この判定を省いてブランチも削除します。すでに worktree を削除してブランチだけ残っている場合は、`git branch -D <branch>` で削除できます。
- `wt rm` を引数なしで実行すると、現在の repo の worktree 一覧を `fzf` で選択して削除できます。
- picker では現在いる worktree は候補から除外し、複数選択もできます。
- それ以外のサブコマンドは `wt list`, `wt cd`, `wt ai` のように `git gtr` へ透過的に委譲します。

よく使う例:

```bash
wt new
# => 例: task/worktree-20260329-143210

wt new codex trust
# => 例: task/codex-trust

wt new fix review -- --from-current -e
# => 例: fix/review
# => 現在のブランチから作成し、作成後に editor を開く

wt rm
# => fzf で削除対象を選ぶ

wt rm --yes
# => fzf で選んだ対象を確認なしで削除

wt list
wt cd
wt ai task/codex-trust
```

> takt が作る作業ディレクトリ（`.worktrees/`）は git worktree ではなく独立クローンのため、
> `wt` / `gtr` の管理対象外です。詳細は [takt の作業ディレクトリの配置](../../takt/README.md#作業ディレクトリの配置) を参照。
