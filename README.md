<div align="center">

# dotfiles

**nix-darwin + home-manager で宣言的に管理する、個人用の macOS 開発環境**

[![nix-check](https://github.com/yoshihiko555/dotfiles/actions/workflows/nix-check.yml/badge.svg)](https://github.com/yoshihiko555/dotfiles/actions/workflows/nix-check.yml)
[![Nix flakes](https://img.shields.io/badge/Nix-flakes-5277C3?logo=nixos&logoColor=white)](config/nix/README.md)
[![nix-darwin](https://img.shields.io/badge/nix--darwin-home--manager-7EBAE4?logo=nixos&logoColor=white)](config/nix/README.md)
[![macOS](https://img.shields.io/badge/macOS-Apple_Silicon-000000?logo=apple&logoColor=white)](#-管理対象ホスト)
[![Neovim](https://img.shields.io/badge/Neovim-57A143?logo=neovim&logoColor=white)](config/nvim/README.md)
[![Claude Code](https://img.shields.io/badge/Claude_Code-Codex_%C2%B7_Antigravity-D97757?logo=anthropic&logoColor=white)](#-ai-エージェント資産)

[特徴](#-特徴) ·
[セットアップ](#-セットアップ) ·
[構成](#-ディレクトリ構成) ·
[Taskfile](#-taskfile-コマンド) ·
[配線](#-home-manager-の配線) ·
[AI エージェント](#-ai-エージェント資産) ·
[ドキュメント](#-関連ドキュメント)

</div>

---

## ✨ 特徴

- **宣言的に再現できる** — CLI・GUI（Homebrew cask）・dotfiles の配線をホストごとに Nix flake で定義し、`switch` 1 回で揃える
- **編集が即時反映される** — 通常の設定は `mkOutOfStoreSymlink` でリポジトリを直接指すため、編集に `switch` は要らない
- **アプリが書き換える設定も repo で持つ** — Claude Code / Antigravity の JSON と Loupedeck Live は drift を検知し、BetterTouchTool も含めて `task` で repo へ回収する
- **AI エージェント資産を一元管理する** — Claude Code / Codex / Antigravity のコンテキスト・スキル・MCP・プラグインを `shared/` から配る
- **整形を CI で守る** — treefmt で nix / shell / yaml / toml を整形し、[pre-commit フック](.githooks/pre-commit)と [GitHub Actions](.github/workflows/nix-check.yml) で検査する

## 💻 管理対象ホスト

| ホスト | 方式（flake の出力） | 役割 |
|---|---|---|
| MacBook Pro | nix-darwin + home-manager（`macbook`） | メイン開発機。GUI アプリ・AI CLI・Alfred などを含む |
| Mac mini（hermes） | nix-darwin + home-manager（`hermes`） | 常時稼働機。LLM 基盤（llama.cpp / llama-swap）を launchd で宣言管理 |
| 会社 Windows（WSL2） | standalone home-manager（`homeConfigurations.wsl`） | WSL2 内部の開発環境 |

ホストごとの管理範囲は [Nix の README](config/nix/README.md)、導入当時の判断と実施結果は[移行記録](config/nix/docs/ROADMAP.md)を参照。

## 🚀 セットアップ

### 新しい MacBook の初回構築

Apple Silicon の MacBook で、`sudo` が使える状態から始める。
この構成は設定を配るアカウントとホームを固定している。初回適用の前に、
`id -un`、ホームディレクトリ、clone 先が [MacBook のホスト定義](config/nix/hosts/macbook/default.nix) と一致することを確認する。
Mac mini は [hermes の構築手順](config/nix/docs/BOOTSTRAP.md)、
会社の Windows は [WSL2 の構築手順](config/nix/docs/BOOTSTRAP-WSL2.md) を参照。

1. ターミナルで Command Line Tools を入れ、インストール画面が完了するまで待つ。

   ```sh
   xcode-select --install
   ```

2. GUI アプリの導入に使う Homebrew と、flakes を有効にした Nix を入れる。[Homebrew 公式](https://brew.sh/)・[Nix インストーラ公式](https://github.com/NixOS/nix-installer)

   ```sh
   /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
   eval "$(/opt/homebrew/bin/brew shellenv)"
   curl -sSfL https://channels.nixos.org/nix-latest/nix-installer | sh -s -- install --enable-flakes
   ```

3. 新しいターミナルを開き、設定が参照するパスに clone してビルドする。

   ```sh
   nix --version
   git clone https://github.com/yoshihiko555/dotfiles.git ~/ghq/github.com/yoshihiko555/dotfiles
   cd ~/ghq/github.com/yoshihiko555/dotfiles
   nix build ./config/nix#darwinConfigurations.macbook.system
   ```

4. ビルドが成功したら、同じディレクトリで既存のシステム用 zsh 設定を退避し、初回の構成を適用する。

   ```sh
   for config_file in /etc/zshenv /etc/zshrc /etc/zprofile; do
     if [ -f "$config_file" ]; then
       sudo mv -n "$config_file" "$config_file.before-nix-darwin"
     fi
   done
   sudo ./result/sw/bin/darwin-rebuild switch --flake ./config/nix#macbook
   ```

5. 新しいターミナルで言語ランタイムを入れ、設定のリンク先と反映状況を確認する。

   ```sh
   cd ~/ghq/github.com/yoshihiko555/dotfiles
   mise install
   task status
   ```

6. 使う GUI アプリの手動導入・ライセンス認証を済ませる。BetterTouchTool は起動と権限付与のあとでトリガーを復元する。
   Loupedeck のプロファイルは Git 管理外なので、使う場合は旧 Mac の `config/loupedeck/` を引き継ぐ。
   [手動導入アプリ一覧](config/nix/docs/MANUAL-APPS.md)・[BetterTouchTool の復元手順](config/nix/docs/BOOTSTRAP.md#bettertouchtool-の設定)

## 🧰 主なツール

| 分類 | ツール | 設定 |
|---|---|---|
| シェル | zsh · sheldon · starship | [zsh の起動設定](shell/README.md) · [プラグインの読み込み順](config/sheldon/plugins.toml) · [プロンプトの表示設定](config/starship/starship.toml) |
| ターミナル | **Ghostty + herdr**（常用）/ WezTerm + tmux（サブ） | [`config/ghostty/`](config/ghostty/README.md) · [`config/herdr/`](config/herdr/README.md) · [`config/wezterm/`](config/wezterm/README.md) · [`config/tmux/`](config/tmux/README.md) |
| エディタ | Neovim · Zed | [`config/nvim/`](config/nvim/README.md) · [`config/zed/`](config/zed/README.md) |
| Git | git · lazygit · gh | [`config/git/`](config/git/README.md) · [`config/lazygit/`](config/lazygit/README.md) · [`config/gh/config.yml`](config/gh/config.yml) |
| ウィンドウ・入力 | AeroSpace · Karabiner-Elements · BetterTouchTool | [ウィンドウ配置](config/aerospace/README.md) · [キー割り当て](config/karabiner/karabiner.json) · [トリガーの回収・復元](config/nix/docs/BOOTSTRAP.md#bettertouchtool-の設定) |
| ランタイム | mise | [言語ランタイムと CLI のバージョン設定](config/mise/config.toml) |
| AI エージェント | Claude Code · Codex CLI · Antigravity CLI · pi · takt · opencode | [`claude/`](claude/README.md) · [`codex/`](codex/README.md) · [`gemini/`](gemini/README.md) · [`pi/`](pi/README.md) · [`takt/`](takt/README.md) · [`config/opencode/`](config/opencode/README.md) |
| ランチャー | Alfred | [`alfred/`](alfred/README.md) |
| デバイス | Loupedeck Live | [プロファイルの回収・反映](taskfiles/dotfiles.yml)（`task loupedeck-export` / `task loupedeck-apply`）。保存先の `config/loupedeck/` は Git 管理外 |

## 📁 ディレクトリ構成

```
dotfiles/
├── shell/          # zsh の起動設定と自作コマンド → shell/README.md
├── config/         # XDG_CONFIG_HOME 系（→ ~/.config）
│   ├── nix/        # nix-darwin + home-manager の実体 → config/nix/README.md
│   ├── nvim/       # エディタ（Neovim）→ config/nvim/README.md
│   ├── herdr/      # ターミナルマルチプレクサ（常用）。プラグイン一覧・通知・自作スクリプト
│   ├── btt/        # BetterTouchTool のトリガー（switch 時に実機へ適用）
│   ├── loupedeck/  # Loupedeck Live のプロファイル（git 管理外）
│   └── ...         # ghostty, wezterm, tmux, starship, mise, sheldon, karabiner,
│                   # aerospace, lazygit, opencode, zed, gh, git
├── ssh/            # ~/.ssh/config に配る SSH クライアント設定
├── home/           # $HOME 直下に置く単体ファイル（editorconfig）
├── claude/         # Claude Code 個人用（→ ~/.claude）
├── claude-work/    # Claude Code 会社用（→ ~/.claude-work）
├── codex-work/     # Codex CLI 会社用設定（→ ~/.codex-work/config.toml）
├── codex/          # Codex CLI（→ ~/.codex）
├── gemini/         # Gemini / Antigravity CLI（→ ~/.gemini）→ gemini/README.md
├── pi/             # pi の設定・エージェントルール・スキル
├── takt/           # takt CLI（→ ~/.takt）→ takt/README.md
├── shared/         # 共通データの実体（agents / skills / mcp / plugins / cliproxyapi）
├── alfred/         # Alfred ワークフロー → alfred/README.md
├── docs/           # Codex のブラウザ自動操作手順・領域をまたぐ ADR
├── taskfiles/      # Taskfile.yml から読み込むタスク定義
├── scripts/        # タスクから呼ぶスクリプト（shell / Python）とテスト
├── .githooks/      # pre-commit（treefmt の整形崩れを検出）
├── .github/        # CI（nix-check.yml）
└── .sops.yaml      # sops-nix の暗号化ルール（仕組みのみ。管理対象の秘匿値は無い）
```

SSH の接続先は [ssh/config](ssh/config)、エディタ共通の書式は [home/editorconfig](home/editorconfig) で変更する。
各 CLI に配るルールとスキルの編集先・反映手順は [共通ルール・スキルの管理](shared/README.md) を参照。

## 📋 Taskfile コマンド

リポジトリのルートで `task --list` を実行すると、タスク名と説明を確認できる。処理を変更するときは、[タスク定義](taskfiles/)から、そこで呼び出す[スクリプト](scripts/)をたどる。

## 🔗 home-manager の配線

配線の定義そのものが正典で、README にパス一覧は持たない。

| ファイル | 役割 |
|---|---|
| [config/nix/home/dotfiles.nix](config/nix/home/dotfiles.nix) | 2 台以上で使う共通配線（zsh, git, mise, nvim, starship, tmux） |
| [config/nix/hosts/macbook/dotfiles.nix](config/nix/hosts/macbook/dotfiles.nix) | MacBook 固有（GUI 系 config, AI CLI, ssh, Alfred, BTT / Loupedeck / herdr プラグインの同期） |
| [config/nix/hosts/hermes/dotfiles.nix](config/nix/hosts/hermes/dotfiles.nix) | hermes 固有 |

設定の反映・回収方法は [Nix の領域 README](config/nix/README.md#設定の反映方式) を参照。

## 🤖 AI エージェント資産

Claude Code / Codex / Antigravity（Gemini）/ pi に配るルールとスキルは `shared/` で管理する。
個人用の Claude Code / Codex では MCP とプラグインも共通定義から同期する。

- [共通ルール・スキルの管理](shared/README.md)
- [個人用 MCP の登録・同期](shared/mcp/README.md) と [プラグイン管理](shared/plugins/README.md)
- [CLIProxyAPI の初回設定と ccx の使い方](shared/cliproxyapi/README.md)
- [Claude Code の会社アカウントとプロファイル](claude/README.md)
- [Codex CLI の会社アカウント](codex-work/README.md)

## 📚 関連ドキュメント

| ドキュメント | 内容 |
|---|---|
| [config/nix/README.md](config/nix/README.md) | nix-darwin + home-manager の構成・管理対象ホスト |
| [config/nix/docs/](config/nix/docs/) | BOOTSTRAP / CHEATSHEET / GUIDE / ROADMAP / ADR |
| [config/nix/patches/README.md](config/nix/patches/README.md) | 上流未修正の問題に対する暫定パッチ |
| [config/nvim/README.md](config/nvim/README.md) | Neovim のプラグイン一覧・キーバインドチートシート・練習問題・ADR |
| [config/tmux/README.md](config/tmux/README.md) | tmux の操作・設定の保守・移行記録 |
| [config/wezterm/README.md](config/wezterm/README.md) | WezTerm（tmux-first）の設定 |
| [config/aerospace/docs/CHEATSHEET.md](config/aerospace/docs/CHEATSHEET.md) | AeroSpace のチートシート |
| [Yazi](config/yazi/README.md) | ファイルマネージャーの設定 |
| [config/lazygit/CHEATSHEET.md](config/lazygit/CHEATSHEET.md) | lazygit のチートシート |
| [shell/zsh/README.md](shell/zsh/README.md) | zsh 分割設定と `wt` / `repo` などの自作コマンド |
| [shared/mcp/README.md](shared/mcp/README.md) | 個人用グローバル MCP の共通定義と同期 |
| [shared/plugins/README.md](shared/plugins/README.md) | Claude Code / Codex の共通プラグイン管理 |
| [claude/plugins/turn-receipt/README.md](claude/plugins/turn-receipt/README.md) | ターンごとの編集・実行件数を表示する自作 mod |
| [takt/README.md](takt/README.md) | takt の起動・SDK 更新・作業クローンの配置。プロバイダ設定と権限・MCP の手順へのリンク |
| [gemini/README.md](gemini/README.md) | Antigravity CLI の起動、設定の反映・回収、権限設計の ADR |
| [alfred/README.md](alfred/README.md) | Alfred ワークフロー詳細 |
| [Codex のブラウザ自動操作](docs/agent-browser-docker.md) | macOS の制限付き環境で agent-browser を使うときの Docker の準備と操作 |
| [docs/adr/DECISIONS.md](docs/adr/DECISIONS.md) | 領域をまたぐ決定の一覧と、各領域の ADR 索引へのリンク |
| [claude/docs/adr/DECISIONS.md](claude/docs/adr/DECISIONS.md) | Claude Code 設定の ADR 索引 |
