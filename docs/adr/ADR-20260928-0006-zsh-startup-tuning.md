# ADR-20260928-0006: 対話 zsh を /bin/zsh に揃え、起動処理をキャッシュと遅延ロードで短縮する

- ステータス: 採用
- 決定日: 2026-09-28
- 関連: [ADR-20260922-0001](ADR-20260922-0001-herdr-migration-trial.md)（herdr 採用。起動は `/bin/zsh -lic herdr`）

## 背景

[zsh-bench](https://github.com/romkatv/zsh-bench) で対話 zsh を計測すると、体感できない上限（上流の目安）を大きく超えていた。

| 指標 | 開始時（nix の zsh） | 目安 |
|---|---:|---:|
| first_prompt_lag（起動からプロンプト表示まで） | 366ms | 50ms |
| first_command_lag（起動から最初のコマンド実行まで） | 373ms | 150ms |
| command_lag（空 Enter から次のプロンプトまで） | 93ms | 10ms |
| input_lag（キー入力から画面反映まで） | 1.2ms | 20ms |

計測で分かった原因は次のとおり。

| 問題 | 内容 |
|---|---|
| 2 つの zsh が補完キャッシュを取り合う | ログインシェル・tmux・WezTerm・herdr は `/bin/zsh`（5.9）。PATH 上の `zsh` は nix-darwin の `programs.zsh.enable` が入れる nix の zsh（5.9.2）で、herdr のポップアップ（`prefix+g` / `prefix+t`）と zsh-bench がこちらを起動していた。`~/.zcompdump` の版数が食い違うと compinit がフルリビルドし、交互に起動するたびに 800〜900ms かかる |
| compinit の二重実行 | nix-darwin 既定の `/etc/zshrc` が compinit・bashcompinit・promptinit を実行し、sheldon の compinit と二重になっていた |
| 起動のたびの外部コマンド | brew shellenv 約 25ms、mise activate 約 33ms（生成 12ms + 初回 hook-env 20ms）、sheldon source 約 20ms、git gtr init 約 55ms、starship init と PROMPT2 で starship を 2 回（約 16ms） |
| Enter ごとの外部コマンド | mise hook-env（毎回プロセスを起動して 9〜12ms）、未使用の右プロンプト（`starship prompt --right` 約 8ms）、starship の git_status（ベンチの 1 万ファイル repo で 49ms） |

## 選択肢

### A. starship のまま、キャッシュと遅延ロードで詰める（採用）

- first_command_lag は目安内に入る見込み
- first_prompt_lag と command_lag は starship のプロセス起動（10〜17ms）と git_status が下限になり、目安には届かない

### B. A に加えて powerlevel10k へ移る

- instant prompt と gitstatusd で 4 指標とも目安内に入る（zsh-bench 作者の参考設定 `diy++` と同じ構成）
- p10k は README で「サポートは非常に限定的」と明記している。見た目を作り直す必要があり、hermes / WSL の方針も決める必要がある

## 決定

**A を採用する。**

1. 対話 zsh は `/bin/zsh` に揃え、herdr のポップアップでも `/bin/zsh` を明示する（tmux・WezTerm と同じ）。
   nix の zsh は `/etc/zshenv` の PATH 設定のために有効にしている nix-darwin の副産物で、選んで使っているものではない。
   `/bin/zsh` は Nix が壊れても起動できる
2. macbook では nix-darwin の `enableGlobalCompInit` / `enableBashCompletion` を無効にし、`promptInit` を空にする（`config/nix/hosts/macbook/zsh.nix`）。
   sheldon の無い hermes では `/etc/zshrc` の compinit が唯一なので、共通層には置かない
3. 起動のたびに外部コマンドで生成していた初期化スクリプトは `~/.cache/zsh/` にキャッシュする。
   ファイル名に実体（brew の版 / Nix store のパス）を含めて更新時に作り直し、設定ファイル
   （`plugins.toml` / `plugins.lock` / mise の `config.toml` / `starship.toml`）の方が新しければ作り直す
   - mise activate の出力冒頭は生成時の PATH を埋め込むため、フック定義以降だけを保存する
   - starship init 内の `PROMPT2=$(starship prompt --continuation)` は値を展開して保存する
   - brew shellenv は出力を zshenv に直接書く。PATH の先頭が既に brew なら何もしない判定も brew と揃える
4. mise は shims 方式にしない。shims はツール起動ごとに約 18ms 増える（node 28→46ms、uv 9→26ms）。
   activate を残し、Enter ごとの hook-env は直前に `mise` を実行したときだけ走らせる（cd 時の切り替えは従来どおり）
5. 未使用の starship 右プロンプトは `RPROMPT=''` で止める
6. 補完系だけを zsh-defer でプロンプト表示後に遅延ロードする。コマンド・環境変数・ウィジェットの挙動を定義するものは同期のまま残す。
   `herdr-init-panes` / `herdr-launch-claude-work` は起動直後のペインへコマンドを送るため、定義が遅れると失敗する。
   遅らせるのは compinit・zsh-autosuggestions・fzf-tab だけ
   - compinit より前の `compdef` 呼び出し（gtr・wt・zoxide・bun）は仮の `compdef` で溜め、遅延 compinit の直後に再実行する
   - compinit は autoload だけ先に宣言する。`~/.bun/_bun` は compinit が未ロードだと自前で実行し、遅延の効果と bun の登録が消えるため
   - zsh-defer による precmd / chpwd の再実行と再描画は止める（`-dmp`）。OSC 133 のマークの二重出力や、herdr・mise のフックの余計な実行を避けるため。
     代わりに、自動提案は読み込み直後に `_zsh_autosuggest_start` を直接呼ぶ
   - compinit は `-i` を付ける（遅延中は確認の問い合わせに答えられないため）
7. zsh-bench は Nix の自作パッケージにし、`/bin/zsh` を計測する起動スクリプトを挟む。
   本体は PATH 上の zsh を計測するうえ、自身も zsh スクリプトなので、`zsh`→`/bin/zsh` を PATH の先頭に置いて `/bin/zsh -f` で起動する

### 入れないもの

- FPATH を子に引き継がせない変更: Ghostty 起動直後の最初のペインで 1 回 0.5 秒作り直すだけのため
- compaudit の間引き（`compinit -C`）、`nix.zsh` の fork 削減、zoxide init のキャッシュ、zcompile: 効果が小さい。compaudit は遅延側に移ったので、最初のプロンプトには効かない
- mise の shims 方式: 決定 4 のとおり
- p10k への移行と、starship の git_status の無効化: 未確定事項に回す

## 検証

各段階の前後値は、それぞれのコミット本文に残している。前半 3 段階は nix の zsh、以降は `/bin/zsh` で計測した（同条件での差は 5% 以内）。

| 段階 | first_prompt | first_command | command_lag |
|---|---:|---:|---:|
| gtr init のキャッシュ | 366 → 319 | 373 → 327 | 93 → 96 |
| 右プロンプトの停止 | 319 → 298 | 327 → 305 | 96 → 82 |
| herdr ポップアップの `/bin/zsh` 明示 | 作り直し 800〜900ms が解消 | | |
| `/etc/zshrc` の compinit 停止 | 307 → 275 | 315 → 283 | 85 → 82 |
| brew shellenv の直書き | 278 → 249 | 286 → 257 | 87 → 87 |
| mise の activate キャッシュと precmd 抑制 | 249 → 216 | 257 → 224 | 87 → 75 |
| sheldon source のキャッシュ | 216 → 194 | 224 → 203 | 75 → 76 |
| starship init のキャッシュ | 194 → 179 | 203 → 187 | 76 → 77 |
| 補完系の遅延ロード | 184 → 131 | 192 → 135 | 79 → 76 |

- 環境変数は、入れ子・素の環境・非対話の 3 経路で、変更の前後で PATH / FPATH / INFOPATH / MANPATH / HOMEBREW_* が一致することを確認した
- 遅延ロードは Python の pty で対話セッションを動かして確認した。起動直後の入力で `ccw` / `wt` / `gtr` / `z` が定義済みであること、
  読み込み後に補完（git / gtr / wt / z / bun）・自動提案・fzf-tab の Tab が変更前と同じ状態になること、OSC 133 が 1 回だけ出ることを見た
- zpty 上では zsh-defer の遅延処理が一度も実行されない。遅延ロードの検証には zpty を使わない
- 対話モードの検証では HISTFILE を scratch に向ける。`/etc/zshrc` の `SAVEHIST=2000` のまま起動したテスト用シェルが、`~/.zsh_history` を 2000 行に切り詰めた（バックアップから復元済み）

## 影響

- キャッシュは `~/.cache/zsh/` に置く。挙動がおかしいときは削除すれば、次の起動で作り直される
- エディタで `mise.toml` を書き換えた場合、cd するか新しいシェルを開くまで反映されない（`mise` コマンド経由なら直後に反映される）
- プロンプト表示後の約 50ms は、Tab が fzf-tab の無い補完になり、自動提案も出ない
- 自動提案の開始処理は内部関数を直接呼ぶため、プラグインの更新で壊れる可能性がある
- brew shellenv の出力が変わったら、zshenv の直書き部分を更新する
- 計測は `zsh-bench` で `/bin/zsh` を測れる（`-i` で回数を指定できる）

## 未確定事項

- command_lag（76ms）と first_prompt_lag（131ms）の残り: starship の git_status を無効にするか、p10k に移るか
- hermes への展開（zsh-bench・遅延ロード・`/etc/zshrc` の compinit 停止は macbook のみ）
