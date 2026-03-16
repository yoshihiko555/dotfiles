# ADR-004: Prefix キーを Ctrl+T に変更

- **状態**: 承認・実施済み (暫定)
- **日付**: 2026-03-17

## コンテキスト

tmux の Prefix を `Ctrl+Q` に設定していたが、WezTerm の Leader キーも `Ctrl+Q` であり衝突していた。WezTerm が先にキーを捕捉するため、tmux の Prefix が機能しない状態だった。

## 選択肢

| キー | 評価 |
|------|------|
| `Ctrl+Q` | WezTerm Leader と衝突。不可 |
| `Ctrl+A` | macOS のキーバインド (行頭移動) と衝突 |
| `Ctrl+Space` | macOS の入力ソース切替と衝突の可能性 |
| `Ctrl+S` | `stty -ixon` で使用可能だが、押しづらい |
| `Ctrl+T` | main ブランチで既に使用中。WezTerm と衝突なし |

## 決定

`Ctrl+T` を Prefix に採用。main ブランチとの整合性があり、WezTerm のキーバインドと衝突しない。

### 暫定の理由

- WezTerm の Leader (`Ctrl+Q`) を将来的に削除/変更する可能性がある (Phase 6)
- その時点で Prefix の再検討を行う

## 影響

- `keybinds.conf` の Prefix を `C-t` に変更
- `.zshrc` の `stty -ixon` は引き続き必要 (Ctrl+Q の XON/XOFF 解放のため)
