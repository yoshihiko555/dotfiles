# ADR-20260729-0002: 3台構成を前提とした Nix 導入方針

- ステータス: 採用
- 決定日: 2026-07-29
- 関連: [ADR-20260424-0001](ADR-20260424-0001-nix-layout.md)（ディレクトリ構成）

## 背景

ADR-20260424-0001 でディレクトリ構成を決めた後、Phase 0 のまま約 3 ヶ月停滞していた
（`nix profile` は空、`/nix/store` が 2.3GB を占有するのみ）。

停滞の原因は、[ROADMAP](../ROADMAP.md) が **単一 macOS 端末を暗黙の前提**にしていたこと。
その前提では Nix の主要な価値（再現性 / マルチホスト / Linux でのビルド再現）が回収できず、
現行の brew + mise + stow 構成に対する優位が出なかった。

改めて実際の稼働環境を棚卸ししたところ、対象は 3 台だった:

| ホスト | system | 用途 |
|---|---|---|
| MacBook Pro | `aarch64-darwin` | メイン開発機。GUI アプリあり |
| Mac mini (hermes, M4) | `aarch64-darwin` | Hermes Agent 運用。ターミナルのみ |
| 会社支給 Windows (WSL2) | `x86_64-linux` | WSL2 上で日常的に開発 |

制約の確認結果:

- 会社 PC の環境設定を個人 dotfiles リポジトリで管理することに、規約上の問題はない
- **Nix は Windows ネイティブでは動作しない**。統一対象は WSL2 内部に限られ、
  Windows 本体（GUI / レジストリ / アプリ）は対象外

これにより前提が「単一 macOS 端末」から「macOS 2 台 + Linux 1 台」へ変わった。
特に **WSL2 で日常開発している**ことの影響が大きく、Nix が最も得意とする Linux が
主戦場に含まれる構図になった。

また現状 hermes への設定配布は `scripts/install-hermes-subset.sh` による手動ファイルコピーで、
これは home-manager の劣化再実装にあたる。

## 選択肢

### A. 現状維持（brew + mise + stow）+ Nix は保留

- 学習コストゼロ。既存構成は単体では十分機能している
- ただし hermes への手動コピーと WSL2 の独立管理が残り、
  **端末が増えるたびに配布方式を設計し直す**ことになる
- ホスト間の差分が暗黙知のまま蓄積する

### B. home-manager でマルチホスト管理（採用）

- 1 つの flake で 3 ホストを宣言的に管理し、共通部分と host 固有部分を明示的に分離できる
- `scripts/install-hermes-subset.sh` を正式に置き換えられる
- WSL2（Linux）はバイナリキャッシュのカバレッジが完全で macOS 固有の SDK 問題も起きないため、
  **学習の入り口として最も安全**
- GUI / cask は brew のまま残すため、メイン機の既存環境を壊さずに進められる

### C. 一気に nix-darwin まで移行

- システム設定（Dock / Finder / キーボード）まで宣言化でき、最終像としては理想
- ただし稼働中のメイン機を最初に触ることになり、リスクが高い割に得るものが少ない
- 学習が追いつかないまま二重管理期間が長期化する恐れがある

## 決定

**B を採用。** home-manager によるマルチホスト管理を目標とする。

### 目標構成

ADR-20260424-0001 の決定どおり、`config/.config/nix/` 内で拡張する（ディレクトリ移動は発生しない）。

```
config/.config/nix/
├── flake.nix
├── flake.lock
├── nix.conf
├── hosts/
│   ├── macbook.nix    # aarch64-darwin / GUI あり
│   ├── hermes.nix     # aarch64-darwin / ターミナルのみ
│   └── wsl.nix        # x86_64-linux / 会社
├── home/
│   ├── common.nix     # 3 台共通（zsh / starship / git / tmux / CLI 群）
│   ├── darwin.nix     # macOS 固有
│   └── linux.nix      # WSL 固有
├── modules/
└── docs/
```

この「共通 + ホスト別 diff」の構造は、既に `shared/agents/`（core.md + diff-*.md）で
採用している思想と同一である。既存の管理方針と整合する。

### 着手順序

1. **WSL2** — Linux で最も素直に動きハマりにくい。壊しても `wsl --unregister` で作り直せるため、
   学習の実験場として最適。稼働中のメイン機を最初に触らない
2. **hermes** — GUI がなく移行対象が明確。`install-hermes-subset.sh` の置き換えで効果が出る。
   `common.nix` に何を含めるかの切り分けがこの段階で確定する
3. **MacBook Pro** — 最後。既に動いているためリスクが最も高く、得るものが最も少ない

### 既存ツールとの共存方針

| ツール | 方針 | 理由 |
|---|---|---|
| stow | 段階的に home-manager へ寄せる | 役割が重複するが、ファイル単位で移行できるため一括移行は不要 |
| mise | **残す** | プロジェクト単位の `.mise.toml` によるランタイム切替は mise が扱いやすい。境界は「言語ランタイム = mise、それ以外の CLI = Nix」 |
| brew | GUI / cask は残す | nix-darwin の `homebrew.*` は brew のラッパーであり、Nix 化されない。Phase 4 で改めて判断 |

## 影響

- [ROADMAP.md](../ROADMAP.md) を改訂。Phase 1（`nix profile` で CLI を試す）は **スキップ**する
- 進行ルールの「Phase は順番に進める」を、「前提が変わった場合は ROADMAP ごと見直す」に緩和する
- [README.md](../../README.md) の「現状 (Phase 0)」記述を更新する
- 移行期間中は brew / stow と Nix の二重管理が発生する
- `scripts/install-hermes-subset.sh` は着手順序 2 の完了時点で役割を終える
  （削除の可否は完了後に別途判断する）
- Windows 本体の設定は Nix の管理対象外のまま残る

## 未確定事項（将来の ADR で扱う）

- home-manager と stow の最終的な境界（どこまで寄せるか）
- nix-darwin 採用可否（GUI / システム設定の宣言化、Phase 4）
- 会社 WSL2 の設定を同一リポジトリに置き続けるか分割するか（現時点では同一で進める）
- 会社 Windows が ARM 版だった場合の system 文字列（実装時に `uname -m` で確認する）
- `common.nix` に含める具体的なパッケージ / プログラムの選定
