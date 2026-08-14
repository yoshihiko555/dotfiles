# Nix ユースケースカタログ（次に何をやるかの判断材料）

「Nix を使うと何ができるか」を価値・コスト・向き不向きの軸で並べたカタログ。
**進行状態・着手順の正典は [ROADMAP.md](ROADMAP.md)**（本書は状態を持たない）。
各項目の () 内は ROADMAP の対応番号。

## 出典

| タグ | 意味 |
|---|---|
| `[moz]` | [mozumasu/dotfiles](https://github.com/mozumasu/dotfiles) の実物調査（2026-07-31 クローン・深掘り） |
| `[ryo]` | [ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) の実物調査（2026-08-01 クローン・深掘り） |
| `[世]` | コミュニティ世論調査（2026-08-01。NixOS Discourse / Lobsters / 個人ブログ / GitHub。定番度: 高/中/低） |

---

## すでに手に入れた能力（2026-08-02 時点）

振り返り用。「Nix 化して何が変わったか」の実績。

| 能力 | 具体的に何が起きたか |
|---|---|
| 宣言的パッケージ管理 + zap | 宣言外の brew が自動削除される。「いつの間にか入っていた/消えていた」が構造的に消滅 |
| dotfiles 配線（mkOutOfStoreSymlink） | stow と同じ編集即反映のまま、ホスト差分（hermes の tmux 等）も宣言で表現 |
| launchd 宣言管理 | llama-swap / miniserve が手書き plist から宣言生成に。マシン再構築時も switch 一発 |
| 世代管理 / rollback | switch のたびにスナップショット。数秒で切り戻し可能 |
| multi-host | 1 つの flake で hermes を管理。MBP / WSL2 も同じ骨格に載る |
| 環境の自己文書化 | 「マシンに何が入っているか」= リポジトリのファイル。git 履歴が変更ログ |
| **宣言からの完全再現（実証済み）** | Phase 3-1c で `/nix` を丸ごと削除し別のインストーラで入れ直したが、`darwin-rebuild switch` 一発で**移行前と同一の store パス**の system が再構築された。所要 1 時間・手動作業は 2 手順のみ。ROADMAP の目的 2 が実地で確認された |

---

## 候補カタログ

### 既知の困りごとに直結するもの（優先検討）

| 項目 | 何が嬉しいか | コスト | 出典・所見 |
|---|---|---|---|
| **Claude settings.json の cp + Schema 検証** | 既知の「settings.json symlink 破壊問題」（本体 UI の書き込みでリンクが壊れる）を、**そもそも symlink にしない**ことで根治。activation で `cp --no-preserve` + JSON Schema 検証 | 小（数十行） | `[ryo]` が実装済みのパターン。CLAUDE.md / commands 等は引き続き symlink でよい。**投資対効果最高クラス** |
| **git hooks で nix 変更時に自動 switch** | flake / nix ファイルの変更を post-merge / post-checkout 等で検知して自動 switch。「反映し忘れ」を構造的に防止 | 中（`[ryo]` は nushell 実装。bash 移植可） | `[ryo]`。hermes の「pull したのに switch 忘れ」対策としても効く |
| **sudo keep-alive + AI エージェント検出** | switch 長時間実行中の sudo 失効防止。エージェント実行時は TTY 依存の出力（nix-output-monitor）をフォールバック | 極小（シェル数行） | `[ryo]`。flake apps（`nix run .#switch`）導入とセットで |

### 実利が大きいもの

| 項目 | 何が嬉しいか | コスト | 出典・所見 |
|---|---|---|---|
| **Remote builders**（4-1） | MBP の重いビルドを hermes に委譲 | 中（root の SSH 鍵配置・builder 登録） | `[世]` 定番度: 中。SSH ベースの確立された手法。**stow では原理的に不可能な唯一の価値** |
| **flake check + CI**（4-3） | push 時に設定の破綻を自動検出 | 小〜中 | `[世]` update-flake-lock action + flake-checker-action の週次 Bot PR が「意識高い個人運用」の型。`[ryo]` は input 別 PR + auto-merge + **tirith スキャン（prompt injection 検知）**まで自作。まず check だけの最小構成で始め、自動更新は後段で |
| **セキュリティ / OS 設定の宣言管理**（4-8） | ゲストログイン無効等の宣言化。**Touch ID sudo は pam_reattach 併用で tmux 内でも効く**（MBP 向け） | 小 | `[ryo]` `security.pam.services.sudo_local.text` + pam-reattach 実装あり。`[moz]` も touchIdAuth 採用。ファイアウォールのみ要設計（miniserve の外部公開と干渉） |
| **comma + nix-index**（4-2） | `, jq` で未インストールコマンドを即実行 | 極小 | `[世]` 定番度: 高（ロングセラー、愛用者多数）。`[ryo]` も nix-index-database 採用 |
| **masApps（App Store 宣言管理）** | App Store アプリも `homebrew.masApps` で ID 指定の宣言管理に | 小（mas 追加のみ） | `[ryo]` 採用。**Phase 3-2（MBP）で効く**。MBP の手動インストール App Store アプリを宣言に載せられる |

### 運用を楽にするもの

| 項目 | 何が嬉しいか | コスト | 出典・所見 |
|---|---|---|---|
| **Nix store の自動 GC**（4-9、導入済み） | 常時稼働機で溜まり続ける世代を週次で削除。`nix.gc.automatic` の 3 行で完結 | 極小 | 当方調査（2026-08-02）。実測は 4 世代 / store 7.1G / 空き 119Gi で**逼迫しておらず緊急性は低い**が、コストがほぼ無いため予防として導入。Determinate 運用時は assertion で使えず launchd 自前宣言が必要だったが、素の Nix 移行で標準オプションに戻せた |
| **nh**（4-7） | rebuild の UX 改善・差分表示・`nh clean` | 極小 | `[世]` 定番度: 中〜高（上昇中）。ただし `[ryo]` は **gc 専用**にしか使わず日常は自作 flake apps。「有名 = 全面採用」ではない実例 |
| **Cachix / Attic**（4-4） | hermes の pull 型自動追従、ビルド共有 | 中（外部依存 or 自前ホスト） | `[世]` 個人利用は自己ホストの Attic が伸びている（Cachix 値上げリスクの保険）。急がない |
| **sops-nix / agenix**（4-5） | 秘匿情報の暗号化コミット | 中 | `[世]` 使い分け論調: 初心者・少数シークレットは agenix、束で扱うなら sops-nix。`[moz]` は sops、`[ryo]` は**不採用**（無しで回る規模なら不要という実例） |
| **specialisation**（4-6） | 同一ホストの設定バリアント切替 | 中 | 現状 zsh 関数で動いており急がない |
| **nix/ 直下に「どこに何を書くか」対応表** | AI エージェントが設定編集で迷わない | 極小 | `[ryo]` の `nix/CLAUDE.md`。当リポジトリの AGENTS.md 運用と相性良 |

### 表現力を広げるもの（Tier 2）

| 項目 | 何が嬉しいか | コスト | 出典・所見 |
|---|---|---|---|
| **自作パッケージ**（4-7） | git-gtr / agent-browser / takt を宣言に載せる。**git-gtr 自作化で brew の git 依存も消える** | 中 | `[moz]` は 14 個の自作 derivation を運用。git-gtr（純シェル）が初題材に最適 |
| **overlays**（4-7） | nixpkgs の部分上書き・patch | 中 | `[moz]` `[ryo]` とも採用。必要になってから |
| **brew-nix** | cask を `pkgs.brewCasks.*` として Nix パッケージ扱いに（launchd 自動起動宣言とも組める） | 中〜高 | `[ryo]` 採用（cask アプリのログイン時自動起動を launchd 宣言化する `mkLoginAgent` パターンが便利）。効果に対して導入コストやや重 |
| **mac-app-util** | Nix 導入 GUI アプリの Spotlight / Dock 登録 | 小 | `[世]` 定番度: 中〜高（「入れて当然」枠）。ただし**当方は GUI を brew cask に置く方針のため現状は恩恵薄**。GUI を Nix 側に寄せるなら必須 |
| **linux-builder** | macOS 上で Linux バイナリ / Docker イメージをビルド | 中 | `[世]` 用途が明確な人向け。**WSL2 があるので二重投資になりやすく優先度低** |
| **dockerTools / flake templates**（4-7） | OCI イメージ生成 / プロジェクト雛形 | 中 / 小 | `[世]` templates は「あると便利」レベル。用途が出てから |

### 対象外・見送りの再確認（世論と突き合わせた結果）

| 項目 | 判断 | 根拠 |
|---|---|---|
| devShell + direnv（Phase 2 で対象外） | **見送り継続** | `[世]` 定番度は高いが、mise 公式が direnv 併用を非推奨（PATH 競合）。mise 前提の当方には合わない、という判断が世論とも整合 |
| nixvim / nvf / lazy2nix 系（Phase 5） | **見送り継続** | `[世]` 賛否割れ（Lua→Nix 変換の起動速度低下報告あり）。`[ryo]` は lazy2nix を自作運用しているが neovim 依存度が高く汎用性低と自己評価 |
| stylix（テーマ統一） | **見送り** | `[世]` 完成度の評価は高いが、`[moz]` `[ryo]` とも不採用。Tokyo Night で統一済みの当方に追加価値薄 |
| impermanence | **対象外** | `[世]` NixOS 専用の概念。macOS では成立しない |
| Determinate Nix 公式 nix-darwin モジュール（`determinateNix.enable`） | **不採用**（2026-08-02） | `nix.enable = false` 問題の正攻法の解で、`customSettings` により宣言性を回復できた（3.15.2 以降）。ただし設定が Determinate 固有の書き方に固定され離脱コストが上がるため、素の Nix への移行（Phase 3-1c）を選んだ。詳細は下記「検討した 3 案と選定」 |

---

## 留意事項: Determinate Nix の政治的リスク（2026-08-01 記録 / 2026-08-02 当方への影響は解消）

`[世]` 2025 年 9 月、Determinate Systems が「2026 年から upstream Nix を配布せず
Determinate Nix のみ配布する」と発表しコミュニティが反発。公式ワーキンググループによる
upstream 専用フォークインストーラーの作成、Nix Steering Committee の不信任投票にまで
発展した（[経緯](https://www.haskellforall.com/2025/10/nix-steering-committee-vote-of-no.html)）。

**この表明は実行された**（2026-08-02 確認）。Determinate Nix Installer は
2025-11-10 に既定を Determinate Nix へ変更し、**2026-01-01 に upstream Nix の
インストールオプションを完全廃止**した（`--prefer-upstream-nix` フラグも撤去）。

- **当方への影響は解消**: Phase 3-1c で hermes を素の Nix へ移行し Determinate 系から離脱した。
  素の Nix の入手には上記ワーキンググループが公開するコミュニティ版
  [`NixOS/nix-installer`](https://github.com/NixOS/nix-installer) を使う
  （Determinate Nix Installer のフォーク。macOS aarch64 は Stable。MBP も同系統）
- ただし**離脱の主因は政治的リスクそのものではなく、下記の技術的制約**だった

---

## 記録: `nix.enable = false` が塞ぐ nix-darwin オプション（2026-08-02、移行により解消）

**本節は解消済みの制約の記録である。** 将来 Determinate Nix を再検討する際の判断材料。

Determinate Nix は自前デーモンが Nix 本体を管理するため、nix-darwin 側で
`nix.enable = false` が必須になる。この 1 行が **`nix.*` 配下をほぼ全面的に無効化する**。
遮断の仕組みは 3 通りあり、危険度が大きく異なる。

| 型 | 仕組み | 挙動 | 危険度 |
|---|---|---|---|
| **サイレント無視** | nix モジュールの config 全体が `handleUnmanaged`（= `mkIf cfg.enable`）で包まれる | 設定を書いても**エラーも警告も出ず**、ファイルが生成されない | **最高** |
| 参照即エラー | `managedDefault` が 13 個のオプションのデフォルト値を `throw` に差し替える | 値を書かずに参照した時点で評価が落ちる（`config.nix.package` 等） | 中 |
| 明示的拒否 | `assertion = cfg.automatic -> config.nix.enable` | メッセージ付きでビルドが止まる（`nix.gc` / `nix.optimise`） | 低（親切） |

サイレント無視の対象には `/etc/nix/nix.conf`・`registry.json`・**`/etc/nix/machines`**
（`nix.buildMachines` の出力先）・`NIX_PATH` が含まれる。とくに 4-1 Remote builders は
「宣言したのに分散ビルドが動かない」という気づきにくい形で破綻するため、
**この項目が移行を決めた主因**となった。

Determinate を再採用する場合は、使いたい `nix.*` オプションが nix-darwin の
`modules/nix/default.nix` で `handleUnmanaged` の内側にないかを必ず確認すること。

### 検討した 3 案と選定（2026-08-02、[ADR-0005](adr/ADR-20260802-0005-upstream-nix-migration.md)）

| 案 | 内容 | 判定 |
|---|---|---|
| A. 現状維持 | 機能ごとに `launchd.daemons` 自前宣言や `nix.custom.conf` 手書きで代替 | **不採用**。代替手段が宣言の外へ漏れ、設定を書き溜めるほど移植コストが上がる |
| B. Determinate 公式 nix-darwin モジュール | `determinateNix.enable = true` + `customSettings` で宣言性を回復（3.15.2 以降、hermes は 3.21.8 で利用可だった） | **不採用**。宣言性は戻るが設定が Determinate 固有の書き方に固定され、将来の離脱コストが上がる |
| **C. 素の Nix へ移行** | Determinate を外し upstream Nix へ | **採用**。MBP と系統が揃い、制約が根本から消える |

C は「Tahoe でインストールできないのではないか」が懸念だったが、
失敗していたのは **Determinate 版インストーラ**であり、`NixOS/nix-installer` では
問題なく完了した。失ったのは lazy-trees と並列評価の 2 つで、
いずれもヘッドレスで日常的に nix を叩かない hermes では恩恵が小さいと判断した。

### 参考リポジトリはこの問題に直面していない（重要）

実物調査（2026-08-02）の結果、**`[moz]` `[ryo]` とも Determinate Nix を採用していない**。
両者の flake inputs に determinate は無く、`nix.settings.*` を通常どおり使っている
（`[moz]` は `darwin/nix.nix` で experimental-features、`[ryo]` は `darwin/system.nix` で
trusted-users / max-jobs 等）。**したがって両者から流用できる解法は無い**。
当方が Determinate になったのは選択ではなく、macOS 26 でシェル版インストーラが失敗し
pkg 版を使った結果だった（Phase 3-1 実施記録）。**2026-08-02 の移行で両者と同じ構成になった**ため、
以後は `nix.settings` まわりの実装をそのまま参考にできる
（`[ryo]` の `darwin/system.nix` はインストーラ生成の nix.conf を宣言で再現した内容であり、
当方の `darwin/default.nix` も同じ方針を採った）。

---

## 判断の軸（迷ったときのガイド）

1. **実利が先、学習は従**: ADR-0003 の「正直な前提」の通り、Nix は学習込みの投資。
   ただし次の一手を選ぶときは実利（時間・安全性が具体的に改善するか）を優先する
2. **既知の困りごとから潰す**: settings.json 問題のように「すでに実害が観測されたもの」への
   対策は、汎用的な機能拡充より優先してよい
3. **メイン機に触る前に保険を**: Phase 3-2（MBP）の前に CI（4-3）を入れる価値は高い
4. **外部依存は最後**: Cachix / sops など外部サービス・鍵管理が絡むものは、
   手動運用の痛みを実感してから
5. **有名 ≠ 自分に必要**: nh を gc 専用にしか使わない ryoppippi、sops を持たない ryoppippi、
   CI を持たない mozumasu のように、上級者ほど取捨選択している
6. **1 switch = 1 変更クラス**: 検証はカテゴリを混ぜず、小さく切って rollback 可能に保つ
