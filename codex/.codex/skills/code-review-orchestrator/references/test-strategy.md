# テスト/静的解析の提案

## 原則
- 実行はユーザー確認後
- 変更範囲に対応する最小限のテストを提案

## 代表コマンド例
- Go: `go test ./...` / `golangci-lint run`
- Frontend: `npm run lint` / `npm run build`
- Python: `ruff check .` / `black .`

## 変更内容別の提案
- API/仕様変更: ルート/ユースケースのテスト追加
- バリデーション変更: 入力境界のテスト追加
- DB変更: マイグレーションとリポジトリの整合テスト
