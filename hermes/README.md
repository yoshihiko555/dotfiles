# Hermes CLI subset

> **2026-07-31 以降、非推奨**: このディレクトリの手動コピー方式は
> nix-darwin + home-manager（`config/.config/nix/`）に置き換えられた。
> `install-hermes-subset.sh` の実行は不要。
> `home/.config/tmux/tmux.conf` と `home/.config/mise/config.toml` は
> `hosts/hermes` からの symlink リンク元として参照され続けている。
> ディレクトリは当面残置し、hermes の安定稼働を確認してから削除する（2026-07-31 判断）
> （[ROADMAP.md Phase 3-1](../config/.config/nix/docs/ROADMAP.md) 参照）。

`macmini-hermes` 向けの手動移植セットです。dotfiles として stow せず、必要なファイルだけ `$HOME` に実体コピーします。

## Install

```bash
./scripts/install-hermes-subset.sh
```

Homebrew の CLI 依存も入れる場合:

```bash
./scripts/install-hermes-subset.sh --brew
```

Neovim 設定もコピーする場合:

```bash
./scripts/install-hermes-subset.sh --with-nvim
```

## Included

- `~/.zsh/hermes-helpers.zsh`
- `~/.config/tmux/tmux.conf` (plugin-less minimal config)
- `~/.config/mise/config.toml`
- `~/.config/starship/starship.toml`
- `~/.config/git/ignore`

The installer appends a small source block to `~/.zshrc`.

## Not Included

- GUI configs: Aerospace, Ghostty, WezTerm, Karabiner, Zed
- AI CLI configs: Claude, Codex, Gemini, shared skills
- Machine-specific Git identity or editor settings
- Existing LazyGit custom commands, because they depend on Antigravity
