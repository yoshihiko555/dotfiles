# Go のデバッグ

Leader は `Space`。共通操作は `lua/plugins/dap.lua`、Go の構成は `dap-go.lua`。
Go のファイルを開くと Delve 用の構成が登録される。Delve が未導入でも通常編集はでき、
デバッグ開始時に Nix の適用を案内する。

## 導入と反映

- Neovim のプラグイン: nvim-dap / nvim-dap-ui / nvim-nio / nvim-dap-go。
  解決したコミットは `config/nvim/lazy-lock.json` に固定する。
- デバッガーの実行ファイル: Nix の `delve`。今回の利用ホストである
  `config/nix/hosts/macbook/packages.nix` に置く。Go ランタイムは引き続き mise。
- Mason / Homebrew / `go install` では Delve を追加しない。2 台以上で使い始めたときに
  Nix の共通層へ移す。

MacBook でパッケージを適用する手順（dotfiles のルートから実行）:

```sh
task nix-fmt
task nix-check
nix build ./config/nix#darwinConfigurations.macbook.system --no-link --option builders ''
sudo darwin-rebuild switch --flake ./config/nix#macbook --option builders ''
```

`--option builders ''` は手元だけでビルドする指定。
適用後、新しいシェルで `command -v dlv` と `dlv version` を確認し、Neovim を再起動する。
プラグインがまだ入っていなければ、必要な 4 件だけをインストールする:

```vim
:Lazy install nvim-dap nvim-dap-ui nvim-nio nvim-dap-go
```

インストール後も Neovim を再起動する。
`Lazy sync` は update / clean も行うので、この導入には使わない。
操作の範囲は [lazy.nvim の公式一覧](https://lazy.folke.io/usage) を参照。

Neovim 内で利用する実体も確認する:

```vim
:lua print(vim.fn.exepath('dlv'))
:lua print(vim.fn.system({'dlv', 'version'}))
:lua print(vim.fn.exepath('go'))
:lua print(vim.fn.system({'go', 'version'}))
```

`dlv` が Nix の profile または `/nix/store/...-delve-.../bin/dlv` に解決されること。
Mason の `bin` 等が先に見つかる場合は二重管理を解消する。
プロジェクトごとの mise 設定や `go.mod` の toolchain により、使われる Go は変わりうる。
プロジェクトのルートで Neovim を起動し、その中でもバージョンを確認する。

Lua は `mkOutOfStoreSymlink` 経由で repo を参照しているため、Lua の変更だけなら
Nix switch は不要。再起動で読み直す。Nix の世代ロールバックでは Lua の内容は戻らない。

## 最初の実行

1. `go.mod` のあるルートで `nvim main.go` を起動する。
2. 止めたい**実行行**へ移動し、`Space → d → b`。ガターに `B` が付く。
3. `Space → d → c` → `Debug Package` を選ぶ。現在のファイルを含むパッケージを起動する。
   `Debug` は現在のファイルを対象とするので、複数ファイル構成では `Debug Package` を使う。
4. 停止すると現在行に矢印が付き、UI が開く。停止行の文はまだ実行されていない。
5. `do` で次へ、`di` で呼び出した関数へ、`dO` で呼び出し元へ戻る（すべて先頭に Space）。
6. `dc` で続行、`dq` で終了。通常終了でも UI は自動で閉じる。

引数が必要なら `Debug (Arguments)`、ビルドタグ等も必要なら
`Debug (Arguments & Build Flags)` を選ぶ。
接続に失敗して UI が残った場合も `du` で切り替え、`dq` で終了して再実行できる。

## 変数・呼び出し履歴・出力

| 表示 / キー | 使い方 |
|-------------|--------|
| Scopes（左上） | ローカル変数・引数。構造体等は `Enter` で展開 |
| Stacks（左側） | goroutine と呼び出し履歴。`Enter` で展開し、フレーム上の `o` で移動 |
| Watches（左下） | Insert に入り式を入力して Enter。停止ごとに値を確認 |
| Breakpoints（左側） | 停止位置の一覧。`o` で移動、`t` で有効・無効を切り替え |
| `<leader>de` | 停止中、単語または Visual 選択した式の値をフロートで確認 |
| `<leader>dr` | DAP REPL を開閉。Insert で式を入力して Enter。`.help` で操作一覧 |
| `<leader>du` | UI 全体を開閉。終了後の出力を見直すときにも使う |

Go の既定構成は `outputMode = "remote"` なので、プログラムの標準出力・標準エラーと
テストの結果は **DAP REPL（下部左）** に出る。右側の Console は integrated terminal 用。
終了時に UI が閉じたら `du` / `dr` で再表示する。次の実行で出力は更新される。
UI の操作は [dap-ui 公式 README](https://github.com/rcarriga/nvim-dap-ui) にもある。

ウィンドウ移動は既存の `Alt+h/j/k/l` または `Ctrl+w` 系を使う。
Visual 選択から `de` で評価した後は、`Esc` で Normal に戻ってからステップ操作を行う。
既存の LSP・バッファ操作は変更していない。キーマップ一覧は
[custom-keybinds.md](custom-keybinds.md#デバッグ-leaderd) を参照。

## Go のテスト

`go.mod` のあるルートを `:pwd` で確認し、対象パッケージの `*_test.go` を開く。

| 操作 | 対象 / 結果の確認 |
|------|------------------|
| `<leader>dc` → `Debug test (go.mod)` | 現在ファイルのディレクトリにあるパッケージ全体。`./...` 全体ではない |
| テスト関数内で `<leader>dt` | Treesitter で検出した付近のテストだけ。Go parser が必要 |
| `<leader>dT` | この Neovim で最後に `dt` で実行したテスト。Go バッファなら別ファイルからも使える |

テストの実行行にも `db` でブレークポイントを置く。
`dt` / `dT` は `-test.v` を付けるため、成功した `t.Log`、`PASS` / `FAIL` も REPL に表示する。
組み込みのパッケージテスト構成は verbose ではなく、成功時の `t.Log` は出ない。
成功時のログも必要なら `dt` を使うか、プロジェクトの launch.json のテスト構成に
`"args": ["-test.v"]` を指定する。失敗時はパッケージ構成でもログと失敗位置が出る。
`dT` は Neovim を終了すると忘れる。パッケージ構成の実行は `dT` の履歴を更新しない。

## 外部依存のない練習用サンプル

下記は一時ディレクトリだけに作る。`TestFailure` は失敗ログを見るために意図的に失敗する。

```sh
debug_dir=$(mktemp -d /tmp/nvim-dap-go.XXXXXX)
cd -P "$debug_dir"
go mod init example.com/dap-sample
cat > main.go <<'EOF'
package main

import "fmt"

func add(a, b int) int {
	total := a + b
	total++
	return total
}

func main() {
	value := 2
	value = add(value, 3)
	fmt.Println(value)
}
EOF
cat > main_test.go <<'EOF'
package main

import "testing"

func TestAdd(t *testing.T) {
	got := add(2, 3)
	t.Logf("got=%d", got)
	if got != 6 {
		t.Fatalf("got %d, want 6", got)
	}
}

func TestFailure(t *testing.T) {
	t.Log("失敗ログの確認")
	t.Fatal("意図した失敗")
}
EOF
nvim main.go
```

確認する順番:

1. `value = add(value, 3)` で `db` → `dc` → `Debug Package`。
   `value` が `2`、Stacks に `main.main` が見える。
2. `di` で `add` へ入り、`do` で `total` の `5 → 6` を確認。
   `dO` で戻り、`do` で `value = 6` を確認する。
3. `value` 上の `de`、Visual で式を選択して `de`、REPL で `value` の評価を試す。
4. `du` を 2 回押して UI 開閉、`dc` で完走。終了後 `dr` で出力 `6` を確認する。
5. `main_test.go` の `t.Logf` に `db`。`dc` → `Debug test (go.mod)` で停止し、
   `got = 6` を確認して続行。`TestFailure` のログと `FAIL` を REPL で確認する。
6. `TestAdd` の中で `dt`。同じ場所で停止・続行し、`got=6` と `PASS` を確認する。
7. `main.go` に戻り `dT` で再停止。`dq` で終了し、通常編集に戻れるか確認する。
8. 新しい Neovim で 1 と 6 を再実行する。`Space → d` を待つと日本語のキー案内が出る。

## プロジェクト設定との境界

dotfiles には共通操作と nvim-dap-go の汎用構成を置く。
接続先・ポート・コンテナ側のパス・`substitutePath` はプロジェクトが持つ。

採用版の nvim-dap は、**新規セッションの選択時**に
`<現在の作業ディレクトリ>/.vscode/launch.json` を標準 provider で読み込む。
親ディレクトリの探索ではないため、`cd <project>` → `nvim`、または `:cd <project>` を使う。
ファイルを保存して `dc` で構成を選ぶだけでよく、`load_launchjs()` を呼ぶ独自ローダーは不要。
実行中の `dc` は続行なので、構成を選び直すなら `dq` で終えてから `dc` を使う。
仕様は [nvim-dap の dap-launch.json](https://github.com/mfussenegger/nvim-dap/blob/master/doc/dap.txt) と
[nvim-dap-go の説明](https://github.com/leoluz/nvim-dap-go#vscode-launch-config) を参照。

最小のプロジェクト設定例（`.vscode/launch.json`）:

```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": "Go: パッケージのテスト（ログ付き）",
      "type": "go",
      "request": "launch",
      "mode": "test",
      "program": "${fileDirname}",
      "args": ["-test.v"]
    }
  ]
}
```

末尾カンマのない標準 JSON で書く。VS Code のすべての機能が動くわけではない。
Learno の Docker 接続は別タスクで、Delve の起動方式と接続方法、ソースパス対応を検証する。

## トラブルシュート

- **Delve が見つからない**: Nix switch、シェルの PATH、Neovim 内の `exepath('dlv')` を確認。
  一時的な確認なら、同じ固定版を `nix shell` で使える（恒久適用ではない）:
  `nix shell ./config/nix#darwinConfigurations.macbook.pkgs.delve --command nvim`。
  Neovim 起動後に対象プロジェクトへ `:cd` して Go ファイルを開く。
- **Go と Delve の非互換**: プロジェクト内の `go version` と `dlv version` を確認。
  互換性チェックを無効にせず、プロジェクトの Go toolchain または Delve の対象版を見直す。
  無関係な flake 入力は一括更新しない。
- **macOS で debugserver の起動後に止まる**: 開発ツールの認証ダイアログを確認する。
  `/usr/sbin/DevToolsSecurity -status` で状態を調べる。設定変更や認証は手元で行い、
  無効という表示だけで原因を断定しない。DAP のログと OS のエラーを合わせて確認する。
  今回は認証前の待機中に `dq` で Neovim へ戻れたが、Delve と debugserver が残った。
  同じ症状ならプロセス一覧で対象を特定して終了する。別のデバッグセッションを一括終了しない。
  手元で Developer Tools Access を認証した後は、起動・実停止・終了が成功した。
  Developer mode は無効のままで動作しており、恒久的な権限設定の変更は行っていない。
- **構成が出ない**: Go ファイルを開き、`:set filetype?` と `:pwd` を確認。
  `:lua print(vim.inspect(require('dap').configurations.go))` で汎用構成を確認できる。
- **outside main module**: 作業ディレクトリとファイルの実体が同じモジュール内か確認。
  macOS の `/tmp` は `/private/tmp` へのリンクなので、一時サンプルへは `cd -P` で移動してから起動する。
- **付近のテストが見つからない**: `*_test.go` のテスト関数内へ移動。
  `:TSInstall go` で parser を用意する。Go 以外のバッファには `dt` / `dT` を割り当てない。
- **ブレークポイントが止まらない**: 宣言・空行でなく実行行に置き、ファイルを保存。
  `B` は設定、`R` は adapter が受理していない印。違うパッケージを起動していないか確認する。
- **起動・接続失敗 / UI が残る**: `dq` → 必要なら `du`。REPL と `:messages` を確認。
  `:lua require('dap').set_log_level('TRACE')` 後に再現し、`:DapShowLog` を開く。
  調査後は `:lua require('dap').set_log_level('INFO')` に戻す。
  ログには対象プログラムの値やパスが含まれるため、共有前に内容を確認する。

## 検証記録（2026-09-20、MacBook Pro）

| 対象 | 版 / 状態 |
|------|-----------|
| Neovim | 0.12.5（nvim-dap の対応対象は 0.12.x / 0.11.7） |
| Go | mise の go1.26.1、darwin/arm64 |
| Delve | Nix の 1.27.1、Go 1.26.7 でビルドされたバイナリ |
| nvim-dap | `cfa2d58f4537` |
| nvim-dap-ui | `cc9dd33aade7` |
| nvim-nio | `edcc181a8753` |
| nvim-dap-go | `b4421153ead5`（Neovim >= 0.9 / Delve >= 1.7 / Go parser が必要） |

Delve 1.27.1 の [互換性判定](https://github.com/go-delve/delve/blob/v1.27.1/pkg/goversion/compat.go)
は Go 1.25〜1.27 を対応範囲とする。Go 1.26.1 は範囲内で、チェック無効化はしていない。
dap-ui / nio の README に独立した最小 Neovim 版の指定はなく、上記の組み合わせで読み込みを検証した。

- **構文・読込確認済み**: 変更 Lua、通常起動、DAP/UI 読込、Go 初回ロード順、Go バッファ限定キー、
  Delve 未導入時の案内、条件付きブレークポイントと入力キャンセル、標準 launch.json provider。
- **実端末で確認済み**: 独立した tmux の Neovim で which-key の日本語案内、UI の表示・手動切り替え、
  起動待ちから `dq` でセッションを閉じること、通常編集と次の起動要求までの復帰。
  認証後、新規 Neovim の `db` → `dc` → `Debug Package` で実停止し、Scopes の `value = 2` と
  Stacks の `main.main` / `main.add` を表示。Normal の `de`、Visual 選択した `a + b` の `de`、
  `dr` による REPL 開閉と式の結果 `5`、完走時の UI 自動クローズ、通常編集への復帰を確認した。
- **実セッションを headless で確認済み**: Go サンプルを実際に Delve で起動し、
  `main.go:13` のブレークポイントに停止。変数・スタックの DAP 応答を取得した。
  `di` で `main.add`、`do` で `total: 5 → 6`、`dO` で呼び出し元に戻り、`value = 6` と出力 `6` を確認。
  UI 自動開閉・手動切り替え、継続実行・手動終了も確認した。単なるプラグイン読込検証とは区別する。
- **DAP テスト確認済み**: `Debug test (go.mod)`、`dt`、別の Go ファイルからの `dT` が
  すべて `main_test.go:7` で停止。パッケージテストの意図した失敗ログ・`FAIL`、
  付近のテストの `got=6`・`PASS` を DAP 出力で確認した。
  終了後に `dr` で開き直した Neovim の REPL バッファでも、成功・失敗・ログを確認した。
  新規 Neovim で最初に `db` → `dt` を使う場合も、実停止と `dq` による終了を確認した。
- **サンプル単体の確認済み**: CLI の `go test -run '^TestAdd$' -v` は成功。
  `go test -v` は意図どおり `TestFailure` だけが失敗し、ログが出た。DAP 経由の確認とは別。
- **Nix 確認済み**: `task nix-fmt`（無関係な整形変更なし）、`task nix-check`、
  MacBook system build。現行世代との差分は Delve 1件のみ。flake.lock と既存プラグインの固定値は変更なし。
- **Nix 未適用**: `sudo -n darwin-rebuild switch ...#macbook` は認証が必要として終了。
  検証プロセスだけ Nix store の Delve を PATH に追加した。通常シェルへの恒久適用は上記 switch が必要。
- **初回の起動待ちは解消**: 認証前は headless / 実端末とも debugserver 起動後にタイムアウトした。
  ユーザーが Developer Tools Access を認証した後、同じ Go / Delve / Lua 設定で上記の実停止が成功した。
  一時サンプルの `/tmp` と `/private/tmp` のパス差によるビルドエラーは `cd -P` で解消した。
  検証用の Neovim・tmux・Delve・debugserver は終了済み。
- **残件**: Nix switch 後、通常の PATH から `dlv` が見つかることを新しいシェル・Neovim で確認する。
  Learno の Docker 接続、他言語、後続プラグインは今回の実セッション検証に含めない。

## 後続タスク

- Learno: Docker 内の Delve 起動確認、接続先・ソースパスの対応設定、API リクエストでの実停止確認。
- TypeScript / Next.js と Python のアダプター。
- neotest、toggleterm.nvim、変数のインライン表示、ブレークポイントの永続化。
