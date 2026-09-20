# claude-swap の管理

MacBook の CodexBar で、複数の Claude アカウントの利用状況を表示するために使う。
アカウントの自動切り替えや、claude-swap 独自のメニューバー常駐は有効にしない。

## 管理範囲

- パッケージ定義: [`../packages/claude-swap.nix`](../packages/claude-swap.nix)
- MacBook への導入: [`../hosts/macbook/packages.nix`](../hosts/macbook/packages.nix)
- 本体のバージョンとソースのハッシュはパッケージ定義で固定する。
- 実行用 Python と依存ライブラリは `flake.lock` の nixpkgs に固定する。
  `uv tool install` は使わず、mise の開発用 Python の更新・削除にも依存しない。
- アカウント登録、Keychain、トークン、利用状況キャッシュは実行時に管理する。
  Nix store や Git に認証情報を入れない。Nix のロールバックも認証状態は巻き戻さない。
- CodexBar を表示に使うため、追加依存の `menubar`（rumps）は導入しない。

## ビルドと導入

リポジトリのルートで実行する。

```sh
# 単体ビルド。上流のテストと Python の import 検査も実行する
nix build ./config/nix#claude-swap --no-link
nix run ./config/nix#claude-swap -- --version

# 通常の MacBook 構成に含めてビルド・差分確認
nxbd

# 差分確認後に反映
nxs
```

新規ファイルが Git の追跡対象になる前は、`./config/nix` の代わりに
`path:./config/nix` を指定すると、未追跡のパッケージ定義も含めて確認できる。

反映後の実行ファイルは `/etc/profiles/per-user/yoshihiko/bin/cswap`。
CodexBar に指定する場合もこのパスを使う。`/nix/store/<hash>-.../bin/cswap` は
更新で変わり、古い世代の GC 後に消えるため、アプリ設定に直接保存しない。

## CodexBar の初期設定

CodexBar 0.60.3 / claude-swap 0.26.0 を前提とする。

この dotfiles では通常用の `~/.claude` と仕事用の `~/.claude-work` を使う。
それぞれログイン済みなら、ログインを切り替えずに登録できる。
`add` は既存の認証情報を読み、公式 API で本人確認して、claude-swap 側へ保存する。

```sh
# 通常用。仕事用のシェルから実行しても通常用を参照する
env -u CLAUDE_CONFIG_DIR -u CLAUDE_SECURESTORAGE_CONFIG_DIR cswap add --alias personal

# claude-work（ccw）で使うログインを登録する
env -u CLAUDE_SECURESTORAGE_CONFIG_DIR CLAUDE_CONFIG_DIR="$HOME/.claude-work" cswap add --alias work

# CodexBar と同じ通常用の環境で、登録した両方のアカウントを確認する
env -u CLAUDE_CONFIG_DIR -u CLAUDE_SECURESTORAGE_CONFIG_DIR cswap list
```

まだログインしていない場合は、通常用は `claude`、仕事用は `ccw` からログインして
対応する登録コマンドを実行する。保存した認証を失効させないよう、登録の途中で
`/logout` は実行しない。

1. CodexBar の Settings → Providers → Claude で
   **Read accounts from claude-swap** を有効にし、上記の実行ファイルを指定する。
2. Settings → Menu → **Multi-account layout** を **Stacked** にして Refresh する。

表示だけなら `cswap auto` やアカウントの Switch 操作は不要。
macOS の Keychain 許可が出た場合は claude-swap によるアクセスを許可する。
CodexBar 自身の Keychain アクセス設定とは別に扱われる。

## 認証の更新

claude-swap は利用状況の取得時に、保存済みの refresh token を使って
期限切れの access token の更新を試みる。Nix が認証を更新するわけではない。
バックグラウンドで表示を更新するには、CodexBar が起動している必要がある。

refresh token 自体が失効・取り消された場合は、該当アカウントで Claude Code に
ログインし直し、上記の該当する `cswap add` コマンドで認証を保存し直す。
`cswap list` と CodexBar の Refresh で復旧を確認する。
複数アカウントの実際の自動更新は、各アカウントを登録した環境で別途確認する。

## 本体の更新

`cswap upgrade` や `uv tool upgrade claude-swap` は使わない。
本体の更新は `packages/claude-swap.nix` の `version` と `src.hash` を変更して行う。
`nix flake update` だけでは claude-swap 本体の固定バージョンは変わらない。

1. [公式リリース](https://github.com/realiti4/claude-swap/releases)を確認する。
2. 対象タグのソースのハッシュを取得して、バージョンと一緒に更新する。
   例: `nix store prefetch-file --json --unpack https://github.com/realiti4/claude-swap/archive/refs/tags/v0.26.0.tar.gz`
3. 上流の `pyproject.toml` の依存条件を確認する。特に 0.26.0 は
   `textual >= 8.2.8, < 9` のため、nixpkgs 更新時にも互換性を確認する。
4. `task nix-fmt`、単体ビルド、`nxbd` で検査してから `nxs` で反映する。

## 参照

- [claude-swap 0.26.0](https://github.com/realiti4/claude-swap/tree/v0.26.0)
- [CodexBar の Claude / claude-swap 連携](https://github.com/steipete/CodexBar/blob/v0.60.3/docs/claude.md)
