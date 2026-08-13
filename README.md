# dotfiles

個人用の設定ファイル管理リポジトリ

## 構成

```
dotfiles/
├── shell/                  # シェル設定（→ ~）
│   ├── .zshrc
│   └── .zprofile
│
├── config/                 # XDG_CONFIG_HOME 系（→ ~）
│   └── .config/
│       ├── wezterm/        # ターミナル (WezTerm)
│       ├── ghostty/        # ターミナル (Ghostty)
│       ├── starship/       # プロンプト
│       ├── mise/           # ランタイム管理
│       ├── sheldon/        # zsh プラグイン
│       ├── karabiner/      # キーリマッピング
│       ├── lazygit/        # Git TUI
│       ├── opencode/       # OpenCode CLI
│       ├── nvim/           # エディタ (Neovim)
│       └── git/            # git 設定 (global ignore 等)
│
├── claude/                 # Claude CLI（→ ~）
│   └── .claude/
│       ├── CLAUDE.md       # shared/agents を @import で参照
│       ├── settings.json
│       ├── agents/         # エージェント定義
│       ├── hooks/          # フック
│       ├── rules/          # ルール
│       ├── templates/      # テンプレート
│       └── skills/         # → shared/skills へのリンク
│
├── codex/                  # Codex CLI（→ ~）
│   └── .codex/
│       ├── AGENTS.md       # 生成物（task sync-agents）
│       ├── config.toml
│       ├── prompts/        # カスタムプロンプト
│       ├── skills/         # → shared/skills へのリンク
│       └── codex_message.sh
│
├── gemini/                 # Gemini CLI（→ ~）
│   └── .gemini/
│       ├── AGENTS.md       # 生成物（task sync-agents）
│       ├── settings.json
│       ├── config/
│       │   └── skills/     # → shared/skills へのリンク
│       └── antigravity-cli/
│           ├── settings.json
│           └── keybindings.json
│
├── takt/                   # takt CLI（→ ~）
│   └── .takt/
│       └── config.yaml
│
├── shared/                 # 共通データ
│   ├── agents/             # CLAUDE.md / AGENTS.md の実体（core + diff）
│   ├── commands/           # Claude/Codex 用コマンド定義
│   │   ├── common/
│   │   ├── claude-only/
│   │   └── codex-only/
│   ├── mcp.template.json   # MCP 設定テンプレート（最小構成）
│   ├── notify_message.sh   # 通知スクリプト
│   └── skills/             # AI エージェント向けスキルの実体
│       ├── common/         # 共通スキル
│       ├── claude-only/    # Claude 専用スキル
│       ├── codex-only/     # Codex 専用スキル
│       ├── antigravity-only/ # Antigravity 専用スキル
│       └── work/           # 会社アカウントでも使うことを明示したスキル
│
├── alfred/                 # Alfred ワークフロー（→ ~/Dropbox/...へリンク）
│   └── Open-VS-or-IT/      # お気に入りフォルダを開くワークフロー
│
├── Taskfile.yml            # エントリポイント（taskfiles/ を読み込む）
├── taskfiles/
│   ├── dotfiles.yml
│   ├── skills.yml
│   └── util.yml
├── scripts/
│   ├── adopt-managed-settings.sh
│   ├── install-brew.sh
│   └── clean-claude.sh
└── README.md
```

## 必要なツール

- Nix（flakes 有効）
- nix-darwin + home-manager（この Flake が入力として管理）
- [go-task](https://taskfile.dev/)（switch 後は Nix が提供）
- Homebrew（GUI / cask と nixpkgs 未収録パッケージ用）

## セットアップ

**まっさらな Mac からの初回構築は
[config/.config/nix/docs/BOOTSTRAP.md](config/.config/nix/docs/BOOTSTRAP.md) を参照。**
Xcode Command Line Tools・Homebrew 本体・GitHub 認証・Nix 本体の導入から初回 `switch` まで
を手順化している。

nix-darwin 導入済みの Mac で設定を取得・反映する場合:

```bash
# リポジトリをクローン（ghq 推奨）
ghq get https://github.com/yoshihiko555/dotfiles.git
cd ~/ghq/github.com/yoshihiko555/dotfiles

# ビルドして事前確認（任意。マシンは無変化）
nix build ./config/.config/nix#darwinConfigurations.macbook.system

# 適用
sudo darwin-rebuild switch --flake ./config/.config/nix#macbook

# 以降は task を使用
task --list
```

`darwin-rebuild` がまだ PATH に無い場合（nix-darwin 未導入、または初回構築時）は、
ビルド結果から直接呼び出す。

```bash
sudo ./result/sw/bin/darwin-rebuild switch --flake ./config/.config/nix#macbook
```

## Taskfile コマンド（日常運用）

```bash
task --list        # タスク一覧
task adopt-settings # mutable 設定の drift を repo へ回収
task sync-skills   # shared/skills のリンクを更新
task sync-agents   # shared/agents から Codex/Gemini の AGENTS.md を生成
task claude-work-init # 会社用 Claude Code 設定ディレクトリを初期化
task sync-claude-work-skills # 会社用 Claude Code の work スキルを同期
task status        # 現在のリンク状態を確認
task edit          # VS Code で開く
task mcp-init      # 最小構成の .mcp.json をコピー
task mcp-show      # 最小構成テンプレートの内容を表示
task clean-claude-dry # Claude デバッグログ削除の dry-run
task clean-claude  # Claude デバッグログを削除
task codex-trust-audit # Codex trust 設定を監査
```

## Neovim LSP（TypeScript / Go / Python）

- `config/.config/nvim/init.lua` と `config/.config/nvim/lua/lsp.lua` で最小構成の LSP を有効化
- 対象サーバー: `gopls` / `pyright-langserver` / `typescript-language-server`
- 前提: home-manager が `gopls`, `pyright`, `typescript`, `typescript-language-server` を導入済み

主なキーマップ:

- `gd` 定義へジャンプ
- `gD` 宣言へジャンプ
- `gr` 参照一覧
- `gi` 実装へジャンプ
- `K` ホバー
- `<leader>rn` リネーム
- `<leader>ca` コードアクション
- `[d` / `]d` 診断の前後移動

補完は挿入モードで `Ctrl-x Ctrl-o`（omnifunc）を使用。

## MCP 運用方針（デフォルト無効）

- Codex (`codex/.codex/config.toml`) の MCP は必要最小限のみ有効にする方針です。追加する MCP は原則
  `enabled = false` を既定にし、実行時オーバーライドで有効化してください。
- ただし `notion` は例外で **デフォルト有効** です。`shared/skills/common/notion-task` スキルが
  会話の途中で呼ばれる前提のため、起動し直さずに使える必要があります。
  初回のみ `codex mcp login notion` で OAuth 認証してください（`codex mcp list` の Auth 列で確認できます）。
- プロジェクトの `.mcp.json` は `task mcp-init` で空の `mcpServers`（通常作業向け）を作成し、必要なMCPだけ追記してください。
- Codex で一時的に有効化する場合は実行時オーバーライドを使います。

```bash
# 無効化している MCP を一時的に有効化する例
codex -c mcp_servers.context7.enabled=true

# 逆に Notion を一時的に無効化したい場合
codex -c mcp_servers.notion.enabled=false
```

- Claude Code 側は `--scope project` を基本にし、個人限定用途は `--scope local` / `--scope user` を使い分けてください。
- Claude Code プラグイン (`claude/.claude/settings.json`) もデフォルト無効です。必要時のみ有効化してください。

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

## takt 運用方針

`takt/.takt/config.yaml` はステップの役割（tags）ごとにプロバイダを割り当てます。

- 実装・テスト（`coding` / `testing`）: Codex（`codex/.codex/config.toml` の `gpt-5.6-sol`）
- 計画・レビュー・最終判定（`plan` / `review` / `final-gate` など）: Claude（`opus`）

ビルトインワークフローはステップに `provider:` を書いていないため、`provider_routing.tags` の指定が
全ワークフローに横断で効きます（優先度は `provider_routing.tags` = 5 > `workflow` = 9 で、数値が小さいほど強い）。
実行時に `takt --provider claude` のように上書きする方法が最優先（= 0）です。

```bash
# 個人アカウント
takt

# 会社アカウント（Claude 側のステップのみ ~/.claude-work を使う）
taktw
```

- `taktw` は `CLAUDE_CONFIG_DIR` を渡すだけなので、Codex / OpenCode のステップは影響を受けません。
- 環境変数はプロセス単位で効くため、同一実行内で Claude アカウントを混在させることはできません。
- API キー（`anthropic_api_key` など）は config.yaml に書かず、`TAKT_ANTHROPIC_API_KEY` 等の環境変数を使います。

### worktree の配置

`worktree_dir: .worktrees` で、takt の worktree を gtr（`wt` コマンド）と同じ場所に寄せています。
gtr は `git worktree list` ベースで worktree を列挙するため、takt が作った worktree も
`gtr list` / `gtr go` / `gtr rm` から扱えます。

- 既定のままだと `<project>/../takt-worktrees` に作られ、ghq 構成では `~/ghq/github.com/<user>/` が汚れます。
- takt を使うプロジェクトでは `.gitignore` に `.worktrees/` を追加してください（未追加だと gtr が警告します）。

### 権限モード

`provider_profiles` は claude / codex とも `edit` です。takt の権限モードは Claude Code の
`--permission-mode` に対応します。

| takt | Claude Code | 備考 |
|---|---|---|
| `readonly` | `default` | 書き込み禁止ではなく都度確認。headless では応答できず停止しうる |
| `edit` | `acceptEdits` | |
| `full` | `bypassPermissions` | 全許可のため使いません |

編集の可否はワークフロー側の `edit` フラグ（`plan` は `edit: false`）が制御するので、
プロバイダ側で `readonly` に二重に絞っていません。

### 実行制御

- `concurrency: 2` — 同時実行タスク数（既定 1）
- `auto_requeue_max_attempts: 1` — 一時的な失敗を 1 回だけ拾い直す（既定 0）

`base_branch` は**意図的に設定していません**。未設定なら `origin/HEAD` → `main` → `master` の順で
自動判定されますが、明示するとブランチ存在チェックが走り、`master` を使うリポジトリでエラーになります。

その他「既定のまま使う」と判断した項目（`auto_pr`、`observability` など）は
`takt/.takt/config.yaml` の末尾に理由付きで列挙しています。

## Worktree 補助コマンド

`git gtr` をそのまま使いつつ、よく使う作成・削除だけ `wt` で短縮できます。

```bash
wt new nvim lsp
# => 例: task/nvim-lsp を自動生成して git gtr new

wt new fix hook tweak -- --from-current -e
# => ブランチ名は自動生成しつつ、gtr のオプションをそのまま渡す

wt rm
# => fzf で今の repo の worktree/branch を選んで削除

wt rm task/nvim-lsp --yes
wt done task/nvim-lsp --yes
# => どちらも git gtr rm ... --delete-branch
```

基本形:

```bash
wt new [topic...]
wt new [topic...] -- [git gtr new options...]
wt rm <branch...> [git gtr rm options...]
wt rm [--yes|--force]
wt done <branch...> [git gtr rm options...]
wt <git gtr command...>
```

- `wt new` は既定で `task/<slug>` 形式のブランチ名を生成します。
- `topic` の先頭が `feat`, `fix`, `docs`, `chore`, `refactor`, `test`, `release`, `task` などの既知 prefix なら、その値をブランチ種別として使います。
- `topic` を省略した場合だけ `task/worktree-YYYYMMDD-HHMMSS` を使います。
- 同じブランチ名が既に存在する場合は `-2`, `-3` を末尾に付けて衝突を避けます。
- `wt new` で `git gtr new` のオプションも渡したい場合は、`--` 以降をそのまま `gtr` に渡します。
- `wt rm` / `wt done` は常に `--delete-branch` を付けます。
- `wt rm` を引数なしで実行すると、現在の repo の worktree 一覧を `fzf` で選択して削除できます。
- picker では現在いる worktree は候補から除外し、複数選択もできます。
- それ以外のサブコマンドは `wt list`, `wt cd`, `wt ai` のように `git gtr` へ透過的に委譲します。

よく使う例:

```bash
wt new
# => 例: task/worktree-20260329-143210

wt new codex trust
# => 例: task/codex-trust

wt new fix review -- --from-current -e
# => 例: fix/review
# => 現在のブランチから作成し、作成後に editor を開く

wt rm
# => fzf で削除対象を選ぶ

wt rm --yes
# => fzf で選んだ対象を確認なしで削除

wt list
wt cd
wt ai task/codex-trust
```

## home-manager の配線

```
~/.zshrc             → dotfiles/shell/.zshrc
~/.zprofile          → dotfiles/shell/.zprofile
~/.config/wezterm    → dotfiles/config/.config/wezterm
~/.config/ghostty    → dotfiles/config/.config/ghostty
~/.config/starship   → dotfiles/config/.config/starship
~/.config/mise       → dotfiles/config/.config/mise
~/.config/sheldon    → dotfiles/config/.config/sheldon
~/.config/karabiner  → dotfiles/config/.config/karabiner
~/.config/opencode/opencode.json → dotfiles/config/.config/opencode/opencode.json
~/.config/nvim       → dotfiles/config/.config/nvim
~/.config/git        → dotfiles/config/.config/git
~/.claude/CLAUDE.md   → dotfiles/claude/.claude/CLAUDE.md
~/.codex/AGENTS.md    → dotfiles/codex/.codex/AGENTS.md
~/.gemini/AGENTS.md  → dotfiles/gemini/.gemini/AGENTS.md
~/.takt/config.yaml   → dotfiles/takt/.takt/config.yaml
~/Dropbox/.../workflows/user.workflow.C9692AD7-... → dotfiles/alfred/Open-VS-or-IT
```

通常の設定は `mkOutOfStoreSymlink` で配線するため、repo 内の編集が即時反映される。
Claude Code と Antigravity CLI が置換書き込みする JSON だけは実ファイルとして生成し、
前回 switch 時の参照コピーとの差分を検知する。drift は次で回収する。

```bash
task adopt-settings TARGET=all
```

### Agent コンテキストファイルの一元管理

- CLAUDE.md / AGENTS.md の実体は `shared/agents/` に集約
  - `core.md`: 全エージェント共通ルール（唯一の編集対象）
  - `diff-claude.md` / `diff-codex.md` / `diff-gemini.md`: CLI 固有の差分
- Claude Code: `claude/.claude/CLAUDE.md` が `@import` で core + diff を参照（生成不要）
- Codex / Gemini: `task sync-agents` で core + diff を連結して各 AGENTS.md を生成
- リポジトリルートの `AGENTS.md` は当リポジトリ固有ルールのみ（`CLAUDE.md` は `@AGENTS.md` で橋渡し）
- core.md / diff-*.md を編集したら `task sync-agents` を実行すること

### Skills の一元管理

- スキル本体は `shared/skills/` に集約
- `claude/.claude/skills`、`codex/.codex/skills`、`gemini/.gemini/config/skills` は相対シンボリックリンクで参照
- Antigravity のグローバルスキルは `~/.gemini/config/skills/<skill-folder>/SKILL.md` として解決されます
- リンク更新は `task sync-skills` で実行

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

詳細は [alfred/README.md](alfred/README.md) を参照。

## Release 共通基盤

release 運用の共通資材は [`yoshihiko555/.github`](https://github.com/yoshihiko555/.github) で管理:

| 資材 | 配置先 | 役割 |
|------|--------|------|
| reusable workflow | `.github/workflows/release.yml` | tag push → GitHub Release 作成 |
| release タスク | `taskfiles/release.yml` | version bump, preflight, tag 作成・push |
| Rulesets JSON | `rulesets/` | branch / tag 保護の共通設定 |
| 運用ドキュメント | `docs/` | Git/release 方針、Rulesets 手順 |

各 repo は caller workflow と `CHANGELOG.md` を置き、Taskfile から `.github` repo の release タスクをローカル参照する。
