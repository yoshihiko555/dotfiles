# Codex CLI の会社アカウント

Claude の `ccw` と同じく、`cxw` は会社用の `CODEX_HOME=~/.codex-work` で起動する。
個人用の `codex` / `cx` は `~/.codex` を使う。個人用の設定変更先は [Codex CLI の README](../codex/README.md) を参照。

```bash
task codex-work-init
source ~/.zsh/codex.zsh  # 新しいターミナルでは不要
cxw login              # ブラウザで会社アカウント・会社ワークスペースを選ぶ
cxw login status
cxw                    # 起動後の /status でもアカウントを確認
```

- `CODEX_HOME` は設定・認証・ログ・セッション・スキルの保存先を分ける
  （[公式仕様](https://learn.chatgpt.com/docs/config-file/environment-variables#core-locations)）。
- `~/.codex-work/config.toml` は `codex-work/config.toml` への symlink。
  個人用とは別の設定として dotfiles で継続管理する。CLI が書き戻す設定も Git の差分になる。
  home-manager で配線し、`task codex-work-init` でも同じリンクを作成できる。
  旧コピー方式の実ファイルがある場合は、内容を `codex-work/config.toml` に回収してから
  タスクを再実行する。内容が異なる既存ファイルは上書きしない。
  認証は ChatGPT ログインに限定し、認証ファイル・履歴は会社用ホームに保存する。
- `AGENTS.md` は共通ルールを共有する。スキルは `shared/skills/common/`、`codex-only/`、`work/` を
  個別にリンクする。`task codex-work-init` の再実行でリンクを同期し、既存の設定・認証・履歴は保持する。
- 個人用の MCP・plugin のログイン・hooks は自動コピーしない。必要な連携は会社用で設定する。
- `CODEX_WORK_HOME` で保存先を変更できる。初期化時と起動時に同じ値を指定する。
- 会社ワークスペースを固定したい場合は、会社用 `config.toml` のトップレベルに
  `forced_chatgpt_workspace_id = "会社ワークスペースの ID"` を追加する
  （[認証の公式仕様](https://learn.chatgpt.com/docs/auth#enforce-a-login-method-or-workspace)）。
- ブラウザが使えない場合は `cxw login --device-auth` を使う。組織側で許可されている必要がある。
- この切り替えは CLI 用。デスクトップアプリや `taktw` の Codex 認証は切り替えない。
