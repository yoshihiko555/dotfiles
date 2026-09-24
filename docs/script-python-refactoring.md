# 補助スクリプトの Python 移行判断

調査・実装日: 2026-09-25。対象は自作の `scripts/`、`taskfiles/`、設定ディレクトリの補助スクリプト。実設定への適用・サービス再起動・コミットは行っていない。

## 方針と環境

- AGENTS.md / shared/agents/core.md、mise 設定、Nix のランタイム境界、bootstrap、treefmt、既存テストを確認した。
- Python は mise の `config/mise/config.toml`（`python = "latest"`）で提供する。今回の最低版は **3.11**（`tomllib` と ISO 日時の `Z` 対応）。実行検証は **3.14.2 / macOS**。最低版での実行は未検証。
- `python3` は PATH 上のものを使う。通常の mise 有効化済みシェルで実行する。Python 未導入なら先に既存の `mise install python` を実行する。macOS 同梱 Python の存在・バージョンには依存しない。
- 外部 Python パッケージは追加しない。Nix は mise 本体・CLI・設定配線、mise は言語ランタイムという役割を維持する。
- 初期導入の `install-brew.sh`、Nix activation が呼ぶ BTT / Loupedeck / herdr 同期は移行しない。今回の3件は bootstrap の前提ではない。認証整理は従来も Python を必要としていたが、trust 監査と MCP 同期には新たな Python 依存が加わる。
- 既存の Bash テストと Python `unittest` の方式に合わせる。Python は既存 treefmt の対象外。shell / YAML は既存 treefmt 設定を使う。
- 速度は選定理由にしていない。プロセス起動削減の余地は以下に記すが、実測前に高速化の効果とは扱わない。

## 候補と優先順位

P1 は誤判定・削除・更新の安全性、P2 は状態照合・復旧・形式変換、P3 は小さな改善余地。優先度と、仕様確認なしで安全に実装できる順番は区別する。

| 候補 | 分類 / 優先度 | 現在の具体的な問題 → 期待効果 | 移行リスク・判断 |
| --- | --- | --- | --- |
| `scripts/cliproxy-auth-prune.py`（旧 Shell） | 移行を推奨 / P1 / 実装済み | Python → TSV → Bash でタブ・改行のあるパスを分割。非 object JSON や timezone なし日時で停止 → 型検証とパス操作を一箇所にまとめる | 削除条件、候補順、通常出力、再起動終了コードを固定。無効入力は削除せず残す |
| `scripts/codex-trust-audit.py`（旧 Shell） | 移行を推奨 / P1 / 実装済み | awk が引用・エスケープ・コメントを誤読し、別テーブルの trust_level を拾う → TOML の構文に沿って監査する | 不正 TOML を成功扱いしていた点は終了1に修正。読み取り専用なのでコメント・書式は変更しない |
| `scripts/codex-trust-manage.sh` | 条件付き / P1 / 次点 | TSV と自作 TOML 抽出、全 projects 再構成、`cat > config` による途中切断・並行更新の恐れ → パーサーと安全な更新へ集約 | コメント・追加キー・managed block の維持仕様が必要。作業中の `codex/config.toml` には触れない。下記の案を確認してから着手 |
| `taskfiles/cliproxy.yml` の setup | 条件付き / P1 | sed 置換値の `&`・区切り文字、YAML の引用、直接リダイレクトによる部分更新 → 入力検証・一時生成・置換へ | YAML と secrets.env の読み込み仕様、コメント保持、秘密値非表示が必要。標準ライブラリに YAML パーサーはない。単純な Python 置換では不十分 |
| `scripts/loupedeck-sync.sh` | 条件付き / P1 | サービス停止後 rsync 失敗時に再起動されない。複数ファイル差し替えが部分適用になる → 復旧処理を検証可能にする | rsync の属性保持を維持。サービス再起動の保証は Bash の trap でも改善可能。Nix activation の Python 配布と復旧単位を決める必要あり |
| `scripts/btt-sync.sh` | 条件付き / P2 | orphan 親の補完と UUID 照合で jq・一時ファイルの反復。途中失敗時の掃除不足、参照 JSON の直接上書き → 構造化データ処理と参照更新を集約 | AppleScript API の失敗・途中適用・GUI の競合、JSON の整形互換、activation 環境を固定する必要あり。速度の比較対象は無効親補完と apply |
| `scripts/mcp-manage.py`（旧 Shell） | 移行を推奨 / P2 / 追加実装済み | jq による検証・マージ・TOML 組み立てが分散、複数クライアントへの部分反映 → 純粋な比較関数と更新処理へ分離 | 既存の対応表記・バックアップ・ロック・全体比較を維持。全出力とバックアップを反映前に用意。2ファイル全体の自動ロールバックは行わない |
| `scripts/codex-trust-prune.sh` | 条件付き / P2 | パスごとの jq / dirname、表記限定の awk 編集 → 候補判定・意味比較の可読性向上 | NUL 区切り、リンク保持、権限判定、バックアップ、競合検査が既にある。writer の方針が固まるまで維持 |
| `scripts/clean-uv.sh` | 条件付き / P2 | ps / awk による PID 照合、DB 参照失敗を0扱い、停止後に trap を登録 → 状態取得と復旧をテストしやすくする | worker status の契約、停止失敗時の扱い、処理中判定の方針が必要。uv / worker 自体は引き続き外部 CLI |
| `taskfiles/skills.yml` の同期 | 条件付き / P2 | find の改行区切り、リンク全削除後に再作成 → 特殊パスと失敗時の部分更新を減らす | Python 導入前の利用を維持する必要がある。NUL 区切りとリンク単位の更新を Bash で先に検討。Nix の配線管理へ役割を移さない |
| `scripts/repo-list.sh` と tmux / herdr sessionizer | 条件付き / P2 | find と TSV のパス境界、basename / sed の反復 → 一覧構築の堅牢化余地 | 出力 TSV と fzf / shell 消費側まで変更しないと改行・タブ問題は解決しない。Python だけの差し替えは不可。件数別計測も必要 |
| `config/herdr/bin/herdr-{init-panes,launch-claude-work,clear-claude-panes,kill-workspace-checked}` | 条件付き / P2 | JSON の状態照合とペインごとの CLI / jq が反復 → 判定を純粋関数化 | GUI の PATH、操作直前の状態変化、通知と終了コードの互換が必要。CLI 待ちが支配的かは未測定 |
| `taskfiles/cliproxy.yml` の status | 条件付き / P3 | 認証ごとに jq と python を起動 → 日時検証を共通化可能 | サービス / HTTP の失敗時出力を固定してから分離。速度は認証件数別に計測する |
| `scripts/adopt-managed-settings.sh` / `taskfiles/util.yml` の status / `claude/hooks/check-settings-drift.sh` | Bash 維持 / P3 | JSON 正規化・比較・コピーが主。status の不正 JSON 処理には改善余地あり | 短い jq 処理を残す。回収の部分適用や hook の JSON 出力エスケープは独立した修正として扱う |
| `scripts/clean-claude.sh` | Bash 維持 / P3 | find / du / delete が中心。改行で件数・dry-run 表示がずれる余地 | 削除自体は find が行う。NUL 処理等の局所修正で十分 |
| `scripts/install-brew.sh` / `scripts/herdr-plugins-sync.sh` | Bash 維持 | インストール CLI と固定 SHA リストの照合が主 | Python 未導入時・activation の入口を維持。対象外のプラグイン管理ファイルとは別物だが変更しない |
| `taskfiles/agents.yml` / `taskfiles/dotfiles.yml` / util の clean・nix 入口 | Bash 維持 | cat による生成または既存コマンドの呼び出し | Task を入口として維持。生成された AGENTS.md は編集対象外 |
| AeroSpace の scripts / layouts | Bash 維持 | CLI 操作が主。auto-grid は最大4窓、ロックと再取得があり、既存テストもある | Python 起動依存の追加に見合う効果が現時点で明確でない |
| tmux の split / init / snapshot / status / kill / cheatsheet、herdr の split / smart-move / status-repo / cheatsheet / agent-console / automatic-rename | Bash 維持 | CLI / fzf / git の呼び出しと短い整形が中心 | 高頻度の入口もあり、言語変更だけで高速化とはいえない。snapshot の固定一時名等は Bash で局所修正可能 |
| `config/nvim/bin/mermaid-render` / 共通通知と claude・codex の通知入口 | Bash 維持 | 外部描画・通知コマンドへの橋渡し | mermaid の Unicode 幅計算は既に Python、未導入時 fallback あり。全体を書き換える理由なし |
| `shared/skills/claude-only/ai-inventory/collect.sh` | 条件付き / P2（補足） | JSONL 集計・git 履歴・JSON 出力の反復 → 集計をまとめる余地が大きい | スキーマと利用数定義の固定、実ログを含まない代表 fixture、計測が先。広範囲かつプラグイン収集も含むため今回移行しない |

外部取り込みの skills / tmux plugins、`claude/hooks/herdr-agent-state.sh`（herdr による上書き管理）、生成物は除外した。`scripts/plugin-manage.py`、`scripts/tests/test-plugin-manage.py`、`shared/plugins/` は調査・編集対象外。既存 Python の `claude/statusline.py`、Alfred の `fmt.py` は言語移行候補に含めない。

## 実装した変更と互換性

1. 認証整理: 判定・検証・削除を `scripts/cliproxy-auth-prune.py` にまとめた。従来通り先頭の `--yes` だけを反映とし、既定・その他の引数は確認のみ。同じ type に未来の有効期限がある場合だけ削除する。`disabled` の意味やアカウント単位の判定は変更しない。
2. trust 監査: `scripts/codex-trust-audit.py` が `tomllib` で読み取る。表の列・summary・hint・並び順と、存在判定 / temp-like の条件は維持する。不正 TOML / 不正 projects 構造は、値を出さず終了1とする（従来の誤った成功扱いの修正）。
3. 初回は `.sh` を互換ラッパーとして残したが、追加依頼に従い3本の旧 `.sh` を削除した。Task と zsh の `trust audit` は Python を直接呼ぶ。`taskfiles/util.yml` は MCP の3行だけ変更し、プラグインの入口は維持。README.md / 実設定には触れていない。

認証整理の apply は `.auth-prune.lock`（作成時0600）への `flock` で自身の並行実行を拒否し、削除直前に対象の内容と代替認証の期限を読み直す。ロックファイルは残り、ロック自体はプロセス終了時に解放される。dry-run はファイルを作らない。

**残る制約:** サービス側はこのロックに参加しないため、再確認と unlink の間の競合を完全には排除できない。複数件削除の途中失敗は従来同様に部分完了で停止し、既に削除したファイルを復元しない。バックアップや新たな秘密情報のコピーは作らない。brew 再起動失敗は元の非ゼロ終了コードを返し、成功表示をしない。完全な復旧を加える場合は保存期間・権限・復旧単位の仕様が別途必要。

## 検証

```sh
python3 scripts/tests/test-script-refactors.py
bash scripts/tests/test-codex-trust-prune.sh
python3 -m unittest discover -s config/aerospace/tests -p 'test_*.py'
```

- 新規17テスト成功。通常出力の完全一致、dry-run 無変更、削除条件、空白・日本語・タブ・改行のパス、壊れた JSON / 型 / timezone、秘密値非表示、TOML 引用・コメント・別テーブル境界、不正 TOML、並行ロック、候補 / 代替認証の変更、unlink 失敗・部分完了とロック解放、brew 終了7を検証。
- 実 Task を一時リポジトリ（空白入りパス）から呼び、brew をスタブ化して引数伝搬と入口互換を確認。zsh の `trust audit` も fixture で確認。
- 初回のラッパー削除前に、変更前の2スクリプトを一時領域へ保存し、同じテストで6件の失敗を再現。移行後のロック等4テストは旧版でスキップ。通常出力と既存の引数・終了コードは旧版でも成功。
- 既存 trust prune テストと AeroSpace 3テストも成功。実際の認証ファイル・サービスには触れていない。
- 変更した shell 2件と YAML 1件は、Nix/treefmt の対象ファイル指定検証で変更0件。`git diff --check` と Bash 構文検査も成功。全体整形は他セッションの差分を巻き込むため実行しない。
- 速度は未測定。高速化を成果として主張しない。

## 次の大きな移行で確認すること

最優先は trust の書き込み側。提案は「全 projects を再生成する方式から、対象 trust_level だけを編集し、追加キー・コメント・書式を保持する方式」への変更。バックアップ、同一対象のロック、書き込み直前の比較、リンク先への atomic replace、変更後の構文・意味検証をセットにする。

`tomllib` は writer ではなく、コメントを保持しない。全表記を支援するなら TOML 編集ライブラリとバージョン固定・再現方法が必要。標準ライブラリだけなら対応表記を限定し、未対応表記を拒否する設計になる。**対応範囲と外部依存の許容を確認してから**移行する。

次に Loupedeck の失敗時再起動・バックアップ復旧を扱う。まず Bash の trap で直せる範囲を分離し、Python 化する場合だけ activation 用の実行環境を明示する。BTT は fake CLI による途中失敗テストと、既存 JSON 出力互換の fixture を先に用意する。MCP の限定移行は追加依頼で実施済み。


## 追加実装: MCP 同期と旧入口の削除

ユーザー確認により、`scripts/mcp-manage.py` へ移行し、旧 `mcp-manage.sh` と認証整理・trust 監査の Bash ラッパーを削除した。3本の Python CLI は shebang と実行権限を揃え、Ruff で import 順序・書式・lint を検証する。Task 名、zsh 関数、引数は維持するが、旧 `.sh` を直接呼ぶ外部の個人スクリプトは `.py` へ更新が必要。

MCP の runtime 依存は Python 3.11+ のみ。jq / taplo / `TAPLO_BIN` / Nix fallback は MCP 本体では不要になった。既存 Bash 統合テストの結果照合には jq / taplo を引き続き使う。設定形式と復旧手順は `shared/mcp/README.md` に反映した。

- 定義の検証、既存値のマージ、既定値の同値判定を関数化。list / diff は値を出さず、ファイルを作らない。
- TOML の通常表記のみを編集する制限と、変更後の全体比較を維持。管理対象の変更テーブル内部は従来どおり再生成し、対象外・変更なしテーブルは保持。汎用のコメント保持 writer を自作したわけではない。
- 同じディレクトリの一時ファイル、リンク先の置換、既存 mode、バックアップ形式、同期ロックを維持。全設定の出力・一時ファイル・バックアップを準備してから置換する。
- 反映直前にファイル内容だけでなくリンクの行き先も再確認する。2件目の置換失敗時は1件目が反映済みとなるが、両方の更新前バックアップが残る。アプリとの完全な排他・自動ロールバックは対象外。
- 末尾が改行のディレクトリで新規設定を作成する fixture は、旧版が終了1・未作成、Python 版が終了0・両設定作成となった。旧版の dirname の command substitution による末尾改行消失を再現・解消した。

追加の検証コマンド:

```sh
python3 scripts/tests/test-mcp-manage.py
bash scripts/tests/test-mcp-manage.sh
ruff check scripts/mcp-manage.py scripts/cliproxy-auth-prune.py scripts/codex-trust-audit.py scripts/tests/test-mcp-manage.py scripts/tests/test-script-refactors.py
ruff format --check scripts/mcp-manage.py scripts/cliproxy-auth-prune.py scripts/codex-trust-audit.py scripts/tests/test-mcp-manage.py scripts/tests/test-script-refactors.py
```

MCP の Python テストでは通常出力、読み取り専用、冪等性、stdio / env / 引数 override、追加キー・秘密値の保持、未対応 TOML、不正入力、空白・日本語・タブ・改行パス、バックアップ権限、同時同期、並行編集・リンク変更、一時ファイル・バックアップ・2件目の置換の失敗、Task 呼び出しを検証する。速度改善は今回も主張しない。

最終検証: MCP 17件 + 認証整理 / trust 監査17件の計34テスト成功。既存 MCP / trust prune の Bash 統合テスト、Python 5ファイルの Ruff check / format、Bash / zsh 構文検査、`git diff --check` も成功。
