# herdr

MacBook では Ghostty の最初のウィンドウを開くと、ログインシェル経由で `herdr` が起動する。herdr 内で **`Ctrl+Q` を押してから `i`** を押すと操作表が開く。先頭の herdr の項目は、開くたびに [config.toml](config.toml) のキー設定と直前の説明コメントから生成される。[Ghostty の起動設定](../ghostty/config)・[操作表の生成スクリプト](bin/herdr-cheatsheet)

## 設定の編集先

| 変えたいもの | 編集先 |
|---|---|
| プレフィックス、キー割り当て、サイドバー、通知音の指定 | [config.toml](config.toml)。キーの説明を変えるときは割り当ての直前のコメントを編集する。 |
| ワークスペース選択やペイン移動など、キーから呼ぶ処理 | [bin/](bin/) の各スクリプト。Ghostty 側のキー割り当ては [herdr.conf](../ghostty/herdr.conf)。 |
| タブ名の自動変更 | [automatic-rename/config.sh](automatic-rename/config.sh)。コマンド実行時にタブ名を更新するフックは [herdr.zsh](../../shell/zsh/herdr.zsh) が読み込む。 |
| デスクトップ通知と通知音 | バナーは [terminal-notifier/config.env](terminal-notifier/config.env) で設定する。完了・承認待ちの音は herdr 本体が [sounds/](sounds/) の MP3 を鳴らす。 |

MacBook の Home Manager が `~/.config/herdr/` に `config.toml`、`bin/`、`sounds/` を個別にリンクする。プラグインの設定も、それぞれの読み込み先にリンクする。[MacBook の配布設定](../nix/hosts/macbook/dotfiles.nix)

## プラグインの更新と反映

1. [plugins.txt](plugins.txt) で、更新するプラグインのコミット SHA（40桁）を書き換える。
2. dotfiles のルートで `bash scripts/herdr-plugins-sync.sh check` を実行し、導入済みの版との差分を確認する。
3. MacBook で `nxs` を実行する。登録済みの版が異なる場合や未導入の場合に、Home Manager が指定の SHA を導入する。最後に同じ `check` で差分が解消したことを確認する。

同期が扱うのは追加と更新。プラグインを外すときは `herdr plugin uninstall <id>` を実行してから一覧の該当行を消す。[同期スクリプト](../../scripts/herdr-plugins-sync.sh)

## 設計の経緯

- [常用のターミナルマルチプレクサに herdr を採用した理由](../../docs/adr/ADR-20260922-0001-herdr-migration-trial.md)
- [エージェントの完了・承認待ち通知を herdr にまとめた理由](../../docs/adr/ADR-20260924-0003-agent-notifications-to-herdr.md)
