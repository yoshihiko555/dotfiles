# ADR-20260801-0004: Nix 設定のディレクトリ層設計（darwin / home / hosts）

- ステータス: 採用
- 決定日: 2026-08-01
- 関連: [ADR-20260424-0001](ADR-20260424-0001-nix-layout.md)（ディレクトリ集約） /
  [ADR-20260730-0003](ADR-20260730-0003-purpose-and-order.md)（実装方針・着手順序）

## 背景

Phase 3-1 / 3-1b（hermes）の実装で、ホスト定義を「hostSpec + 目次の default.nix +
機能群ファイル」に分割する作法が確立した。一方で、Phase 3-2（MacBook Pro）・
Phase 3-3（WSL2）に同じ構成を展開する前に、以下の問題が残っていた。

- **`hosts/common/` という名前が実態と乖離している**。中身は `nix.enable` / `homebrew` 等の
  darwin 専用モジュールで、standalone home-manager の WSL2 はこの層を通れない。
  このまま Phase 3-3 に進むと「common なのに WSL2 で使えない」混乱が確実に起きる
- homebrew のような「共通と固有が混在する機能」を、どの単位・どのファイルに
  書くかの規約が明文化されていない。ホストが 3 台に増えたとき、
  「これはどこに書く？」の迷いがそのまま運用コストになる
- hermes で確立した形が最適とは限らず、ホスト追加前に管理形態そのものを
  設計しておく必要がある（ユーザー提起）

## 選択肢

### A. 現状維持（hosts/common + hosts/&lt;host&gt;）

- 移行コストゼロ
- しかし `common` の名前の嘘は残り、WSL2 追加時（Phase 3-3）に必ず顕在化する

### B. 機能軸（modules/&lt;機能&gt;/&lt;ホスト&gt;.nix）

- 機能の全体像（homebrew 全体など）が 1 ディレクトリで見える
- しかしホスト視点が散る。「このマシンで何が起きているか」を知るには全機能
  ディレクトリの横断が必要で、トラブル対応時の視点と噛み合わない
- ホスト追加時の作業が全機能ディレクトリに散る。WSL2 のような非対称ホストでは
  機能ごとに「該当なし」の歯抜けが散在する
- 機能軸が効くのは「ホスト数 >> 機能数」の大規模構成。個人 3 台には過剰。
  ryoppippi が modules/ 軸なのは実質 1 台 × 複数アーキでホスト個性が無いため、
  mozumasu が 4 台でホスト軸なのは当方と同じ理由と分析した

### C. レイヤー明示のホスト軸（採用）

```
config/.config/nix/
├── darwin/     # darwin ホスト共通のシステム層（WSL2 は通らない）
├── home/       # 全ホスト共通のユーザー層（dotfiles 配線・CLI パッケージ）
├── hosts/      # ホスト固有。薄く保つ
│   ├── hermes/ # default.nix（hostSpec + 目次）+ 機能群ファイル
│   ├── macbook/（Phase 3-2 で作成）
│   └── wsl/    #（Phase 3-3 で作成。standalone home-manager）
├── modules/    # オプション定義（hostSpec 等）
└── packages/   # 自作 derivation（将来）
```

- `hosts/common` を `darwin/` に改名し、「darwin 専用」という実態を層の名前で表現する
- WSL2 の非対称性（darwin 層を通らず home 層だけ共有する）が構造で読み取れる
- mozumasu の実構成（`darwin/` + `home-manager/` + `hosts/`）とも一致し、
  「コピーして削る」方針（ADR-0003）の延長にある

## 決定

**C を採用。** 併せて以下の設計規約を定める。

1. **ホスト軸 + 層明示**。機能軸は 3 台規模には過剰なので採らない
2. `hosts/<host>/` は「hostSpec + 目次の default.nix + 機能群ファイル」で構成し、
   **薄く保つ**。ロジックを書きたくなったら共通層かオプション化を検討する
3. **2 台以上で使い始めたら共通層へ昇格**する（システム層 → `darwin/`、
   ユーザー層 → `home/`）。新規はまず使うホストの `hosts/<host>/` に書く。
   最初から共通に置くと「宣言が実態より先行する」腐敗（使っていない端末にも入る）を生むため
4. 機能の増築は「新ファイル + default.nix の imports に 1 行」。
   homebrew の例では、共通 brew/cask = `darwin/homebrew.nix`、
   ホスト固有 = `hosts/<host>/homebrew.nix` の実質 3 ファイルになる
   （WSL2 に brew は無いため 4 ファイル目は発生しない）
5. mozumasu 流の `mkIf` による 1 ファイル内条件分岐（homebrew-personal / work）は
   採らない。3 台規模では分岐よりファイル分割の方が読みやすい。
   会社/個人の分離が必要になったら Phase 3-2 で再検討する

## 検証

改名・分割はいずれも純リファクタであることを、**ビルド成果物のストアパスが
変更前後で完全一致する**ことで確認した（`ps5ndcmg…-darwin-system`）。
switch 不要で、hermes には git pull のみで配布した。

## 影響

- `hosts/common/` → `darwin/` に git mv、`flake.nix` の参照を変更
- [ROADMAP.md](../ROADMAP.md) の「目標構成」を本設計で確定し、設計規約を追記
- [GUIDE.md](../GUIDE.md) のファイルマップ・編集場所早見表を更新
- Phase 3-2 / 3-3 のホスト追加は本規約に従う（macbook / wsl ディレクトリは
  着手時に作成する。未使用スケルトンは宣言と実態のズレになるため事前に置かない）

## 未確定事項（将来の ADR で扱う）

- 会社/個人の homebrew 分離（mozumasu の personal / work 相当）の要否 — Phase 3-2 で判断
- `modules/` へのオプション化（mkOption / mkIf による機能モジュール化）を
  導入する基準 — hosts が「薄く保てなくなった」ときに検討
- WSL2（hosts/wsl）の内部構成の詳細 — Phase 3-3 着手時に
  [PHASE-3-3-WSL2.md](../PHASE-3-3-WSL2.md) を本規約に合わせて改訂する
