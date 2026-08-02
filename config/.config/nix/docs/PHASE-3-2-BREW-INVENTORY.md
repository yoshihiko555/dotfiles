# Phase 3-2 前提調査: MacBook Pro brew 棚卸し

作成: 2026-08-02。Phase 3-2（MacBook Pro の nix-darwin + home-manager 化）に先立ち、
brew 管理下の全アイテムを「役割・宣言状態・今後の行き先」で整理する。

- 実測: formula（leaves）29 / cask 13 / tap 8 / brew 管理外の残骸 1
- 「更新」列は Cellar/Caskroom の最終更新月（**導入月ではない**。upgrade で更新される）
- 「行き先」列の凡例:
  - **nix共通** = `home/packages.nix`（3 台共通層。hermes で稼働実績あり）
  - **nix新規** = `home/packages.nix` へ新規追加（nixpkgs 属性確認済み）
  - **brew残留** = `hosts/macbook/homebrew.nix` で宣言継続
  - **削除候補** = 用途消滅・残骸と判断（**最終判断は未実施**）
  - **要判断** = 情報不足または品質リスクあり

---

## 1. formula（brew leaves 29 件 + 隠れ 4 件 + 依存扱い 1 件）

### 1-1. シェル・ターミナル基盤

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `sheldon` | zsh プラグインマネージャ（`.zshrc` から起動） | 宣言済 | 2026-01 | nix新規（0.8.5 一致） |
| `starship` | プロンプト | 宣言済 | 2026-07 | nix共通 |
| `zoxide` | ディレクトリジャンプ | 宣言済 | 2026-07 | nix共通 |
| `fzf` | ファジーファインダ | 宣言済 | 2026-07 | nix共通 |
| `tmux` | ターミナルマルチプレクサ | 宣言済 | 2026-07 | nix共通 |
| `tmux-fingers` | tmux のヒントモード（tap: morantron） | 宣言済（隠れ※） | 2026-06 | brew残留（tap 専用） |
| `stow` | dotfiles リンカ。**home-manager 移行完了で廃止予定** | 宣言済 | 2026-01 | 経過措置として nix新規 → Phase 3-2 完了後に削除 |

※「隠れ」= インストール済みだが `--installed-on-request` フラグが落ちており
`brew leaves` に出ない。`brew autoremove` で意図せず消え得る状態（対象:
`git-gtr` / `go-task` / `ffmpeg` / `tmux-fingers` の 4 件。nix 宣言化で解消される）。

### 1-2. Git・開発フロー

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `git` | バージョン管理 | 宣言済 | 2026-07 | nix共通 |
| `gh` | GitHub CLI | 宣言済 | 2026-08 | nix共通 |
| `ghq` | リポジトリ管理 | 宣言済 | 2026-06 | nix共通 |
| `lazygit` | Git TUI | 宣言済 | 2026-07 | nix共通 |
| `git-gtr` | worktree ヘルパー（tap: coderabbitai） | 宣言済（隠れ※） | 2026-06 | brew残留（Phase 3-2 で `hosts/macbook/homebrew.nix` に宣言。hermes 未使用のため darwin 共通層からは降格済み 2026-08-02。Phase 4-7 で自作パッケージ化候補） |
| `go-task` | タスクランナー（`taskfiles/` で使用、tap: go-task） | 宣言済（隠れ※） | 2026-06 | nix新規（**タスクランナーは go-task に統一**と決定 2026-08-02。nixpkgs `go-task` 3.48.0 確認済み。Makefile は stow と同時期に廃止、flake apps は Nix 操作専用） |

### 1-3. エディタ・言語ツール（nvim / LSP）

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `neovim` | エディタ | 宣言済 | 2026-07 | nix共通 |
| `tree-sitter-cli` | **nvim-treesitter の grammar ビルド依存**（コミット `38b8136` で意図的に追加） | 宣言済 | 2026-07 | nix新規（nixpkgs `tree-sitter` 属性。バイナリ名は同じ `tree-sitter`。grammar ビルドの動作検証を Phase 3-2 適用時に 1 回行う） |
| `gopls` | Go LSP | 宣言済 | 2026-07 | nix新規（0.23.0 一致） |
| `pyright` | Python LSP | 宣言済 | 2026-07 | nix新規（1.1.411 一致） |
| `typescript` | tsc 本体（tsls の依存として leaves から除外） | 宣言済 | 2026-07 | nix新規（tsls の依存に含まれるか要確認） |
| `typescript-language-server` | TypeScript LSP | 宣言済 | 2026-06 | nix新規（5.3.0 一致） |

> LSP 群は「言語ランタイム = mise」の境界の外側（エディタ支援ツール）として
> Nix 側に置く。mise のランタイムと衝突しない。

### 1-4. AI CLI・LLM 基盤

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `agent-browser` | エージェント用ブラウザ自動化（L1 採用中） | 宣言済 | 2026-08 | brew残留（nixpkgs 0.27.0 vs brew 0.33.1 で追従差が大きい） |
| `gemini-cli` | Gemini CLI | 宣言済 | 2026-06 | **削除確定**（2026-08-02。Antigravity CLI へ置き換わっており今後起動しない。Google 自体が gemini-cli 廃止 → Antigravity CLI の方針） |
| `opencode` | opencode CLI | 宣言済 | 2026-07 | nix新規（**残す + nixpkgs 移行**と決定 2026-08-02。nixpkgs 1.18.9 > brew 1.18.5 で追従も問題なし） |
| `cliproxyapi` | 自前 API プロキシ（ccx / Codex 構成で使用、launchd 常駐） | 宣言済（2026-08-02 追記） | 2026-08 | brew残留（nixpkgs 未収録）。`hosts/macbook/homebrew.nix` で宣言化 |
| `ollama` | LLM ランタイム | 宣言済 | 2026-08 | **削除実行済み**（2026-08-02。未使用のため。依存の `mlx` / `mlx-c` も連鎖除去） |

> ROADMAP「共存方針」: 日常的に使う AI CLI 群（claude-code / codex / gemini-cli /
> opencode / agent-browser）は追従速度の理由で brew に残る、が既定方針。

### 1-5. CLI ユーティリティ

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `mise` | ランタイムマネージャ（共存方針で存続確定） | 宣言済 | 2026-08 | nix共通（mise 本体の配布のみ nix。ランタイムは mise 管理） |
| `d2` | ダイアグラム DSL | 宣言済 | 2026-03 | nix共通 |
| `glow` | Markdown ビューア | 宣言済 | 2026-06 | nix共通 |
| `tree` | ディレクトリ表示 | 宣言済 | 2026-06 | nix共通 |
| `yazi` | ファイラ TUI | 宣言済 | 2026-06 | nix共通 |

### 1-6. メディア・文書処理

| formula | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `ffmpeg` | 動画変換（tap: homebrew-ffmpeg のカスタム版） | 宣言済（隠れ※） | 2026-06 | **削除方針**（2026-08-02。デジタルガーデンの YouTube 自動投稿（第 1〜2 回）で使った名残。以降の用途なし。tap `homebrew-ffmpeg/ffmpeg` も連動削除） |
| `switchaudio-osx` | オーディオデバイス切替 CLI | 宣言済 | 2026-06 | nix新規（1.2.2 一致。proxy-audio-device と併用と推測） |
| `poppler` | PDF 処理 CLI 群（pdftotext 等） | **未宣言** | 2026-07 | **削除確定**（2026-08-02。使っていない） |
| `libass` | 字幕レンダリングライブラリ | **未宣言** | 2026-07 | **削除方針**（同上、YouTube 自動投稿の名残） |
| `libomp` | OpenMP ランタイム（LLVM の並列計算ライブラリ。単体で使うものではなくビルド時依存） | 宣言済 | 2026-07 | **削除方針**（依存ゼロ。Brewfile への追加はコミット `8ee8645`「実環境に同期」= 意図的導入ではなく実態の写し。YouTube 自動投稿期のビルド依存の名残と推測） |

### 1-7. brew 管理外の残骸

| 項目 | 状態 | 行き先 |
|---|---|---|
| `/opt/homebrew/bin/rg`（ripgrep 15.2.0） | **現在も動作する**（symlink → Cellar 実体あり）。ただし brew 台帳から外れており upgrade されない野良状態 | 使用継続 → Phase 3-2 適用で nix 側 `home/packages.nix` の ripgrep に正式移行し、その後 Cellar 残骸を手動除去（rg が使えない期間は発生しない） |

---

## 2. cask（13 件）

| cask | 役割 | Brewfile | 更新 | 行き先 |
|---|---|---|---|---|
| `ghostty` | ターミナル（主力） | 宣言済 | 2026-04 | brew残留 |
| `wezterm@nightly` | ターミナル（ghostty とは別用途で使用中） | 宣言済 | 2026-03 | brew残留（**両方残す**と決定 2026-08-02） |
| `zed` | エディタ | 宣言済 | 2026-08 | brew残留 |
| `claude-code@latest` | Claude Code | 宣言済 | 2026-07 | brew残留 |
| `codex` | Codex CLI | 宣言済 | 2026-08 | brew残留 |
| `codexbar` | Codex メニューバー | **未宣言** | 2026-08 | brew残留 + **宣言追加**（使用中と確認済み、2026-08-02） |
| `cmux` | ターミナルマルチプレクサ系 | **未宣言** | 2026-07 | brew残留 + **宣言追加**（使用中と確認済み、2026-08-02） |
| `aerospace` | タイル型 WM（tap: nikitabobko） | 宣言済 | 2026-03 | brew残留 |
| `orbstack` | コンテナ/VM（Docker Desktop 代替） | 宣言済 | 2026-06 | brew残留 |
| `1password-cli` | 1Password CLI | 宣言済 | 2026-08 | brew残留 |
| `easydict` | 辞書・翻訳 | 宣言済 | 2026-06 | brew残留 |
| `font-udev-gothic-nf` | UDEV Gothic Nerd Font | 宣言済 | 2026-06 | brew残留（nixpkgs のフォント配布へ移す選択肢もあるが急がない） |
| `proxy-audio-device` | 仮想オーディオデバイス | 宣言済 | 2026-04 | brew残留 |
| ~~`docker-desktop`~~ | （宣言のみ・実機なし） | 宣言済 | — | 宣言撤去候補（orbstack が代替稼働中） |

**個人/業務分離（homebrew-personal.nix / homebrew-work.nix）は不採用**（2026-08-02 判断）:
業務用 macOS 端末の配布予定がなく、WSL2 に cask（GUI）需要もないため。
再検討トリガー: 業務 Mac が配布されたとき。

---

## 3. tap（8 件）

| tap | 用途 | Brewfile | 行き先 |
|---|---|---|---|
| `coderabbitai/tap` | git-gtr | 宣言済 | 継続（`darwin/homebrew.nix` 宣言済み） |
| `go-task/tap` | go-task | 宣言済 | go-task の nix 移行完了後に untap |
| `morantron/tmux-fingers` | tmux-fingers | 宣言済 | 継続 |
| `nikitabobko/tap` | aerospace | 宣言済 | 継続 |
| `yoshihiko555/nudge` | 自作 tap（nudge cask、本体未インストール） | 宣言済（2026-08-02 追記） | **残す**（2026-08-02 判断） |
| ~~`homebrew-ffmpeg/ffmpeg`~~ | カスタム ffmpeg | — | **untap 実行済み**（2026-08-02。ffmpeg 削除に連動） |
| ~~`rtk-ai/tap`~~ | RTK（却下済み、formula ゼロ） | — | **untap 実行済み**（2026-08-02。再導入時は tap し直す） |
| `homebrew/core` | 標準 | — | 継続 |

---

## 4. 行き先サマリと未決事項

### 4-1. サマリ（formula 34 件 = leaves 29 + 隠れ 4 + 依存扱い typescript の内訳）

| 行き先 | 件数 | 内容 |
|---|---|---|
| nix共通（hermes 実績あり） | 14 | d2, fzf, gh, ghq, git, glow, lazygit, mise, neovim, starship, tmux, tree, yazi, zoxide |
| nix新規（属性確認済み） | 10 | sheldon, stow(経過措置), gopls, pyright, typescript, typescript-language-server, switchaudio-osx, tree-sitter-cli, opencode, go-task |
| brew残留 | 4 | agent-browser, cliproxyapi, git-gtr, tmux-fingers |
| 削除（**実行済み**） | 6 | gemini-cli, poppler, ffmpeg, libass, libomp, ollama |

→ **全 34 件の行き先が確定**（2026-08-02）。

### 4-2. 掃除の実施記録（2026-08-02）

- `brew uninstall` 6 件（gemini-cli / poppler / ollama / libomp / libass / ffmpeg）
  + 孤児依存の連鎖削除（mlx, mlx-c, python@3.14, gnupg ほか約 50 件、計 600MB 超回収）
- `brew untap` 2 件（homebrew-ffmpeg/ffmpeg, rtk-ai/tap）
- `gnupg` の連鎖削除は影響なしを確認（git 署名未使用・gpg は元々依存としてのみ存在）
- Brewfile を実態に同期: 削除分の宣言除去、`cliproxyapi` / `cmux` / `codexbar` /
  `yoshihiko555/nudge` tap の宣言追加、`docker-desktop` 宣言を削除（ユーザー確認済み）
- 掃除後の実測: leaves 24 / cask 13 / tap 6。宣言と実態のズレは
  「隠れ 4 件のフラグ落ち」（nix 宣言化で解消）を除き解消
- 残る手動作業: 孤立 rg の Cellar 残骸除去（**nix の ripgrep 適用後**に実施。
  先に消すと rg が使えない期間が発生するため順序厳守）

### 4-3. 確定済み判断（2026-08-02）

- **方針**: なるべく Nix で管理できるものは Nix で管理する
- シェル基盤は stow 以外すべて nix へ。stow は移行完了まで残し、完了後に削除
- Git/開発フロー系は整理案どおり
- **タスクランナーは go-task に統一**。Makefile は stow と同時期に廃止
  （Phase 3-2 完了後は bootstrap も Nix が担うため「新規端末に go-task が無い」
  問題が消滅する）。nix flake apps は `nix run .#switch` など Nix 操作の
  エントリポイント専用とし、タスクランナーの代替には使わない
- `gemini-cli` は削除（Antigravity CLI へ置き換わり済み。Google の方針としても gemini-cli は廃止方向）
- `poppler` は削除（未使用）
- `ffmpeg` / `libass` / `libomp` は削除（デジタルガーデンの YouTube 自動投稿
  第 1〜2 回で使った名残。以降の用途なし）
- `ollama` は削除（未使用。hermes の llama.cpp/llama-swap が LLM 基盤を担う）
- `opencode` は残す + nixpkgs 移行
- `wezterm@nightly` / `ghostty` は別用途で併用中のため両方残す
- `tree-sitter-cli` は用途判明（nvim-treesitter の grammar ビルド依存、`38b8136`）
  → nixpkgs `tree-sitter` へ移行
- 孤立 rg は現在も動作しており使用中 → nix の ripgrep へ正式移行後に残骸除去
- cask の personal / work 分離は不採用（業務 Mac 配布予定なし）
- `yoshihiko555/nudge` tap は残す（宣言追加済み）
- `cmux` / `codexbar` は両方使用中 → 宣言追加済み
- `docker-desktop` の Brewfile 宣言は削除（OrbStack が代替稼働中）
- `~/.config/nvim-dev` のリンク切れ symlink は削除済み
- **hermes 側も棚卸し実施**（2026-08-02）: cask 7 個は使用実態を確認しすべて継続。
  git-gtr のみ未使用と判断し darwin 共通層から降格 → zap で削除（switch 適用済み。
  hermes の brew は formula ゼロ・tap ゼロ・cask 7 個のみに）
