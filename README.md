# dotfiles

個人用の設定ファイル管理リポジトリ

## 構成

```
.dotfiles/
├── backup/                 # 生成物の退避
├── Brewfile                # Homebrew パッケージ定義
├── shell/                  # シェル設定（→ ~）
│   ├── .zshrc
│   └── .zprofile
│
├── config/                 # XDG_CONFIG_HOME 系（→ ~）
│   └── .config/
│       ├── wezterm/        # ターミナル
│       ├── starship/       # プロンプト
│       ├── mise/           # ランタイム管理
│       └── sheldon/        # zsh プラグイン
│
├── claude/                 # Claude CLI（→ ~）
│   └── .claude/
│       ├── CLAUDE.md
│       └── settings.json
│
├── codex/                  # Codex CLI（→ ~）
│   └── .codex/
│       ├── AGENTS.md
│       └── config.toml
│
├── shared/                 # 共通データ
│   └── skills/             # Codex/Claude 共通スキルの実体
│       ├── common/
│       ├── codex-only/
│       └── claude-only/
│
├── Makefile
├── Taskfile.yml
├── scripts/
└── README.md
```

## 必要なツール

- [GNU Stow](https://www.gnu.org/software/stow/) - シンボリックリンク管理
- [go-task](https://taskfile.dev/) - 日常タスク実行用
- Homebrew（任意） - 依存ツールの導入や Brewfile の適用に使用

```bash
# macOS
brew install stow
```

## セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 初回セットアップ（依存インストール + リンク）
make bootstrap

# 以降は task を使用
task --list
task link           # 全パッケージをリンク
task link-shell     # シェル設定のみ
task link-config    # .config 配下のみ
task link-claude    # Claude CLI のみ
task link-codex     # Codex CLI のみ
```

## Makefile コマンド（初回セットアップ用）

```bash
make bootstrap     # 依存ツールをインストールして全パッケージをリンク
make install-deps  # 依存ツール (stow, go-task) をインストール
make link          # 全パッケージをリンク
make help          # ヘルプ表示
```

## Taskfile コマンド（日常運用）

```bash
task --list        # タスク一覧
task link          # 全パッケージをリンク
task link-shell    # シェル設定のみ
task link-config   # .config 配下のみ
task link-claude   # Claude CLI のみ
task link-codex    # Codex CLI のみ
task unlink        # 全パッケージのリンクを解除
task restow        # 全パッケージを再リンク
task sync-skills   # shared/skills のリンクを更新
task status        # 現在のリンク状態を確認
task brew          # Homebrew パッケージを適用
task edit          # VS Code で開く
```

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
make link-config

# ホーム直下の設定を追加（新パッケージ）
mkdir -p git
mv ~/.gitconfig git/
stow -vt ~ git
# 必要なら Taskfile.yml に link-git を追加
```

## シンボリックリンクの仕組み

```
~/.zshrc           → .dotfiles/shell/.zshrc
~/.zprofile        → .dotfiles/shell/.zprofile
~/.config/wezterm  → .dotfiles/config/.config/wezterm
~/.config/starship → .dotfiles/config/.config/starship
~/.claude          → .dotfiles/claude/.claude
~/.codex           → .dotfiles/codex/.codex
```

ホームディレクトリの設定ファイルは、dotfiles ディレクトリへのリンクになります。
dotfiles 内のファイルを編集すると、実際の設定に反映されます。

### Skills の一元管理

- スキル本体は `shared/skills/` に集約
- `claude/.claude/skills` と `codex/.codex/skills` は相対シンボリックリンクで参照
- リンク更新は `task sync-skills` で実行
