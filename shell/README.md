# zsh の起動設定

ホームに配置する zsh 設定は [home-manager の共通設定](../config/nix/home/dotfiles.nix) でこのディレクトリにリンクしている。
`wt`、`repo`、`cxw` などの使い方は [自作コマンド一覧](zsh/README.md) を参照。手元では `~/.zsh/README.md` で読める。

## 起動時に読むファイル

対話型のログインシェルでは、次の 3 ファイルを上から順に読む。

| ファイル | 読む条件 | 主な設定 |
|---|---|---|
| [.zshenv](zshenv) | すべての zsh | `DOTFILES`、Homebrew と `~/.local/bin` の PATH、mise の初期化 |
| [.zprofile](zprofile) | ログイン時 | Nix デーモンと OrbStack の初期化ファイルがあれば読み込む |
| [.zshrc](zshrc) | 対話時 | 履歴とキー割り当て、ツールの初期化、`~/.zsh/` の関数とエイリアス。共通の関数を定義した後で、端末固有の `~/.zshrc.local` があれば読む |

補完・略語・自動提案の読み込み順は [sheldon の設定](../config/sheldon/plugins.toml)、プロンプトの表示項目と配色は [starship の設定](../config/starship/starship.toml) で管理する。

## 設計の経緯

- 対話シェルを `/bin/zsh` に揃え、初期化結果のキャッシュと補完の遅延読み込みで起動時間を短縮した。[起動時間の計測と採用理由](../docs/adr/ADR-20260928-0006-zsh-startup-tuning.md)
- 普段使うリポジトリでの描画は約 30ms だったため、Git の状態とランタイムのバージョンを表示する starship の同期描画を継続した。[プロンプトの計測と採用理由](../docs/adr/ADR-20261121-0011-zsh-prompt-stay-sync.md)
