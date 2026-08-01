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

- [ ] llama.cpp / llama-swap / miniserve を nixpkgs 移行（hosts/hermes に配置。
      brew 版とのバージョン・Metal 動作を比較確認してから切替）
- [ ] `launchd.user.agents` で llama-swap / miniserve を宣言管理
      （既存 plist は退避。KeepAlive + RunAtLoad をそのまま表現）
- [ ] llama-swap の `config.yaml` を宣言管理へ取り込み、`llama-server` の
      パスを Nix ストアパスに差し替え（ストアパス補間が必要なため
      mkOutOfStoreSymlink 原則の**例外**。理由コメント必須）
- [ ] `ai.hermes.gateway` の PATH に Nix プロファイル bin
      （`/etc/profiles/per-user/agent/bin` 等）を追加。plist を宣言管理に
      取り込むか hermes-agent 側の管理に残すかはここで判断
- [ ] gh の brew 暫定残留（hosts/hermes、2026-08-01 措置）を解除
- [ ] 野良 plist（`/private/tmp/com.hermes.poc.capture.jreid.plist`）と
      孤児 `suica_host.py` の扱いをユーザーに確認（勝手に消さない）
- [ ] 完了確認: hermes の brew 残留が「cask 7 個 + git-gtr のみ」になる

### リスクと段取りの注意

- 切替時に LLM 推論・ニュース配信が一時停止する（llama-swap / miniserve の
  bootout → 新宣言での起動）。**Hermes Agent の稼働に影響が出る時間帯を
  ユーザーと合意してから実施**する
- gateway 本体（ai.hermes.gateway）は Hermes Agent の心臓部。PATH 追加以上の
  変更（起動宣言の取り込み）は、venv 再構築等と絡めず最小差分で行う
- 旧 plist は削除ではなく `*.bak` 退避（rollback 可能に）

## 完了条件

1. hermes の brew list が「cask + git-gtr」のみになる
2. llama-swap / miniserve が Nix 宣言由来の launchd agent として稼働する
3. Hermes Agent（gateway）が Nix 移行後の CLI 群（gh 等）を発見できる
4. `darwin-rebuild switch` だけで上記が再現できる
