# ADR-20261127-0003: claude.ai の Artifacts の写しは、正本をクラウドに置き、Claude Code の hook と同期スキルで追従させる

- ステータス: 採用
- 決定日: 2026-11-27
- 関連: [ADR-20261127-0004](ADR-20261127-0004-artifact-export-id.md)（書き出し先で使う名前）、[ADR-20261127-0005](ADR-20261127-0005-artifact-export-layout.md)（書き出し先での置き方）

## 背景

homebase（別のリポジトリ）の v4「ナレッジ」は、登録したフォルダの HTML を取り込み、一覧・閲覧・検索・AI への質問をする（homebase の `docs/requirements/functional.md` の FR-058〜FR-063）。
claude.ai の Artifacts もその資料に入れたいが、homebase は claude.ai へ取りに行かず、写した先のフォルダ `~/claude-artifacts/` を読む（homebase の `docs/architecture/architecture.md`「ナレッジ（v4。ADR-20261123-046〜049）」、書き出し先は 2026-11-24 に決定）。

- claude.ai から Artifacts を取る公式の手段は Compliance API だけで、鍵を作れるのは Claude Enterprise の組織に限られ、鍵は全会話を読める（homebase の `docs/project-overview.md`「背景・目的」の「v4: ナレッジ」、2026-11-23 の調査）。個人の組織では鍵を作れない（同「スコープ（v4）」の「Out of Scope」）
- Artifacts の一覧・中身の取得・削除には、Claude Code の Artifact ツール（list・read・delete）を使う。Claude Code の外から呼べる手段は未確認
- 2026-11-27 に MacBook の Claude Code 2.1.332 で、Artifact ツールの PostToolUse hook（matcher `Artifact`）を確かめた
  - publish（新規・再公開・`files` 付き）でも delete でも動く。list・read などのほかの操作でも動く
  - publish では、入力に公開したローカルのファイル、応答に Artifact の URL が入る。delete の応答には、URL と削除できたかだけが入る
  - 設定に hook を足したあと、Claude Code を起動し直さずに効いた
- hook を通らない変更がある: claude.ai の Web のチャットやデスクトップアプリで作った Artifact、Web で消した Artifact、ブラウザで編集した版
- 型から作った Artifact のうち Data 型の 1 本は、read で取れる本体が型の器だけで、本文は型の側のファイルと Artifact のデータベースから描かれた（2026-11-27 に確認）。ほかの型（Slides など）が同じかは未確認

## 選択肢

### A. スキルだけで書き出す（不採用）

- 公開のたびにスキルを呼ぶかはモデル次第で、毎回通る保証がない

### B. Compliance API で claude.ai から取る（不採用）

- 個人の組織では鍵を作れない。作れても、鍵は全会話を読める

### C. ローカルを正本にし、ローカルでの削除もクラウドへ反映する（不採用）

- ローカルでの消し間違いが、元に戻せないクラウドの削除になる

### D. クラウドを正本にし、hook と同期スキルで追従させる（採用）

- Claude Code からの公開・削除は、毎回 hook を通る
- hook を通らない変更は、クラウドの一覧と突き合わせれば拾える

## 決定

**claude.ai の Artifacts の写しは、正本をクラウドに置き、Claude Code の hook と同期スキルで追従させる。**

1. Claude Code で公開・削除したものは、hook がその場で書き出し先に写す・消す
2. hook を通らない変更は、同期スキル（`artifact-sync`）がクラウドの一覧と突き合わせて取り込む。クラウドに無くなったものは、書き出し先からも消す
3. 削除はクラウドから行う。書き出し先だけで消したものは、次の同期で戻る
4. 同期は、一覧を最後まで取れたと確かめられないときは、書き出し先から何も消さない
5. 同期は、本人が Claude Code で頼んだときに行う。一覧と中身を取る手段が Claude Code の Artifact ツールしかないため
6. 対象は個人用のアカウント（`~/.claude`）だけにする。会社用（`ccw`、`~/.claude-work`）には hook もスキルも置かない。会社の資料を個人の homebase に混ぜないため
7. 型から作った Artifact（一覧で web page 以外のもの）は写さない。Data 型の本体は単体の HTML として読めず、homebase で資料にならないため

## 検証

- 試験用の Artifact で、新規の公開・再公開・`files` 付きの公開・削除を行い、書き出し先に写る・上書きされる・消えることを確かめた（2026-11-27、2.1.332）
- 既にあった 34 本のうち、Data 型の 1 本を除く 33 本を Artifact ツールの一覧と read で書き出し、クラウドの一覧の ID と書き出し先のフォルダが一致した（2026-11-27）
- 同期スキルを最初から最後まで通した実行は未確認

## 影響

- Web で作った・消した Artifact は、同期を頼むまで書き出し先に反映されない
- クラウドで消した Artifact は、同期で書き出し先からも消えるので、手元に写しが残らない
- 書き出し先は Claude Code の sandbox の外にあるので、同期スキルは書き出し先の操作を sandbox を外して行う
- hook は Artifact ツールのすべての操作で起動する。publish と delete 以外では何もせずに終わる

## 決定しないこと

- 同期を定期に実行するか: Web で作った Artifact が homebase に出ないことが続いたら決める。非対話の実行（`claude -p`）で、Artifact ツールと書き出し先への書き込みが通るかは未確認
- Data 型以外の型を写すか: Slides などの型から作った Artifact を homebase で読みたくなったら、その型の本体が単体の HTML になるかを確かめて決める
- 削除の候補の選び方（題名・更新日などの目安）: `artifact-sync` の SKILL.md で調整する

## 参照

- 実装: ae42e79
- homebase の `docs/requirements/functional.md` の FR-059 の備考、`docs/project-overview.md`「homebase の外で作るもの」
