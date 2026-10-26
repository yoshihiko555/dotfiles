# Nix パッチ

このディレクトリの `*.patch` は上流未修正の問題に対する暫定修正。
上流で解決したら該当の override とパッチを取り除く。

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
