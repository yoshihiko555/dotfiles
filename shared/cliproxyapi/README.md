# CLIProxyAPI

MacBook で `ccx` を起動すると、個人用 Claude Code が `http://127.0.0.1:8317` の CLIProxyAPI に接続する。普段の設定・スキル・プラグインを使いながら、セッション内で Claude と Codex などのモデルを切り替えられる。

## 初回設定と認証

1. dotfiles のルートで `task cliproxy-setup` を実行する。必要に応じて Homebrew で CLIProxyAPI を導入し、`$(brew --prefix)/etc/cliproxyapi.conf` を生成してサービスを再起動する。`ccx` が接続に使うキーは初回に生成され、次回から引き継がれる。
2. Claude を使うには `cliproxyapi --claude-login`、Codex のモデルも使うには `cliproxyapi --codex-login` でログインする。OAuth の認証ファイルは端末の `~/.cli-proxy-api/` に保存される。
3. ログイン後に `brew services restart cliproxyapi` を実行し、`task cliproxy-status` でサービスの稼働状態・OAuth の期限・公開モデルを確認する。

## 日常の起動

| やりたいこと | 操作 |
|---|---|
| プロキシ経由で対話する | 作業するリポジトリで `ccx` を起動する。 |
| モデルを切り替える | セッション内の `/model` で選ぶ。例として `/model gpt-6.1-sol-claude` は Codex に切り替える。候補は `task cliproxy-status` の公開モデル欄で確認できる。 |
| サブエージェントに作業を委譲する | `ccx -f` で起動する。委譲先のモデルがプロキシにない場合は、`ccf` と同じ委譲先モデルを使う。 |

`/model` で選んだモデルは、普段の `cc` と共有する `~/.claude/settings.json` に保存される。プロキシ専用のモデルを選んだ日は、終了前に `/model` で通常の Claude モデルに戻す。起動時だけ指定したいときは `ccx --model <モデルID>` を使う。[ccx の実装](../../shell/zsh/claude.zsh)

## 設定の編集と反映

| 変えたいもの | 編集先 |
|---|---|
| OAuth 経由で公開するモデルの別名・除外設定、プロキシの基本設定 | [conf.tmpl](conf.tmpl) |
| 汎用 OpenAI 互換プロバイダのモデルと別名 | [openai-compat.tmpl](openai-compat.tmpl) |
| OpenCode Go のモデルと別名 | [opencode-go.tmpl](opencode-go.tmpl) |

外部プロバイダを使う場合だけ、[secrets.env.example](secrets.env.example) を雛形に端末の `${XDG_CONFIG_HOME:-$HOME/.config}/cliproxyapi/secrets.env` を用意し、権限を `600` にする。汎用プロバイダには `OPENAI_COMPAT_NAME`・`OPENAI_COMPAT_BASE_URL`・`OPENAI_COMPAT_API_KEY` の3つ、OpenCode Go には `OPENCODE_GO_API_KEY` を設定する。

テンプレートや端末の `secrets.env` を変えたら、`task cliproxy-setup` で設定を再生成し、サービスを再起動する。生成先を直接編集した内容は次の反映で上書きされる。状態を確認するだけなら `task cliproxy-status` を使う。[タスク定義](../../taskfiles/cliproxy.yml)

## 接続できないとき

`task cliproxy-status` でサービス、OAuth の期限、公開モデルの順に見る。サービスが停止していれば `brew services start cliproxyapi`、稼働中でも `503 auth_unavailable` で認証が失効していれば、該当のログインをやり直して再起動する。再ログイン後も古い認証ファイルが残る場合は、`task cliproxy-auth-prune` で削除候補を確認できる（既定は確認のみ）。
