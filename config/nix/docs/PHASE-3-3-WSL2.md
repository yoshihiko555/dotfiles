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

### 着手時に必ず対応が要る既知の障害（2026-08-17 調査）

いずれも**実装を始めてから詰まる**箇所。作業手順 2 に入る前に方式を決めておく。

#### B1: 共通層の `homeDirectory` が macOS パス固定

`home/default.nix:9` が `home.homeDirectory = lib.mkForce "/Users/${hostSpec.username}"` と
なっており、**`mkForce` のため `hosts/wsl/` 側からの通常の上書きが効かない**。
WSL2 では `/home/<user>` が必要なため、共通層である `home/default.nix` 自体に手を入れる。

方式の候補:

- (a) `home/default.nix` で `pkgs.stdenv.isDarwin` により分岐する
- (b) `modules/hostSpec.nix` に `homeDirectory` オプションを追加し、各ホストが宣言する

**(b) を推す。** ADR-0004 の「共通層は薄く保ち、ホスト差分は hostSpec で表現する」方針に沿い、
macOS 2 台側の記述も明示的になる。

#### B2: `hostSpec` の受け渡しが nix-darwin の `config` に依存している

`flake.nix:84` の `extraSpecialArgs = { hostSpec = config.hostSpec; }` は
**nix-darwin システム設定の `config` から値を取っている**ため、standalone home-manager では
その `config` が存在せず成立しない。`homeConfigurations.wsl` では別方式が要る。

方式の候補:

- (a) `extraSpecialArgs` に `hostSpec` の値を直接渡す
- (b) `modules/hostSpec.nix` を home-manager モジュールとして直接 import し、home 設定側で完結させる

あわせて、**`hosts/hermes/` `hosts/macbook/` をそのまま雛形にはできない**点に注意する。
両者の `dotfiles.nix` は `home-manager.users.<user> = { ... }` という**入れ子**で書かれており、
これは `commonModules` が `home-manager.darwinModules.home-manager` を読み込んでいるために
成立している構文である。standalone にはこの入れ子先が無いため、
**`home/dotfiles.nix`（入れ子なしの平モジュール）の方が構造的に近い雛形**になる。
`hosts/wsl/default.nix` の「hostSpec + imports の目次」という形だけは
`hosts/macbook/default.nix` を踏襲してよい。

ADR-0004 は「WSL2（`hosts/wsl`）の内部構成の詳細は Phase 3-3 着手時に改訂する」（同 ADR 97 行目）
として、この点を意図的に未確定のまま残している。**方式を決めたら ADR-0004 を改訂すること。**

#### B3: standalone home-manager の switch コマンドが未文書化

`darwin-rebuild switch` に相当する**初回のブートストラップ呼び出しが
[BOOTSTRAP.md](BOOTSTRAP.md) / [CHEATSHEET.md](CHEATSHEET.md) のいずれにも無い**
（BOOTSTRAP.md は冒頭で「対象は macOS のみ」と明示しており、WSL2 を扱っていない）。

`home/default.nix:15` で `programs.home-manager.enable = true` を有効化しているため
2 回目以降は `home-manager switch` で足りると見込まれるが、
**初回コマンドはリポジトリ内に根拠が無い**。home-manager 公式ドキュメントで確認してから
手順化する。手順 5 で確定したら CHEATSHEET.md に Linux 用として追記する。

---

## 事前に判明している移植阻害要因

Nix 以前の問題として、現行 `shell/.zshrc` には Linux で壊れる箇所があった。
**これらの修正は Phase 3-0（着手前の前提作業）として 2026-07-30 に完了済み**
（コミット `ccf2639`。Nix と無関係に価値がある改善）。

| 箇所 | 問題 | 対応 | 状態 |
|---|---|---|---|
| `eval "$(sheldon source)"` | `command -v` ガードが無い | ガードを追加 | 済 |
| `eval "$(zoxide init zsh)"` | 同上 | ガードを追加 | 済 |
| `eval "$(git gtr init zsh)"` | 同上 | ガードを追加（`command -v git-gtr` で検出） | 済 |
| `eval "$(starship init zsh)"` | 同上 | ガードを追加 | 済 |
| `. "$HOME/.local/bin/env"` | 存在チェック無し | ガードを追加 | 済 |
| 各所の dotfiles 絶対パス | `$HOME/ghq/github.com/yoshihiko555/dotfiles` を直書き | `.zshenv` の `$DOTFILES` に集約 | 済 |
| `/Users/yoshihiko/.bun/_bun` | 絶対パスをハードコード | **見送り**。既に `[ -s ... ]` でガード済みで起動時エラーにならず、bun インストーラーの自動追記行のため書き換えても再追記されうる | — |
| `claude-mem` alias | 絶対パスをハードコード | **見送り**。alias 定義はパスを解決しないので起動時は無害。同じくインストーラー管理下 | — |
| `aliases.zsh` の `ls -G` | ~~BSD ls 専用~~ **誤り**。GNU coreutils にも `-G`（`--no-group`）があり Linux でもエラーにならない | 本フェーズで判断。色が付かず `ll` のグループ列が消えるだけの見た目の問題 | 保留 |
| `aliases.zsh` の `trend` / `daily` / `weekly` | Dia (macOS) 依存 | 本フェーズで判断。起動時は無害で実行時に `open` が無いだけ。**Windows 端末に Dia を入れる予定が無いなら対応不要** | 保留 |

`.zshrc` には既に `[[ -f ~/.zshrc.local ]] && source ~/.zshrc.local` の仕組みがあるため、
**ホスト固有の記述はここへ逃がす**のが基本方針。

なお `git gtr` は調査の結果 **Linux でも導入可能**だった。`coderabbitai/tap` の formula は
純シェル実装（`bin/git-gtr` + `lib` + `adapters`）で `depends_on :macos` が無い。
下記「作業手順」#3 の判断材料とする。

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

`flake.nix` は `config/nix/` にある（[ADR-20260424-0001](adr/ADR-20260424-0001-nix-layout.md)。
2026-08-14 のフラット化で `config/.config/nix/` から改名、[ADR-20260814-0006](adr/ADR-20260814-0006-flatten-repo-layout.md)）。
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
| `claude.zsh` / `cc-interrupt.zsh` | 要分岐 | Q1 で確定（2026-08-17、下記「保留事項」参照）。移植対象。`claude.zsh` は `HOMEBREW_PREFIX` 依存の除去が必要。`ccw` / `taktw` の会社アカウント切替部分は WSL2 では不要 |
| `takt.zsh` | **移植対象外** | Q1 で確定（2026-08-17）。WSL2 では takt を使わない |
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
| 1 | Nix インストール | [`NixOS/nix-installer`](https://github.com/NixOS/nix-installer)（macOS 2 台と同じ**素の Nix**。[BOOTSTRAP.md](BOOTSTRAP.md) / [ADR-20260802-0005](adr/ADR-20260802-0005-upstream-nix-migration.md) 参照）。**Determinate 系インストーラは使わない**（2026-01-01 に upstream Nix の選択肢が撤去され、必ず Determinate Nix が入るため）。`nix.conf` で `experimental-features = nix-command flakes` |
| 2 | flake へ WSL ホストを追加 | `hosts/wsl/` を新設し `homeConfigurations` を追加。**macOS 2 台は既に本実装済みのためプレースホルダ不要**。ADR-0004 のレイヤー構成（`darwin/` / `home/` / `hosts/<host>/`）に従う |
| 3 | `home.packages` を定義 | `hermes/Brewfile` の 18 個が出発点（`fd` `fzf` `gh` `ghq` `git` `lazygit` `neovim` `ripgrep` `starship` `tmux` `tree` `zoxide` `glow` `d2` `yazi` 等）。`git gtr` は Linux 対応を確認の上で判断 |
| 4 | `home.file` で配線 | starship / git / tmux / sheldon / `.zsh/*` を `mkOutOfStoreSymlink` でリンク |
| 5 | `home-manager switch` | 動作確認 |
| 6 | WSL2 固有設定 | クリップボード連携、`wsl.conf`（interop / PATH 抑制） |
| 7 | 記録 | ADR + ROADMAP を更新し、詰まった点を残す |

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。

---

## 保留事項（次回の会話で確定する）

- **Q1: WSL2 で AI CLI（Claude Code / Codex / takt / Gemini）を使うか**
  → **A1: 確定（2026-08-17）**。WSL2 で使う AI CLI は **Codex と Claude Code のみ**（両方ともインストール済み）。
  Claude Code は**会社アカウントのみ**を入れており、**個人／会社の切替を行う予定は無い**。
  - **`takt` / Gemini CLI は WSL2 では使わない**。`takt.zsh` は移植対象外
  - `ccw` / `taktw` による会社アカウント切替（`~/.claude-work`）は **WSL2 では移植不要**
  - `claude.zsh` / `cc-interrupt.zsh` は移植対象。ただし `claude.zsh` は `HOMEBREW_PREFIX` 依存が
    あるため Linux 向けのガードが要る
  - Codex / Claude Code は既に WSL2 上へ導入済みのため、Nix で宣言し直すか
    現状の導入方法（apt / npm 等）を残すかは手順 0 の調査結果を見て判断する

  AI CLI 関連の移植は **Phase 3-3 の初回スコープからは外し、後続の別タスクとして
  新規フェーズ番号を採番する**（Phase 3-1b は
  [PHASE-3-1B-HERMES-DAEMONS.md](PHASE-3-1B-HERMES-DAEMONS.md) で消費済みのため転用しない）。
  どちらの結論でも手戻りが出ない構成にしてある
- **Q2: WSL2 のパッケージ管理を Nix に寄せるか、apt と併用するか**
  → 手順 0 の調査結果を見て確定する。既定は「開発用 CLI は Nix、apt は OS 基盤のみ」
- **Q3: `git gtr` の Linux 対応可否**
  → 非対応なら WSL2 では `wt.zsh` 側の worktree ヘルパーで代替できるか検討する
