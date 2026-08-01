# Nix 移行ロードマップ

dotfiles を段階的に Nix 管理へ寄せていくための計画。
Nix の学習度合いに合わせて、小さく動かしながら進める。

方針・目的の根拠は [ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)。

---

## 目的

| 優先 | 目的 |
|---|---|
| 1 | **環境依存の切り分けを宣言的に表現する**（ヘッドレスな hermes に GUI cask を乗せない等） |
| 2 | **新端末で環境を引き継げるようにする**（現状 8 手順・順序が暗黙 → 1 コマンドへ） |
| 3 | 複数マシンで同一環境を構築する |

### 目的から外したもの

これを明示しておくのは、スコープが膨らんで停滞するのを防ぐため。

- スキル管理の宣言化（現状で困っていない）
- devShell + direnv（mise と重複）
- zsh 起動最適化（実測 0.244 秒で十分速い）
- launchd の宣言管理（自己管理対象が `cliproxyapi` の 1 つだけ）
  → **2026-08-01 改訂: hermes に限りスコープ入り**（[Phase 3-1b](PHASE-3-1B-HERMES-DAEMONS.md)）。
  「1 つだけ」は MacBook Pro 視点の前提で、hermes には自前 launchd agent が
  3 つあると判明したため。MacBook Pro / WSL2 は引き続き対象外

---

## 前提: 管理対象ホスト

| ホスト | system | 用途 | Nix の適用範囲 |
|---|---|---|---|
| MacBook Pro | `aarch64-darwin` | **メイン開発機**（現在の主戦場） | CLI + dotfiles。GUI アプリ本体は brew cask |
| Mac mini (hermes, M4) | `aarch64-darwin` | Hermes Agent 運用。**ヘッドレス** | ほぼ全体。cask は乗せない |
| 会社 Windows (WSL2) | `x86_64-linux` | **予備機**。現状稼働プロジェクトなし | WSL2 内部のみ。Windows 本体は対象外 |

> WSL2 は当初「日常的に開発している」と判断していたが、実態は予備機だった。
> 詳細と経緯は ADR-20260730-0003 を参照。

---

## ステータス凡例

| 記号 | 意味 |
|---|---|
| `[x]` | 完了 |
| `[~]` | 進行中 |
| `[ ]` | 未着手 |
| `[-]` | 対象外（判断済み。記録として残す） |
| `[?]` | 条件付き（トリガー待ち） |

---

## Phase 0: 基盤セットアップ — `[x]` 完了（2026-04-24）

- [x] `config/.config/nix/` にディレクトリ集約（stow 経由で `~/.config/nix/` にリンク）
- [x] `flake.nix`（最小の devShell 定義）
- [x] `nix.conf` で `experimental-features = nix-command flakes` を有効化
- [x] `shell/.zprofile` で login shell でも Nix を初期化
- [x] ドキュメント（ROADMAP / ADR）を `docs/` 配下に整備

**完了条件**: `nix develop ~/.config/nix` でサンドボックス shell が起動する → 達成

---

## Phase 1: CLI ツール単体を nix profile で試す — `[-]` 対象外（スキップ）

> **2026-07-29 判断: スキップ。**
> 候補ツール（`fd` / `bat` / `eza` / `dust` / `procs`）はいずれも brew で導入でき、
> 実利がなく学習目的にとどまる。Phase 3 で同じ学習が実務と同時に得られる。
> 当初計画の記録として残す。

---

## Phase 2: プロジェクト用 devShell を拡張 — `[-]` 対象外

> **2026-07-30 判断: 対象外。**
> mise がプロジェクト単位のランタイム切替を担っており、役割が重複する。
> mise を残す方針（下記「共存方針」）のため、devShell / direnv に価値が出ない。
> 当初計画の記録として残す。
>
> 再検討のトリガー: mise で賄えないツール（protoc / terraform / LSP 群など）の
> バージョン差異がプロジェクト間で問題になった場合。

---

## Phase 3: nix-darwin + home-manager 導入 — `[~]` 現在地

3 ホストを 1 つの flake で宣言的に管理する。**nix-darwin を最初から使う**
（理由は `homebrew.onActivation.cleanup = "zap"` による腐敗の構造的防止）。

### 目標構成

```
config/.config/nix/
├── flake.nix              # darwinConfigurations + homeConfigurations の 2 系統
├── hosts/
│   ├── common/            # 3 台共通（+ homebrew-personal / homebrew-work の分離）
│   ├── macbook/
│   ├── hermes/
│   └── wsl/               # standalone home-manager
├── home/
│   ├── dotfiles.nix       # mkOutOfStoreSymlink による配線
│   ├── darwin.nix
│   └── linux.nix
├── modules/
├── packages/              # nixpkgs に無いツールの自作パッケージ
└── docs/
```

`shared/agents/` の core + diff と同じ構造。

### 方式

- 原則 **`mkOutOfStoreSymlink`**（編集が即反映される。stow と同じ挙動）
- **「原則 + 例外」**とする。循環参照の罠やアプリが書き込むファイルには
  `home.activation` を使い、**例外の理由をコメントに残す**
- 設定内容を Nix 言語で書き直す（`programs.*` への全面移行）方針は採らない

### Phase 3-0: 着手前の前提作業 — `[x]` 完了（2026-07-30, `ccf2639`）

`shell/.zshrc` の移植阻害要因を修正する。**Nix と無関係に価値がある改善。**

- [x] `eval "$(sheldon source)"` に `command -v` ガードを追加
- [x] `eval "$(zoxide init zsh)"` に `command -v` ガードを追加
- [x] `eval "$(git gtr init zsh)"` に `command -v` ガードを追加（Linux 対応は要確認）
- [x] `eval "$(starship init zsh)"` に `command -v` ガードを追加
- [x] `. "$HOME/.local/bin/env"` に存在チェックを追加
- [x] dotfiles の絶対パス直書きを変数に集約（`.zshenv` の `$DOTFILES`）

**参考**: `hermes/home/.zsh/hermes-helpers.zsh` に**正しくガードが入った実装が既にある**。
本体へ還流させる形になる。

**完了条件**: `.zshrc` が Linux でエラーなく起動する（WSL2 で検証可能な状態になる）。
→ `PATH=/usr/bin:/bin` の環境で `.zshrc` を読み込みエラーが出ないことを確認済み。

#### 見送った項目（対応不要と判断）

| 項目 | 理由 |
|---|---|
| `/Users/yoshihiko/.bun/_bun` の `~/.zshrc.local` 退避 | 既に `[ -s ... ]` でガード済みで起動時エラーにならない。かつ bun インストーラーが `~/.zshrc`（dotfiles への symlink）へ自動追記した行のため、書き換えても再追記されうる |
| `claude-mem` alias の `~/.zshrc.local` 退避 | alias 定義はパスを解決しないので起動時は無害。同じくインストーラー管理下 |

#### Phase 3-3 へ移送した項目

| 項目 | 理由 |
|---|---|
| `aliases.zsh` の `ls -G` の `$OSTYPE` 分岐 | **「BSD 専用」という前提が誤りだった**。GNU coreutils にも `-G`（`--no-group`）があり、Linux でもエラーにならない（Debian 実測で `ls -G /` は exit 0）。色が付かず `ll` のグループ列が消えるだけの見た目の問題 |
| Dia 依存 alias（`trend` / `daily` / `weekly`）の `$OSTYPE` 分岐 | 起動時は無害で、実行時に `open` が無いだけ。Windows 端末に Dia を入れる予定が現状ないため、そもそも対応不要の可能性が高い |

#### 判明したこと

- `git gtr` は **Linux でも導入可能**。`coderabbitai/tap` の formula は純シェル実装
  （`bin/git-gtr` + `lib` + `adapters`）で `depends_on :macos` が無い。
  Phase 3-3 の `home.packages` に含めるかは別途判断
- `git gtr` の検出は `command -v git-gtr`（実バイナリ名）で行う。
  `git gtr` 形式では git のサブコマンド解決を経由してしまう

### Phase 3-1: hermes（Mac mini）— `[x]` 完了（2026-07-31）

macOS のため学習が MacBook Pro に転用でき、ヘッドレスで GUI 移行の考慮が不要。
メイン機ではないため壊れても業務が止まらない。

- [x] `flake.nix` を multi-host 構造へ拡張（mozumasu の構造をコピーして削る）
- [x] `hosts/common/` に 3 台共通のパッケージ・設定を定義
- [x] `hosts/hermes/` を定義。cask 7 個を宣言（**当初の「cask を 1 つも書かない」方針は撤回**。
      実機に GUI cask が存在する実態が判明したため。詳細は下記「実施記録」参照）
- [x] `home/dotfiles.nix` で `mkOutOfStoreSymlink` の配線を書く
- [x] `homebrew.brews` に `hermes/Brewfile` を移す（実測 17 個。ROADMAP の「18 個」表記は誤りだった。
      共通 CLI 15 + hermes 固有 fd/ripgrep + 実機の LLM 基盤 llama.cpp/llama-swap/miniserve を
      追加宣言し、宣言と実態が一致）
- [x] `homebrew.onActivation.cleanup = "zap"` を有効化（非対話 activation で正常動作。
      mozumasu が報告していた対話 dry-run 化問題は再現せず、宣言外の古い openssl@3 等が自動削除された）
- [x] `darwin-rebuild switch --flake .#hermes` で適用（2026-07-31 成功）
- [x] `scripts/install-hermes-subset.sh` が不要になったことを確認（home-manager が全機能を代替）
- [~] `hermes/Brewfile` / `hermes/home/` の重複解消（削除の可否は別途判断） — Brewfile 二重管理と
      zsh 再実装（hermes-helpers.zsh）は解消済み。hermes 固有部分は `hosts/hermes/zshrc.local` へ
      抽出し、共有部分は shell/ パッケージへの symlink に置換。`tmux.conf` / `mise/config.toml` は
      リンク元として存続中。ディレクトリは当面残置し、hermes の安定稼働を確認してから削除する（2026-07-31 判断）

**完了条件**:
1. `darwin-rebuild switch --flake .#hermes` 一発で hermes の環境が再現できる → 達成
2. `install-hermes-subset.sh` を使わずに済む → 達成
3. **（撤回、2026-07-31）** cask が 1 つも入っていない（環境切り分けが宣言で機能している）
   → hermes 実機に GUI cask 7 個が存在する実態が判明したため撤回。
   環境切り分けの検証は「cask ゼロ」ではなく
   「cask を含む全パッケージの宣言管理 + zap による宣言外の自動削除」で達成する

#### 実施記録（2026-07-31）

- macOS 26 (Tahoe) ではシェル版 Determinate installer が `/etc/fstab` 書き込みで失敗する。
  **pkg 版**（`https://install.determinate.systems/determinate-pkg/stable/Universal` を
  `installer -pkg` で導入）が正。そのため hermes は「Determinate Nix」ディストリビューション
  （`determinate-nixd` 込み、`nix.conf` は `determinate-nixd` 管理、カスタム設定は
  `/etc/nix/nix.custom.conf`）になった。MacBook Pro のシェル版インストール（素の Nix）とは
  系統が異なる
- SSH 経由の root 作業には「システム設定 → 共有 → リモートログイン →
  リモートユーザーにフルディスクアクセスを許可」の ON が必要
  （OFF だと root でも `/etc/fstab` 等の rename が `Operation not permitted` になる。
  hermes で 2026-07-31 に有効化済み）
- hermes は repo 所有者（`agent`）と sudo 実行者（`admin`）が別のため、
  root への `git config --global --add safe.directory <repo>` 登録が必要だった
  （libgit2 の所有権チェック）。単一ユーザー機（MacBook Pro）では不要の見込み
- `/opt/homebrew` の所有権を `admin` から `agent`（= `system.primaryUser`）へ変更した
  （nix-darwin は homebrew 処理を `primaryUser` で実行するため。brew は prefix 所有者が実行する設計）
- sudo 経由の activation ではユーザーの tap trust が見えないため
  `HOMEBREW_NO_REQUIRE_TAP_TRUST=1` が必要（`hosts/common/homebrew.nix` に対応済み、
  コミット `384d22e`）
- 初回のみの儀式: `/etc/zshenv` `/etc/zshrc` `/etc/zprofile` を `*.before-nix-darwin` へ退避
  してから初回 switch（mozumasu の README と同じ手順）
- 初回 switch コマンド:
  `sudo -H /nix/var/nix/profiles/default/bin/nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake <repo>/config/.config/nix#hermes`。
  2回目以降は `sudo darwin-rebuild switch --flake <repo>/config/.config/nix#hermes`
  （`darwin-rebuild` が `/run/current-system/sw/bin` に入るため）

### Phase 3-1b: hermes の完全 Nix 化 — `[~]` 進行中（2026-08-01 着手）

CLI を brew から Nix パッケージ管理へ移し、自前デーモン群を launchd 宣言管理に
取り込む。調査結果と詳細計画: [PHASE-3-1B-HERMES-DAEMONS.md](PHASE-3-1B-HERMES-DAEMONS.md)

- [x] nixpkgs 収録の CLI 16 個を `homebrew.brews` から `home/packages.nix`
      （`home.packages`）へ移行（2026-08-01 適用・検証済み）。`gh` のみ暫定で brew にも残す
      （gateway の PATH 問題、詳細は計画ドキュメント）。
      注記: `git` は `git-gtr` の依存として brew にも残り、PATH では brew 版が先勝ちする
      （実害なし。git-gtr の自作パッケージ化（Phase 4-7）で解消可能）
- [ ] LLM 基盤（llama.cpp / llama-swap / miniserve）の nixpkgs 移行
- [ ] llama-swap / miniserve の launchd 宣言管理化
- [ ] `ai.hermes.gateway` の PATH に Nix プロファイル bin を追加
- [ ] 野良 plist / 孤児プロセスの扱いをユーザー確認
- [ ] 完了確認: brew 残留が「cask 7 個 + git-gtr」のみになる

**完了条件**: 計画ドキュメントの完了条件 1〜4 を満たす。

### Phase 3-2: MacBook Pro — `[ ]`

既に動いている環境のため最もリスクが高い。**hermes で手応えを得てから着手する。**

- [ ] アプリが書き込むファイルの**除外リスト**を確定（`~/.claude/settings.json` 等）
- [ ] 復旧手段を用意（別シェルの確保、リカバリ手順の文書化）
- [ ] `hosts/macbook/` を定義。GUI cask 13 個はここに置く
- [ ] `homebrew-personal.nix` / `homebrew-work.nix` の分離を検討
- [ ] `~/.config/nvim-dev` の手動リンク（worktree 参照）の扱いを決める
- [ ] stow から home-manager へ段階移行（パッケージ単位）
- [ ] `taskfiles/link.yml` / `Makefile` の link ターゲットを撤去
- [ ] Nix を Determinate pkg 版へ入れ直して hermes と系統統一（現状はシェル版の素の Nix）
- [ ] flake apps（`nix run .#switch`）パターンの導入検討（mozumasu 流用。評価をユーザー権限で行い
      root には store パスだけ渡す構造で、safe.directory 問題も回避できる）
- [x] `config/.config/wezterm.bak`（17 ファイル）の腐敗を解消 — 2026-07-30 に削除（Nix 待ちせず先行対応）
- [x] `taskfiles/link.yml` の `link-tmux` / `restow-tmux`（存在しないパッケージ参照）を解消 — 2026-07-30 に撤去（Nix 待ちせず先行対応）

**完了条件**: メイン機の CLI + dotfiles が home-manager 管理下に入り、
brew は GUI / cask と nixpkgs 未収録パッケージ専用になる。

### Phase 3-3: WSL2 — `[?]` 条件付き（実稼働待ち）

**着手トリガー**: 会社の業務プロジェクトが動き始め、WSL2 を日常的に使うようになったとき。

詳細な作業計画・設計: [PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md)

- `targets.genericLinux.enable = true` が必要
- flake の出力が `homeConfigurations` 系統になる（nix-darwin とは独立）
- `git gtr` は Homebrew 専用 tap のため Linux 対応を要確認

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。

---

## Phase 4: 付加機能の順次導入 — `[ ]`

> Phase 3 の完了を待たず、**タイミングが来たものから個別に導入する**。
> 一気に進めない。各項目は独立している。
>
> （旧 Phase 4「nix-darwin 移行」は Phase 3 に吸収した）

### 4-1: Remote builders — `[ ]` 優先度: 高

hermes をビルドマシンにし、MacBook Pro のビルド負荷を逃がす。
両機とも `aarch64-darwin` なので成果物がそのまま使える。

**stow では原理的に代替不可能な唯一の価値。** ヘッドレス機の存在価値が上がる。

- [ ] hermes を builder として登録（`nix.buildMachines`）
- [ ] `builders-use-substitutes` を有効化してキャッシュ併用
- [ ] MacBook Pro でのビルドが hermes に委譲されることを確認

**完了条件**: MacBook Pro で `darwin-rebuild` を実行したとき、重いビルドが hermes で走る。

**前提**: Phase 3-1 完了

### 4-2: `comma`（`,` コマンド）— `[ ]` 優先度: 高

インストールせずコマンドを即実行する。導入コストがほぼゼロ。

- [ ] `comma` と `nix-index` を導入
- [ ] `nix-index` データベースの定期更新を設定

**完了条件**: `, <command>` で未インストールのコマンドが実行できる。

### 4-3: `nix flake check` + CI — `[ ]` 優先度: 中

設定自体の検証。リポジトリに `.github` が無く **CI 未設定のため純増**。
`link-tmux` の腐敗は CI があれば検出できていた。

- [ ] `nix flake check` が通る状態にする
- [ ] treefmt-nix でフォーマッタを統合（mozumasu 採用）
- [ ] GitHub Actions で `nix flake check` を実行

**完了条件**: push 時に設定の破綻が自動検出される。

### 4-4: Cachix Deploy — `[ ]` 優先度: 中

hermes が pull 型で設定に自動追従する。
現状は SSH して `install-hermes-subset.sh` を叩きに行く必要がある。

**注意**: 外部サービス依存。まず手動運用に慣れてから。

**前提**: Phase 3-1 完了

### 4-5: sops-nix — `[ ]` 優先度: 中

秘匿情報を暗号化したままコミットする。
現状は `shared/cliproxyapi.conf.tmpl` のテンプレート化と
`~/.claude-work`（git 管理外）で回避しており、**秘匿情報だけリポジトリの外**にある。

**着手トリガー**: 3 台目が実稼働し、各マシンへの手動配置が負担になったとき。

### 4-6: `specialisation` — `[ ]` 優先度: 低

同一ホストで設定バリアントを切り替える。
`ccw` / `taktw`（会社アカウント切替、`~/.claude-work`）の宣言化に使える。

**注意**: home-manager 版は**実験的機能**。採用するなら nix-darwin 側で。
現状の zsh 関数で動いているため急がない。

### 4-7: Tier 2 機能（採否未判断）— `[ ]`

| 機能 | 内容 |
|---|---|
| overlays | nixpkgs のパッケージを部分上書き・patch。upstream が壊れていても自分で直せる |
| 自作パッケージ（`packages/`） | nixpkgs 未収録の CLI を宣言に載せる。`agent-browser` / `git-gtr` / `takt` が候補 |
| `dockerTools` | Dockerfile なしで OCI イメージ生成。レイヤ最適化が自動 |
| flake templates | `nix flake init -t` でプロジェクト雛形 |
| `nh`（nix helper） | rebuild の UX 改善・差分表示（ryoppippi 採用） |

---

## Phase 5: 対象外と判断したもの（記録）— `[-]`

再検討時に「なぜ採らなかったか」を追えるように残す。

| 項目 | 理由 |
|---|---|
| NixOS 本体 / impermanence / microVM | Linux サーバを常用しないため無関係 |
| deploy-rs / colmena / NixOps | 複数サーバへのデプロイ用。対象がない |
| devenv.sh / Devbox | mise と重複。Nix 本体を学ぶ方針のため迂回不要 |
| lazy2nix 相当（nvim プラグインの Nix 化） | `lazy-lock.json` で既にピン留めしており追加価値が小さい |
| zsh の zcompile / init キャッシュ / zsh-defer | 実測 0.244 秒で既に十分速い |

---

## 既存ツールとの共存方針

| ツール | 方針 |
|---|---|
| **stow** | 段階的に home-manager へ寄せ、**最終的に廃止**（Phase 3-2 完了後） |
| **mise** | **残す**。境界は「言語ランタイム = mise、それ以外の CLI = Nix」 |
| **brew** | GUI / cask と nixpkgs 未収録パッケージ用に**恒久的に残る**。`homebrew.*` で宣言化 |

**brew が恒久的に残る理由**: `agent-browser` / `git-gtr`（サードパーティ tap）/
`gemini-cli` / `opencode` / `claude-code` / `codex` は nixpkgs 未収録または追従が遅い。
**日常的に使う AI CLI 群こそ brew に残る**（Phase 4-7 の自作パッケージ化で一部は移せる可能性がある）。

---

## 進行ルール

- Phase は原則 **順番に**進める。ただし **前提が変わった場合は ROADMAP ごと見直す**
  - 2026-07-29: 3 台構成が判明し Phase 1 のスキップを決定
  - 2026-07-30: WSL2 の稼働実態が判明し着手順序を反転、nix-darwin を前倒し
- **Phase 4 は Phase 3 の完了を待たない。** 各項目は独立しており、タイミングが来たものから導入する
- 各 Phase の中で「採用 / 不採用 / 保留」の判断が出たら **ADR を書く**
- 学習が追いつかない場合は、その Phase に**無期限で滞留してよい**
- **実装は mozumasu の構造をコピーして削る。** ゼロから設計しない
- ROADMAP は学習状況に応じて随時更新（固定計画ではない）
