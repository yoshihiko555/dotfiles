# Nix 移行ロードマップ

dotfiles を段階的に Nix 管理へ寄せていくための計画。
Nix の学習度合いに合わせて、小さく動かしながら進める。

方針・目的の根拠は [ADR-20260730-0003](adr/ADR-20260730-0003-purpose-and-order.md)。

---

## 現在地

**Phase 3（3-0 〜 3-3）は 2026-08-18 に全ホストで完了した。**
実質的には Phase 4 を「タイミングが来たものから個別に」進める運用フェーズに入っている（一気に進めない）。

| ホスト | 状態 |
|---|---|
| MacBook Pro | `[x]` 管理下（2026-08-07）。CLI / cask / dotfiles を宣言管理し、stow は廃止 |
| Mac mini (hermes) | `[x]` 管理下（2026-07-31）。CLI・LLM 基盤・launchd デーモンまで宣言管理済みで、brew 残留は cask 7 個 + git-gtr（+依存）のみ。2026-08-02 に素の Nix へ移行（3-1c） |
| 会社 Windows (WSL2) | `[x]` 管理下（2026-08-18）。`flake.nix` に `homeConfigurations.wsl` を追加し、standalone home-manager で導入。予備機のため実稼働（日常利用）はまだ先。詳細は Phase 3-3 実施記録を参照 |

下記「目的」の 3 項目はいずれも達成済み。

**2026-08-14 に Phase 4 の 4 項目（4-3 / 4-1 / 4-8 / 4-5）を実施し、いずれも決着した。**

| 項目 | 結果 |
|---|---|
| 4-3 flake check + CI | 完了。treefmt-nix + GitHub Actions（`ubuntu-latest` で通過） |
| 4-1 Remote builders | 完了。hermes への委譲を実測で確認 |
| 4-8 セキュリティ宣言管理 | 完了。ただし **Touch ID sudo は macOS 側の要因で不採用** |
| 4-5 sops-nix | 基盤のみ導入し**管理対象ゼロで待機**。`~/.ssh/config` は平文配線に変更 |

残る能動タスクは 4-9 の GC 初回発動確認（2026-09 上旬）のみ。
他はトリガー待ちか任意着手。

> ホストごとの構成・運用ルールは [../README.md](../README.md) を参照。
> このファイルは**進捗と判断の履歴**、README は**現在の管理方法**と役割を分ける。

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

## Phase 3: nix-darwin + home-manager 導入 — `[x]` 完了（2026-08-18）

3 ホストを 1 つの flake で宣言的に管理する。**nix-darwin を最初から使う**
（理由は `homebrew.onActivation.cleanup = "zap"` による腐敗の構造的防止）。

### 目標構成（2026-08-01 に層設計を確定、ADR-0004）

```
config/nix/
├── flake.nix              # darwinConfigurations + homeConfigurations の 2 系統
├── darwin/                # darwin ホスト共通のシステム層（WSL2 は通らない）
├── home/                  # 全ホスト共通のユーザー層（dotfiles 配線・CLI パッケージ）
├── hosts/                 # ホスト固有。薄く保つ
│   ├── hermes/            # default.nix（hostSpec+目次）+ 機能群ファイル
│   ├── macbook/           # Phase 3-2 で作成
│   └── wsl/               # Phase 3-3 で作成（standalone home-manager、darwin/ を通らない）
├── modules/               # オプション定義（hostSpec 等）
├── packages/              # nixpkgs に無いツールの自作パッケージ（将来）
└── docs/
```

`shared/agents/` の core + diff と同じ構造。

**設計規約**（運用コストを下げるための約束、ADR-0004）:

1. ホスト軸 + 層明示。機能軸（modules/<機能>/<ホスト>.nix）は 3 台規模には過剰なので採らない
2. `hosts/<host>/` は「hostSpec + 目次の default.nix + 機能群ファイル」で構成し、**薄く保つ**
3. **2 台以上で使い始めたら共通層へ昇格**（システム層 → darwin/、ユーザー層 → home/）。
   新規はまず使うホストの hosts/<host>/ に書く（宣言が実態より先行する腐敗を防ぐ）
4. 機能の増築は「新ファイル + default.nix の imports に 1 行」

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
- [x] `hosts/common/` に 3 台共通のパッケージ・設定を定義（2026-08-01 に `darwin/` へ改名、ADR-0004）
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
- [x] `hermes/Brewfile` / `hermes/home/` の重複を解消 — 2026-08-07 完了。
      tmux / mise は `home/dotfiles.nix` の共通層へ昇格し、hermes 固有部分は
      `hosts/hermes/zshrc.local` に集約。`hermes/` と `scripts/install-hermes-subset.sh` を削除した

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
  `sudo -H /nix/var/nix/profiles/default/bin/nix run github:nix-darwin/nix-darwin/master#darwin-rebuild -- switch --flake <repo>/config/nix#hermes`。
  2回目以降は `sudo darwin-rebuild switch --flake <repo>/config/nix#hermes`
  （`darwin-rebuild` が `/run/current-system/sw/bin` に入るため）
  ※ 実施当時のパスは `config/.config/nix` だった。2026-08-14 のフラット化後のパスに書き換えている

### Phase 3-1b: hermes の完全 Nix 化 — `[x]` 完了（2026-08-01）

CLI を brew から Nix パッケージ管理へ移し、自前デーモン群を launchd 宣言管理に
取り込む。調査結果と詳細計画: [PHASE-3-1B-HERMES-DAEMONS.md](PHASE-3-1B-HERMES-DAEMONS.md)

- [x] nixpkgs 収録の CLI 16 個を `homebrew.brews` から `home/packages.nix`
      （`home.packages`）へ移行（2026-08-01 適用・検証済み）。`gh` のみ暫定で brew にも残す
      （gateway の PATH 問題、詳細は計画ドキュメント）。
      注記: `git` は `git-gtr` の依存として brew にも残り、PATH では brew 版が先勝ちする
      （実害なし。git-gtr の自作パッケージ化（Phase 4-7）で解消可能）
      → **2026-08-02 解消**: git-gtr は hermes で未使用と判断し darwin 共通層から降格
      （ADR-0004 ルール 3）。zap が git-gtr と依存の brew 版 git を連鎖除去し、
      git は nix 版に一本化された。MBP 向けは Phase 3-2 で hosts/macbook/ に宣言する
- [x] LLM 基盤（llama.cpp / llama-swap / miniserve）の nixpkgs 移行（b10133 / 240 へ更新）
- [x] llama-swap / miniserve の launchd 宣言管理化（home-manager launchd.agents）
- [x] `ai.hermes.gateway` 対策は plist 無改変の `~/.local/bin/gh` symlink 方式で解決
- [x] 野良 plist / 孤児プロセスは残骸と判明、掃除済み（suica は次回再起動で消滅）
- [x] 完了確認: brew 残留は cask 7 個 + git-gtr（+依存）のみ
      → 2026-08-02 に git-gtr も降格・削除し、**brew 残留は cask 7 個のみ**
      （formula ゼロ・tap ゼロ。cask 7 個は棚卸しの結果すべて継続と判断）

**完了条件**: 計画ドキュメントの完了条件 1〜4 を満たす。→ **すべて達成（2026-08-01）**

### Phase 3-1c: 素の Nix への移行 — `[x]` 完了（2026-08-02）

hermes を Determinate Nix から**素の Nix**（`NixOS/nix-installer` 版）へ移行し、
MacBook Pro と系統を統一した。判断の根拠と検討した代替案は
[ADR-20260802-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)。

**着手理由**: Determinate 運用に必須の `nix.enable = false` が nix-darwin の
`nix.*` 配下をほぼ全面的に無効化しており、設定を書き溜めるほど移植コストが
上がる構造だった。とくに `nix.buildMachines`（4-1）は**エラーを出さず無視される**ため、
「設定したのに効かない」形で破綻する危険があった。

- [x] nix-darwin をアンインストール（`darwin-uninstaller`。要 root）
- [x] Determinate Nix をアンインストール（`/nix/nix-installer uninstall`）
- [x] `NixOS/nix-installer` 2.35.1 で素の Nix を導入（`--enable-flakes`）
- [x] nix-darwin を再導入（`nix.enable = false` のまま。従来どおり動くことを確認）
- [x] `nix.enable = false` を解除し、`nix.settings` で nix.conf の内容を宣言
- [x] GC を標準の `nix.gc.automatic` へ移行（4-9）
- [x] `trusted-users` に作業ユーザーを追加

**実施記録（2026-08-02）**:

- 所要 約 1 時間。停止したサービスは `llama-swap` / `miniserve` / `ai.hermes.gateway` の 3 つ
- **`/run/current-system` が移行前と同一の store パスで再現された**
  （`ps5ndcmgdwfwdalgym1gbh2p1j4qf436-darwin-system-26.11.15abb8c`）。
  `/nix` を丸ごと削除して別インストーラで入れ直しても flake から同一のシステムが
  再構築できることの実証であり、**目的 2 の達成確認**にあたる
- **Tahoe 26.4.1 で `NixOS/nix-installer` は問題なく動作した。**
  7/21 に `/etc/fstab` で失敗したのは Determinate 版インストーラであり、別実装だった
  （両者はフォーク関係にあるが fstab / APFS 処理の堅牢性が異なる）
- `nix.enable` を解除すると nix-darwin が `/etc/nix/nix.conf` を管理下に置くため、
  インストーラが書いていた設定は `nix.settings` で明示しないと失われる。
  とくに `experimental-features` を落とすと flake を評価できず switch 不能になる
- 既存の `/etc/nix/nix.conf` は nix-darwin の `knownSha256Hashes` に登録済みだったため
  activation は中断しなかった（`*.before-nix-darwin` への退避は行われる）
- **nix 本体のバージョンも nix-darwin が管理する**（nixpkgs 版 2.34.8 が
  インストーラ由来の 2.35.1 より PATH で優先される）。
  インストーラのバージョン差は運用上無関係で、MBP に nix-darwin を入れれば自動的に揃う
- 移行の副作用: `trusted-users` が root のみになる、mise の trust が外れる（`mise trust` で復旧）

### Phase 3-2: MacBook Pro — `[x]` 完了（2026-08-07）

既に動いている環境のため最もリスクが高い。**hermes で手応えを得てから着手する。**
→ 前提棚卸しは完了（2026-08-02、[PHASE-3-2-BREW-INVENTORY.md](PHASE-3-2-BREW-INVENTORY.md) /
[PHASE-3-2-CLI-INVENTORY.md](PHASE-3-2-CLI-INVENTORY.md)）。

**安全な移行順序（2026-08-05 決定。リカバリ手順書の代わり）**:

1. **初回 switch は `homebrew.onActivation.cleanup = "none"`** で行う
   （zap の自動削除を無効化した状態で全宣言の動作を確認する）
2. **dotfiles 配線はパッケージ単位で unstow → home-manager 化**（一括切替しない。
   戻しは restow 1 コマンド）
3. **zap の解禁は最後**（brew 宣言が実機で証明されてから）

リカバリ手順の文書化は**不採用**（2026-08-05 判断）: hermes で switch / ロールバック
（`nxrb`）/ 同一システム再現まで実証済みで、home-manager の衝突は switch が
中断されるだけで環境を壊さない。Nix の世代機構と stow の残置が復旧手段そのもの。
MBP は単一ユーザー機のため hermes でハマった admin/agent 分離系の地雷も発生しない。
唯一「壊れる」タイプのリスクは zap の宣言漏れ削除で、上記順序 1・3 で無効化する。

- [x] アプリが書き込むファイルの**除外リスト**を確定 — 2026-08-02 調査完了。
      除外必須 3 件（`~/.claude/settings.json`、`~/.gemini/antigravity-cli/settings.json`、
      同 `keybindings.json`。後者 2 件はコミット `ca7e49b` に実害記録あり）。
      要注意 5 件（codex config.toml / karabiner.json / lazy-lock.json / flake.lock /
      mise config.toml）は移行時に個別検証。
      **2026-08-06 追記**: `~/.gemini/antigravity-cli/settings.json` は
      「`trustedWorkspaces` 追記時に壊れる」のではなく、**`agy` を起動するたびに実体化する**
      ことが判明した（追記なしでも再現）。repo 側の編集が home 側に届かないまま
      古い設定で動き続けるため、**除外リスト内でも最優先で mozumasu 方式に移すべき対象**。
      経緯と権限設計は [gemini/README.md](../../../gemini/README.md) に記録
- [x] 復旧手段を用意 → 上記のとおり「安全な移行順序」で代替（文書化は不採用）
- [x] `hosts/macbook/` を定義。GUI cask 13 個はここに置く — 2026-08-05 完了、
      初回 switch も成功（下記実施記録）
- [-] ~~`homebrew-personal.nix` / `homebrew-work.nix` の分離を検討~~ → **不採用**
      （2026-08-02）。業務用 macOS 端末の配布予定がなく、WSL2 に cask（GUI）需要も
      ない。再検討トリガー: 業務 Mac が配布されたとき
- [x] `~/.config/nvim-dev` の手動リンク（worktree 参照）の扱いを決める —
      リンク切れ（worktree 実体なし）と判明し削除（2026-08-02）
- [x] stow から home-manager へ段階移行（パッケージ単位）— 2026-08-07 完了
- [x] `taskfiles/link.yml` / `Makefile` の link ターゲットを撤去 — 2026-08-07 完了
      （タスクランナーは go-task に統一、Makefile は stow と同時期に廃止 — 2026-08-02 決定）

#### 実施記録（2026-08-05、初回 switch）

- 初回 switch は `nix build .#darwinConfigurations.macbook.system` の成果物に含まれる
  `darwin-rebuild` を使用（root での GitHub fetch が不要になる。hermes の
  `nix run github:nix-darwin/...` 方式より簡潔）。/etc/zsh* の退避儀式は hermes と同じ
- **`brew bundle` は 21 依存すべて「Using」**（新規インストール・削除ともゼロ）。
  2026-08-02 の棚卸しで宣言と実態を同期済みだったため、初回から完全一致した
- home-manager の共通配線（zsh / starship / git / nvim）は既存の stow リンクと
  実体が同一のため「skipped since they are the same」で衝突なく通過
- 単一ユーザー機のため hermes で必要だった safe.directory / tap trust /
  homebrew 所有権の対処はすべて不要だった（想定どおり）
- 活性化時に `/etc/ssh/ssh_host_*`（ホスト鍵）が生成されるが、これはサーバ側の鍵で
  リモートログインを有効にしない限り未使用。個人鍵（`~/.ssh`）には無関係
- **移行期の PATH**: 旧実体（brew の git/tmux 等、mise の golangci-lint、npm -g の takt 等）が
  残っている間はそちらが優先される。これは `cleanup = "none"` の設計どおりで、
  ルール 3 の掃除（旧実体の削除 + zap 解禁）で nix 版へ自然に切替わる
- 注記: agy は nix 版 1.1.8 が手動導入版 1.1.9 よりわずかに旧い
  （nixpkgs は updateScript による自動追従あり）

#### 実施記録（2026-08-06、npm / uv / mise / 野良系の掃除）

上記「移行期の PATH」のうち **brew 以外の系統を掃除し、nix 版への切替を完了**した。
詳細は [PHASE-3-2-CLI-INVENTORY.md](PHASE-3-2-CLI-INVENTORY.md) 6 章。

- npm -g（takt / clasp / sandbox-runtime）・uv tool（mcp-proxy）・mise（golangci-lint）・
  `~/.local/bin` の重複コピー（uv / uvx）と agy 残骸を削除
- 対話シェルで対象 6 コマンドが `/etc/profiles/per-user/yoshihiko/bin` に解決することを確認。
  空白期間なし（agy で実証した「rm した瞬間に nix 版が引き継ぐ」挙動が全件で再現）
- **brew formula は手つかず**。MBP には formula 70 個超が残り、`/opt/homebrew/bin` が
  PATH で nix より先のため、gh / ghq / git / lazygit / starship / tmux / yazi / zoxide 等は
  依然 brew 版が使われている。これは安全な移行順序のルール 3（zap の解禁は最後）どおりで、
  別タスクとして扱う
- [-] ~~Nix を Determinate pkg 版へ入れ直して hermes と系統統一~~ → **対象外**（2026-08-02）。
      Phase 3-1c で **hermes を素の Nix へ移行したため、MBP は現状のままで系統が揃った**。
      MBP は `NixOS/nix-installer` 由来の素の Nix（2.34.5）で hermes と同系統。
      nix-darwin を導入すれば nix 本体も nixpkgs 版に統一されるため、
      インストーラのバージョン差（2.34.5 / 2.35.1）は解消される
- [ ] flake apps（`nix run .#switch`）パターンの導入検討（mozumasu 流用。評価をユーザー権限で行い
      root には store パスだけ渡す構造で、safe.directory 問題も回避できる）
- [x] `config/.config/wezterm.bak`（17 ファイル）の腐敗を解消 — 2026-07-30 に削除（Nix 待ちせず先行対応）
- [x] `taskfiles/link.yml` の `link-tmux` / `restow-tmux`（存在しないパッケージ参照）を解消 — 2026-07-30 に撤去（Nix 待ちせず先行対応）

#### 実施記録（2026-08-06、zap 解禁 = 安全な移行順序ルール 3 完了）

`hosts/macbook/homebrew.nix` の `cleanup = lib.mkForce "none"` を撤去し、
darwin 共通層の `"zap"` に復帰。switch で宣言外 formula が自動削除された。

- **事前突合で「失われる CLI ゼロ」を確認してから解禁**: leaves 25 個は
  宣言済み 4 個 + nix 版が `/etc/profiles/per-user/.../bin` に存在する 21 個で全件カバー
- zap は **35 formula を削除、go-task/tap も untap**。formula は 69 → 34 個になり、
  残りは宣言 4 個（agent-browser / cliproxyapi / git-gtr / tmux-fingers）とその依存のみ
- gh / ghq / starship / tmux / nvim / rg / fzf / lazygit / yazi / zoxide 等が
  nix 版に解決されることを確認。空白期間なし
- `git` は git-gtr の依存として brew に残置（Phase 3-1b の注記どおり。brew / nix とも
  2.55.0 で実害なし。git-gtr の自作パッケージ化（Phase 4-7）で解消可能）。
  `node` / `npm` も agent-browser の依存で残るが、mise が PATH 上位で node 25 を提供
- 副作用 1: **既存シェルは起動時に記憶した旧絶対パスでフックを叩き続ける**
  （`_mise_hook` / starship がプロンプト描画のたびにエラー）。`exec zsh` で解消
- 副作用 2: tmux `popup.conf` の `w` バインドが `/opt/homebrew/bin/fzf` を直書きしており
  popup が即死 → 素の `fzf` に修正（tmux サーバーの PATH で nix 版に解決される）

#### 実施記録（2026-08-07、stow 廃止 + home-manager 一本化）

- shell / config / claude / codex / gemini / takt / editorconfig の旧リンクをパッケージ単位で解除し、
  home-manager の `mkOutOfStoreSymlink` へ移行。Alfred の Dropbox 配線も home-manager に統合
- `config` はエントリ単位で配線。認証・ランタイムファイルが共存する gh / zed / opencode は
  ディレクトリ全体を置換せず、管理対象ファイルだけをリンクした
- tmux / mise を `home/dotfiles.nix` の共通層へ昇格。macbook / hermes 両構成の実ビルドに成功し、
  hermes の手動配布用 `hermes/` と `scripts/install-hermes-subset.sh` を削除
- Claude Code の `settings.json`、Antigravity CLI の `settings.json` / `keybindings.json` は、
  書き込み可能な実ファイル + `.nix-managed` 参照コピーで管理。drift 中は switch が上書きを拒否し、
  `task adopt-settings` で repo へ回収する。Claude Code は Stop hook でも即時検知
- codex `config.toml` / karabiner.json / lazy-lock.json / flake.lock / mise config.toml は
  実機でリンクが維持されることを確認し、通常配線とした
- `taskfiles/link.yml` / `Makefile` / stow worktree script を撤去し、Nix と Homebrew の双方から
  stow を削除。`task status` は home-manager の二段リンクと mutable drift を検査する形へ更新
- macbook へ switch 済み。全リンクが repo に解決すること、mutable 3 ファイルに drift がないこと、
  tmux / mise / nvim / task の起動を確認。hermes 構成も実ビルド済み

**完了条件**: メイン機の CLI + dotfiles が home-manager 管理下に入り、
brew は GUI / cask と nixpkgs 未収録パッケージ専用になる。

### Phase 3-3: WSL2 — `[x]` 完了（2026-08-18）

**当初の着手トリガー**（会社の業務プロジェクトが動き始め、WSL2 を日常的に使うようになったとき）は
点灯していないが、明示的な指示により前倒しで実施した。

詳細な作業計画・設計: [PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md)。
内部構成の確定は [ADR-20260801-0004](adr/ADR-20260801-0004-module-layer-design.md) の
「改訂（2026-08-18）」節にも反映済み。

- [x] `targets.genericLinux.enable = true` を設定
- [x] flake の出力に `homeConfigurations.wsl` を追加（nix-darwin とは独立）
- [x] `git gtr` の Linux 対応可否を確認 → **不採用**。formula は純シェル実装で動作見込みだが
      nixpkgs に無く、WSL2 では使わないと判断したため対応不要

**完了条件**: WSL2 上で `home-manager switch` により zsh / starship / git が再現できる。→ 達成。

#### 実施記録（2026-08-18）

**実機の情報**

| 項目 | 値 |
|---|---|
| system | `x86_64-linux`（`uname -m` → x86_64） |
| username | `stakizawa`（macOS 側の yoshihiko とは異なる会社アカウント） |
| homeDirectory | `/home/stakizawa` |
| dotfiles clone 先 | 当初 `~/src/dotfiles` だったが、macOS 2 台と揃えるため `~/ghq/github.com/yoshihiko555/dotfiles` へ移動した |

**実装内容**（コミット `b865a9a` / `3f261d9`）

- `modules/hostSpec.nix` に `homeDirectory` オプションを追加し、`home/default.nix` から
  macOS パスのハードコード（`lib.mkForce "/Users/${hostSpec.username}"`）を除去した（B1 の解消）
- `flake.nix` に `homeConfigurations.wsl` を追加。**`commonModules` は再利用していない**。
  理由は `extraSpecialArgs = { hostSpec = config.hostSpec; }` が nix-darwin システム設定の
  `config` に依存しており standalone では成立しないため（B2）
- hostSpec の値は `hosts/wsl/hostSpec.nix` に plain attrset として分離し、`flake.nix` が
  `import` して `extraSpecialArgs` へ直接渡す方式を採用した
- `hosts/wsl/default.nix` は `targets.genericLinux.enable = true` のみの最小構成
- **sops-nix は読み込まない**。管理対象がゼロで、Linux では復号先の扱いが darwin と異なるため

**実機での作業手順（実際に通ったもの）**

1. `/etc/wsl.conf` に `[boot] systemd = true` / `[interop] appendWindowsPath = false` /
   `[automount] options = "metadata"` を設定し、Windows 側から `wsl --shutdown` で反映
2. Nix インストール: `curl -sSfL https://artifacts.nixos.org/nix-installer | sh -s -- install --enable-flakes`。
   systemd を有効にしてあるため planner が multi-user（nix-daemon あり）を選ぶ
3. 初回 switch:
   `nix run home-manager/master -- switch -b backup --flake ~/ghq/github.com/yoshihiko555/dotfiles/config/nix#wsl`

**新たに判明した知見**

- **`-b backup` フラグが必須。** darwin 側は `flake.nix` で
  `home-manager.backupFileExtension = "backup"` を設定しているが、これは nix-darwin モジュール版の
  オプションで **standalone home-manager には効かない**。standalone では CLI の
  `-b/--backup-extension` で指定する。付け忘れると既存 dotfiles との衝突で switch が失敗する
- **`--flake` は 2 回目以降も毎回必須。** flake が `~/.config/home-manager/` ではなく dotfiles
  リポジトリ内にあるため、引数なしの `home-manager switch` では自動検出されない
- `#wsl` は `homeConfigurations.wsl` に解決される（`#homeConfigurations.wsl` ではない）。
  home-manager CLI の `setFlakeAttribute()` 実装による
- **ghq は clone に不要。** ghq はパス規約だけのツールで既存ディレクトリをそのまま認識するため、
  Nix 未導入の初期状態でも素の `git clone` で ghq 構造のパスへ置けばよい。
  ブートストラップの順序は破綻しない
- 共通層（`home/`）は Linux でもそのまま成立した。macOS 上で
  `nix eval .#homeConfigurations.wsl.activationPackage.drvPath` が通ることを事前確認済み

**スコープの決着**

- **Q1（AI CLI）**: 既に記録済み（Codex / Claude Code のみ、takt / Gemini は使わない。
  詳細は [PHASE-3-3-WSL2.md](PHASE-3-3-WSL2.md) の保留事項参照）
- **Q2（Nix と apt の併用方針）**: 開発用 CLI は Nix（共通層の 16 パッケージ）。
  既にインストール済みだった Codex / Claude Code は Nix 外のまま維持し、宣言し直さない
- **Q3（git gtr の Linux 対応）**: **不採用**。formula は純シェル実装で Linux でも動く見込みだが
  nixpkgs に無く自前 derivation か手動配置が必要で、WSL2 では使わないと判断
- **`sheldon` は入れない判断**。共通層に無く `hosts/macbook/packages.nix` にホスト固有として
  置かれているため、WSL2 では zsh プラグインなしの素の状態になる。`.zshrc` の
  `eval "$(sheldon source)"` は Phase 3-0 のガードで黙ってスキップされエラーは出ない。
  不便を感じたら `hosts/wsl/packages.nix` を作って 1 行足す
- 手順 5（`hosts/wsl/packages.nix`）と手順 6（クリップボード連携 / `wsl-open`）は
  **追加機能のため今回は実施しない**。win32yank は nixpkgs に無く、`wslu` は 2026-04-09 に
  nixpkgs から削除済み（upstream アーカイブ）で後継は `wsl-open`、という調査結果は
  将来の参考として残す

---

## Phase 4: 付加機能の順次導入 — `[~]` 現在地

> 各項目の「何が嬉しいか・コスト」の比較は [USECASES.md](USECASES.md) を参照。
> Phase 3 の完了を待たず、**タイミングが来たものから個別に導入する**。
> 一気に進めない。各項目は独立している。
>
> （旧 Phase 4「nix-darwin 移行」は Phase 3 に吸収した）

### 4-1: Remote builders — `[x]` 完了（2026-08-14）

hermes をビルドマシンにし、MacBook Pro のビルド負荷を逃がす。
両機とも `aarch64-darwin` なので成果物がそのまま使える。

**stow では原理的に代替不可能な唯一の価値。** ヘッドレス機の存在価値が上がる。

- [x] hermes を builder として登録（`nix.buildMachines`、`hosts/macbook/nix-builders.nix`）
- [x] `builders-use-substitutes` を有効化してキャッシュ併用
- [x] MacBook Pro でのビルドが hermes に委譲されることを確認

**完了条件**: MacBook Pro で `darwin-rebuild` を実行したとき、重いビルドが hermes で走る。
→ 達成。`-j0`（ローカルビルド禁止）付きのビルドが hermes 上で実行され、
`uname -a` が `mac-mini.local` / `T8132`（M4）を返すことで実証した。

#### 実施記録（2026-08-14）

- **root の SSH 設定に依存しない構成を採った。** nix-daemon は root 権限で SSH 発信するが、
  `/var/root/.ssh/` の状態は sudo 無しでは確認できない。そこで
  (1) builder 専用鍵を新規作成（個人鍵 `id_ed25519_macmini` を root に流用しない。
  漏洩時の影響範囲を鍵ごとに限定するため）、(2) `sshKey` に絶対パスを指定して
  root の `~/.ssh/config` を経由しない、(3) known_hosts の初回登録問題は
  `publicHostKey`（ホスト公開鍵ファイル全体の base64）で回避する、とした。
  そのため `hostName` は alias ではなく IP 直書きになっている
- **`nix.distributedBuilds = true` の明示が必須だった。** `buildMachines` を書くだけでは
  有効にならない。nix-darwin は `distributedBuilds = false`（既定）のとき
  `nix.settings.builders` を明示的に `null` へ上書きし、`/etc/nix/machines` が
  存在しても無視する（`modules/nix/default.nix` 945-969 行、rev 15abb8c で確認）。
  **下記「解消済み」の事故とは別経路で同じ「黙って効かない」状態になりうる**ため、
  適用後は `/etc/nix/nix.conf` から `builders = ` の行が消えていることを確認するのが確実
- `builders-use-substitutes` は distributed build の**送り手（MBP）側**の設定のため、
  `darwin/` 共通層ではなく `hosts/macbook/` に置いた（ADR-0004 ルール 3）
- `speedFactor = 2` は M4（10 コア）と M1 Pro（8 コア = 6P+2E）の世代差・コア数差からの
  見積りで**実測値ではない**。運用しながら見直す
- `hostName` が DHCP の IP 直書きのため、**ルーター側で hermes に IP 予約をしておかないと
  IP 変更で静かに壊れる**
- 検証時の注意: nix のビルド環境には `hostname` コマンドが無い（coreutils ではなく
  別パッケージ）。委譲の確認には `uname -n` を使う

**前提**: Phase 3-1 完了

**（解消済み）**: 2026-08-02 まで `nix.enable = false` により `nix.buildMachines` を
書いても `/etc/nix/machines` が生成されない制約があった（nix-darwin の `handleUnmanaged` の
内側にあるため、**エラーも警告も出ずに無視される**）。この制約が Phase 3-1c の
素の Nix 移行を決めた主因のひとつであり、現在は `nix.buildMachines` がそのまま使える。

### 4-2: `comma`（`,` コマンド）— `[ ]` 優先度: 高

インストールせずコマンドを即実行する。導入コストがほぼゼロ。

- [ ] `comma` と `nix-index` を導入
- [ ] `nix-index` データベースの定期更新を設定

**完了条件**: `, <command>` で未インストールのコマンドが実行できる。

### 4-3: `nix flake check` + CI — `[x]` 完了（2026-08-14）

設定自体の検証。リポジトリに `.github` が無く **CI 未設定のため純増**。
`link-tmux` の腐敗は CI があれば検出できていた。

- [x] `nix flake check` が通る状態にする（`checks.<system>.formatting` を追加）
- [x] treefmt-nix でフォーマッタを統合（mozumasu 採用）
- [x] GitHub Actions で `nix flake check` を実行（`.github/workflows/nix-check.yml`）
- [x] 初回 CI が緑になることを確認（`ubuntu-latest` で通過。macos runner は不要だった）

**完了条件**: push 時に設定の破綻が自動検出される。→ 達成。

#### 実施記録（2026-08-14）

- **適用範囲は nix + shell + yaml/toml に限定**。lua / markdown / json は対象外とした。
  `config/` 配下に nvim の設定（lua 36 / md 195 / json 63 ファイル）が同居しており、
  巻き込むと整形差分が巨大になって何が変わったかレビューできなくなるため
- **フォーマッタの既定値は、既存のコードスタイルに合わせて上書きした**（core.md の
  「既存のコードスタイルに合わせる」に従う）。判断の根拠は `treefmt.nix` のコメントに残した
  - `shfmt -ci`: `case` ブロックを 1 段字下げする既存スタイルを維持
  - `shfmt -bn`: `&&` / `|` を行頭に置く継続行スタイルを維持（リポジトリ内 6 件すべてが行頭型）
  - `shfmt -sr` は**不採用**。`> "$file"` はスペースあり多数派（16/18）だが
    `2>/dev/null` 系はスペースなしが全会一致（19/19）で、`-sr` は両者を区別できないため、
    有効化すると多数派 16 件を直すために全会一致 21 件を崩すことになる
  - `shfmt -kp` は**不採用**。桁揃えとインデントを区別できず、`-bn` 後の while ブロック等で
    壊れた出力（インデント 20 列超）を生んだ
  - `taplo align_comments = false`: 行末コメントの桁揃えで starship.toml の可読性が落ちるため
  - `taplo array_auto_expand = false`: 短い配列が複数行へ展開されるのを抑止
  - `yamlfmt retain_line_breaks = true`: taskfiles の意図的な空行区切りを潰さないため
- **アプリが書き戻すファイルは除外**した。整形しても次のアプリ起動で崩れ、CI が理由もなく
  赤くなるため。Phase 3-2 の「要注意 5 件」と全件突合し、`codex/config.toml` /
  `mise/config.toml` を個別に除外（`karabiner.json` / `lazy-lock.json` は `*.json`、
  `flake.lock` は既定の `*.lock` で既にカバー済み）。同じ理由で gh が書き込む
  `config/gh/config.yml` も除外
- `config/aerospace/layouts/*.sh` も除外。`move_app_to_workspace 'id'  'M1'` の
  **引数列の桁揃えが意図的**（どのアプリがどの画面へ行くか一覧できる）で、
  shfmt が単一スペースへ潰すため
- **`self` が `config/nix` サブツリーにしかスコープされない制約が判明した。**
  flake がリポジトリ直下ではなくサブディレクトリにあるため
  `git+file://...?dir=config/nix` として解決され、`self.outPath` に
  `scripts/` や `shared/` が含まれない。このため `checks.formatting` の検査対象は
  実質 nix サブツリーのみになる。**リポジトリ全体のフォーマット崩れ検出は
  CI 側の独立ステップ**（`nix run .#formatter -- --ci`、ライブチェックアウト全体が対象）が担う
- CI runner は `ubuntu-latest` を選定（`formatter.x86_64-linux` と
  `checks.x86_64-linux.formatting` のクロス評価がローカルで成功したため）。
  **初回実行で落ちたら `macos-14` へ切り替える**旨をワークフローにコメントで明記。
  `actions/checkout` の shallow clone で git+file flake が解決できない場合は
  `fetch-depth: 0` を追加する
- ローカル検証用に `task nix-check` / `task nix-fmt` を追加（既存の `task status` は
  home-manager の symlink drift 検査で役割が異なる）

### 4-4: Cachix Deploy — `[ ]` 優先度: 中

hermes が pull 型で設定に自動追従する。
現状は SSH して pull + `darwin-rebuild switch` を実行する必要がある。

**注意**: 外部サービス依存。まず手動運用に慣れてから。

**前提**: Phase 3-1 完了

### 4-5: sops-nix — `[~]` 基盤のみ導入・管理対象ゼロで待機（2026-08-14）

秘匿情報を暗号化したままコミットする。

**当初の「着手トリガー」（3 台目が実稼働し、各マシンへの手動配置が負担になったとき）は
点灯していないが、明示的な指示により前倒しで検証した。**
結果、**現時点で sops に載せるべき秘密は存在しない**と判明したため、
仕組みだけ導入して管理対象ゼロで待機させている。

- [x] `sops-nix` を flake input に追加し home-manager の `sharedModules` へ配線
- [x] `age` / `sops` を共通 CLI に追加、`.sops.yaml` と age 鍵を用意
- [x] `.gitignore` に平文の誤コミット防止パターンを追加
- [-] `~/.ssh/config` の暗号化管理 → **不採用**（下記）。平文で `ssh/config` に配線した

#### 棚卸しの結果: 配るべき静的な秘密が無い（2026-08-14）

| 候補 | 実態 | sops 向きか |
|---|---|---|
| `shared/cliproxyapi.conf.tmpl` の API キー | `task cliproxy-setup` が**各マシンで `openssl rand` により生成**。マシン内に閉じる | ✗ 配る必要がない設計 |
| cliproxyapi の OAuth（`codex-*.json` / `claude-*.json`） | `--codex-login` 等で対話ログイン、期限付きで自動リフレッシュ | ✗ 配っても即陳腐化 |
| `~/.claude-work` | 秘匿ストアではなく**会社アカウント用の Claude Code 設定ディレクトリ一式**。認証は `ccw` 実行時のログインで生成 | ✗ 静的な秘密ではない |
| `TAKT_ANTHROPIC_API_KEY` | `takt/config.yaml` のコメントに変数名のみ。**実体はどこにも未設定** | ○ 唯一の候補だが現在未使用 |
| SSH 秘密鍵 | 用途別に使い分け（`id_ed25519` / `id_ed25519_macmini` / `github_anvil`） | △ マシンごとに別鍵の方が漏洩時の影響を限定できる |

**参考: mozumasu の用途**（同じ構造を借りている先）は 6 件すべてが
「**対話ログインもその場生成もできない固定トークン**」だった
（GitHub Models API / GitHub Packages / 社内 MCP / OTel / カレンダー連携 / private marketplace 定義）。
当リポジトリはキーをその場生成・認証を対話ログインで賄う設計のため、**同じ需要が発生していない**。

#### `~/.ssh/config` を sops で管理しなかった理由

当初は「内部 IP を public リポジトリに晒さない」ことを動機に暗号化を試みたが、
以下 2 点で撤回した。

1. **動機が崩れた**: Phase 4-1 で `hosts/macbook/nix-builders.nix` に同じ IP を平文で
   コミットしている。`nix.buildMachines.hostName` は**評価時に必要な値**であり、
   sops（実行時にファイルを復号する仕組み）では**原理的に隠せない**。
   片方だけ暗号化しても意味がない
2. **macOS では dangling symlink の窓が構造的に避けられない**: sops-install-secrets の
   macOS 実装は `secretsMountPoint` に何を指定しても **RAM ディスクを強制マウント**する
   （`hdiutil attach ram://` + `newfs_hfs` + `mount`）。復号済み平文がディスクに一切
   触れない強い特性の裏返しとして、**再起動すれば復号先は 100% 消える**。
   ログイン時に launchd agent（`RunAtLoad`）が復元するが順序保証は無く、
   その間 `~/.ssh/config` が壊れうる。`sops.templates` も同じ symlink 機構を通るため回避不可

`~/.ssh/config` の中身は 44 行・5 エントリで、実質 `192.168.1.100`（公開済み）と
`github.com`（公開情報）のみ。RAM ディスク級の保護に見合わないと判断した。

**将来の着手トリガー**: GitHub Packages のトークンのように、**対話ログインも
その場生成もできない固定シークレット**を複数マシンで共有したくなったとき。
`.sops.yaml` に 1 行足せば載せられる状態にしてある。

**その時の設計結論**（今回の調査で確定済み、再調査不要）:
- 鍵は age 鍵ファイル方式（`sops.age.keyFile`）。macOS の既定パスは
  `~/Library/Application Support/sops/age/keys.txt`（`XDG_CONFIG_HOME` 未設定時）
- **darwin モジュールではなく home-manager モジュールを使う。**
  nix-darwin 版は `owner` の既定が `root` でユーザー所有のファイルを置けない。
  home-manager 版は macOS 専用の launchd agent を実装済みで、
  「home-manager は systemd 前提で macOS では動かない」という情報は**誤り**
- WSL2（Phase 3-3）では Linux なので同じ home-manager モジュールがそのまま使える
- **age 秘密鍵を失うと復号不能**。`~/Library/Application Support/sops/age/keys.txt` は
  リポジトリ外（パスワードマネージャー等）にバックアップすること

### 4-6: `specialisation` — `[ ]` 優先度: 低

同一ホストで設定バリアントを切り替える。
`ccw` / `taktw`（会社アカウント切替、`~/.claude-work`）の宣言化に使える。

**注意**: home-manager 版は**実験的機能**。採用するなら nix-darwin 側で。
現状の zsh 関数で動いているため急がない。

### 4-7: Tier 2 機能（採否未判断）— `[ ]`

| 機能 | 内容 |
|---|---|
| overlays | nixpkgs のパッケージを部分上書き・patch。upstream が壊れていても自分で直せる |
| 自作パッケージ（`packages/`） | nixpkgs 未収録の CLI を宣言に載せる。`agent-browser` / `git-gtr` / `baton`（自作 Go、buildGoModule） / `orchex`（自作） / `termaid` が候補（2026-08-02 更新。`takt` は公式 flake が判明したため flake input で宣言する方式に変更、自作パッケージ化は不要に） |
| `dockerTools` | Dockerfile なしで OCI イメージ生成。レイヤ最適化が自動 |
| flake templates | `nix flake init -t` でプロジェクト雛形 |
| `nh`（nix helper） | rebuild の UX 改善・差分表示（ryoppippi 採用） |

### 4-8: セキュリティ / OS 設定の宣言管理 — `[x]` 完了（2026-08-14）

ゲストログイン無効・画面ロック・Touch ID sudo（MBP 向け）等を
`system.defaults` / `security.pam` で宣言化する。検証は hermes で行う。

- [x] hermes で安全な項目（loginwindow / screensaver 等）を宣言（`hosts/hermes/security.nix`）
- [x] hermes へ適用して挙動確認 → **意図しないサービス断なし**（下記検証結果）
- [x] MBP の loginwindow / screensaver を宣言（`hosts/macbook/security.nix`）
- [-] **Touch ID sudo は不採用**（下記「Touch ID sudo の顛末」）。
      `security.pam.services.sudo_local.touchIdAuth` は宣言しない
- [-] アプリケーションファイアウォールは**要設計** → hermes 分は**解決**（下記実施記録）。
      MBP は現在無効で、有効化は実挙動の変化を伴うため**今回スコープ外**とした
      （常用ネットワークサービスの洗い出しが先。別途再検討）

**完了条件**: hermes のセキュリティ設定が宣言で再現でき、意図しないサービス断が無い。→ 達成。

#### Touch ID sudo の顛末（2026-08-14、不採用）

**nix 側は正しく動作していたが、macOS 26.5.2 側で Touch ID が発動しなかった。**

確認できたこと（すべて実機）:

| 項目 | 結果 |
|---|---|
| `/etc/pam.d/sudo_local` の生成 | `pam_tid.so` が正しく書かれる |
| `/etc/pam.d/sudo` | `auth include sudo_local` を先頭に持つ（macOS 14+ の既定） |
| Touch ID の登録 | 有効（`bioutil -r` で `Effective biometrics for unlock: 1`） |
| 本体の状態 | 開いた状態（クラムシェルではない） |
| `SUDO_ASKPASS` 等 | 未設定 |
| **実際の挙動** | **指紋を求められない。** Authorization Services の認可ダイアログ（パスワード入力欄のみ）が出て、Touch ID センサーに触れても無反応 |
| `pam_reattach` の関与 | **無関係。** `reattach = false` にして switch し直しても同じ挙動 |

Apple は macOS 15.4 で `sudo` を Rust 実装へ置き換えており、その過程で PAM の扱いが
変わった可能性があるが、`/usr/bin/sudo` は setuid（`-r-s--x--x`）で読めず未確認。

**不採用の理由**: 指紋が使えない以上、GUI ダイアログはマウス操作を強いるぶん
CLI でのパスワード入力より不便なだけ。宣言を外すと `sudo_local` は 0 バイトの
空ファイルとして生成され（nix-darwin は宣言の有無に関わらずこのファイルを管理する）、
`pam_opendirectory` によるターミナル内の `Password:` 入力に戻る。

将来 OS 側で挙動が変わったら再検討する。`hosts/macbook/security.nix` に
経緯をコメントで残してあるので、再訪時に同じ検証を繰り返さずに済む。

#### 実施記録（2026-08-14）

- **層の配置**: Touch ID は MBP 専用（hermes はヘッドレスで生体認証デバイスが無い）のため
  共通層へ昇格せずホスト固有層に置く（ADR-0004 ルール 3）
- **ファイアウォールの「要設計」は解決した。** hermes は実機で既に有効・ステルス ON で、
  miniserve を per-app 許可 2 件で明示的に通していたが、**すべて手動設定で nix 管理外**だった。
  nix-darwin の `networking.applicationFirewall` モジュールは global 系オプション
  （`--setglobalstate` / `--setallowsigned` / `--setallowsignedapp` / `--setstealthmode`）
  しか操作せず、**per-app の allow/block には触れない**ため、現在値をそのまま宣言すれば
  miniserve の許可を壊さずに宣言管理へ取り込める
- **`blockAllIncoming` は意図的に宣言しない。** true にすると per-app 許可を無視して
  受信を全遮断し、miniserve どころか SSH ごとリモートからロックアウトされる。
  同モジュールは全オプションが `nullOr bool` の既定 `null` で、activation script が
  `lib.optionalString (cfg.X != null)` でガードされているため、**未宣言なら
  `setblockall` は一度も呼ばれない**（pin 済み rev の実ソースで確認）
- hermes への適用は **tmux 内で実行**すること。`switch` のたびに `socketfilterfw` が
  再実行されるため、適用の瞬間に SSH が切れうる（切れても tmux 内の処理は継続する）
  → 実際には SSH 断は発生しなかった

#### 検証結果（2026-08-14、hermes 適用後）

**per-app 許可は壊れないことを実証した。** 事前の懸念（宣言管理がアプリ個別の
許可設定を消すのではないか）は杞憂で、モジュール実装の読みどおりだった。

| 項目 | 適用後の実測値 |
|---|---|
| `--getglobalstate` | `Firewall is enabled. (State = 1)` — 維持 |
| `--getstealthmode` | `stealth mode is on` — 維持 |
| `--listapps` | miniserve **2 件とも `Allow incoming connections`**（nix store 版 / brew Cellar 版） |
| miniserve の稼働 | `*:18080 (LISTEN)`、MBP からの `curl` は 200 |
| `GuestEnabled` | 0 |
| `askForPassword` / `askForPasswordDelay` | 1 / 0（**効いた**。要検証としていた懸念は解消） |

**判明したこと: `system.defaults` のユーザー単位設定は `system.primaryUser` にしか入らない。**
hermes で `defaults read com.apple.screensaver askForPassword` を **admin ユーザー**で
実行すると「does not exist」になるが、`agent`（= primaryUser）では `1` が返る。
screensaver / dock / finder 等のユーザー単位設定を今後増やすときに効いてくる性質。
複数ユーザーが居るホストで「全ユーザーに効かせたい」場合は別の手段が要る
（hermes はヘッドレスかつ運用は agent なので実害なし）

### 4-9: Nix store の自動 GC — `[x]` 完了（2026-08-02）

常時稼働の hermes で、放置すれば世代が溜まり続ける問題への予防。
実測（2026-08-02）: system プロファイル 4 世代 / store 7.1G / ディスク空き 119Gi。
**逼迫はしておらず緊急性は低い**。コストがほぼ無いため予防として入れた位置づけ。

- [x] `hosts/hermes/nix-gc.nix` で `nix.gc.automatic` を宣言（週次・日曜 3:15・`--delete-older-than 30d`）
- [x] hermes に適用し、`/Library/LaunchDaemons/org.nixos.nix-gc.plist` の生成を確認
- [ ] 30 日後、実際に古い世代が削除されることを確認（初回発動待ち）

**経緯**: 当初は `nix.enable = false`（Determinate 運用）のため
`nix.gc.automatic` / `nix.optimise.automatic` が assertion で弾かれ、
`launchd.daemons` の自前宣言 + コマンドパス直書きで代替していた。
Phase 3-1c の素の Nix 移行で標準オプションが使えるようになり、そちらへ寄せた。
`config.nix.package` も解決できるようになったためパス直書きが不要になっている。

**Determinate Nixd の自動 GC との違い**（移行前の調査記録）: Determinate も既定で
自動 GC を持つが、判定軸が「ディスク空き容量」（5〜20% を維持、5% 未満で緊急モード）であり、
本設定の「世代の古さ」とは守備範囲が異なっていた。世代は GC root のため、
世代を消さない限り store のパスは回収されない。

**完了条件**: hermes の古い世代が人手を介さず週次で削除される。

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
| **stow** | **廃止済み**（2026-08-07）。dotfiles 配線は home-manager に一本化 |
| **mise** | **残す**。境界は「言語ランタイム = mise、それ以外の CLI = Nix」。例外: nixpkgs 未収録の pipx 系 CLI（現状 `termaid` のみ）は mise の pipx backend が最も低コストのため mise に置いてよい（2026-08-02、[PHASE-3-2-CLI-INVENTORY.md](PHASE-3-2-CLI-INVENTORY.md)。将来は Phase 4-7 で自作パッケージ化） |
| **brew** | GUI / cask と nixpkgs 未収録パッケージ用に**恒久的に残る**。`homebrew.*` で宣言化 |

> 2026-08-02: 全管理系統（brew / mise / npm -g / go install / uv tool / pipx / cargo /
> 野良バイナリ）の横断棚卸しを実施し、境界の運用は破綻していないことを確認
> （方針改訂不要と判断）。詳細は PHASE-3-2-BREW-INVENTORY.md / PHASE-3-2-CLI-INVENTORY.md。

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
