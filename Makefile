# Bootstrap Makefile
# 初回セットアップ用。日常的なタスクは Taskfile.yml (task コマンド) を使用。

DOTFILES_DIR := $(shell pwd)

.PHONY: bootstrap install-deps link help

help:
	@echo "Bootstrap commands (初回セットアップ用):"
	@echo "  make bootstrap   - 依存ツールをインストールして全パッケージをリンク"
	@echo "  make install-deps - 依存ツール (stow, go-task) をインストール"
	@echo "  make link        - 全パッケージをリンク"
	@echo ""
	@echo "日常的なタスクは 'task --list' を参照してください。"

# 初回セットアップ（依存インストール + リンク）
bootstrap: install-deps link
	@echo ""
	@echo "✅ セットアップ完了！"
	@echo "今後は 'task' コマンドを使用してください。"
	@echo "  task --list  # 利用可能なタスク一覧"

# 依存ツールをインストール
install-deps:
	@echo "📦 依存ツールをインストール中..."
	@command -v brew >/dev/null || (echo "❌ Homebrew が必要です" && exit 1)
	@command -v stow >/dev/null || brew install stow
	@command -v task >/dev/null || brew install go-task
	@echo "✅ 依存ツールのインストール完了"

# 全パッケージをリンク（最小限）
link:
	@echo "🔗 シンボリックリンクを作成中..."
	stow -v -t ~ shell
	stow -v -t ~ config
	stow -v -t ~ claude
	stow -v -t ~ codex
	stow -v -t ~ gemini
	@echo "✅ リンク作成完了"
