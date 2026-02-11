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
│       ├── opencode/       # OpenCode CLI
│       └── git/            # git 設定 (global ignore 等)
│
├── claude/                 # Claude CLI（→ ~）
│   └── .claude/
│       ├── CLAUDE.md
│       ├── settings.json
│       ├── agents/         # エージェント定義
│       ├── hooks/          # フック
│       ├── rules/          # ルール
│       ├── templates/      # テンプレート
│       └── skills/         # → shared/skills へのリンク
│
├── codex/                  # Codex CLI（→ ~）
│   └── .codex/
│       ├── AGENTS.md
│       ├── config.toml
│       ├── prompts/        # カスタムプロンプト
│       ├── skills/         # → shared/skills へのリンク
│       └── codex_message.sh
│
├── gemini/                 # Gemini CLI（→ ~）
│   └── .gemini/
│       └── settings.json
│
├── tmux/                   # tmux 設定（→ ~）
│   └── .tmux.conf
│
├── shared/                 # 共通データ
│   ├── commands/           # Claude/Codex 用コマンド定義
│   │   ├── common/
│   │   ├── claude-only/
│   │   └── codex-only/
│   ├── mcp.template.json   # MCP 設定テンプレート
│   ├── notify_message.sh   # 通知スクリプト
│   └── skills/             # Codex/Claude 共通スキルの実体
│       ├── common/         # 共通スキル
│       ├── claude-only/    # Claude 専用スキル
│       └── codex-only/     # Codex 専用スキル
│
├── alfred/                 # Alfred ワークフロー（→ ~/Dropbox/...へリンク）
│   └── Open-VS-or-IT/      # お気に入りフォルダを開くワークフロー
│
├── Makefile
├── Brewfile                # Homebrew パッケージ定義
├── Taskfile.yml            # エントリポイント（taskfiles/ を読み込む）
├── taskfiles/
│   ├── link.yml
│   ├── skills.yml
│   └── util.yml
├── scripts/
│   ├── install-brew.sh
│   └── clean-claude.sh
└── README.md
```

## 必要なツール

- [GNU Stow](https://www.gnu.org/software/stow/) - シンボリックリンク管理
- [go-task](https://taskfile.dev/) - 日常タスク実行用
- Homebrew（任意） - 依存ツールの導入や Brewfile の適用に使用

```bash
# macOS
brew install stow go-task
```

## セットアップ

```bash
# リポジトリをクローン（ghq 推奨）
ghq get https://github.com/yoshihiko555/dotfiles.git
cd ~/ghq/github.com/yoshihiko555/dotfiles

# 初回セットアップ（依存インストール + リンク）
make bootstrap

# 以降は task を使用
task --list
task link           # 全パッケージをリンク
task link-shell     # シェル設定のみ
task link-config    # .config 配下のみ
task link-claude    # Claude CLI のみ
task link-codex     # Codex CLI のみ
task link-tmux      # tmux のみ
task link-alfred    # Alfred ワークフローのみ
```

## Makefile コマンド（初回セットアップ用）

```bash
make bootstrap     # 依存ツールをインストールして全パッケージをリンク
make install-deps  # 依存ツール (stow, go-task) をインストール
make link          # shell/config/claude/codex/gemini/tmux をリンク
make help          # ヘルプ表示
```

- `make link` は `gemini` を含み、`alfred` は含みません。

## Taskfile コマンド（日常運用）

```bash
task --list        # タスク一覧
task link          # 全パッケージをリンク
task link-alfred   # Alfred ワークフローのみ
task link-shell    # シェル設定のみ
task link-config   # .config 配下のみ
task link-claude   # Claude CLI のみ
task link-codex    # Codex CLI のみ
task link-tmux     # tmux のみ
task unlink        # 全パッケージのリンクを解除
task restow        # 全パッケージを再リンク
task sync-skills   # shared/skills のリンクを更新
task status        # 現在のリンク状態を確認
task brew          # Homebrew パッケージを適用
task edit          # VS Code で開く
task mcp-init      # カレントディレクトリに .mcp.json をコピー
task mcp-show      # MCP テンプレートの内容を表示
task clean-claude-dry # Claude デバッグログ削除の dry-run
task clean-claude  # Claude デバッグログを削除
```

- `task link` は `alfred` を含み、`gemini` は含みません。

## Stow の使い方

### 基本コマンド

```bash
# リンク作成
stow -vt ~ <パッケージ名>

# リンク削除
stow -Dvt ~ <パッケージ名>

# ドライラン（実行せず確認のみ）
stow -nvt ~ <パッケージ名>

# 再リンク（削除して作成）
stow -Rvt ~ <パッケージ名>
```

### オプション

| オプション | 説明                                 |
| ---------- | ------------------------------------ |
| `-v`       | 詳細表示 (verbose)                   |
| `-t ~`     | ターゲットディレクトリをホームに指定 |
| `-n`       | ドライラン（シミュレーション）       |
| `-D`       | リンク削除 (delete)                  |
| `-R`       | 再リンク (restow)                    |

### パッケージ追加の例

```bash
# .config 系ツールを追加
mkdir -p config/.config/neovim
mv ~/.config/neovim config/.config/neovim/
task link-config

# ホーム直下の設定を追加（新パッケージ）
mkdir -p git
mv ~/.gitconfig git/
stow -vt ~ git
# 必要なら taskfiles/link.yml に link-*/unlink-* タスクを追加
```

## シンボリックリンクの仕組み

```
~/.zshrc             → dotfiles/shell/.zshrc
~/.zprofile          → dotfiles/shell/.zprofile
~/.config/wezterm    → dotfiles/config/.config/wezterm
~/.config/ghostty    → dotfiles/config/.config/ghostty
~/.config/starship   → dotfiles/config/.config/starship
~/.config/mise       → dotfiles/config/.config/mise
~/.config/sheldon    → dotfiles/config/.config/sheldon
~/.config/karabiner  → dotfiles/config/.config/karabiner
~/.config/opencode   → dotfiles/config/.config/opencode
~/.config/git        → dotfiles/config/.config/git
~/.claude            → dotfiles/claude/.claude
~/.codex             → dotfiles/codex/.codex
~/.gemini            → dotfiles/gemini/.gemini
~/.tmux.conf         → dotfiles/tmux/.tmux.conf
~/Dropbox/.../workflows/user.workflow.C9692AD7-... → dotfiles/alfred/Open-VS-or-IT
```

ホームディレクトリの設定ファイルは、dotfiles ディレクトリへのリンクになります。
dotfiles 内のファイルを編集すると、実際の設定に反映されます。

### Skills の一元管理

- スキル本体は `shared/skills/` に集約
- `claude/.claude/skills` と `codex/.codex/skills` は相対シンボリックリンクで参照
- リンク更新は `task sync-skills` で実行

## Alfred ワークフロー

専用 task でシンボリックリンクを作成して管理。

```bash
task link-alfred   # ワークフローをリンク
task unlink-alfred # リンク解除
```

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
