# dotfiles

個人用の設定ファイル管理リポジトリ

## 構成

```
.dotfiles/
├── README.md
├── config/
│   └── .config/
│       └── mise/           # mise (ランタイムバージョン管理)
│           └── config.toml
└── zsh/
    ├── .zshrc              # zsh設定
    └── .zprofile           # ログインシェル設定
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
stow -vt ~ config zsh

# 個別にリンクする場合
stow -vt ~ zsh      # zsh設定のみ
stow -vt ~ config   # .config配下のみ
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

新しい設定を追加する場合：

```bash
# 例: starship の設定を追加
mkdir -p config/.config/starship
mv ~/.config/starship/starship.toml config/.config/starship/
stow -vt ~ config
```

## シンボリックリンクの仕組み

```
~/.zshrc        → .dotfiles/zsh/.zshrc
~/.zprofile     → .dotfiles/zsh/.zprofile
~/.config/mise  → .dotfiles/config/.config/mise
```

ホームディレクトリの設定ファイルは、dotfilesディレクトリへのリンクになっています。
dotfiles内のファイルを編集すると、実際の設定に反映されます。
