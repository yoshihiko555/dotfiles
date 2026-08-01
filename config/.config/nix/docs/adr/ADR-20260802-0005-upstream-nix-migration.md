# ADR-20260802-0005: hermes を素の Nix へ移行（Determinate Nix からの離脱）

- ステータス: 採用
- 決定日: 2026-08-02
- 関連: [ADR-20260730-0003](ADR-20260730-0003-purpose-and-order.md)（実装方針・着手順序） /
  [ADR-20260801-0004](ADR-20260801-0004-module-layer-design.md)（層設計）

## 背景

Phase 3-1 で hermes に nix-darwin を導入した際、macOS 26 (Tahoe) でシェル版インストーラが
`/etc/fstab` 書き込みに失敗したため pkg 版を使い、結果として hermes は「Determinate Nix」
ディストリビューションになった。**選択ではなく事故の産物**である
（MacBook Pro は `NixOS/nix-installer` 由来の素の Nix で、両機の系統が食い違っていた）。

Determinate Nix は自前デーモン（`determinate-nixd`）が Nix 本体を管理するため、
nix-darwin 側で `nix.enable = false` が必須になる。4-9（GC の自動化）を検討する過程で、
**この 1 行が `nix.*` 配下をほぼ全面的に無効化している**ことが判明した。遮断は 3 通りある。

| 型 | 仕組み | 挙動 | 危険度 |
|---|---|---|---|
| サイレント無視 | nix モジュールの config 全体が `handleUnmanaged`（= `mkIf cfg.enable`）で包まれる | 設定を書いてもエラーも警告も出ず、ファイルが生成されない | **最高** |
| 参照即エラー | `managedDefault` が 13 個のオプションのデフォルト値を `throw` に差し替える | 値を書かずに参照した時点で評価が落ちる（`config.nix.package` 等） | 中 |
| 明示的拒否 | `assertion = cfg.automatic -> config.nix.enable` | メッセージ付きでビルドが止まる（`nix.gc` / `nix.optimise`） | 低 |

とくに問題なのはサイレント無視で、`nix.buildMachines` がこれに該当する。
4-1 Remote builders は ROADMAP で優先度「高」かつ「stow では原理的に代替不可能な唯一の価値」と
位置づけているが、宣言しても `/etc/nix/machines` が生成されず、
**エラーも警告も出ないまま分散ビルドが動かない**形で破綻する構造だった。

実害は現時点では 4-1 / 4-4 の 2 項目に限られていた。しかし回避策（`launchd` 自前宣言や
`nix.custom.conf` 手書き、`determinateNix.customSettings`）で設定を書き溜めるほど
**移植コストが上がり続ける**ため、`nix.*` 依存の設定がまだ 1 つも無いうちに
決着させるべきだと判断した（ユーザー提起）。

## 選択肢

### A. 現状維持（機能ごとに回避策で凌ぐ）

- 実害が 2 項目に限られる以上、当面は回る
- しかし代替手段が宣言の外（手書きファイル）へ漏れ、Nix 化の目的である
  「環境の自己文書化」を損なう
- 何より、将来この制約を忘れた状態で設定を積み増すと移植コストが不可逆に増える

### B. Determinate 公式 nix-darwin モジュール

- `determinate.darwinModules.default` を読み込み `determinateNix.enable = true` とすると
  `nix.enable = false` が不要になり、`determinateNix.customSettings` で
  `/etc/nix/nix.custom.conf` を宣言的に生成できる（Determinate Nix 3.15.2 以降。
  hermes は 3.21.8 で利用可能だった）
- 宣言性は回復するが、**設定が Determinate 固有の書き方に固定される**。
  素の Nix の端末では `determinateNix.*` を解決できず評価が落ちるため、
  MacBook Pro との共通化ができず、将来の離脱コストはむしろ上がる
- lazy-trees・並列評価を維持できる点は利点

### C. 素の Nix へ移行（採用）

- Determinate を外し upstream Nix（コミュニティ版 [`NixOS/nix-installer`](https://github.com/NixOS/nix-installer)）へ
- `nix.*` がフルに使えるようになり、制約が根本から消える
- MacBook Pro と系統が揃う。さらに nix 本体のバージョンも nix-darwin が
  nixpkgs 経由で管理するため、Phase 3-2 で MBP に nix-darwin を導入すれば自動的に一致する
- 実物調査の結果、**`[moz]` `[ryo]` とも Determinate を採用していない**（両者の flake inputs に
  determinate は無く `nix.settings.*` を通常どおり使用）。移行により両者と同じ構成になり、
  「コピーして削る」方針（ADR-0003）の資産が再び使えるようになる
- Determinate Systems は 2025-11-10 に既定を Determinate Nix へ変更し、
  **2026-01-01 に upstream Nix のインストールオプションを完全廃止**した。
  表明どおり実行された以上、今後も方針転換のリスクを負い続けることになる

## 決定

**C を採用。** 失うのは lazy-trees と並列評価の 2 つ（いずれも upstream には無い
Determinate 固有機能で、代替不可）。ただし hermes は**ヘッドレスの Agent 運用機であり、
日常的に nix コマンドを叩く機械ではない**ため、恩恵は小さいと判断した。

移行は「1 switch = 1 変更クラス」に従い 3 段階に分けた。

1. Nix の入れ替えのみ（flake は変更せず `nix.enable = false` のまま switch し、従来どおり動くことを確認）
2. `nix.enable = false` を解除し、`nix.settings` で nix.conf の内容を宣言
3. GC を `launchd.daemons` の自前宣言から標準の `nix.gc.automatic` へ移行

## 検証

- **`/run/current-system` が移行前と同一の store パスで再現された**
  （`ps5ndcmg…-darwin-system-26.11.15abb8c`）。`/nix` を丸ごと削除し別インストーラで
  入れ直しても flake から同一のシステムが再構築できることの実証であり、
  ROADMAP の目的 2（新端末で環境を引き継げる）の達成確認にあたる
- **Tahoe 26.4.1 で `NixOS/nix-installer` 2.35.1 は問題なく動作した。**
  7/21 に `/etc/fstab` で失敗したのは Determinate 版インストーラであり、別実装だった
  （両者はフォーク関係にあるが fstab / APFS 処理の堅牢性が異なる）
- 移行後、`config.nix.package` が解決でき（GC の launchd に nixpkgs 版 nix のパスが埋まる）、
  `nix.gc.automatic` の assertion も通ることを確認した
- 所要は約 1 時間。停止したサービスは `llama-swap` / `miniserve` / `ai.hermes.gateway` の 3 つで、
  いずれも復旧済み

## 影響

- `darwin/default.nix`: `nix.enable = false` を削除し `nix.settings` を宣言（`d87cb50`）。
  nix-darwin が nix.conf を管理下に置くため、インストーラが書いていた設定
  （`extra-experimental-features` / `always-allow-substitutes` / `max-jobs` / `extra-nix-path`）を
  明示しないと失われる。とくに experimental-features を落とすと flake を評価できず switch 不能になる
- `hosts/hermes/nix-gc.nix`: `launchd.daemons` 自前宣言から `nix.gc.automatic` へ（`38372c2`）
- `trusted-users` が移行直後 root のみになるため作業ユーザーを追加（`e3bab94`）。
  root は nix-darwin が既定で含めるため書かない（書くと重複する）
- mise の trust が外れる副作用がある（`mise trust` で復旧。設定変更は不要）
- [ROADMAP.md](../ROADMAP.md): Phase 3-1c として移行を記録。
  Phase 3-2 の「MBP を Determinate pkg 版へ入れ直して統一」は**対象外**に変更
  （hermes 側を動かしたことで MBP は現状のまま系統が揃った）。
  4-1 の設計上の注意は解消済みとして書き換え、4-9 を完了に
- [USECASES.md](../USECASES.md): 制約の記録を「解消済み」として残し、
  Determinate 公式モジュールを対象外へ移動。政治的リスクの節に配布廃止の実行を追記

## 未確定事項（将来の ADR で扱う）

- **Phase 3-2 で MBP に nix-darwin を導入する際、nix 本体が nixpkgs 版に切り替わる**
  （現在は nix-installer 由来の 2.34.5）。hermes と同じ扱いになるはずだが、
  メイン機のため影響を事前に確認すること
- 4-1 Remote builders は `nix.buildMachines` で素直に書けるようになった。
  着手時期は未定（Phase 3-2 完了後が自然）
- `/etc/nix` に残る Determinate の遺物（`macos-keychain.crt` / `sentry-endpoint`）の掃除。
  現在の nix.conf はどちらも参照していないため無害
- lazy-trees は upstream Nix へ長期間マージされていない。将来 upstream に入れば
  Determinate 固有の優位性は消えるが、追う必要はない（当方の用途では恩恵が小さい）
