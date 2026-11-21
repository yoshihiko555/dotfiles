# ~/.zsh/

`.zshrc` から切り出した設定ファイル群。すべて `source` で読み込まれる。

| ファイル | 内容 |
|---|---|
| `aliases.zsh` | エイリアス定義 |
| `functions.zsh` | 汎用関数 (lazygit, cheat, mdopen, mde, mkcd, port, fh, fb, fkill, fe) |
| `tmux.zsh` | tmux 操作 (tss, tk, tp) |
| `docker.zsh` | Docker 操作 (dex, dcf) |
| `wt.zsh` | git worktree 操作 (wt) |
| `repo.zsh` | ghq + fzf リポジトリ移動 (repo) |
| `trust.zsh` | Codex trust 管理 (trust) |
| `cc-interrupt.zsh` | Claude Code 中断証跡ロガー (cc_interrupt) |
| `claude.zsh` | Claude Code 会社アカウント切替 (ccw) / CLIProxyAPI 切替 (ccx) |
| `codex.zsh` | Codex CLI 会社アカウント切替 (cxw) |
| `ccusage.zsh` | Claude Code・Codex の使用量を個人と仕事のアカウント別に表示 (ccu) |
| `takt.zsh` | takt 会社アカウント切替 (taktw) |
| `nix.zsh` | nix-darwin 反映コマンド (nxb, nxs, nxg 等) / Homebrew 更新 (bxu) / hermes リモート反映 (hxb, hxs, hxg 等) |
| `screenpipe.zsh` | screenpipe の一時停止 / 再開 / 状態確認 / 実体の復旧 (spoff, spon, sps, spfix) |
| `herdr.zsh` | herdr-automatic-rename のシェルフック（コマンド実行でタブ名を追従） |
| `terminal-browser.zsh` | terminal-browser の起動ショートカット (tb) |
| `prompt-marks.zsh` | OSC 133 の semantic prompt マーク（Ctrl+L でスクロールバックを失わない） |

## Codex の会社アカウント (`cxw`)

dotfiles で `task codex-work-init` を実行し、新しいターミナルで `cxw login` から会社アカウントにログインする。
既存のターミナルでは `source ~/.zsh/codex.zsh` で読み込める。

- 個人用は `codex` / `cx`、会社用は `cxw`。会社用の保存先は `~/.codex-work`（`CODEX_WORK_HOME` で変更可能）。
- 会社用の `config.toml` は dotfiles の `codex-work/config.toml` へリンクする。設定変更はそのまま Git の差分になる。
- `cxw login status` で認証方式を確認し、起動後の `/status` でアカウントを確認する。
- `cxw` も `aliases.zsh` の `codex` 関数を使い、Herdr 用の環境変数調整と nice を引き継ぐ。
- 親シェルの API キー・アクセストークン・workload identity・SQLite 保存先の指定は、会社用の起動時だけ解除する。
- 共通スキルを追加・削除したら `task codex-work-init` を再実行する。既存の会社用設定・認証・履歴は保持する。

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
# => どちらも git gtr rm ... --delete-branch
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
- `wt rm` / `wt done` は常に `--delete-branch` を付けます。
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
> `wt` / `gtr` の管理対象外です。詳細は [takt/README.md](../../takt/README.md) を参照。
