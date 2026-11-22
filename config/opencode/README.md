# OpenCode

## OpenCode から Pencil を使う

MacBook で Pen.app を開き、作業するリポジトリで `opencode` を起動する。Pencil の接続先や有効・無効を変えるときは、[opencode.json](opencode.json) の `mcp.pencil` を編集する。この設定では Pen.app 同梱の MCP サーバーを `--app desktop --agent openCodeCLI` で起動する。

Home Manager はこのファイルを `~/.config/opencode/opencode.json` にリンクする。リンクの作成後は dotfiles 側を編集すれば、次回の OpenCode 起動時に変更が読み込まれる。`task mcp-sync` は Claude Code と Codex 用の設定を同期する。[MacBook の配布設定](../nix/hosts/macbook/dotfiles.nix)・[共通 MCP の同期手順](../../shared/mcp/README.md)

## takt から OpenCode を使う

takt のステップを担当するモデルや MCP サーバーの割り当ては [takt/runtime.yaml](../../takt/runtime.yaml) で変更する。[プロバイダの割り当てと確認方法](../../takt/docs/providers.md)・[takt の権限と MCP](../../takt/docs/permissions-and-mcp.md)
