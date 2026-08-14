# dotfiles

個人用の設定ファイル管理リポジトリ。
**nix-darwin + home-manager** で MacBook Pro と Mac mini（hermes）を宣言的に管理する。

## 構成

```
dotfiles/
├── shell/        # zsh 設定（zshenv / zprofile / zshrc + zsh/ 分割）→ shell/zsh/README.md
├── config/       # XDG_CONFIG_HOME 系（→ ~/.config）
│   ├── nix/      # nix-darwin + home-manager の実体 → config/nix/README.md
│   ├── nvim/     # エディタ（Neovim）→ config/nvim/docs/README.md
│   └── ...       # wezterm, ghostty, tmux, starship, mise, sheldon, karabiner,
│                 # aerospace, lazygit, opencode, zed, gh, git
├── ssh/          # ~/.ssh/config（IP・ホスト名のみ。秘匿情報は含めない）
├── home/         # $HOME 直下に置く単体ファイル（editorconfig）
├── claude/       # Claude Code（→ ~/.claude）
├── codex/        # Codex CLI（→ ~/.codex）
├── gemini/       # Gemini / Antigravity CLI（→ ~/.gemini）→ gemini/README.md
├── takt/         # takt CLI（→ ~/.takt）→ takt/README.md
├── shared/       # 共通データの実体（agents / skills / 各種テンプレート）
├── alfred/       # Alfred ワークフロー → alfred/README.md
├── taskfiles/    # Taskfile.yml から読み込むタスク定義
├── scripts/      # タスクから呼ぶシェルスクリプト
└── .github/      # CI（nix-check.yml）
```

各 CLI ディレクトリの中身（`agents/` `hooks/` `rules/` `skills/` 等）と、`shared/` の
`agents/` `skills/` の役割は [Agent コンテキストファイルの一元管理](#agent-コンテキストファイルの一元管理)
以降を参照。

## 必要なツール

- Nix（flakes 有効）
- nix-darwin + home-manager（この Flake が入力として管理）
- [go-task](https://taskfile.dev/)（switch 後は Nix が提供）
- Homebrew（GUI / cask と nixpkgs 未収録パッケージ用）

## セットアップ

**まっさらな Mac からの初回構築は
[config/nix/docs/BOOTSTRAP.md](config/nix/docs/BOOTSTRAP.md) を参照。**
Xcode Command Line Tools・Homebrew 本体・GitHub 認証・Nix 本体の導入から初回 `switch` まで
を手順化している。

nix-darwin 導入済みの Mac で設定を取得・反映する場合:

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

## Taskfile コマンド（日常運用）

```bash
task --list        # タスク一覧
task status        # home-manager の配線と mutable 設定の drift を確認
task adopt-settings # アプリが変更した mutable 設定を repo へ回収
task sync-skills   # shared/skills のリンクを更新
task sync-agents   # shared/agents から Codex/Gemini の AGENTS.md を生成
task claude-work-init # 会社用 Claude Code 設定ディレクトリを初期化
task sync-claude-work-skills # 会社用 Claude Code の work スキルを同期
task edit          # VS Code で開く
task mcp-init      # 最小構成の .mcp.json をコピー
task mcp-show      # 最小構成テンプレートの内容を表示
task clean-claude-dry # Claude デバッグログ削除の dry-run
task clean-claude  # Claude デバッグログを削除
task codex-trust-audit # Codex trust 設定を監査
task nix-check     # nix flake の評価とフォーマット検査（nix flake check）
task nix-fmt       # nix + shell + yaml/toml を treefmt で整形（nix fmt）
task cliproxy-setup  # CLIProxyAPI を導入しテンプレートから設定を生成
task cliproxy-status # CLIProxyAPI の稼働状態と公開モデル一覧を確認
```

push 時は GitHub Actions（[.github/workflows/nix-check.yml](.github/workflows/nix-check.yml)）が
`nix flake check` 相当を実行する。ローカルでは `task nix-check` / `task nix-fmt` で先に確認する。

## home-manager の配線

配線の定義そのものが正典で、README にパス一覧は持たない。

| ファイル | 役割 |
|---|---|
| [config/nix/home/dotfiles.nix](config/nix/home/dotfiles.nix) | 2 台以上で使う共通配線（zsh, git, mise, nvim, starship, tmux） |
| [config/nix/hosts/macbook/dotfiles.nix](config/nix/hosts/macbook/dotfiles.nix) | MacBook 固有（GUI 系 config, AI CLI, ssh, Alfred） |
| [config/nix/hosts/hermes/dotfiles.nix](config/nix/hosts/hermes/dotfiles.nix) | hermes 固有 |

通常の設定は `mkOutOfStoreSymlink` で配線するため、repo 内の編集が即時反映される。
Claude Code と Antigravity CLI が置換書き込みする JSON だけは実ファイルとして生成し、
前回 switch 時の参照コピーとの差分を検知する。drift は次で回収する。

```bash
task status                  # 配線と drift の確認
task adopt-settings TARGET=all
```

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
- Antigravity のグローバルスキルは `~/.gemini/config/skills/<skill-folder>/SKILL.md` として解決されます
- リンク更新は `task sync-skills` で実行

## MCP 運用方針（デフォルト無効）

- Codex (`codex/config.toml`) の MCP は必要最小限のみ有効にする方針です。追加する MCP は原則
  `enabled = false` を既定にし、実行時オーバーライドで有効化してください。
- ただし `notion` は例外で **デフォルト有効** です。`shared/skills/common/notion-task` スキルが
  会話の途中で呼ばれる前提のため、起動し直さずに使える必要があります。
  初回のみ `codex mcp login notion` で OAuth 認証してください（`codex mcp list` の Auth 列で確認できます）。
- プロジェクトの `.mcp.json` は `task mcp-init` で空の `mcpServers`（通常作業向け）を作成し、必要なMCPだけ追記してください。
- Codex で一時的に有効化する場合は実行時オーバーライドを使います。

```bash
# 無効化している MCP を一時的に有効化する例
codex -c mcp_servers.computer-use.enabled=true

# 逆に Notion を一時的に無効化したい場合
codex -c mcp_servers.notion.enabled=false
```

- Claude Code 側は `--scope project` を基本にし、個人限定用途は `--scope local` / `--scope user` を使い分けてください。
- Claude Code プラグイン (`claude/settings.json`) もデフォルト無効です。必要時のみ有効化してください。

```bash
# Claude: プロジェクト限定でプラグインを有効化
claude plugin enable context7@claude-plugins-official --scope project
claude plugin enable Notion@claude-plugins-official --scope project

# Claude: 一括無効化（最小構成に戻す）
claude plugin disable --all --scope user
claude plugin disable --all --scope project
claude plugin disable --all --scope local
```

## Claude Code 会社アカウント運用

会社アカウント用の Claude Code 設定は Git 管理しません。`ccw` は
`CLAUDE_CONFIG_DIR=~/.claude-work` を付けて Claude Code を起動します。

```bash
# 初回だけ実行
task claude-work-init

# 会社アカウントとして起動・ログイン
ccw
```

- 個人用: `claude` / `cc` / `ccp`（通常の `~/.claude`）
- 会社用: `ccw`（Git 管理外の `~/.claude-work`）
- 会社用の `settings.json`、認証情報、履歴、plugin 状態は Git に含めません。
- `shared/skills/common/` は個人用・会社用の両方で使ってよい共通スキル置き場です。
- `shared/skills/work/` は会社用に追加したいスキル置き場です。
- `task sync-claude-work-skills` は `shared/skills/common/*` と `shared/skills/work/*` を `~/.claude-work/skills/` にリンクします。

## Alfred ワークフロー

home-manager が Dropbox 配下へシンボリックリンクを作成して管理する。

### WezTerm Open

Alfredから指定ディレクトリをWezTermで3分割ペインレイアウトで開く。

**キーワード:** `wez`

```
3分割レイアウト:
┌──────┬──────┐
│      │  2   │
│  1   ├──────┤
│      │  3   │
└──────┴──────┘
```

### post

コンテンツ投稿サイト（Adobe Firefly / Contentful / Zenn / Note / YouTube Studio）を一括で開く。

**キーワード:** `post`

### audio-output

オーディオ出力デバイスを一覧から選んで切り替える（`SwitchAudioSource` 依存）。

**キーワード:** `audio`

詳細は [alfred/README.md](alfred/README.md) を参照。

## 関連ドキュメント

| ドキュメント | 内容 |
|---|---|
| [config/nix/README.md](config/nix/README.md) | nix-darwin + home-manager の構成・管理対象ホスト |
| [config/nix/docs/](config/nix/docs/) | BOOTSTRAP / CHEATSHEET / GUIDE / ROADMAP / ADR |
| [config/nvim/docs/README.md](config/nvim/docs/README.md) | Neovim のプラグイン一覧・キーバインドチートシート・練習問題・ADR |
| [shell/zsh/README.md](shell/zsh/README.md) | zsh 分割設定と `wt` / `repo` などの自作コマンド |
| [takt/README.md](takt/README.md) | takt のプロバイダ割り当て・権限モード・作業ディレクトリ配置 |
| [gemini/README.md](gemini/README.md) | Gemini / Antigravity CLI の設定と権限設計 |
| [alfred/README.md](alfred/README.md) | Alfred ワークフロー詳細 |
