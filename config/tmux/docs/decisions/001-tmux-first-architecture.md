# ADR-001: tmux-first アーキテクチャの採用

- **状態**: 承認
- **日付**: 2026-03-16
- **関連**: 移行計画原本 (`digital-garden/content/notes/tech/2026-03-16_tmux-migration-plan.md`)

## コンテキスト

WezTerm の Lua カスタマイズで以下を実現していた:

- ワークスペース管理 (GHQ プロジェクト選択, worktree 対応)
- ペインレイアウト (split, overlay, smart-splits)
- ステータスバー (セッションタブ, baton 統合, leader 表示)
- コマンドパレット
- セッション復元

しかし以下の課題があった:

- **ターミナルエミュレータへのロックイン**: WezTerm 固有の Lua API に強く依存
- **SSH/リモート環境で使えない**: WezTerm のワークスペース管理はローカル専用
- **tmux との二重管理**: WezTerm のペイン管理と tmux が競合する場面がある
- **保守コストの増大**: Lua モジュールが 10+ ファイルに膨張

## 決定

tmux をセッション/ペイン管理の中心に据え、WezTerm は GUI レンダラーに限定する。

### 理由

1. **ポータビリティ**: tmux は SSH 先でもローカルでも同じ操作体験
2. **エコシステム**: TPM プラグイン (resurrect, fingers 等) で機能を補完可能
3. **シンプル**: シェルスクリプト + fzf で拡張。Lua より透明性が高い
4. **AI ツール統合**: claude-squad 等の tmux ネイティブツールを活用可能

## 影響

### 得るもの

- ターミナルエミュレータの差し替え自由度
- SSH 環境での同一操作体験
- tmux エコシステムの活用
- シェルスクリプトによる高い透明性と拡張性

### 失うもの

- WezTerm Lua の柔軟な GUI カスタマイズ (ただし GUI レンダラーとしては継続利用)
- WezTerm ネイティブの QuickSelect (tmux-fingers で代替)
- WezTerm のネイティブタブ (tmux セッションタブで代替)

### リスク

- tmux のネスト問題 (SSH 先で tmux in tmux)
- WezTerm 透過/背景画像が tmux 越しで劣化する可能性
- 移行期間中の操作体験の一時的な低下

## 代替案

1. **WezTerm のまま改善**: Lua モジュールを整理して続ける → ロックイン解消にならない
2. **Zellij に移行**: Rust 製の新しいマルチプレクサ → プラグインエコシステムが未成熟
3. **tmux + Zellij 併用**: → 複雑性が増すだけ
