# dotfiles

個人用の設定ファイル管理リポジトリ

## 構成

```
.dotfiles/
├── README.md
└── zsh/
    ├── .zshrc      # zsh設定
    └── .zprofile   # ログインシェル設定
```

## セットアップ

```bash
# リポジトリをクローン
git clone https://github.com/YOUR_USERNAME/dotfiles.git ~/.dotfiles

# シンボリックリンクを作成
ln -s ~/.dotfiles/zsh/.zshrc ~/.zshrc
ln -s ~/.dotfiles/zsh/.zprofile ~/.zprofile
```

## シンボリックリンクの仕組み

```
~/.zshrc → ~/.dotfiles/zsh/.zshrc
~/.zprofile → ~/.dotfiles/zsh/.zprofile
```

ホームディレクトリの設定ファイルは、dotfilesディレクトリへのリンクになっています。
dotfiles内のファイルを編集すると、実際の設定に反映されます。
