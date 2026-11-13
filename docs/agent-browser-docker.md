# agent-browser の Docker 実行

macOS の Codex サンドボックスから Chrome を起動すると、OS へのアプリ登録や
Mach ポートの権限制限で異常終了する場合がある。ブラウザは Docker 内で起動し、
ホストの agent-browser は CDP 接続だけを行う。

## 初回セットアップ

Docker を起動し、Python と agent-browser が利用できる状態で実行する。
Python は mise 管理のものを使う。Python パッケージの追加は不要。

```sh
docker pull mcr.microsoft.com/playwright:v1.52.0-noble
```

標準は既存環境で検証済みの `v1.52.0-noble`（Chromium 136）に固定している。
最新ブラウザの検証用ではないため、対象サイトが新しいブラウザを必要とする場合は更新する。
更新時は `scripts/agent-browser-docker.py` の `IMAGE` と
このコマンドを揃える。[Playwright 公式 Docker イメージ](https://playwright.dev/docs/docker)を
開発・テスト用に使用する。
別バージョンの検証では、コマンドより前に `--image <イメージ:タグ>` を指定できる。

## 操作

以下は dotfiles のルートでの例。他のプロジェクトではスクリプトの絶対パスを使う。
作業中は同じカレントディレクトリと `--session` を使う。

```sh
python3 scripts/agent-browser-docker.py --session ui-check open http://host.docker.internal:3000
python3 scripts/agent-browser-docker.py --session ui-check snapshot -i
python3 scripts/agent-browser-docker.py --session ui-check click @e1
python3 scripts/agent-browser-docker.py --session ui-check screenshot --full ./page.png
python3 scripts/agent-browser-docker.py --session ui-check close
```

- `open` はコンテナを必要に応じて起動する。`start` でブラウザだけ先に起動することもできる。
- `status` は状態を表示する。`close` はこの作業のブラウザとコンテナだけを終了する。
- 作業ディレクトリとセッション名ごとに、ブラウザ・Cookie・デーモンを分ける。
- CDP は毎回明示し、接続できない場合は停止する。Mac の Chrome は起動しない。
- CDP の公開先は `127.0.0.1` の自動割当ポート。ホストのファイルはマウントしない。
- `batch 'open <URL>' 'snapshot -i'` も使える。`batch` 内での `close` は禁止し、最後に単独で実行する。

## 接続とファイルの扱い

コンテナ内の `localhost` は Mac を指さない。Mac 上の開発サーバーは
`host.docker.internal` を使う。アプリの許可ホスト・CORS・OAuth リダイレクト先に
`localhost` が固定されている場合は、この接続先に対応する開発設定が必要になる。

スクリーンショットはホスト側に保存される。`file://` やブラウザ内でのダウンロード先は
コンテナ側になるため、ホストのファイルパスと同一視しない。

Codex がデーモン用ソケットへの書き込みを拒否した場合は、ラッパーの実行について
権限昇格を要求する。実行制限を解除するために Chrome の起動フラグを変えて再試行しない。

Docker 停止、イメージ未取得、CDP の接続失敗ではエラーで止まる。
起動途中の失敗では作成したコンテナを削除する。操作を中断した場合も、最後に `close` を実行する。

## 検証

```sh
python3 scripts/tests/test-agent-browser-docker.py
node --check scripts/agent-browser-docker-server.cjs
```

実機ではページ表示・フォーム操作・スクリーンショット・複数セッションの分離・
`close` 後のコンテナ削除を確認する。
