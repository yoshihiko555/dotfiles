# dotfiles

個人用の設定ファイル管理リポジトリ

## 構成

```
.dotfiles/
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
└── README.md
```

## 必要なツール

- [GNU Stow](https://www.gnu.org/software/stow/) - シンボリックリンク管理

```bash
# macOS
brew install stow
```

## セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles
cd ~/.dotfiles

# 全パッケージをリンク
make

# 個別にリンクする場合
make link-shell     # シェル設定のみ
make link-config    # .config 配下のみ
make link-claude    # Claude CLI のみ
make link-codex     # Codex CLI のみ
```

## Makefile コマンド

```bash
make              # 全パッケージをリンク
make link         # 全パッケージをリンク
make link-<pkg>   # 特定パッケージをリンク
make unlink       # 全パッケージのリンクを解除
make unlink-<pkg> # 特定パッケージのリンクを解除
make help         # ヘルプ表示
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
make link-git  # ※ Makefile に git を追加する必要あり
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
