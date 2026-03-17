# ADR-006: TPM 導入と Phase 3 プラグイン選定

- **状態**: 承認・実施済み (部分的)
- **日付**: 2026-03-17

## コンテキスト

Phase 3 ではプラグインによる機能拡張を計画していた。移行計画では 4 つのプラグインを候補としていた:

| プラグイン | 用途 |
|-----------|------|
| tmux-resurrect | セッション保存/復元 |
| tmux-continuum | 自動保存 |
| tmux-fingers | 画面内テキスト選択 (QuickSelect 相当) |
| tmux-open | コピーモードから URL/パスを開く |

## 決定

### 導入するもの

- **TPM (Tmux Plugin Manager)**: 自動ブートストラップ方式で導入。`plugins.conf` 内で TPM が未インストールなら自動 clone + プラグインインストールを行う
- **tmux-fingers**: `Prefix+F` で画面内の URL, UUID, ハッシュ等にラベルを付けて選択。WezTerm の QuickSelect に相当
- **tmux-open**: コピーモードで選択したテキストを `o` でブラウザ、`S` で Google 検索

### 後回しにするもの

- **tmux-resurrect / tmux-continuum**: tmux セッションはターミナルを閉じても生存するため、マシン再起動時のみ必要。現時点では優先度が低い

### TPM 自動ブートストラップ

```bash
# TPM がなければ clone
if "test ! -d ~/.tmux/plugins/tpm" \
   "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm'"
# プラグインがなければ自動インストール
if "test ! -d ~/.tmux/plugins/tmux-fingers" \
   "run '~/.tmux/plugins/tpm/bin/install_plugins'"
```

TPM 公式ドキュメントで推奨されている手法。別端末でも tmux 起動時に自動で環境が整う。

## 影響

- tmux-fingers は初回起動時に別途バイナリのインストールが必要 (`brew install` を選択)
- `~/.tmux/plugins/` は dotfiles 管理外 (ランタイム依存)
- resurrect/continuum は将来的にマシン再起動対策が必要になった段階で導入検討
