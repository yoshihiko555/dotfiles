# ~/.zsh/

`.zshrc` から切り出した設定ファイル群。すべて `source` で読み込まれる。

| ファイル | 内容 |
|---|---|
| `aliases.zsh` | エイリアス定義 |
| `functions.zsh` | 汎用関数 (lazygit, cheat, mdopen, mkcd, port, fh, fb, fkill, fe) |
| `tmux.zsh` | tmux 操作 (tss, tk, tp) |
| `docker.zsh` | Docker 操作 (dex, dcf) |
| `wt.zsh` | git worktree 操作 (wt) |
| `repo.zsh` | ghq + fzf リポジトリ移動 (repo) |
| `trust.zsh` | Codex trust 管理 (trust) |
| `cc-interrupt.zsh` | Claude Code 中断証跡ロガー (cc_interrupt) |
| `claude.zsh` | Claude Code 会社アカウント切替 (ccw) / CLIProxyAPI 切替 (ccx) |
| `takt.zsh` | takt 会社アカウント切替 (taktw) |
| `nix.zsh` | nix-darwin 反映コマンド (nxb, nxs, nxg 等) / hermes リモート反映 (hxb, hxs, hxg 等) |

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
