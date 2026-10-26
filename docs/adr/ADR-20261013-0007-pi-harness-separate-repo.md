# ADR-20261013-0007: pi の設定は dotfiles、拡張は専用リポジトリ pi-harness で管理する

- ステータス: 採用
- 決定日: 2026-10-13
- 関連: [config/nix ADR-20261013-0007](../../config/nix/docs/adr/ADR-20261013-0007-omp-prebuilt-binary.md)（同時に試用を始めた omp の入れ方）

## 背景

2026-10-12 に pi（nixpkgs の `pi-coding-agent`）を macbook に入れた。pi は組み込みのツールが最小限で、
拡張（TypeScript）・skill・プロンプトを足して育てる前提の作りになっている。試用しながら自分用に
育てるにあたり、その設定と拡張をどこでリポジトリ管理するかを決める必要があった。

pi のユーザー設定は `~/.pi/agent/` にあり、次のものが同居している。

| 中身 | 性質 |
|---|---|
| `auth.json` | OAuth トークン・API キー。公開してはいけない |
| `sessions/`、`models-store.json` | pi が書き込む実行データ |
| `settings.json` | pi が `deviceId`（マシン固有）・`lastChangelogVersion` を書き込む。`pi install` もここに追記する |
| `AGENTS.md` | pi が読むグローバルな指示。Claude Code と違い、pi はこのファイルを読む |

拡張は pi package（ディレクトリ単位）にまとめられ、ローカルパスで登録するとコピーされずにその場で
読み込まれる。登録先を git の URL に変えれば、他のマシンへも `pi install git:…` で配れる。

## 選択肢

### A. 設定も拡張も dotfiles に置く（不採用）

- Claude / Codex / Gemini / OpenCode の設定と同じ置き場所になる
- 拡張は `package.json`・依存・型チェック・テストを持つ TypeScript のプロジェクトになり、
  dotfiles に `node_modules` とビルド用の設定を抱え込む

### B. 設定も拡張も専用リポジトリに置く（不採用）

- pi 関連が 1 か所にまとまる
- `shared/agents/core.md` から `task sync-agents` で各 CLI の AGENTS.md を生成する仕組みに乗れず、
  共通ルールを pi にだけ別管理することになる

### C. 設定は dotfiles、拡張は専用リポジトリ（採用）

- AGENTS.md は他の CLI と同じく `task sync-agents` で生成し、dotfiles から配る
- 拡張は専用リポジトリ（pi package）で、Node のプロジェクトとして完結させる

## 決定

**C を採用する。**

1. dotfiles: `shared/agents/diff-pi.md` を追加し、`task sync-agents` で `pi/AGENTS.md` を生成する。
   macbook の home-manager で `~/.pi/agent/AGENTS.md` にファイル単位でリンクする。
   `~/.pi/agent/` をディレクトリごと張らないのは、認証情報と pi が書き込むファイルが同居するため
2. `diff-pi.md` には、pi 固有の差分として「pi にはツール実行前の確認がないので、取り消しにくい操作は
   実行前にユーザーの返答を待つ」だけを書く
3. `~/.pi/agent/settings.json` は試用中は管理しない。pi がマシン固有の値を書き込むため、Claude の
   settings.json と同じ問題を抱える。pi-harness の登録は、マシンごとに `pi install <パス>` を 1 回実行して済ませる
4. 拡張は非公開リポジトリ [yoshihiko555/pi-harness](https://github.com/yoshihiko555/pi-harness) に置く。
   npm + tsc + vitest、Node は pi の実行環境（nixpkgs の pi が使う Node 24）に合わせて mise で 24 に固定する。
   pi 本体の型は開発用の依存として、入っている pi と同じ 1.1.0 に固定し、拡張からは `import type` だけで使う

## 検証

- pi-harness: `npm run check`（型チェックとテスト）が通る
- `pi install ~/ghq/github.com/yoshihiko555/pi-harness` の後、`pi --mode rpc` の `get_commands` で
  `/hello` が `source: extension`（pi-harness 由来）として返り、pi 本体の型との重複警告は出ない
- `~/.pi/agent/AGENTS.md` のリンクは、switch 後に pi の起動ヘッダーで読み込みを確認する

## 影響

- pi の共通ルールは他の CLI と同じく `core.md` の編集と `task sync-agents` で更新される
- `task sync-agents` を実行した際、9/29 に `core.md` へ追記した「Runtime & dependencies」節が
  Codex / Gemini の AGENTS.md に未反映だったことが分かり、あわせて生成し直した
- pi を更新したら、pi-harness の開発用依存（`@earendil-works/pi-coding-agent`）の版も合わせる

## 未確定事項

- `settings.json` を管理するか。設定が固まってきたら、Claude と同じ「実ファイル + adopt」方式に乗せるかを判断する
  → 2026-10-26 に [ADR-20261026-0008](ADR-20261026-0008-pi-settings-mutable-copy.md) で、
  `deviceId` と `lastChangelogVersion` を除外して「実ファイル + adopt」方式に乗せると決めた
- hermes など他のホストで pi を使うか。使う場合は pi-harness を git の URL で登録する
- 既存の `shared/skills` を pi の skill としてそのまま読めるかは未確認
  → 2026-10-15 に確認し配布した。`task sync-skills` が common と pi-only を `pi/skills` にリンクし、
  macbook で `~/.pi/agent/skills` へ張る。pi は多段の symlink をたどってユーザー skill として読み込む
