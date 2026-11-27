# ADR-20261127-0004: 書き出し先で Artifact を識別する名前に、URL の末尾の ID を使う

- ステータス: 採用
- 決定日: 2026-11-27
- 関連: [ADR-20261127-0003](ADR-20261127-0003-artifact-export-sync.md)（前提。写しの作り方）、[ADR-20261127-0005](ADR-20261127-0005-artifact-export-layout.md)（この名前のフォルダに置く）

## 背景

claude.ai の Artifacts を `~/claude-artifacts/` に写すとき、homebase との約束で、名前は Artifact の ID にし、再公開では同じものを上書きする（homebase の `docs/requirements/functional.md` の FR-059 の備考）。
どの ID を使うかは決まっていなかった。

2026-11-27 に MacBook の Claude Code 2.1.332 で、Artifact ツールの入力と応答を確かめると、Artifact には 2 つの ID があった。

- URL の末尾の ID（`https://claude.ai/artifact/<ID>` の `<ID>`）: 一覧（list）の各行、publish の応答、delete の入力と応答に出る
- UUID: publish の応答の `artifact_id` と、read で保存したフォルダの名前に出る。一覧と delete には出ない

hook は delete の応答から消すものを決め、同期スキルは一覧と書き出し先を突き合わせる（ADR-20261127-0003 の「決定」1・2）。

## 選択肢

### A. UUID を使う（不採用）

- 一覧と delete に UUID が出ないので、URL と UUID の対応表を書き出し先に持ち、hook と同期スキルで保ち続ける必要がある

### B. URL の末尾の ID を使う（採用）

- 公開・削除・一覧のどれも同じ ID で扱えて、対応表が要らない
- 名前から Artifact の URL を組み立てて開ける

## 決定

**書き出し先で Artifact を識別する名前に、URL の末尾の ID を使う。**

1. 公開の応答から ID を取り出せないときは、写さずに警告する

## 検証

- 試験用の Artifact で、publish の応答の URL から取った名前で写ったものが、delete の応答の URL で消えた（2026-11-27、2.1.332）
- 既にあった 33 本は、一覧の URL から取った ID で書き出した（2026-11-27）

## 影響

- Artifact ツールの説明は、`url` に渡せる形として `claude.ai/artifact/{id}` と `claude.ai/code/artifact/{uuid}` の 2 つを挙げている（2026-11-27、2.1.332）。後者の形の URL が応答に返ると、同じ Artifact が UUID の名前で写る。2026-11-27 に確かめた 34 本と試験用の 1 本は、すべて `https://claude.ai/artifact/<ID>` の形で、後者の形が返るのは見ていない
- homebase の docs は「Artifact の ID」とだけ書いていて、どちらの ID かは書いていない

## 決定しないこと

- UUID の形の URL が返ったときの扱い: 書き出し先に UUID の形の名前のフォルダができたら決め直す。それまでは受け入れる。そのフォルダは一覧に無い名前なので、次の同期で消える（ADR-20261127-0003 の「決定」2）
- URL の形がほかに変わったときの扱い: hook が ID を取り出せないという警告を出したら決め直す
