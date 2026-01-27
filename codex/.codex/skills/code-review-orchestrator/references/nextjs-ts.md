# Next.js/TypeScript レビュー観点

## 正しさ
- Server/Client Component の境界が正しいか
- useEffect 依存配列の漏れや無限ループ
- 例外/エラー境界の欠如（error.tsx, not-found.tsx）

## セキュリティ
- 入力値の検証/サニタイズ
- 認可ガードの漏れ

## 性能
- 不要な再レンダリング
- fetch キャッシュ/再検証の設定

## 設計/可読性
- 型定義が一貫しているか
- ディレクトリ構成の責務が守られているか
