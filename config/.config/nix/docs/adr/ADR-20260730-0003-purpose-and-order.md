# ADR-20260730-0003: Nix 導入の目的と着手順序の再定義

- ステータス: 採用
- 決定日: 2026-07-30
- 関連: [ADR-20260424-0001](ADR-20260424-0001-nix-layout.md)（ディレクトリ構成） /
  [ADR-20260729-0002](ADR-20260729-0002-multi-host-adoption.md)（**本 ADR で一部改訂**）

> ## ⚠️ 改訂注記（2026-07-31）
>
> Phase 3-1（hermes）実施の過程で、以下の記述に**事実誤認**が判明した。
> 記録として原文は残す。
>
> | 本 ADR の記述 | 実態・改訂後 |
> |---|---|
> | 目的 1「ヘッドレスな hermes に GUI cask を乗せない」 | **撤回**。hermes 実機に GUI cask 7 個（1password / 1password-cli / codex / ghostty / google-chrome / orbstack / zed）が存在し、「ヘッドレスだが、たまに GUI でも使う」実態が判明。目的 1（環境依存の切り分けの宣言的表現）は「cask ゼロ」ではなく「ホストごとの cask 宣言 + zap による宣言外の自動削除」で達成する |
>
> 詳細は [ROADMAP.md](../ROADMAP.md) Phase 3-1 の「実施記録（2026-07-31）」を参照。

## 背景

ADR-20260729-0002 の翌日に方針を精査した結果、前提に複数の誤りと不足が見つかった。

### ADR-0002 の事実誤認

ADR-0002 は背景に「**WSL2 上で日常的に開発**」と記載し、これを根拠に着手順序を WSL2 優先とした。
その後の確認で実態は以下だった。

- 会社支給 Windows / WSL2 は **予備の開発端末**
- 社内業務が発生した場合に使う想定だが、**現状は稼働プロジェクトがなく日常的には使用していない**
- 普段の開発は **MacBook Pro が主流**

したがって ADR-0002 が「3 つのトリガーが全点灯」とした判定のうち、
**「Linux を日常的に触る」は現時点では点灯していない**。

### 参考リポジトリの調査結果

[mozumasu/dotfiles](https://github.com/mozumasu/dotfiles) と
[ryoppippi/dotfiles](https://github.com/ryoppippi/dotfiles) を調査し、以下を確認した。

- mozumasu の `robusta` は **WSL (Ubuntu) 上の standalone home-manager**。
  nix-darwin 構成（geisha / mocha / bourbon）とは独立した構成。
  → flake の出力が `darwinConfigurations` と `homeConfigurations` の **2 系統に割れる**
- WSL では `targets.genericLinux.enable = true` が必要
- ドットファイルは **`mkOutOfStoreSymlink` が主軸**（ADR-0002 の D1 方針は妥当）
- ただし `xdg.configFile` + `mkOutOfStoreSymlink` には**循環参照の罠**があり、
  複雑なケースは `home.activation` で手続き的に `ln -s` する必要がある。
  ryoppippi は共通ドットファイルを全て activation script で処理している
  → **「home-manager にすれば宣言的に完結する」は理想であって実態ではない**
- `~/.claude/settings.json` 問題は mozumasu も踏んでおり、
  **「Nix 生成 → 書き込み可能コピー + Stop hook で drift 検出」**で解決している
- mozumasu は `homebrew-personal.nix` / `homebrew-work.nix` で会社/個人を分離している

### 動機に関する事実確認

- **launchd は nix-darwin を選ぶ理由にならない**。home-manager にも `launchd.agents` があり、
  ユーザーレベルのエージェントは単体で管理できる。
  かつ自機の LaunchAgents はほぼサードパーティ製アプリの自動更新で、
  **自己管理対象は `homebrew.mxcl.cliproxyapi` の 1 つのみ**
- **zsh 起動時間は 0.244 秒**（10 回平均）。zcompile / init キャッシュ / zsh-defer は未導入だが、
  **最適化の余地が小さいため目的から外す**
- スキル管理（`taskfiles/skills.yml` の 70 行の手書き shell）については、
  現状困っていないため**目的から外す**

### 現行構成に見つかった腐敗

宣言と実態のズレが検出されないまま放置されている実例。

- `taskfiles/link.yml` の `link-tmux` / `restow-tmux` が**存在しない `tmux/` パッケージ**を参照
  （tmux 設定は `config/.config/tmux/` にある）。`task restow` は失敗する
- `config/.config/wezterm.bak` の 17 ファイルが git 管理下に残存

### 差分が複製として表現されている実例

- `hermes/home/.config/tmux/tmux.conf` は本体（10 ファイル分割ローダ）と**共通行 0** の再実装
- `hermes/home/.zsh/hermes-helpers.zsh` は `.zshrc` の再実装。
  かつ**こちらだけ `command -v` ガードが入っており、品質が分岐している**
- `hermes/Brewfile` と `Brewfile` の二重管理
- `scripts/install-hermes-subset.sh`（125 行）

## 選択肢

### A. ADR-0002 のまま WSL2 から着手

- Linux は Nix が最も素直に動き、壊しても `wsl --unregister` で作り直せる
- しかし **投資先が日常的に使わない端末**になり、学習のフィードバックループが回らない
- さらに **Linux での学習は nix-darwin に転用されない**（launchd / `homebrew.*` /
  system defaults はすべて darwin 固有）

### B. hermes（Mac mini）から着手（採用）

- macOS なので **学習がそのまま MacBook Pro に転用される**
- ターミナルのみ（ヘッドレス）で GUI 移行の考慮が不要
- メイン機ではないため、壊れても業務が止まらない
- `install-hermes-subset.sh` / `hermes/Brewfile` / `hermes-helpers.zsh` の
  **重複解消という測定可能な成果がある**
- brew パッケージが 18 個と少なく、`homebrew.brews` の宣言が現実的なサイズ
- Hermes Agent が常時稼働しており、日常的に動いている

### C. MacBook Pro から着手

- 恩恵は最大だが、移行時に `shell` パッケージのリンクを張り替える工程がある
- 失敗するとシェルが起動しない。**メイン機で最初にやるべきではない**

## 決定

**B を採用。** 併せて目的を再定義する。

### 目的（優先順）

1. **環境依存の切り分けを宣言的に表現する** ← 主目的
   ヘッドレスな hermes に GUI cask を乗せない、といった「乗せない」を宣言として書く
2. **新端末で環境を引き継げるようにする**
   現状の新端末セットアップは 8 手順あり、順序が暗黙。これを 1 コマンドにする
3. **複数マシンで同一環境を構築する**

### 目的から外すもの（明示）

| 項目 | 理由 |
|---|---|
| スキル管理の宣言化 | 現状の `sync-skills` で困っていない |
| devShell + direnv | mise と役割が重複。mise を残す方針のため価値がない |
| zsh 起動最適化 | 実測 0.244 秒で既に十分速い |
| launchd の宣言管理 | 自己管理対象が 1 つだけで、かつ home-manager 単体で可能 |

### 副次目標（Tier 1、順次導入）

- **Remote builders** — hermes をビルドマシンにし、MacBook Pro のビルド負荷を逃がす。
  両機とも `aarch64-darwin` なので成果物がそのまま使える。
  **stow では原理的に代替不可能な唯一の価値**であり、hermes を最初に構築する理由を補強する
- **`comma`（`,`）** — インストールせずコマンドを即実行。導入コストがほぼゼロ
- **`nix flake check` + CI** — 設定自体の検証。リポジトリに `.github` が無く CI 未設定のため純増
- **Cachix Deploy** — hermes が pull 型で設定に自動追従する
- **sops-nix** — 秘匿情報を暗号化したままコミットする

### 着手順序

**hermes → MacBook Pro → WSL2**（ADR-0002 の順序を反転）

WSL2 は「実稼働し始めたら着手する」**条件付き**に格下げする。

### nix-darwin を最初から使う

ADR-0002 では nix-darwin を Phase 4（未判断）としていたが、**最初から使う**。

- 理由は **`homebrew.onActivation.cleanup = "zap"`**。
  宣言にないパッケージが自動削除されるため、上記「腐敗」と同種のズレが構造的に発生しなくなる
- launchd は理由に含めない（実態が伴っていない）

### 方式（ADR-0002 の D1 を修正）

- **原則 `mkOutOfStoreSymlink`（編集が即反映される方式）を維持する**
- ただし **「全面固定」ではなく「原則 + 例外」とする**。
  循環参照の罠や、アプリが書き込むファイルには `home.activation` を使う。
  **例外を使う場合は理由をコメントに残す**
- `~/.claude/settings.json` のような**アプリが書き込むファイルは除外リストで管理**する
- 設定内容を Nix 言語で書き直す方針（`programs.*` への全面移行）は採らない

### 実装方針

**mozumasu の構造をコピーして自分用に削る。** ゼロから設計しない。
特に `hosts/common` + `homebrew-personal.nix` / `homebrew-work.nix` の分け方と、
`dotfiles.nix` の `mkLink` パターンを流用する。

## 正直な前提（記録しておく）

**実利だけで判断するなら、Nix は現時点で「必要」ではない。**

- hermes の重複問題は、stow パッケージを `config-common` / `config-macos-gui` に分割し、
  hermes では common だけ stow することでも解決できる
- tmux は既に 10 ファイル分割のローダ構成なので、`source-file` のリストを変えるだけで済む
- stow 再設計のコストは Nix 導入コストより一桁安い

それでも導入するのは、**学習と将来への布石**という動機を認めた上での投資である。
この記述を残すのは、半年後に「なぜ入れたのか」を追えるようにするため
（ADR-0002 の Phase 0 が 3 ヶ月停滞した原因は、目的が曖昧だったことにある）。

## 影響

- **ADR-20260729-0002 の背景記述（WSL2 の稼働実態）と着手順序を本 ADR で改訂する。**
  ADR-0002 側にも改訂注記を追加する
- [ROADMAP.md](../ROADMAP.md) を全面改訂し、**完了状態を持つ形式**にする
- `docs/PHASE-3-1-WSL2.md` を `docs/PHASE-3-3-WSL2.md` へリネームする（着手順序の変更に伴う）
- Phase 4（旧: nix-darwin 移行）は Phase 3 に吸収し、Phase 4 は
  **付加機能（Tier 1〜2）の順次導入**に置き換える
- Phase 2（devShell 拡張）は「対象外」に変更する（mise と重複）

## 未確定事項（将来の ADR で扱う）

- `home.file` / `xdg.configFile` と `home.activation` の使い分け基準（実装しながら確定する）
- アプリが書き込むファイルの除外リストの確定（`~/.claude/settings.json` 以外に何があるか）
- `settings.json` drift 検出を mozumasu 方式（Stop hook）で実装するか
- WSL2 着手の判断基準（どの程度稼働したら着手するか）
- Tier 2 機能（overlays / dockerTools / flake templates / nh）の採否
- stow の最終的な廃止時期（MacBook Pro 移行完了後）
