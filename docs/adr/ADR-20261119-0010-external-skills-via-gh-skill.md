# ADR-20261119-0010: GitHub で配布されている外部スキルは gh skill で共通スキルに取り込み、gh skill の更新機能で版を上げる

- ステータス: 採用
- 決定日: 2026-11-19
- 関連: [ADR-20261119-0009](ADR-20261119-0009-agent-relay-skill.md)（別の取り込み方。herdr 付属スキルは `herdr --skill` の出力をそのまま置く）

## 背景

日本語推敲スキル yomiyasu（nanaism/yomiyasu、MIT）は、digital-garden リポジトリの `.claude/skills/yomiyasu` に手でコピーして使っていた。
2026-10-05 に試用で入れ、上流の `skills/yomiyasu/` を取り直して差し替える形で 2 回更新した（digital-garden の `d11907c`・`4408df8`）。
そのため使えるのは digital-garden の Claude Code に限られていた。
他のリポジトリと他の CLI でも使いたいので、dotfiles の共通スキルに移す。

上流は頻繁にリリースしている。v2.3.0（2026-10-24）から v3.2.1（2026-11-19）までで 8 回ある（`gh release list -R nanaism/yomiyasu`）。
手で取り直して差し替える運用では追いつかないので、更新の手間を減らす仕組みも合わせて決める。

dotfiles の共通スキルは `shared/skills/common/` に実体を置き、`task sync-skills` が Claude Code・Codex・Antigravity CLI（agy）・pi の各置き場へリンクを張る。
ここにある自作スキルには、出典の記録がない。
各 CLI のスキルの置き場所（`~/.claude/skills` など）は home-manager 経由で dotfiles の `claude/skills` などを指している（2026-11-19 に `readlink -f` で確認）。

同じ名前のスキルをプロジェクト側と共通スキルの両方に置くと、版がずれる。
移す時点で、digital-garden のコピーは v3.1.0、共通スキルに入れたものは v3.2.1 だった。
両方あるときにどちらが読まれるかは未確認である。

上流が案内している入れ方は、`npx skills add`・`gh skill install`・`npx openskills install`・Claude Code プラグイン・ZIP・`.agents/skills/` へのコピーである（上流 README の「インストール」節）。

## 選択肢

### A. Claude Code プラグインで入れる（不採用）

- 上流のプラグインは Claude Code 用だけである。Codex 用のマニフェスト（`skills/yomiyasu/.codex-plugin/`）は v3.1.0 で上流から消えた（上流のタグ v3.0.1 と v3.1.0 のツリーを比べて確認）
- スキル名が `yomiyasu:yomiyasu` に変わる。上流 README は、`yomiyasu` とだけ書くと「Unknown skill」になると注意している
- 更新は `claude plugin update` で行われ、git の差分を読んでから取り込む運用に乗らない

### B. 上流のアーカイブを取得して差し替える自前のスクリプトを作る（不採用）

- SKILL.md を上流のまま保てるが、取得・差し替え・出典の記録を自分で保守することになる
- 同じことを gh skill が行えるので、保守するコードを増やす理由がない

### C. `npx skills` で入れる（不採用）

- 推奨の方式では、npx skills が持つ置き場所に実体を 1 つ置き、各エージェントの置き場所からリンクする。更新は `npx skills update` で行う（vercel-labs/skills の `docs/commands.md`「Installation Methods」節）
- 実体の置き場所が共通スキルの外になり、dotfiles のリンク配布と別の配り方が並ぶ。実体の置き場所を共通スキルに向けられるかは未確認である
- gh はすでに使っているが、npx skills は新しく増える依存になる

### D. gh skill で共通スキルの置き場所に入れ、gh skill の更新機能で版を上げる（採用）

- 置き場所を指定（`--dir`）すれば、既存のリンク配布にそのまま乗る
- gh skill は出典（リポジトリ・タグ・ツリーの SHA）を SKILL.md の frontmatter に書き、それを手がかりに新しい版を検出して差し替える
- 差し替えた結果は git の作業ツリーに出るので、差分を読んでからコミットできる

## 決定

**GitHub で配布されている外部スキルは、gh skill で共通スキルの置き場所に取り込み、gh skill の更新機能で版を上げる。**

1. 取り込み先は共通スキルの置き場所とし、全 CLI へは既存のリンク配布で届ける
2. 出典は gh skill が SKILL.md に書く記録を正とし、別の出典ファイルは置かない。取り込んだスキルの中身は手で直さない
3. 更新は「新しい版があるかの確認」と「差し替え」に分ける。差し替えはコミットせずに止め、差分を読んでから取り込む
4. 更新の対象は gh skill の出典の記録を持つスキルに限る。自作スキルと、ほかの方法で入れたスキル（herdr 付属スキルなど）には触れない
5. 共通スキルに取り込んだスキルと同じ名前のコピーを、プロジェクト側に置かない

## 検証

いずれも 2026-11-19、MacBook、gh 2.104.0 で確かめた。

- 一時ディレクトリで gh skill の挙動を確かめた
  - v3.1.0 に固定して入れてから更新すると v3.2.1 に差し替わり、上流に無いファイルは消えた
  - 名前を指定して `--all` を付けると、指定したスキルだけが更新され、出典の記録が無いスキルには触れなかった
  - 非対話の実行で `--all` を付けないと、更新は適用されなかった
- yomiyasu v3.2.1 を共通スキルに取り込み、Claude Code・Codex・agy・pi の置き場所から読めること、同梱の lint が動くことを確かめた
- 出典の SHA を古い値に書き換えた状態で、`task skill-outdated` が更新 1 件を報告し、`task skill-update` が v3.2.1 に差し替えた。
  差し替え後の中身は上流の v3.2.1 と一致し、異なるのは SKILL.md の frontmatter だけだった

## 影響

- SKILL.md の frontmatter は gh skill が書き直す（キーの並べ替えと出典の追加）。そのため上流のファイルとは一致しない
- 上流のスキルディレクトリを丸ごと取り込む。digital-garden では yomiyasu の `assets/` を除いていたが、今後は含まれる
- 差し替えは全 CLI がリンクしているディレクトリを直接書き換えるので、差分を読む前から新しい版が効く。
  yomiyasu の同梱スクリプトは `allowed-tools` で実行が許可されているため、差し替える前に新しい版の確認とリリースノートを読む
- 会社用の Claude Code・Codex も共通スキルを配る仕組みに乗っているので、次の同期で外部スキルが入る
- gh skill の出典の記録の形式に依存する。形式が変われば、更新対象の絞り込み（決定 4）を見直す

## 決定しないこと

- 新しい版の通知: 定期の確認は置かず、GitHub のリリース通知（Watch の Releases）で受ける。更新の見落としが続いた時点で、定期の確認を置くかを決める
- CLI 専用の外部スキルの置き場所: 今回は共通スキルだけを対象にした。特定の CLI だけで使う外部スキルを入れる時点で、取り込み先を広げるかを決める
- herdr 付属スキルを gh skill に寄せるか: [ADR-20261119-0009](ADR-20261119-0009-agent-relay-skill.md) の「決定」1 のとおり `herdr --skill` の出力を置く運用を続ける（`shared/skills/common/herdr/README.md`）。herdr の更新で再生成の手間が問題になった時点で決める

## 参照

- digital-garden での導入と更新: `b3fb63a`（導入）、`d11907c`・`4408df8`（更新）
- 上流: https://github.com/nanaism/yomiyasu
