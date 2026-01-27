---
name: frontend-test-author
description: Frontend (Next.js/React) のテスト作成・修正を行うスキル。UI/画面/featureサービス/coreユースケースのテスト追加、既存テストの失敗修正、Vitest+Testing Libraryのセットアップやテスト配置判断が必要なときに使用する。
---

# Frontend Test Author

## Overview

フロントエンドの単体・結合テストを最小構成で追加・修正し、CIで安定して通る状態にする。

## Workflow

1) 対象と責務を決める  
- UIコンポーネント: `frontend/src/tests/components/**`  
- 画面/ドメイン: `frontend/src/tests/features/<domain>/**`  
  - 画面: `screens/`  
  - サービス(API): `services/`  
- コアユースケース: `frontend/src/tests/core/usecases/**`  
- E2Eは `frontend/src/e2e/**`（依頼がある場合のみ）

2) テスト基盤を確認する  
- `frontend/package.json` に `vitest` / `@testing-library/*` / `jsdom` があるか確認する  
- `frontend/vitest.config.ts` と `frontend/src/tests/setup.tsx` があるか確認する  
- `@/` エイリアスが有効か確認する

3) テスト実装の基本方針  
- `render` / `screen` / `userEvent` を使用する  
- ラベルは正規表現で取得する（`/メールアドレス/` など）  
- 非同期UIは `findByRole` / `waitFor` を使う  
- パスワードの表示トグル等でラベルが衝突する場合は `getByLabelText(/パスワード/, { selector: 'input' })` を使う  
- ネイティブバリデーションで `submit` が止まる場合は `fireEvent.submit(form)` を使う

4) レイヤ別のテストパターン  
- 画面（App Router）  
  - `next/navigation` を `vi.mock` で差し替える  
  - `useRouter` / `useSearchParams` の戻り値を制御する  
- サービス(API)  
  - `apiClient` の `GET/POST` を `vi.spyOn` でモックする  
  - `ensureOk` 由来の `ApiError` を検証する  
- ユースケース  
  - Repositoryインターフェースを `vi.fn()` でモックする  
  - 例外伝播の確認を最小限追加する

5) 実行  
- `cd frontend && npm test`  
- CI用: `cd frontend && npm run test:ci`

## Minimal Examples

### 画面（App Router）
```tsx
import { render, screen } from '@testing-library/react'
import { useRouter } from 'next/navigation'
import { vi } from 'vitest'

vi.mock('next/navigation', () => ({ useRouter: vi.fn() }))
```

### サービス(API)
```ts
import { apiClient } from '@/lib/api/client'
import { vi } from 'vitest'

vi.spyOn(apiClient, 'POST').mockResolvedValue({ data: { accessToken: 'token', user: {} } })
```
