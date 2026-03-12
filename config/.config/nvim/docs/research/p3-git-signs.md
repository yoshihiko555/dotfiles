# Phase 3: Git ガターサイン

## 背景

エディタ内でGitの変更状態（追加/変更/削除行）をリアルタイムに可視化し、
hunk単位の操作（ステージ/リセット）やinline blameを行いたい。

## 候補

| プラグイン | Stars | 特徴 | 備考 |
|-----------|-------|------|------|
| gitsigns.nvim | ~6,600 | 全部入り（ガター・blame・hunk操作・word diff）、Pure Lua、依存ゼロ | デファクト標準 |
| mini.diff | ~210 | 軽量、histogram diff、overlay view | inline blame なし、別途プラグイン必要 |
| vgit.nvim | ~840 | ガター + diff preview + git log | plenary 依存、スコープが広すぎる |
| vim-gitgutter | ~8,500 | VimScript、長い歴史 | モダン Neovim では選外 |
| vim-signify | ~2,700 | マルチVCS対応 | VimScript、機能不足 |

## 比較

| 機能 | gitsigns.nvim | mini.diff | vgit.nvim |
|------|---------------|-----------|-----------|
| ガターサイン | Yes | Yes | Yes |
| inline blame | **Yes** | No | Yes |
| word-level diff | **Yes** | No | No |
| hunk stage/unstage | Yes | stage/reset のみ | stage/reset |
| hunk テキストオブジェクト | `ih`/`ah` | あり | なし |
| Pure Lua | Yes | Yes | Yes |
| 外部依存 | なし | なし | plenary + devicons |

## 結論

**gitsigns.nvim を採用**。inline blame + word diff + hunk 操作を単一プラグインで全カバー。
依存ゼロ・Pure Lua・活発なメンテナンスで文句なし。

→ ADR-20260313-009
