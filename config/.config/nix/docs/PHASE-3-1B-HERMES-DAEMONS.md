# Phase 3-1b: hermes の完全 Nix 化（LLM 基盤 + デーモン宣言管理）

hermes に残る brew 管理（LLM 基盤）と、launchd 直下の自前デーモン群を
Nix の宣言管理へ移行するための調査結果と作業計画。
調査は 2026-08-01 に実施（読み取り専用）。

## 背景: ROADMAP の前提修正

ROADMAP は「launchd の宣言管理」を目的外としていたが、その根拠
「自己管理対象が cliproxyapi の 1 つだけ」は **MacBook Pro 視点の前提**だった。
hermes には自前の launchd agent が 3 つ + Hermes Agent 内部スケジューラがあり、
前提が変わったため（進行ルール準拠）、**hermes に限り launchd 宣言管理をスコープに入れる**。
MacBook Pro / WSL2 では引き続き目的外。

## 調査結果（2026-08-01）

### 常駐デーモン一覧

| デーモン | 起動主体 | 実体 | 備考 |
|---|---|---|---|
| llama-swap | launchd `~/Library/LaunchAgents/com.user.llama-swap.plist` | `/opt/homebrew/bin/llama-swap --config ~/.config/llama-swap/config.yaml --listen 127.0.0.1:8080` | RunAtLoad + KeepAlive。単純な plist で宣言化容易 |
| miniserve | launchd `~/Library/LaunchAgents/com.hermes.miniserve.plist` | `/opt/homebrew/bin/miniserve --port 18080 …` | 同上 |
| **ai.hermes.gateway** | launchd `~/Library/LaunchAgents/ai.hermes.gateway.plist` | `~/.hermes/hermes-agent/venv/bin/python -m hermes_cli.main gateway run --replace` | Hermes Agent 本体。**PATH に /opt/homebrew/bin を固定注入**し gh / agent-browser / ffmpeg / op 等を PATH 探索 |
| llama-server | llama-swap の子（オンデマンド、TTL 600s） | config.yaml の `cmd` に `/opt/homebrew/bin/llama-server` 直書き ×2 | 常駐しない |
| pyright-langserver | gateway の子 | `~/.hermes/lsp/bin/` 配下 | Nix 移行対象外 |
| suica_host.py + playwright | **不明**（launchd 外。手動起動後に孤児化と推測） | `~/.hermes/poc/monthly-office/` | 起動主体をユーザー確認要 |
| com.hermes.poc.capture.jreid | `/private/tmp/` の**野良 plist**（停止中） | POC 用の一時ジョブ残存 | 扱いをユーザー確認要 |

- OS の crontab は未使用。定期実行は Hermes Agent 内部スケジューラ（`~/.hermes/cron/jobs.json`）で、launchd とは別レイヤー（今回のスコープ外）
- tmux 常駐なし

### /opt/homebrew 参照インベントリ（brew を消すと壊れる箇所）

| 分類 | 箇所 | 影響 |
|---|---|---|
| **直接影響（要修正）** | `~/.config/llama-swap/config.yaml` の `cmd` ×2（llama-server） | llama-swap 移行時に必須 |
| 〃 | 上記 plist 2 つの ProgramArguments と PATH | 宣言化で置き換え |
| **PATH 探索（gateway 経由）** | hermes-agent ソース各所（gh / agent-browser / ffmpeg / docker / libopus / ssl cert 等の候補パス列挙） | 探索ロジック自体は無修正でよい。**gateway の PATH に Nix の bin を足せば解決**する見込み |
| **直書き（要個別修正）** | `poc/monthly-office/rakuraku_login.py:35`, `run_login.sh:5-6` の `/opt/homebrew/bin/op` | op は cask（1password-cli）由来のため**当面は壊れない**。cask 精査時に注意 |

### nixpkgs 収録確認（2026-08-01）

`llama-cpp` / `llama-swap`（v240）/ `miniserve`（0.35.0）いずれも収録あり。
ただし llama.cpp は更新が非常に速く、nixpkgs-unstable の追従ラグと
Metal ビルドの品質は移行時に実測確認すること。

## 作業計画

- [x] llama.cpp / llama-swap / miniserve を nixpkgs 移行（2026-08-01。
      b8890→b10133 / 209→240 のアップグレードを兼ねた。Metal 動作は実推論で確認済み）
- [x] home-manager の `launchd.agents` で llama-swap / miniserve を宣言管理（2026-08-01。
      Label・ログパス・KeepAlive は旧 plist と同一。手書き plist は宣言版に置換）
- [x] llama-swap の `config.yaml` を宣言管理へ取り込み（2026-08-01、
      `hosts/hermes/llama-swap-config.yaml`）。当初案のストアパス補間ではなく
      「裸のコマンド名 + サービス PATH に Nix bin を注入」方式を採用したため、
      **例外を作らず mkOutOfStoreSymlink（編集即反映）のまま**管理できた
- [x] `ai.hermes.gateway` 対策（2026-08-01）: **plist は無改変**。gateway の PATH が
      `~/.local/bin` を含む（/opt/homebrew/bin より先）ことを利用し、
      `~/.local/bin/gh` → `/etc/profiles/per-user/agent/bin/gh`（安定パス）の
      symlink を home-manager で配置。plist が hermes-agent 側で再生成されても壊れない
- [x] gh の brew 暫定残留を解除（2026-08-01）
- [x] 野良 plist / 孤児プロセスはユーザー確認の結果「残骸」と判明（2026-08-01）。
      野良 plist は掃除済み。`suica_host.py` は次回再起動で消滅する
      （どこにも登録が無いため復活しない）
- [x] 完了確認（2026-08-01）: brew 残留は cask 7 個 + git-gtr + その依存
      （git/gettext/pcre2 等）のみ。
      注記: zap は宣言済み formula の依存（git-gtr → git 等）を削除しない。
      依存まで無くすには git-gtr の自作パッケージ化（Phase 4-7）が必要

### リスクと段取りの注意

- 切替時に LLM 推論・ニュース配信が一時停止する（llama-swap / miniserve の
  bootout → 新宣言での起動）。**Hermes Agent の稼働に影響が出る時間帯を
  ユーザーと合意してから実施**する
- gateway 本体（ai.hermes.gateway）は Hermes Agent の心臓部。PATH 追加以上の
  変更（起動宣言の取り込み）は、venv 再構築等と絡めず最小差分で行う
- 旧 plist は削除ではなく `*.bak` 退避（rollback 可能に）

## 完了条件 → すべて達成（2026-08-01）

1. hermes の brew list が「cask + git-gtr（+依存）」のみになる → 達成
2. llama-swap / miniserve が Nix 宣言由来の launchd agent として稼働する → 達成
   （ストアパス起動をプロセスで確認、実推論 200 応答）
3. Hermes Agent（gateway）が Nix 移行後の CLI 群（gh 等）を発見できる → 達成
   （~/.local/bin/gh 経由、gh 2.96.0 nixpkgs 版が応答）
4. `darwin-rebuild switch` だけで上記が再現できる → 達成

## 実施記録（2026-08-01）

- **llama-server b10133 は `-hf` のモデルを HuggingFace hub キャッシュ
  （`~/.cache/huggingface/hub/`）に保存する**。blob は拡張子なしのため
  `*.gguf` 検索では見つからない点に注意
- 移行後の初回推論が失敗したのは移行起因ではなく、**gemma のモデルキャッシュが
  以前から消失していたため**（Qwen3.5-9B は存置、過去 438 回の推論実績あり）。
  オンデマンド再ダウンロード（約3分）が旧 `healthCheckTimeout: 60` に殺されていた
- 対策として `healthCheckTimeout: 600` へ引き上げ（config はリポジトリ管理に
  なったので恒久化）。**モデルキャッシュが消えても自己回復する**構成になった
- ダウンタイム最小化の段取り: hermes 上で `darwin-rebuild build`（sudo 不要）で
  事前ダウンロード → 旧 agent を bootout → switch（activation のみ）。
  実績ダウンタイムは数分
