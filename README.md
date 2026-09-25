<div align="center">

# dotfiles

**nix-darwin + home-manager で宣言的に管理する、個人用の macOS 開発環境**

[![nix-check](https://github.com/yoshihiko555/dotfiles/actions/workflows/nix-check.yml/badge.svg)](https://github.com/yoshihiko555/dotfiles/actions/workflows/nix-check.yml)
[![Nix flakes](https://img.shields.io/badge/Nix-flakes-5277C3?logo=nixos&logoColor=white)](config/nix/README.md)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-home--manager-7EBAE4?logo=nixos&logoColor=white)](config/nix/README.md)
[![macOS](https://img.shields.io/badge/macOS-Apple_Silicon-000000?logo=apple&logoColor=white)](#-管理対象ホスト)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](config/nvim/docs/README.md)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Codex_%C2%B7_Antigravity-D97757?logo=anthropic&logoColor=white)](#-ai-エージェント資産)

[特徴](#-特徴) ·
[セットアップ](#-セットアップ) ·
[構成](#-ディレクトリ構成) ·
[Taskfile](#-taskfile-コマンド) ·
[配線](#-home-manager-の配線) ·
[AI エージェント](#-ai-エージェント資産) ·
[ドキュメント](#-関連ドキュメント)

</div>

---

## ✨ 特徴

- **宣言的に再現できる** — CLI・GUI（Homebrew cask）・dotfiles の配線をホストごとに Nix flake で定義し、`switch` 1 回で揃える
- **編集が即時反映される** — 通常の設定は `mkOutOfStoreSymlink` でリポジトリを直接指すため、編集に `switch` は要らない
- **アプリが書き換える設定も repo で持つ** — Claude Code / Antigravity の JSON と Loupedeck Live は drift を検知し、BetterTouchTool も含めて `task` で repo へ回収する
- **AI エージェント資産を一元管理する** — Claude Code / Codex / Antigravity のコンテキスト・スキル・MCP・プラグインを `shared/` から配る
- **整形を CI で守る** — treefmt で nix / shell / yaml / toml を整形し、pre-commit フックと GitHub Actions で検査する

## 💻 管理対象ホスト

| ホスト | 方式（flake の出力） | 役割 |
|---|---|---|
| MacBook Pro | nix-darwin + home-manager（`macbook`） | メイン開発機。GUI アプリ・AI CLI・Alfred などを含む |
| Mac mini（hermes） | nix-darwin + home-manager（`hermes`） | 常時稼働機。LLM 基盤（llama.cpp / llama-swap）を launchd で宣言管理 |
| 会社 Windows（WSL2） | standalone home-manager（`homeConfigurations.wsl`） | 構築中。WSL2 内部のみが対象 |

ホストごとの管理範囲は [config/nix/README.md](config/nix/README.md)、進捗は
[ROADMAP](config/nix/docs/ROADMAP.md) を正とする。

## 🧰 主なツール

| 分類 | ツール | 設定 |
|---|---|---|
| シェル | zsh · sheldon · starship | [`shell/`](shell/zsh/README.md) · [`config/sheldon/`](config/sheldon/) · [`config/starship/`](config/starship/) |
| ターミナル | **Ghostty + herdr**（常用）/ WezTerm + tmux（サブ） | [`config/ghostty/`](config/ghostty/) · [`config/herdr/`](config/herdr/) · [`config/wezterm/`](config/wezterm/README.md) · [`config/tmux/`](config/tmux/docs/README.md) |
| エディタ | Neovim · Zed | [`config/nvim/`](config/nvim/docs/README.md) · [`config/zed/`](config/zed/) |
| Git | git · lazygit · gh | [`config/git/`](config/git/) · [`config/lazygit/`](config/lazygit/CHEATSHEET.md) · [`config/gh/`](config/gh/) |
| ウィンドウ・入力 | AeroSpace · Karabiner-Elements · BetterTouchTool | [`config/aerospace/`](config/aerospace/docs/CHEATSHEET.md) · [`config/karabiner/`](config/karabiner/) · [`config/btt/`](config/btt/) |
| ランタイム | mise | [`config/mise/`](config/mise/) |
| AI エージェント | Claude Code · Codex CLI · Antigravity CLI · takt · opencode | [`claude/`](claude/) · [`codex/`](codex/) · [`gemini/`](gemini/README.md) · [`takt/`](takt/README.md) · [`config/opencode/`](config/opencode/) |
| ランチャー | Alfred | [`alfred/`](alfred/README.md) |
| デバイス | Loupedeck Live | `config/loupedeck/`（git 管理外） |

## 🚀 セットアップ

### 必要なツール

- Nix（flakes 有効）
- nix-darwin + home-manager（この Flake が入力として管理）
- [go-task](https://taskfile.dev/)（switch 後は Nix が提供）
- Homebrew（GUI / cask と nixpkgs 未収録パッケージ用）
- Python 3.11 以上（mise 管理。MCP・プラグインの同期タスクで使う）

> [!TIP]
> **まっさらな Mac からの初回構築は [config/nix/docs/BOOTSTRAP.md](config/nix/docs/BOOTSTRAP.md) を参照。**
> Xcode Command Line Tools・Homebrew 本体・GitHub 認証・Nix 本体の導入から初回 `switch` まで
> を手順化している。

### nix-darwin 導入済みの Mac で取得・反映する

```bash
# リポジトリをクローン（ghq 推奨）
ghq get https://github.com/yoshihiko555/dotfiles.git
cd ~/ghq/github.com/yoshihiko555/dotfiles

# ビルドして事前確認（任意。マシンは無変化）
nix build ./config/nix#darwinConfigurations.macbook.system

# 適用
sudo darwin-rebuild switch --flake ./config/nix#macbook

# 以降は task を使用
task --list
```

`darwin-rebuild` がまだ PATH に無い場合（nix-darwin 未導入、または初回構築時）は、
ビルド結果から直接呼び出す。

```bash
sudo ./result/sw/bin/darwin-rebuild switch --flake ./config/nix#macbook
```

ホスト名（`macbook` / `hermes`）ごとの管理範囲と、日常の反映コマンド（`nxs` / `hxs` 等の
エイリアス）は [config/nix/README.md](config/nix/README.md) と
[config/nix/docs/CHEATSHEET.md](config/nix/docs/CHEATSHEET.md) を参照。

## 📁 ディレクトリ構成

```
dotfiles/
├── shell/          # zsh 設定（zshenv / zprofile / zshrc + zsh/ 分割）→ shell/zsh/README.md
├── config/         # XDG_CONFIG_HOME 系（→ ~/.config）
│   ├── nix/        # nix-darwin + home-manager の実体 → config/nix/README.md
│   ├── nvim/       # エディタ（Neovim）→ config/nvim/docs/README.md
│   ├── herdr/      # ターミナルマルチプレクサ（常用）。プラグイン一覧・通知・自作スクリプト
│   ├── btt/        # BetterTouchTool のトリガー（switch 時に実機へ適用）
│   ├── loupedeck/  # Loupedeck Live のプロファイル（git 管理外）
│   └── ...         # ghostty, wezterm, tmux, starship, mise, sheldon, karabiner,
│                   # aerospace, lazygit, opencode, zed, gh, git
├── ssh/            # ~/.ssh/config（IP・ホスト名のみ。秘匿情報は含めない）
├── home/           # $HOME 直下に置く単体ファイル（editorconfig）
├── claude/         # Claude Code 個人用（→ ~/.claude）
├── claude-work/    # Claude Code 会社用（→ ~/.claude-work）
├── codex/          # Codex CLI（→ ~/.codex）
├── gemini/         # Gemini / Antigravity CLI（→ ~/.gemini）→ gemini/README.md
├── takt/           # takt CLI（→ ~/.takt）→ takt/README.md
├── shared/         # 共通データの実体（agents / skills / mcp / plugins / cliproxyapi）
├── alfred/         # Alfred ワークフロー → alfred/README.md
├── docs/           # 領域をまたぐ決定の ADR（docs/adr/）
├── taskfiles/      # Taskfile.yml から読み込むタスク定義
├── scripts/        # タスクから呼ぶスクリプト（shell / Python）とテスト
├── .githooks/      # pre-commit（treefmt の整形崩れを検出）
├── .github/        # CI（nix-check.yml）
└── .sops.yaml      # sops-nix の暗号化ルール（仕組みのみ。管理対象の秘匿値は無い）
```

各 CLI ディレクトリの中身（`agents/` `hooks/` `rules/` `skills/` 等）と、`shared/` の
`agents/` `skills/` の役割は [Agent コンテキストファイルの一元管理](#agent-コンテキストファイルの一元管理)
以降を参照。

## 📋 Taskfile コマンド

`task`（引数なし）または `task --list` で一覧を表示する。

| 分類 | コマンド | 内容 |
|---|---|---|
| **配線・回収** | `task status` | home-manager の配線と mutable 設定の drift を確認 |
| | `task adopt-settings` | アプリが変更した mutable 設定を repo へ回収 |
| | `task btt-export` | BetterTouchTool の現在のトリガー設定を repo へ回収 |
| | `task btt-apply` | repo の BetterTouchTool 設定を実機へ適用（switch でも自動実行） |
| | `task loupedeck-export` | Loupedeck Live のプロファイルを `config/loupedeck/`（git 管理外）へ回収 |
| | `task loupedeck-apply` | repo の Loupedeck Live プロファイルを実機へ適用（switch でも自動実行） |
| **Nix** | `task nix-check` | nix flake の評価とフォーマット検査（`nix flake check`） |
| | `task nix-fmt` | nix + shell + yaml/toml を treefmt で整形（`nix fmt`）。lua/md/json は対象外 |
| **エージェント資産** | `task sync-agents` | `shared/agents` から Codex / Gemini の AGENTS.md を生成 |
| | `task sync-skills` | `shared/skills` のリンクを更新 |
| | `task claude-work-init` | 会社用 Claude Code 設定ディレクトリを初期化 |
| | `task sync-claude-work-skills` | 会社用 Claude Code の common + work スキルを同期 |
| **MCP** | `task mcp-list` | 個人用グローバル MCP の登録状況を表示（読み取り専用） |
| | `task mcp-diff` | 共通定義との差分を表示（読み取り専用） |
| | `task mcp-sync` | 共通定義を Claude / Codex へ同期（バックアップ付き） |
| **プラグイン** | `task plugin-list` | 共通プラグインの対応表と登録状態を表示（読み取り専用） |
| | `task plugin-diff` | 導入・有効化候補と実行コマンドを確認（読み取り専用） |
| | `task plugin-sync` | 同期対象の既存プラグインを各 CLI で導入・有効化 |
| **掃除** | `task clean-claude-dry` | Claude デバッグログ削除の dry-run |
| | `task clean-claude` | Claude デバッグログを削除 |
| | `task clean-uv-dry` | uv キャッシュ prune を実行できる状態か確認 |
| | `task clean-uv` | uv キャッシュの不要エントリを prune（claude-mem worker を一時停止） |
| **CLIProxyAPI** | `task cliproxy-setup` | CLIProxyAPI を導入しテンプレートから設定を生成 |
| | `task cliproxy-status` | 稼働状態・OAuth 期限・公開モデルを確認 |
| | `task cliproxy-auth-prune` | 新しい認証に置き換わった失効ファイルを削除（既定は確認のみ） |

> [!NOTE]
> push 時は GitHub Actions（[.github/workflows/nix-check.yml](.github/workflows/nix-check.yml)）が
> `nix flake check` 相当を実行する。ローカルでは `task nix-check` / `task nix-fmt` で先に確認する。
> commit 時は `.githooks/pre-commit` がステージ済みファイルの整形崩れを検出して止める
> （検査のみ。落ちたら `task nix-fmt` → `git add`）。

## 🔗 home-manager の配線

配線の定義そのものが正典で、README にパス一覧は持たない。

| ファイル | 役割 |
|---|---|
| [config/nix/home/dotfiles.nix](config/nix/home/dotfiles.nix) | 2 台以上で使う共通配線（zsh, git, mise, nvim, starship, tmux） |
| [config/nix/hosts/macbook/dotfiles.nix](config/nix/hosts/macbook/dotfiles.nix) | MacBook 固有（GUI 系 config, AI CLI, ssh, Alfred, BTT / Loupedeck / herdr プラグインの同期） |
| [config/nix/hosts/hermes/dotfiles.nix](config/nix/hosts/hermes/dotfiles.nix) | hermes 固有 |

通常の設定は `mkOutOfStoreSymlink` で配線するため、repo 内の編集が即時反映される。
アプリが書き換える設定だけは次の方式で扱う。

| 対象 | 方式 | 回収 |
|---|---|---|
| Claude Code / Antigravity CLI の JSON | 実ファイルとして生成し、前回 switch 時の参照コピーとの差分で drift を検知 | `task adopt-settings` |
| BetterTouchTool | 設定実体が SQLite のため、switch 時に AppleScript API で repo の JSON を流し込む（追加・更新のみ） | `task btt-export` |
| Loupedeck Live | switch 時にプロファイルを適用。drift 中は警告のみでスキップ | `task loupedeck-export` |
| herdr プラグイン | switch 時に `config/herdr/plugins.txt` の固定リストへ揃える | — |

```bash
task status                  # 配線と drift の確認
task adopt-settings TARGET=all
```

## 🤖 AI エージェント資産

Claude Code / Codex / Antigravity（Gemini）で共有する資産は `shared/` に実体を置き、
各 CLI のディレクトリからリンク・生成・同期で配る。

### Agent コンテキストファイルの一元管理

- CLAUDE.md / AGENTS.md の実体は `shared/agents/` に集約
  - `core.md`: 全エージェント共通ルール（唯一の編集対象）
  - `diff-claude.md` / `diff-codex.md` / `diff-gemini.md`: CLI 固有の差分
- Claude Code: `claude/CLAUDE.md` が `@import` で core + diff を参照（生成不要）
- Codex / Gemini: `task sync-agents` で core + diff を連結して各 AGENTS.md を生成
- リポジトリルートの `AGENTS.md` は当リポジトリ固有ルールのみ（`CLAUDE.md` は `@AGENTS.md` で橋渡し）
- core.md / diff-*.md を編集したら `task sync-agents` を実行すること

### Skills の一元管理

- スキル本体は `shared/skills/` に集約
  - `common/`: 共通スキル（個人用・会社用の両方で使う）
  - `claude-only/` / `codex-only/` / `antigravity-only/`: CLI 専用スキル
  - `work/`: 会社アカウントでも使うことを明示したスキル
- `claude/skills`、`codex/skills`、`gemini/config/skills` は相対シンボリックリンクで参照
- Antigravity のグローバルスキルは `~/.gemini/config/skills/<skill-folder>/SKILL.md` として解決される
- リンク更新は `task sync-skills` で実行

### プラグインの共通管理

Claude Code / Codex で利用できる既存プラグインを `shared/plugins/plugins.json` にまとめる。
Context7・Notion・claude-mem のクライアント別 ID と導入方針を管理し、
CLI 同期・アプリ管理・採用候補を区別する。

`task plugin-list` / `task plugin-diff` は読み取り専用。
`task plugin-sync -- context7` のように個別導入できる。
詳細は [共通プラグイン管理](shared/plugins/README.md)、
対象外を含む選定理由は [対象調査](shared/plugins/INVENTORY.md) を参照。

### MCP 運用方針

Figma・Pencil・drawio は Claude Code / Codex 共通のグローバル MCP として `task mcp-sync` で配る。
それ以外はプロジェクト単位の登録と、Codex の実行時オーバーライドを基本にする。

<details>
<summary><b>個人用グローバル MCP の共通管理</b></summary>

- Figma・Pencil・drawio を Claude Code / Codex 共通のグローバル管理対象にする。
  この3件は共通利用の対象とし、それ以外の Codex MCP の既定方針は下記に従う。
- `shared/mcp/servers/<名前>.json` に接続定義、`shared/mcp/clients.json` に
  クライアント別の利用対象と引数の上書きを置く。詳細は [共通定義の説明](shared/mcp/README.md)。
- 実装は `scripts/mcp-manage.py`（Python 3.11 以上。外部パッケージや jq / taplo は不要）。
  `task mcp-list` / `task mcp-diff` は読み取り専用、`task mcp-sync` で反映する。
  OAuth・接続の成否は検査しない。
- プラグイン由来 MCP、会社用 `ccw` は今回の移行対象外。
  グローバル登録先ではない `~/.claude/.mcp.json` への配布は廃止した。
- 同期は個人用の `~/.claude.json` と `~/.codex/config.toml` の管理対象のみを更新する。
  実体の symlink を保持し、更新前の設定を `~/.local/state/dotfiles/mcp-backups/` に保存する。
  `task mcp-sync -- figma` のように1件だけ指定することもできる。

</details>

<details>
<summary><b>既存の登録方法と既定方針</b></summary>

- Codex (`codex/config.toml`) の MCP は必要最小限のみ有効にする。追加する MCP は原則
  `enabled = false` を既定にし、実行時オーバーライドで有効化する。
- Notion は両 CLI ともプラグイン経由に統一し、Codex の直接登録 MCP は廃止した。
  `task plugin-sync -- notion` で導入・有効化を同期する。`notion-task` もプラグイン由来のツールを使う。
  Codex のリモート状態確認にはネットワークとログインが必要で、初回の Notion 認証は別途行う。
- プロジェクト限定の MCP は、そのプロジェクトで `claude mcp add --scope project ...` を使って登録する。
- Codex で一時的に有効化する場合は実行時オーバーライドを使う。

```bash
# 無効化している MCP を一時的に有効化する例
codex -c mcp_servers.computer-use.enabled=true
```

- Claude Code 側は `--scope project` を基本にし、個人限定用途は `--scope local` / `--scope user` を使い分ける。
- 全プロジェクトで使いたい MCP（Figma など）は **user scope** に置く。user scope の保存先
  `~/.claude.json` は履歴を含む mutable state のため、`task mcp-sync` で管理対象の MCP のみを更新する。
  差分がなければ書き込まない。管理対象から外した定義も自動削除はしない。
  OAuth が必要な MCP は適用後に Claude Code で `/mcp` を実行して認証する。

```bash
task mcp-diff        # 適用対象を確認
task mcp-sync        # Claude / Codex に適用
```

- Claude Code プラグインは `claude/settings.json` の `enabledPlugins` で個別に管理する。
  Notion・Context7 など、普段使うプラグインは有効。プラグイン由来の MCP も各プラグインに管理を任せる。

```bash
# Claude: プロジェクト限定でプラグインを有効化
claude plugin enable context7@claude-plugins-official --scope project
claude plugin enable notion@claude-plugins-official --scope project

# Claude: 一括無効化（最小構成に戻す）
claude plugin disable --all --scope user
claude plugin disable --all --scope project
claude plugin disable --all --scope local
```

</details>

### Claude Code 会社アカウント運用

`ccw` は `CLAUDE_CONFIG_DIR=~/.claude-work` を付けて Claude Code を起動する。
設定ファイル（`settings.json` / `CLAUDE.md` / `rules`）は個人用と同じく home-manager が
配線する。認証情報・履歴・plugin 状態は Git に含めない。

```bash
# 初回だけ実行
task claude-work-init

# 会社アカウントとして起動・ログイン
ccw
```

| 用途 | コマンド | 設定ディレクトリ |
|---|---|---|
| 個人用 | `claude` / `cc` / `ccp` | `~/.claude` |
| 会社用 | `ccw` | `~/.claude-work` |

> [!WARNING]
> 会社用では **`statusLine` と hooks は現状動かない。** 詳細は下の「運用メモ」を参照。

<details>
<summary><b>運用メモ</b></summary>

- 配布物は `claude-work/` 配下（`settings.json` / `CLAUDE.md` / `rules`）。
  `statusline.py` / `claude_message.sh` / `hooks/` は `claude/` の実体を共有する。
- `settings.json` は個人用と同じ mutable 実ファイル方式。drift は `task status` で確認し、
  `task adopt-settings TARGET=claude-work` で repo へ回収する。
- `autoMode` は Claude Code が起動環境から自動生成し社内情報を含みうるため、repo には載せない。
  drift 比較から除外し、switch 時は実ファイル側の値をそのまま引き継ぐ。
- 会社用の認証情報、履歴、plugin 状態は Git に含めない。
- **`statusLine` と hooks は現状動かない。** 会社アカウントには管理設定
  `allowManagedHooksOnly: true` が配信されており、Claude Code は `statusLine` /
  `fileSuggestion` / `subagentStatusLine` と hooks を managed 設定のものだけに絞る
  （[公式ドキュメント](https://code.claude.com/docs/en/hooks)）。管理設定側にこれらの定義は
  無いため、ユーザー設定の指定は無視される。ポリシーが変われば記述はそのまま有効になるので
  `claude-work/settings.json` には残している。
- 上記のため、会社用の drift 検出は `task status` と switch 時の警告の 2 経路
  （個人用は Stop hook を含めた 3 経路）。
- `shared/skills/common/` は個人用・会社用の両方で使ってよい共通スキル置き場。
- `shared/skills/work/` は会社用に追加したいスキル置き場。
- `task sync-claude-work-skills` は `shared/skills/common/*` と `shared/skills/work/*` を `~/.claude-work/skills/` にリンクする。

</details>

## 📚 関連ドキュメント

| ドキュメント | 内容 |
|---|---|
| [config/nix/README.md](config/nix/README.md) | nix-darwin + home-manager の構成・管理対象ホスト |
| [config/nix/docs/](config/nix/docs/) | BOOTSTRAP / CHEATSHEET / GUIDE / ROADMAP / ADR |
| [config/nix/patches/README.md](config/nix/patches/README.md) | 上流未修正の問題に対する暫定パッチ |
| [config/nvim/docs/README.md](config/nvim/docs/README.md) | Neovim のプラグイン一覧・キーバインドチートシート・練習問題・ADR |
| [config/tmux/docs/README.md](config/tmux/docs/README.md) | tmux-first 環境の実装と移行計画 |
| [config/wezterm/README.md](config/wezterm/README.md) | WezTerm（tmux-first）の設定 |
| [config/aerospace/docs/CHEATSHEET.md](config/aerospace/docs/CHEATSHEET.md) | AeroSpace のチートシート |
| [config/lazygit/CHEATSHEET.md](config/lazygit/CHEATSHEET.md) | lazygit のチートシート |
| [shell/zsh/README.md](shell/zsh/README.md) | zsh 分割設定と `wt` / `repo` などの自作コマンド |
| [shared/mcp/README.md](shared/mcp/README.md) | 個人用グローバル MCP の共通定義と同期 |
| [shared/plugins/README.md](shared/plugins/README.md) | Claude Code / Codex の共通プラグイン管理 |
| [claude/plugins/turn-receipt/README.md](claude/plugins/turn-receipt/README.md) | ターンごとの編集・実行件数を表示する自作 mod |
| [takt/README.md](takt/README.md) | takt のプロバイダ割り当て・権限モード・作業ディレクトリ配置 |
| [gemini/README.md](gemini/README.md) | Gemini / Antigravity CLI の設定と権限設計 |
| [alfred/README.md](alfred/README.md) | Alfred ワークフロー詳細 |
| [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) | 領域をまたぐ決定の ADR 索引（領域内の ADR は `config/<領域>/docs/adr/`） |
| [claude/docs/adr/DECISIONS.md](claude/docs/adr/DECISIONS.md) | Claude Code 設定の ADR 索引 |
