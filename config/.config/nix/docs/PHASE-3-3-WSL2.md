# Phase 3-3: WSL2 への home-manager 導入（作業計画）

会社支給 Windows の WSL2 に Nix + home-manager を導入する。
[ROADMAP](ROADMAP.md) の Phase 3-3、方針は
[ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)
（[ADR-20260729-0002](adr/ADR-20260729-0002-multi-host-adoption.md) を改訂）。

WSL2 側には dotfiles リポジトリをクローン済みで、参照可能な状態にある。

> **ステータス: 条件付き（実稼働待ち）**
>
> 本フェーズは当初 Phase 3-1（最初の着手対象）だったが、WSL2 が予備機であり
> 現状は稼働プロジェクトがなく日常的に使用していないことが判明したため、
> **最後（Phase 3-3）に変更した**。
>
> **着手トリガー**: 会社の業務プロジェクトが動き始め、WSL2 を日常的に使うようになったとき。
>
> 順序変更の理由（ADR-20260730-0003）:
> - 投資先が日常的に使わない端末になり、学習のフィードバックループが回らない
> - **Linux での学習は nix-darwin にほとんど転用されない**
>   （launchd / `homebrew.*` / system defaults はすべて darwin 固有）

## 設計の前提（調査で判明）

- WSL は **standalone home-manager** として構成する。nix-darwin 構成とは独立し、
  flake の出力が `darwinConfigurations` と `homeConfigurations` の **2 系統に割れる**
- **`targets.genericLinux.enable = true` が必須**（非 NixOS ディストリ向け統合）
- 実例: [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles) の `hosts/robusta/home.nix`
  が同一構成（Windows の WSL/Ubuntu 上の standalone home-manager）

---

## 事前に判明している移植阻害要因

Nix 以前の問題として、現行 `shell/.zshrc` には Linux で壊れる箇所がある。
**これらの修正は Phase 3-0（着手前の前提作業）として済ませる**
（Nix と無関係に価値がある改善。ROADMAP の Phase 3-0 にチェックリスト化してある）。

| 箇所 | 問題 | 対応 |
|---|---|---|
| `eval "$(sheldon source)"` | `command -v` ガードが無い | ガードを追加 |
| `eval "$(zoxide init zsh)"` | 同上 | ガードを追加 |
| `eval "$(git gtr init zsh)"` | 同上。かつ `coderabbitai/tap` の Homebrew 専用で **Linux 対応は要確認** | ガードを追加。Linux 非対応なら WSL2 では導入しない |
| `eval "$(starship init zsh)"` | 同上 | ガードを追加 |
| `/Users/yoshihiko/.bun/_bun` | 絶対パスをハードコード | `~/.zshrc.local` へ退避 |
| `claude-mem` alias | 絶対パスをハードコード | `~/.zshrc.local` へ退避 |
| `. "$HOME/.local/bin/env"` | 存在チェック無し | ガードを追加 |
| `aliases.zsh` の `ls -G` | BSD ls 専用 | `$OSTYPE` で分岐（GNU は `--color=auto`） |
| `aliases.zsh` の `trend` / `daily` / `weekly` | Dia (macOS) 依存 | `$OSTYPE` で分岐 |
| 各所の dotfiles 絶対パス | `$HOME/ghq/github.com/yoshihiko555/dotfiles` を直書き | 変数に集約 |

`.zshrc` には既に `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` の仕組みがあるため、
**ホスト固有の記述はここへ逃がす**のが基本方針。

---

## 設計方針

### D1: home-manager の役割を「パッケージ管理 + 配線」に限定する

**設定ファイルを Nix 言語で書き直さない。**
`home.file.<name>.source = config.lib.file.mkOutOfStoreSymlink "..."` を用い、
リポジトリ内の実ファイルへ live symlink を張る。

理由:

- `programs.zsh` 等へ書き直すと、既存の zsh 設定（900 行超）を Nix 化することになり学習コストが跳ね上がる
- `mkOutOfStoreSymlink` は **stow と同じ挙動**（編集が即反映され、`home-manager switch` が不要）
- 将来 `programs.*` へ寄せる場合も、ファイル単位で段階移行できる

WSL2 において Nix が担うのは次の 3 点に限る:

1. brew の代わり（パッケージ管理）
2. stow の代わり（シンボリックリンクの配線）
3. ホスト差分の宣言

### D2: flake は現在地のまま、pure eval の制約は D1 で回避する

`flake.nix` は `config/.config/nix/` にある（[ADR-20260424-0001](adr/ADR-20260424-0001-nix-layout.md)）。
リポジトリ上位の `shell/.zshrc` を相対パスで参照すると **flake root の外になり pure eval で弾かれる**。

D1 の `mkOutOfStoreSymlink` は文字列としてパスを扱うためこの制約を受けない。
**ADR-0001 の配置決定を変更する必要はない。**

### D3: OS 差分は zsh 側の分岐で表現し、Nix に持ち込みすぎない

Nix 側で表現するのは **パッケージ集合とリンク対象ファイル**まで。
シェル内部のロジック分岐（`ls -G` vs `ls --color=auto` 等）は zsh 側で `$OSTYPE` を使う。
その方が読みやすく、デバッグも容易。

---

## 移植対象の棚卸し

| 対象 | 分類 | 備考 |
|---|---|---|
| `.zshrc` の setopt / HISTORY | 共通 | そのまま移植可 |
| `aliases.zsh` | 要分岐 | `ls -G`、Dia 系 alias が macOS 依存 |
| `functions.zsh` | 要分岐 | `mdopen` は既に `xdg-open` fallback あり |
| `tmux.zsh` / `docker.zsh` / `wt.zsh` / `repo.zsh` | 共通 | dotfiles 絶対パスの変数化が望ましい |
| `trust.zsh` | 共通 | Codex trust 管理。リポジトリパスを直書き |
| `claude.zsh` / `takt.zsh` / `cc-interrupt.zsh` | **保留** | 下記「保留事項」の Q1 次第。`claude.zsh` は `HOMEBREW_PREFIX` 依存あり |
| `.zshenv` の `/opt/homebrew` | macOS 専用 | Linux では不要 |
| `.zprofile` の OrbStack | macOS 専用 | |
| aerospace / karabiner / wezterm / ghostty / zed | macOS 専用 | GUI |
| starship / git / tmux / sheldon / nvim の config | 共通 | そのままリンク可能 |
| mise | 共通 | ADR-0002 の方針どおり mise を残す |
| WSL2 固有 | 新規 | クリップボード（`win32yank` / `clip.exe`）、`wslview` によるブラウザ起動、`/mnt/c` の性能問題回避、systemd 有効化、Windows PATH 混入の抑制（`wsl.conf`） |

---

## 作業手順

| # | 作業 | 内容 |
|---|---|---|
| 0 | 現状調査 | ディストロ種別 / systemd の有効可否 / 既存 zsh 設定 / dotfiles クローン先 / `uname -m`（system 文字列の確定）/ 既存 apt パッケージ |
| 1 | Nix インストール | Determinate installer（macOS と同じ）。`nix.conf` で `experimental-features = nix-command flakes` |
| 2 | flake を multi-host 構造へ拡張 | `hosts/wsl.nix` + `home/common.nix` + `home/linux.nix` を新設。macOS 2 台分はプレースホルダで置く |
| 3 | `home.packages` を定義 | `hermes/Brewfile` の 18 個が出発点（`fd` `fzf` `gh` `ghq` `git` `lazygit` `neovim` `ripgrep` `starship` `tmux` `tree` `zoxide` `glow` `d2` `yazi` 等）。`git gtr` は Linux 対応を確認の上で判断 |
| 4 | `home.file` で配線 | starship / git / tmux / sheldon / `.zsh/*` を `mkOutOfStoreSymlink` でリンク |
| 5 | `home-manager switch` | 動作確認 |
| 6 | WSL2 固有設定 | クリップボード連携、`wsl.conf`（interop / PATH 抑制） |
| 7 | 記録 | ADR + ROADMAP を更新し、詰まった点を残す |

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。

---

## 保留事項（次回の会話で確定する）

- **Q1: WSL2 で AI CLI（Claude Code / Codex / takt / Gemini）を使うか**
  → `claude.zsh` / `takt.zsh` / `cc-interrupt.zsh` の移植可否と、会社アカウント切替（`ccw` / `taktw`、`~/.claude-work`）の扱いが変わる。
  現時点の設計では **Phase 3-1 の初回スコープから外し、Phase 3-1b として分離**する。
  どちらの結論でも手戻りが出ない構成にしてある
- **Q2: WSL2 のパッケージ管理を Nix に寄せるか、apt と併用するか**
  → 手順 0 の調査結果を見て確定する。既定は「開発用 CLI は Nix、apt は OS 基盤のみ」
- **Q3: `git gtr` の Linux 対応可否**
  → 非対応なら WSL2 では `wt.zsh` 側の worktree ヘルパーで代替できるか検討する
