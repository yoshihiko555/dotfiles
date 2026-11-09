# Hermes dashboard の常駐運用

Mac mini の dashboard と MBP の SSH トンネルを、各ユーザーの GUI ログイン後に launchd で起動する。
MBP のブラウザで `http://127.0.0.1:13000` を直接開く。

```text
MBP ブラウザ → 127.0.0.1:13000 → SSH → mini 127.0.0.1:9119
```

## 管理対象

| ホスト | ユーザー | launchd label | 定義 |
| --- | --- | --- | --- |
| mini | agent | com.hermes.dashboard | hosts/hermes/hermes-agent.nix |
| MBP | yoshihiko | com.hermes.dashboard-tunnel | hosts/macbook/hermes-dashboard.nix |

plist は各ユーザーの `~/Library/LaunchAgents/<label>.plist`。
通常は Nix / Home Manager で反映する。既存世代と flake.lock に差がある場合は、全体反映による他サービスの更新を確認する。
生成済みの追加 plist だけを個別登録した場合は、Nix store の依存が GC されないよう、その出力を `nix-store --realise <drv> --add-root <永続パス> --indirect` で保持する。

## 起動とログ

mini は現行 launcher に `dashboard --host 127.0.0.1 --port 9119 --no-open --skip-build` を渡す。
`HERMES_DISABLE_LAZY_INSTALLS=1` で起動時の依存追加を抑える。画面のビルド済みファイルと依存パッケージが前提。
Hermes 更新後はビルドの完了と dashboard の再起動を確認する。`--skip-build` は古い画面の鮮度を保証しない。

- mini: `~/.hermes/logs/gui.log`。Hermes 本体が 10 MiB、バックアップ 5 世代でローテーションする。
- MBP: `~/Library/Logs/hermes-dashboard-tunnel.log` と `.previous`。接続開始ごとに入れ替えて直近 2 回分を保持する。SSH の連続診断出力は `-q` で抑える。
- 起動直後に終了して gui.log へ出ない場合は、`launchctl print` の終了コードを確認し、サービスを解除して上記 launcher をターミナルで直接実行する。

MBP は GUI 環境の `SSH_AUTH_SOCK` を使う。鍵が未ロードなら既存 Keychain から読み込むだけで、パスフレーズを保存・変更しない。
`macmini-agent` に明示的な localhost 転送を追加し、手動接続用の `macmini-hermes` とは共用しない。
同じ 13000 番を使う手動トンネルとは同時起動できない。

## 日常の確認

MBP:

```sh
curl --fail --silent http://127.0.0.1:13000/api/status
launchctl print gui/$(id -u)/com.hermes.dashboard-tunnel
```

mini（`ssh macmini-agent` で接続して実行）:

```sh
launchctl print gui/$(id -u)/com.hermes.dashboard
curl --fail --silent http://127.0.0.1:9119/api/status
```

トンネルの稼働と dashboard の正常応答は別に確認する。SSH の `ExitOnForwardFailure` は転送先アプリの稼働までは検知しない。

## 停止・再開

両サービスとも KeepAlive を使うため、PID の kill や `hermes dashboard --stop` だけでは復活する。
各ホストの該当ユーザーで `<label>` を上表の値に置き換える。

```sh
# 現在のログイン中だけ解除。次回ログインでは再起動する。
launchctl bootout gui/$(id -u)/<label>
# 同じログイン中に再開
launchctl bootstrap gui/$(id -u) ~/Library/LaunchAgents/<label>.plist
```

恒久的に無効化する場合は Nix の定義を無効化して反映する。
個別登録段階なら bootout の後、その追加 plist と専用の GC root を除去する。

## 復帰の範囲

- MBP のスリープ中は接続を維持できない。復帰後に古い接続の切断を検知して再接続する。
- SSH は 30 秒間隔、3 回の無応答で切断を検知する設定。launchd の再起動抑制は 60 秒。復帰が即時とは限らない。
- 家庭内 LAN の `192.168.1.100` が到達先。外出先利用には別途 VPN 等が必要。
- mini は FileVault の解除と agent の GUI ログインが必要。常駐化だけでは電源投入からの完全無人復帰にはならない。
- 再ログイン・実スリープ・再起動後の確認は、作業を中断してよいタイミングで実施する。

## 既知の profile 警告

default / intelligence / back-office の Discord 認証情報の共有について dashboard が警告する。
現在は default が Discord を担当し、他 profile は runner でジョブを実行する構成。
これは dashboard 常駐化のための移行要件ではない。警告だけを理由にトークンを変更したり `gateway migrate --multiplex` を実行しない。
