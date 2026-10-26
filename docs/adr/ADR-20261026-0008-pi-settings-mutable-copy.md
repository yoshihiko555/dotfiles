# ADR-20261026-0008: pi の settings.json を実ファイル + adopt 方式で管理し、端末固有の値は載せない

- ステータス: 採用
- 決定日: 2026-10-26
- 関連: [ADR-20261013-0007](ADR-20261013-0007-pi-harness-separate-repo.md)（未確定事項「`settings.json` を管理するか」への回答）

## 背景

ADR-0007 では、pi がマシン固有の値を書き込むことを理由に `~/.pi/agent/settings.json` を試用中は管理しないとした。
試用が進み、既定のプロバイダ・モデルと pi-harness の登録（`packages`）が固まってきたため、管理するかを改めて判断した。

2026-10-26 時点の中身と、pi 1.4.0 の実装から分かった性質は次のとおり。

| キー | 書き込む契機 | 性質 |
|---|---|---|
| `defaultProvider` / `defaultModel` | `/model` での選択 | 残したい設定 |
| `packages` | `pi install` | 残したい設定。agent dir からの相対パスで記録される |
| `collapseChangelog` | 設定画面 | 残したい設定 |
| `lastChangelogVersion` | pi の更新後の初回起動 | 更新のたびに変わる |
| `deviceId` | ChatGPT ログインで初めて必要になったとき | `randomUUID()` の乱数。ログイン時に `ext_agent_host_id` として OpenAI へ送られる |

- pi は `settings.json` を temp → rename ではなく `writeFileSync` で上書きする。Claude / Antigravity と違い、symlink でも壊れない
- `deviceId` は認証情報ではない（トークンは `auth.json`）。ただし pi 自身がバグ報告から除外し、
  プロジェクト設定経由で全クローンが同じ ID になるのを防ぐ作りになっている（`getOrCreateDeviceId` のコメント）
- OpenAI 側で `deviceId` が何に使われるか（失効の単位になるか等）は公開情報では確認できなかった

## 選択肢

### A. 管理しない（不採用）

- ADR-0007 の現状維持
- 新しいマシンでは既定モデルや pi-harness の登録を手で作り直すことになる

### B. symlink で repo の実体を指す（不採用）

- `writeFileSync` なので技術的には成立し、追加は `dotfiles.nix` の 1 行で済む
- `deviceId` が public リポジトリに載り、symlink を張る全マシンで同じ ID になる。pi の設計意図に反する
- 消しても pi が repo のファイルへ書き戻すため、特定のキーだけ載せないことができない
- `lastChangelogVersion` が pi を更新するたびに差分として出る

### C. 実ファイル + adopt 方式に乗せ、端末固有のキーを除外する（採用）

- Claude / Antigravity の `settings.json` と同じ `scripts/apply-managed-settings.sh` / `adopt-managed-settings.sh` を使う
- `manage_mutable_json` の preserve（除外キー）で `deviceId` と `lastChangelogVersion` を repo に載せず、
  反映時は実ファイル側の値を引き継ぐ。drift 判定からも外れる

## 決定

**C を採用する。**

1. `pi/settings.json` を repo の正とする。`deviceId` と `lastChangelogVersion` は含めない
2. `apply_pi` / `adopt_pi` を追加し、除外キーに `deviceId lastChangelogVersion` を指定する。
   switch（`home.activation.mutableDotfiles` の `all`）と `task apply-settings TARGET=pi` で反映し、
   pi 側の変更は `task adopt-settings TARGET=pi` で回収する
3. `task status` に pi の drift 表示を加える。Claude の Stop hook に相当する即時通知は作らない
4. `lastChangelogVersion` は差分として載ること自体は問題ないが、コピー方式では drift 扱いになり
   pi を更新するたびに反映が止まるため、`deviceId` と同じく除外する

## 検証

- 実機と切り離した `HOME` で次を確認した
  - 初回の apply で実ファイルに `deviceId` / `lastChangelogVersion` が残り、参照コピー（`.settings.json.nix-managed`）が作られる
  - `lastChangelogVersion` だけの変更は drift にならず、apply で値が引き継がれる
  - `defaultModel` を変えると apply が上書きを拒否し、adopt で repo へ回収される。回収結果に `deviceId` は含まれない
  - 回収後の apply は「変更なし」になる
- 実機で `task apply-settings TARGET=pi` の後、`task status` が `✅ pi settings` を返す
- 変更したシェル・YAML・Nix ファイルは treefmt の `--fail-on-change` を通る

## 影響

- pi で `/model` を切り替えると、次の switch で pi の分だけ drift 警告が出て反映がスキップされる。
  `task adopt-settings TARGET=pi` で回収すれば再開する（Claude と同じ運用）
- pi には Stop hook 相当がないので、drift に気づくのは switch の警告か `task status` になる
- `packages` の pi-harness のパスは agent dir からの相対パスなので、ghq の配置が同じマシンでしか通らない

## 未確定事項

- 新しいマシンで、`settings.json` の `packages` だけで pi-harness が読み込まれるか（`pi install` を省けるか）は未確認
- drift の即時通知が欲しくなったら、pi-harness の拡張で Claude の Stop hook 相当を作るかを判断する
- hermes など他のホストで pi を使う場合、`apply_pi` は macbook の activation からしか呼ばれない点を見直す
