あなたはStorybookのメンテナです。
以下の React コンポーネントに対して、Storybook (CSF) の .stories.tsx を生成してください。

必須：
- Default
- Loading（該当する場合）
- Error（該当する場合）
- Empty（該当する場合）
- Edge cases（長文、最小/最大、disabled など）

ルール：
- 表示だけでなく「状態の意図」がわかる stories にする
- args/controls を適切に設定して再利用しやすく
- 可能な限りモックデータを stories 側で閉じる

components/ 配下の以下ファイル一覧に対して、足りない .stories.tsx を一括で作成してください。
既存storiesがあるものは、状態網羅（loading/error/empty/edge）を満たすように更新してください。

出力は「どのファイルを新規/更新するか」→「差分コード」の順で。