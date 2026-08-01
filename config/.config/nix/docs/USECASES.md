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

## すでに手に入れた能力（2026-08-01 時点）

振り返り用。「Nix 化して何が変わったか」の実績。

| 能力 | 具体的に何が起きたか |
|---|---|
| 宣言的パッケージ管理 + zap | 宣言外の brew が自動削除される。「いつの間にか入っていた/消えていた」が構造的に消滅 |
| dotfiles 配線（mkOutOfStoreSymlink） | stow と同じ編集即反映のまま、ホスト差分（hermes の tmux 等）も宣言で表現 |
| launchd 宣言管理 | llama-swap / miniserve が手書き plist から宣言生成に。マシン再構築時も switch 一発 |
| 世代管理 / rollback | switch のたびにスナップショット。数秒で切り戻し可能 |
| multi-host | 1 つの flake で hermes を管理。MBP / WSL2 も同じ骨格に載る |
| 環境の自己文書化 | 「マシンに何が入っているか」= リポジトリのファイル。git 履歴が変更ログ |

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

---

## 留意事項: Determinate Nix の政治的リスク（2026-08-01 記録）

`[世]` 2025 年 9 月、Determinate Systems が「2026 年から upstream Nix を配布せず
Determinate Nix のみ配布する」と発表しコミュニティが反発。公式ワーキンググループによる
upstream 専用フォークインストーラーの作成、Nix Steering Committee の不信任投票にまで
発展した（[経緯](https://www.haskellforall.com/2025/10/nix-steering-committee-vote-of-no.html)）。

- 当方への影響: hermes は Determinate pkg 版を採用済み。**Phase 3-2 の
  「MBP を Determinate pkg に統一」は着手前に情勢を再確認すること**
- 緩和要因: 当方の flake は `nix.enable = false` で Nix 本体の出自に依存しない
  設計のため、将来 upstream 系インストーラへの乗り換えは可能（ロックインは浅い）

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
