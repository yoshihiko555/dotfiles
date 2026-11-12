# Nix パッチ

このディレクトリの `*.patch` は上流未修正の問題に対する暫定修正。
上流で解決したら該当の override とパッチを取り除く。

---

## takt の daemon が symlink の config.yaml で起動しない問題

`takt-daemon-config-symlink.patch` は takt 0.75.0 向けの暫定修正。
`hosts/macbook/packages.nix` の `taktPackage` で `postInstall` から適用する。
ビルド済みの `dist/*.js` を対象にするため `patches =` ではなく `postInstall` で当てる。

### 症状

`takt manager` が `Daemon startup was not confirmed; see the global logs directory` で止まる。
`~/.takt/logs/daemon-start-*.log` には次のエラーが出る。

```
Error: ELOOP: too many symbolic links encountered, open '/Users/<user>/.takt/config.yaml'
    at async readPrivateFile (dist/infra/daemon/privateFile.js:26:18)
    at async readDaemonConfiguration (dist/features/daemon/configuration.js:13:19)
```

daemon は設定を `readPrivateFile`（`O_NOFOLLOW` で開く）で読む。
home-manager は `~/.takt/config.yaml` を symlink で配るため、開いた時点で `ELOOP` になる。
daemon 以外の経路（`takt run` 等）は symlink を辿って読むので影響しない。

### 修正内容

`readDaemonConfiguration` だけ、`realpath` で行き先を解決してから `readPrivateFile` に渡す。
`readPrivateFile` 自体は変えないので、IPC・lock 等の他のファイルは今までどおり symlink を開かない。

### 更新・撤回

`nxu takt` で takt を上げたら、`dist/features/daemon/configuration.js` が変わっていないかを確認する。
変わっていればパッチが当たらず、ビルドが落ちる。
上流で symlink を読めるようになったら、`packages.nix` の `taktPackage` とパッチを取り除く。
撤回後は `takt manager` を起動し、`~/.takt/logs/` に増えた `daemon-start-*.log` が空であることを確認する
（起動のたびに作られ、失敗時だけエラーが書かれる）。

---

## tmux の同期描画修正（2026-10-26 撤去）

`tmux-sync-clear.patch` は tmux 3.7c 向けの暫定修正だった。
takt / Ink が同期描画（DECSET 2026）の中で全画面消去を行うと、
tmux が本文の描画前に空画面を端末へ確定し、画面が点滅していた。

tmux 3.8 で、同期中は端末への描画を保留して同期終了時に再描画する処理が上流に入った
（`screen-write.c` の `screen_write_should_draw_lines`）。
nixpkgs の 3.8 更新に合わせて、パッチと `home/packages.nix` の override を取り除いた。

点滅が再発した場合の調査記録: https://app.notion.com/p/3d26d81aac5281028876f0d6de84e2fd

### tmux を更新・差し替えるとき

1. `task nix-fmt` で整形し、`nxbd` で MacBook のビルドと世代差分を確認する。
2. ビルドした tmux を別ソケットで起動し、takt の長い会話・推論・ツール実行と、
   日本語表示・スクロールを確認する。既存サーバーにテスト入力を送らない。
   エージェントによる検証は仮想端末内で行い、ユーザーのタブ・ウィンドウ・
   フォーカスを変更しない。表示の複製や確認用GUIタブも勝手に開かない。
3. 検証後に `nxs` でインストールする。
4. 既存セッションの作業終了後に、普段の tmux サーバーを新しい版で起動し直す。
   インストールや設定再読み込みだけでは、起動済みサーバーのコードは変わらない。
   作業中の既定サーバーに `kill-server` を実行しない。
   再起動後の `default` は通常の WezTerm 起動処理に作成させる。
   `tmux new-session -s default` だけで先に作ると baton が起動しない。
   WezTerm の `new-session -A` は既存セッションへ接続するだけなので、
   その状態で WezTerm を開き直しても baton は起動しない。
   空の `default` を作ってしまった場合は、そのシェルで `baton` を実行する。
