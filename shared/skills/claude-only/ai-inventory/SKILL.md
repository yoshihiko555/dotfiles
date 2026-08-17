---
name: ai-inventory
description: 月次でAI資産（skill・subagent・command・plugin・MCP・hook・context・memory）を棚卸しし、Notion台帳「A I - A S S E T S」と突き合わせて新規・更新・消滅の差分を記録したうえで、削除候補・重複統合候補・要改善候補を提示するスキル。実際の削除やステータス変更は行わず、候補の提示と台帳の同期、月次レポート作成までを担当する。「AI資産の棚卸しをして」「skillを整理したい」「使ってないskillを洗い出したい」「月次棚卸し」「AI-ASSETSを更新して」「棚卸しレポートを作って」といった依頼で使う。
allowed-tools: Bash, Read, AskUserQuestion, mcp__claude_ai_Notion__notion-query-data-sources, mcp__claude_ai_Notion__notion-create-pages, mcp__claude_ai_Notion__notion-update-page, mcp__claude_ai_Notion__notion-search, mcp__claude_ai_Notion__notion-fetch
---

# ai-inventory

## このスキルがやること/やらないこと

やること: 資産の収集 → Notion台帳との差分算出 → 台帳への反映 → 判定案の提示 → 月次レポート作成。

やらないこと:
- **削除の実行はしない。** skill/agent/plugin/waste の実体削除、Notionレコードのプロパティ書き換え（ステータス変更）は、このスキルの範囲外。「削除候補」「統合候補」「要改善候補」として提示するところまでで止める
- 端末はこのMacBookのみが対象。hermes/WSL2は対象外
- 会社用Claude Code環境は存在確認と件数記載のみ。台帳DBにはレコードを作らない

## 前提

- 台帳: Notion DB `A I - A S S E T S`
  - data source ID: `collection://3bf6d81a-ac52-8032-9050-000b266faacf`
  - URL: https://app.notion.com/p/3bf6d81aac5280529945dcefd03261cf
  - 親ページ（レポートの作成先）: 無題ハブ「W O R K F L O W」（`1416d81aac528070960ac832992675a5`）
- Notion操作は Notion MCP（`mcp__claude_ai_Notion__notion-*`）を使う。以下は論理名（`query-data-sources` / `create-pages` / `update-page` / `search` / `fetch`）で記載する

## 手順

### Step 1: 資産一覧を収集する

`collect.sh` を実行し、標準出力のJSONを得る。

```
bash <skill-dir>/collect.sh
```

出力は `assets[]`（各要素に `id` / `display_name` / `type` / `origin` / `scope` / `targets` / `path` / `usage_this_month` / `usage_measurable` / `last_modified` / `notes`）、`stats`、`waste[]` を持つJSON。`id`（安定ID、後述）をキーとして扱う。

利用実績（`usage_this_month`）はtranscriptの記録期間に制約がある（→[既知の制約](#既知の制約)）。特に序盤の実行では「ゼロ＝使われていない」と早合点せず、記録期間の短さを踏まえて判定する。

### Step 2: Notion台帳の既存レコードを取得する

`query-data-sources`（data_source_id: `collection://3bf6d81a-ac52-8032-9050-000b266faacf`）で全レコードを取得する。`名前`（title）が安定ID。

### Step 3: 差分を算出する

安定ID（`名前`）をキーに、Step 1のJSONとStep 2のNotionレコードを突き合わせる。

- **新規**: JSONにあってNotionにない → レコード作成候補
- **更新**: 両方にある → 次の値を再計算する
  - `前回の利用` ← 現在の `今月の利用`（繰り下げ）
  - `今月の利用` ← JSONの `usage_this_month`
  - `連続ゼロ月数` ← 今月の利用が0なら現在値+1、1以上なら0にリセット
  - `最終更新日` ← JSONの `last_modified`
  - `最終棚卸し日` ← 実行日
- **消滅**: NotionにあってJSONにない → 実体が見つからないことを意味する。ステータス「アーカイブ済」候補とし、判定メモに「実体消滅（確認日）」を記録する案を用意する

### Step 4: 差分サマリを提示し承認を取る

新規N件 / 更新M件 / 消滅K件の内訳を、各件の安定ID＋表示名のリストで提示する。

`AskUserQuestion` で反映してよいか確認する。承認の粒度は2段階に分ける。

- **新規作成・更新（プロパティの数値更新）は一括承認**でよい。壊れても実害が小さく、再実行で復旧できるため
- **消滅（Notionレコードのアーカイブ）だけは個別承認。** 1件ごとに「このレコードをアーカイブ済にしてよいか」を確認してから `update-page` する。誤って実体を見落としているだけの資産を一括で消してしまうリスクがあるため、ここは一括承認の対象に含めない

反映は `create-pages`（新規）／`update-page`（更新・アーカイブ）で行う。

### Step 5: 判定案を提示する（自動でステータスは変えない）

以下の軸で判定案をリスト化して提示するだけにとどめる。Notionの `ステータス` `判定メモ` は書き換えない（人間が埋める運用のため）。

| 軸 | 条件 | 提示する候補 |
|---|---|---|
| 利用実績 | 連続ゼロ月数が3以上 | 削除候補 |
| 重複 | 同一表示名が複数スコープ/実体パスに存在 | 統合候補 |
| 鮮度 | 最終更新日から6か月以上経過 | 要改善候補 |
| 整合性 | hookスクリプトが実行不可（存在しない/実行権限なし）、`@`参照先ファイルが不在 | 要改善候補（JSONの `notes` に結果がなければ、`実体パス` を対象に `Bash` で存在・実行権限を確認する） |
| waste | JSONの `waste[]`（旧バージョンcache、`.bak`、空ディレクトリ等） | 削除候補（パスとサイズを列挙するのみ） |

いずれも「候補の提示」で終わる。ユーザーが個別に判断し、Notion側の `ステータス` `判定メモ` は手動で埋めてもらう（唯一の例外はStep 4の消滅処理で、個別承認を得たうえで `アーカイブ済` を設定する場合のみ）。

### Step 6: 月次レポートを当月タスクの本文に書く

**新しいページは作らない。** T A S K DB にある毎月繰り返しタスク「月次棚卸_AI資産レビュー」の当月インスタンスを特定し、その本文に `update-page`（`insert_content`）でレポートを追記する。

当月インスタンスの特定は次のSQLで一意に決まる（同名タスクは各月1件ずつ存在する）。

```sql
SELECT url, "タスク名", "ステータス", "date:開始日:start"
FROM "collection://1316d81a-ac52-81be-b589-000baec0b7a6"
WHERE "タスク名" = '月次棚卸_AI資産レビュー'
  AND "date:開始日:start" LIKE '<YYYY-MM>%'
```

- T A S K DB の data source ID: `collection://1316d81a-ac52-81be-b589-000baec0b7a6`（title列は `タスク名`）
- 0件または複数件なら、候補を提示してユーザーに選ばせる（推測で決め打ちしない）
- 「月次棚卸しとしてAI資産レビューを行う対象を精査する」のような単発タスクが同時期に存在することがあるが、**そちらには書かない**。後から振り返らないため、記録は繰り返しタスク側に集約する
- ページのプロパティ（ステータス等）は変更しない。本文への追記のみ。既存本文は消さず末尾へ追記する

本文は `## AI資産棚卸し YYYY-MM` の見出しで始め、以下を含める。

- 総数と種別内訳
- 利用実績トップ
- ゼロ利用一覧
- 重複の指摘
- wasteと推定削減容量
- 今月の判断と次アクション
- 会社環境の件数（存在確認できた数のみ。`collect.sh` の出力に含まれない場合は「未確認」と記載する。台帳DBにはレコードを作らない）
- 台帳DBへのリンク: https://app.notion.com/p/3bf6d81aac5280529945dcefd03261cf

## プロパティ仕様（全14）

自動更新（このスキルが毎月書き換える12個）:

| # | プロパティ | 型 | 内容 |
|---|---|---|---|
| 1 | 名前 | title | 安定ID |
| 2 | 表示名 | text | 人間が読む名前 |
| 3 | 種別 | select | skill / subagent / command / plugin / MCP / hook / context / memory |
| 4 | 提供元 | select | 自作 / プラグイン / 公式ビルトイン |
| 5 | スコープ | select | dotfiles / global / project / work |
| 6 | 配布先 | multi-select | Claude / Codex / Gemini / Antigravity |
| 7 | 実体パス | text | 定義ファイルのパス（複数リポジトリに重複する場合は列挙） |
| 8 | 今月の利用 | number | 直近実行分の利用回数 |
| 9 | 前回の利用 | number | 前回実行時の「今月の利用」を繰り下げた値 |
| 10 | 連続ゼロ月数 | number | 利用0が続いた月数 |
| 11 | 最終更新日 | date | 実体の最終更新日 |
| 12 | 最終棚卸し日 | date | このスキルの最終実行日 |

人間が埋める（判断の記録用の2個。原則このスキルは書き込まない。唯一の例外はStep 4の消滅処理で、個別承認後に `ステータス=アーカイブ済` と `判定メモ` を設定する場合のみ）:

| # | プロパティ | 型 | 内容 |
|---|---|---|---|
| 13 | ステータス | select | 現役 / 要改善 / 削除候補 / アーカイブ済 / 未評価 |
| 14 | 判定メモ | text | 判断の理由 |

## 安定IDの規則

形式: `<スコープ>:<種別>:<名前>`

スコープは資産の所在であり、そのまま「取れる改善アクション」を表す。

| スコープ | 意味 | アクション |
|---|---|---|
| `dotfiles` | dotfilesリポジトリでgit管理され、home-manager経由で配布される | 自分で直せる |
| `global` | 端末のグローバル位置にあるがdotfiles管理外（plugin、`~/.claude.json`のMCPなど） | 入れ替える／抜くしかない |
| `project` | ghq配下の各リポジトリに存在する | そのリポジトリ側で直す |
| `work` | 会社用Claude Code環境 | 台帳DBには入れず、月次レポートに件数のみ記載 |

例: `dotfiles:skill:agent-browser`、`dotfiles:hook:check-settings-drift`、`global:plugin:claude-mem`、`global:mcp:filesystem`、`project:agent:code-reviewer`、`project:context:learno`、`project:memory:learno`

CLIをプレフィックスにしないのは、agent-browserのように1実体が複数CLIへ配布されるケースが分裂し、`配布先`（multi-select）と役割が衝突するため。リポジトリ名をプレフィックスにしないのは、ローカルagentのユニーク名正規化と両立しないため。

## 既知の制約

- **transcriptの最古が2026-07-15。** 利用実績は約30日の窓しか取れず、初回実行は部分窓での判定になる。「連続ゼロ3か月」の判定が実際に機能し始めるのは2026年11月頃から
- **skillの利用回数はSkillツール呼び出しとスラッシュコマンド出現の合算が必須。** どちらか片方だけでは `/commit` のような常用skillをゼロ利用と誤判定する
- **hook / context / memoryは利用実績を測れない。** 利用回数列は空のまま扱い、鮮度（最終更新日）と整合性チェック（hookスクリプトの実在・実行可能性、`@`参照先の存在）で代替判断する
- **pluginの利用実績は内包skill/agentの呼び出し合計。** plugin自体を直接呼んだ回数ではなく間接指標であることを判定時に踏まえる
- **Step 6 のNotion書き込みはメインセッションから実行する。** 書き込み先が「完了」ステータスのタスクページであるため、subagentに委譲するとAuto Modeの分類器に拒否されることがある（2026-08の初回実行で発生。1行の追記でも拒否され、メインセッションからは通った）。収集や集計はsubagentに委譲してよいが、`update-page` は自分で呼ぶこと
