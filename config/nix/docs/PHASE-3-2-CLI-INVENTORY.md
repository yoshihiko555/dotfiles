# Phase 3-2 前提調査: グローバル CLI の管理元棚卸し

作成: 2026-08-02。brew 以外の管理系統（mise / npm -g / go install / uv tool / pipx /
cargo / 野良バイナリ / bun・deno）を横断調査し、ROADMAP「既存ツールとの共存方針」の
境界（言語ランタイム = mise、それ以外の CLI = Nix、brew は cask + nixpkgs 未収録専用）
に対する実態のズレと、Nix 移行対象を確定する。brew 側は
[PHASE-3-2-BREW-INVENTORY.md](PHASE-3-2-BREW-INVENTORY.md) で棚卸し済み。

発端: 2026-08-01 に `pipx:termaid` を mise へ追加した際、境界と食い違うことに気づいた
（Notion タスク「グローバルCLIの管理元を棚卸ししNix移行対象を確定する」）。

---

## 1. 管理系統別の実測サマリ

| 系統 | 件数 | 内訳 | 診断 |
|---|---|---|---|
| mise（グローバル） | 7 | go, node, python, rust, uv, golangci-lint, pipx:termaid | ほぼ健全（違反 2 のみ） |
| npm -g | 4（実質） | sandbox-runtime, clasp, screenpipe, takt | **全件宣言なし** |
| uv tool | 2 | mcp-proxy, orchex | **全件宣言なし** |
| go install | 1 | baton（自作） | 宣言なし + 設置場所リスク※ |
| `~/.local/bin` 野良 | 2 | agy, ffmpeg | agy 宣言なし、ffmpeg は残骸（2026-08-06 に screenpipe により復活、6章参照） |
| pipx（独立）/ cargo / bun / deno | 0 | — | 問題なし |

※ baton は `go install` の産物が mise の go インストール bin 直下
（`~/.local/share/mise/installs/go/<ver>/bin`）に置かれており、go のバージョンアップで
消え得る。`~/.local/bin/baton` の手動コピーが実質の本体。

npm 本体は mise の node 経由（brew の node は他 formula の依存としてのみ存在、npm 実行に無関係）。

## 2. 境界判定

- **言語ランタイム（mise が正）**: go / node / python / rust。`uv` は Python エコシステムの
  コアツール + pipx backend の実体のため境界違反とみなさない（グレーゾーンとして注記）
- **境界違反（mise にいる非ランタイム CLI）**: `golangci-lint` / `pipx:termaid` の**既知 2 件のみ**。
  新規の違反は発見されなかった → mise の運用は破綻しておらず、方針改訂の必要なし

## 3. 宣言なし野良 CLI（9 件）と行き先の確定（2026-08-02）

| ツール | 現管理元 | 役割 | Nix 対応 | 行き先 |
|---|---|---|---|---|
| `golangci-lint`※ | mise | Go linter | nixpkgs 2.12.2（mise 2.11.4 より新しい） | **Nix 宣言**（Phase 3-2） |
| `@anthropic-ai/sandbox-runtime` | npm -g | サンドボックス実行（`srt`） | nixpkgs `sandbox-runtime` 0.0.68 | **Nix 宣言**（Phase 3-2） |
| `@google/clasp` | npm -g | Google Apps Script CLI | nixpkgs `google-clasp` 3.3.0 | **Nix 宣言**（Phase 3-2） |
| `mcp-proxy` | uv tool | MCP stdio↔SSE プロキシ | nixpkgs `mcp-proxy` 0.10.0（uv 版 0.11.0 より旧い点は許容） | **Nix 宣言**（Phase 3-2） |
| `agy` | 野良（curl installer） | Antigravity CLI | **nixpkgs `antigravity-cli` 収録あり**（unfree・aarch64-darwin 対応・mainProgram=agy。要 allowUnfree） | **Nix 宣言**（Phase 3-2） |
| `takt` | npm -g | AI エージェントワークフロー制御 | nixpkgs 未収録だが**公式 flake あり**（`github:nrslib/takt`、buildNpmPackage・4 システム対応） | **flake input として Nix 宣言**（Phase 3-2） |
| `baton` | go install | AI セッション管理（自作） | 未収録（自作） | **Phase 4-7 で自作パッケージ化**（buildGoModule）。それまで導入手順を文書化 |
| `orchex` | uv tool | 自作 CLI | 未収録（自作） | **Phase 4-7 で自作パッケージ化**。それまで導入手順を文書化 |
| `screenpipe` | npm -g | 画面・音声の継続記録 | **皆無**（nixpkgs issue #331110 は未完了で closed。prebuilt Rust バイナリ本体が起動時に ffmpeg の不在を検知すると自動で再取得する構造（`screenpipe_core::ffmpeg` モジュール。postinstall ではない）で Nix 化ハードル高） | **個別管理を継続**。導入手順（バージョン固定の `npm i -g screenpipe@x.y.z`）を文書化して穴を明示 |

※ golangci-lint は「宣言なし」ではなく境界違反（mise 宣言済み）だが、行き先が同じためここに含めた。

## 4. 境界違反 2 件の扱い

| ツール | 扱い |
|---|---|
| `golangci-lint` | Nix へ移送（上表）。mise の宣言は Phase 3-2 適用時に削除 |
| `pipx:termaid` | **当面 mise 例外として明文化**（nixpkgs 未収録の pipx 系 CLI は mise の pipx backend が最も低コスト）。将来は Phase 4-7 で自作パッケージ化する意向（2026-08-02 判断）。ROADMAP 共存方針に例外を追記済み |

## 5. 方針判定（Notion タスク完了条件 5）

**案 B（境界維持・個別移送）を採用。ROADMAP / ADR の方針改訂は不要**（2026-08-02 決定）。

- 案 C（mise 廃止・Nix 一本化）が必要になるのは境界運用が破綻している場合だが、
  実測の違反は 2 件のみで破綻とは言えない
- 基本方針として「**Nix で宣言できるものは Nix で宣言する**」を確認。
  nixpkgs 未収録でも公式 flake があれば flake input で宣言する（takt が該当）

## 6. 実施記録

- 2026-08-02: `~/.local/bin/ffmpeg`（51MB の野良静的ビルド、YouTube 自動投稿の名残）を削除。
  brew 版 ffmpeg の削除（PHASE-3-2-BREW-INVENTORY.md）と合わせ ffmpeg は完全に撤去
  → 2026-08-06 に screenpipe が再取得したため撤去済みではない（下記）
- 2026-08-06: `~/.local/bin/ffmpeg`（51MB, Mach-O arm64, version 8.0）が復活していることを確認。
  `~/.screenpipe/screenpipe.2026-08-06.0.log` に
  `screenpipe_core::ffmpeg: ffmpeg not found. installing...`（取得元
  `https://www.osxexperts.net/ffmpeg80arm.zip`）のログがあり、screenpipe 本体（npm の
  postinstall ではなく `screenpipe_core::ffmpeg` モジュール）が起動時に ffmpeg の不在を
  検知して自動で再取得したことを確認。`com.screenpipe.agent` は launchd で `RunAtLoad` +
  `KeepAlive=true` の常駐設定であり、screenpipe を停止しない限り再取得される
- ~~`~/.local/bin` の `uv` / `uvx`（mise 管理版との重複コピー）は当面残置~~
  → 2026-08-06 に削除（下記）
- 2026-08-06: **旧実体の掃除を実施し、nix 版への切替を完了**（Notion「MBP の旧 CLI 実体を
  掃除して Nix 版へ切り替える」）。実施内容と切替後の解決先:
  - `npm rm -g takt @google/clasp @anthropic-ai/sandbox-runtime`
  - `uv tool uninstall mcp-proxy`（`mcp-proxy` / `mcp-reverse-proxy` の 2 実行ファイル）
  - mise の `golangci-lint` 宣言を削除 + `mise uninstall golangci-lint --all`
  - `~/.local/bin` の `uv` / `uvx` 重複コピーを削除
  - `~/.local/bin/agy.<epoch>.old`（164MB、手動導入 1.1.9 の残骸）を削除
  - 対話シェルで `takt` / `clasp` / `srt` / `mcp-proxy` / `mcp-reverse-proxy` / `golangci-lint` が
    すべて `/etc/profiles/per-user/yoshihiko/bin` に解決することを確認。動作確認済み
    （takt 0.55.1 / clasp 3.3.0 / golangci-lint 2.12.2）
  - `uv` / `uvx` は Nix 未収録のため mise 版のまま（設計どおり）
- 2026-08-06: `rg` は**掃除対象外と再判断**。棚卸し時に「brew 台帳外の野良」と記録したが、
  実測では brew 台帳内で `opencode` の依存（`installed_on_request: false`）だった。
  rg 単独を剥がしても brew formula 70 個超が PATH で nix より優先される状況は変わらないため、
  MBP の brew formula 掃除タスクへ移送する

## 7. 残作業（Phase 3-2 実装時に消化）

- [x] `golangci-lint` / `sandbox-runtime` / `google-clasp` / `mcp-proxy` / `antigravity-cli` を
      Nix 宣言に追加（置き場所は hosts/macbook か home/ 共通層かを ADR-0004 ルール 3 で判断。
      agy は allowUnfree の設定が必要）— 2026-08-05 の初回 switch で配布済み
- [x] `takt` を flake input（`github:nrslib/takt`）として宣言 — 2026-08-05 完了
- [x] mise の `golangci-lint` 宣言を削除（Nix 側の適用確認後）— 2026-08-06 完了
- [x] npm -g / uv tool 側の旧インストールを掃除（Nix 側の適用確認後）— 2026-08-06 完了
- [ ] `baton` / `orchex` / `screenpipe` の導入手順を文書化（Phase 4-7 までのつなぎ）
- [ ] Phase 4-7 候補に `baton`（buildGoModule）/ `orchex` / `termaid` を追加 → ROADMAP 反映済み

## 8. 付録: 全ツール詳細一覧（管理系統別・2026-08-02 実測）

1 章はサマリのため、各ツールの詳細をここに全量残す（Notion タスク完了条件 1 の実体）。

### 8-1. mise（`~/.config/mise/config.toml` = グローバル設定、7 件）

| tool | version | 種別 | 宣言 | 備考 |
|---|---|---|---|---|
| `go` | 1.26.1（latest） | 言語ランタイム | 宣言済 | 旧 1.25.5 も残存（latest 追従の副産物） |
| `node` | 25.2.1 | 言語ランタイム | 宣言済 | npm 本体もここに同梱 |
| `python` | 3.14.2（latest） | 言語ランタイム | 宣言済 | |
| `rust` | 1.94.0 | 言語ランタイム | 宣言済 | 実体は `~/.cargo`（rustup 相当）への symlink |
| `uv` | 0.10.8（latest） | Python パッケージ管理 | 宣言済 | mise のコアツール扱い。境界違反とみなさない |
| `golangci-lint` | 2.11.4（latest） | Go linter（非ランタイム） | 宣言済 | **境界違反** → Nix へ移送 |
| `pipx:termaid` | 0.8.0（latest） | mermaid→Unicode art 変換 | 宣言済 | **境界違反** → mise 例外として明文化 |

`[settings] pipx.uvx = true` により pipx 本体は不要（uvx で代替）。独立 pipx 環境は存在しない。

### 8-2. npm -g（実質 4 件 + 同梱 2）

npm 本体は mise の node 経由（`~/.local/share/mise/installs/node/25/bin/npm`）。
brew の node は他 formula の依存としてのみ存在し npm 実行には無関係。

| package | version | 役割 | 宣言 |
|---|---|---|---|
| `npm` / `corepack` | 11.6.2 / 0.34.5 | node 同梱 | 宣言済扱い |
| `@anthropic-ai/sandbox-runtime` | 0.0.64 | サンドボックス実行（`srt`） | **未宣言** |
| `@google/clasp` | 3.1.3 | Google Apps Script CLI | **未宣言** |
| `screenpipe` | 0.4.26 | 画面・音声の継続記録 | **未宣言** |
| `takt` | 0.54.1 | AI エージェントワークフロー制御 | **設定（~/.takt）は宣言済み・本体導入手順は未宣言** |

### 8-3. go install（1 件）

- `GOBIN` = `~/.local/share/mise/installs/go/1.26.1/bin`（mise の go bin 直下）。`~/go/bin` は無い

| バイナリ | 役割 | 宣言 | 備考 |
|---|---|---|---|
| `baton` | AI セッション管理（自作、tmux 連携。ADR: config/tmux/docs/decisions/003-baton-vs-claude-squad.md） | **未宣言** | GOBIN 側は go バージョンアップで消失リスク。`~/.local/bin/baton` のコピーが実質本体 |

### 8-4. uv tool（2 件）

| tool | version | 役割 | 宣言 |
|---|---|---|---|
| `mcp-proxy` | 0.11.0 | MCP stdio↔SSE プロキシ | **未宣言** |
| `orchex` | 0.3.2 | 自作 CLI | **未宣言** |

### 8-5. `~/.local/bin`（野良・重複）

| 項目 | 種別 | 宣言 | 備考 |
|---|---|---|---|
| `agy` | 単体バイナリ（Antigravity CLI 1.1.9、~165MB） | **未宣言** | 公式 curl インストーラ由来。nixpkgs `antigravity-cli` へ移行予定 |
| `baton` | 単体バイナリ（8-3 のコピー） | **未宣言** | |
| `ffmpeg` | 野良静的ビルド 51MB | — | 2026-08-02 削除（YouTube 自動投稿の名残）→ **2026-08-06 screenpipe により復活**（6章参照） |
| `uv` / `uvx` | mise 版と同一バージョンの重複コピー | 宣言不要 | PATH で mise 版優先、実害なし。掃除候補として残置 |
| `mcp-proxy` / `orchex` 等 | uv tool の symlink | 8-4 参照 | |

### 8-6. その他の系統

| 系統 | 状態 |
|---|---|
| pipx（独立） | 存在しない（mise backend に一本化） |
| cargo install | グローバルバイナリなし |
| bun | 追加グローバルパッケージなし（本体は既知の例外、ROADMAP 記載済み） |
| deno | 未導入 |
| プロジェクトローカル `.mise.toml` | `~/ghq` 深さ 3 の走査では検出なし（全リポジトリの網羅走査はしておらず**未確認**） |

## 9. 調査メモ

- ローカルの `nix search nixpkgs <term>` は評価キャッシュがないと非常に遅い。
  `search.nixos.org` の Elasticsearch backend への直接クエリの方が速い（次回への申し送り）
- nixpkgs の `antigravity-cli` は GCS の公式配布バイナリを fetchurl するラッパーで、
  `passthru.updateScript` により自動追従される。手元 1.1.9 に対し master 1.1.8 と追従は良好
