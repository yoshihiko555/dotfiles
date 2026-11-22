# Claude Code の会社アカウント

`ccw` は `CLAUDE_CONFIG_DIR=~/.claude-work` で Claude Code を起動する。会社用の認証情報・履歴・プラグインの状態はこのディレクトリで管理し、Git の管理対象から外している。個人用の起動方法は [Claude Code の README](../claude/README.md) を参照。

## MacBook での初期設定

1. MacBook の Nix 設定を `nxs` で反映する。Home Manager が会社用の `CLAUDE.md` と `rules/` をリンクし、`settings.json` を Claude Code が書き換えられる実ファイルとして配布する。`hooks/`、`statusline.py`、`claude_message.sh`、`themes/` のリンク先は個人用と共通。[MacBook の設定](../config/nix/hosts/macbook/dotfiles.nix)
2. dotfiles のルートで `task claude-work-init` を実行する。会社用ディレクトリと `skills/` を用意し、`shared/skills/common/` の共通スキルと `shared/skills/work/` の会社用スキルをリンクする。後からスキルを追加・削除したときは `task sync-claude-work-skills` で同期する。[初期化・同期タスク](../taskfiles/skills.yml)
3. 新しい対話 zsh で `ccw` を起動し、会社アカウントでログインする。[起動関数](../shell/zsh/claude.zsh)

## 設定差分の確認と回収

- 端末で設定を変えたら、dotfiles のルートで `task status` を実行する。`Claude work settings` は端末の実ファイルと前回反映時の参照コピーを比較する。[状態確認タスク](../taskfiles/util.yml)
- リポジトリに残す変更があれば、`task adopt-settings TARGET=claude-work` で回収し、`git diff -- claude-work/settings.json` で内容を確認する。逆にリポジトリ側を編集したときは、`task apply-settings TARGET=claude-work` または `nxs` で反映する。[回収処理](../scripts/adopt-managed-settings.sh)・[反映処理](../scripts/apply-managed-settings.sh)

`autoMode` と `modelSettings` は端末で自動生成される。回収時は両方を除外し、反映時は端末の値を引き継ぐ。`autoMode` には社内情報が含まれる場合がある。`task status` の比較が除外するのは `autoMode` だけなので、`modelSettings` だけの変化でも差分が表示されることがある。

## 会社用 hooks の確認状況

2026-11-21 に `ccw` で `statusLine` の動作を確認した。会社用 hooks の実行は未確認。以前は会社から `allowManagedHooksOnly: true` が配信され、hooks と `statusLine`、`fileSuggestion`、`subagentStatusLine` が管理設定のものに制限されていた。[hooks の公式資料](https://code.claude.com/docs/en/hooks)

会社用で設定差分を把握する手段は、`task status` と `switch` 時の警告の2つ。個人用では Stop hook でも差分を通知する。
