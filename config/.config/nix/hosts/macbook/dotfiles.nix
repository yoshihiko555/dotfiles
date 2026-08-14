{ config, ... }:
let
  username = config.hostSpec.username;
  dotfilesDir = config.hostSpec.dotfilesDir;
in
{
  home-manager.users.${username} =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    in
    {
      # MacBook 固有の XDG 設定。git / mise / nvim / starship / tmux は
      # 2 台以上で使うため home/dotfiles.nix の共通層で配線する。
      xdg.configFile = {
        "aerospace".source = mkLink "config/.config/aerospace";
        "gh/config.yml".source = mkLink "config/.config/gh/config.yml";
        "ghostty".source = mkLink "config/.config/ghostty";
        "karabiner".source = mkLink "config/.config/karabiner";
        "lazygit".source = mkLink "config/.config/lazygit";
        "nix".source = mkLink "config/.config/nix";
        "opencode/opencode.json".source = mkLink "config/.config/opencode/opencode.json";
        "sheldon".source = mkLink "config/.config/sheldon";
        "wezterm".source = mkLink "config/.config/wezterm";
        "zed/keymap.json".source = mkLink "config/.config/zed/keymap.json";
        "zed/settings.json".source = mkLink "config/.config/zed/settings.json";
      };

      # CLI が生成する履歴・認証情報・キャッシュは各ディレクトリに残し、
      # リポジトリで管理するエントリだけを個別に配線する。
      home.file = {
        ".editorconfig".source = mkLink "editorconfig/.editorconfig";

        ".claude/.mcp.json".source = mkLink "claude/.claude/.mcp.json";
        ".claude/CLAUDE.md".source = mkLink "claude/.claude/CLAUDE.md";
        ".claude/agents".source = mkLink "claude/.claude/agents";
        ".claude/claude_message.sh".source = mkLink "claude/.claude/claude_message.sh";
        ".claude/docs".source = mkLink "claude/.claude/docs";
        ".claude/hooks".source = mkLink "claude/.claude/hooks";
        ".claude/rules".source = mkLink "claude/.claude/rules";
        ".claude/skills".source = mkLink "claude/.claude/skills";
        ".claude/statusline.py".source = mkLink "claude/.claude/statusline.py";
        ".claude/templates".source = mkLink "claude/.claude/templates";

        ".codex/AGENTS.md".source = mkLink "codex/.codex/AGENTS.md";
        ".codex/codex_message.sh".source = mkLink "codex/.codex/codex_message.sh";
        ".codex/config.toml".source = mkLink "codex/.codex/config.toml";
        ".codex/rules".source = mkLink "codex/.codex/rules";
        ".codex/skills".source = mkLink "codex/.codex/skills";

        ".gemini/AGENTS.md".source = mkLink "gemini/.gemini/AGENTS.md";
        ".gemini/antigravity/mcp_config.json".source = mkLink "gemini/.gemini/antigravity/mcp_config.json";
        ".gemini/config/skills".source = mkLink "gemini/.gemini/config/skills";
        ".gemini/settings.json".source = mkLink "gemini/.gemini/settings.json";

        ".takt/config.yaml".source = mkLink "takt/.takt/config.yaml";

        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.C9692AD7-2800-42B7-8F97-8F8CCD1CC88E".source =
          mkLink "alfred/Open-VS-or-IT";
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.D644F268-263B-4B05-929D-7E80AEA91BC0".source =
          mkLink "alfred/audio-output";
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.455DAC0F-6957-4573-9A95-565C76C88D28".source =
          mkLink "alfred/post";
      };

      # Claude Code / Antigravity CLI は JSON を rename で置換するため、symlink では
      # 管理できない。repo を正として実ファイルを生成し、前回 switch 時の参照コピーと
      # 差がある間は上書きを拒否する。repo へ回収後は target == source になるため再開できる。
      home.activation.mutableDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        json_equal() {
          left="$1"
          right="$2"
          left_normalized="$(${pkgs.coreutils}/bin/mktemp)"
          right_normalized="$(${pkgs.coreutils}/bin/mktemp)"

          if ${pkgs.jq}/bin/jq -S . "$left" > "$left_normalized" 2>/dev/null \
            && ${pkgs.jq}/bin/jq -S . "$right" > "$right_normalized" 2>/dev/null; then
            if ${pkgs.diffutils}/bin/cmp -s "$left_normalized" "$right_normalized"; then
              equal=0
            else
              equal=1
            fi
          elif ${pkgs.diffutils}/bin/cmp -s "$left" "$right"; then
            equal=0
          else
            equal=1
          fi

          ${pkgs.coreutils}/bin/rm -f "$left_normalized" "$right_normalized"
          return "$equal"
        }

        manage_mutable_json() {
          label="$1"
          source="$2"
          target="$3"
          reference="$4"

          if ! ${pkgs.jq}/bin/jq -e . "$source" >/dev/null 2>&1; then
            echo "warning: $label: repo 側が不正な JSON のため更新を拒否しました: $source" >&2
            return 0
          fi

          ${pkgs.coreutils}/bin/mkdir -p "''${target%/*}"

          if [ -e "$target" ] && [ ! -f "$target" ]; then
            echo "warning: $label: 通常ファイルではないため更新を拒否しました: $target" >&2
            return 0
          fi

          if [ -f "$target" ] && [ -f "$reference" ] && ! json_equal "$target" "$reference"; then
            if ! json_equal "$target" "$source"; then
              echo "warning: $label の drift を検出。上書きしません。" >&2
              echo "warning: task adopt-settings TARGET=$label で repo へ回収してから再度 switch してください。" >&2
              return 0
            fi
          elif [ -f "$target" ] && [ ! -f "$reference" ] && ! json_equal "$target" "$source"; then
            echo "warning: $label: 初回管理時の既存内容が repo と異なるため上書きしません。" >&2
            echo "warning: 内容を確認し、task adopt-settings TARGET=$label で回収してください。" >&2
            return 0
          fi

          if [ -L "$target" ]; then
            ${pkgs.coreutils}/bin/rm -f "$target"
          fi
          ${pkgs.coreutils}/bin/install -m 0644 "$source" "$target"
          ${pkgs.coreutils}/bin/install -m 0644 "$source" "$reference"
        }

        manage_mutable_json \
          claude \
          "${dotfilesDir}/claude/.claude/settings.json" \
          "$HOME/.claude/settings.json" \
          "$HOME/.claude/.settings.json.nix-managed"
        manage_mutable_json \
          antigravity-settings \
          "${dotfilesDir}/gemini/.gemini/antigravity-cli/settings.json" \
          "$HOME/.gemini/antigravity-cli/settings.json" \
          "$HOME/.gemini/antigravity-cli/.settings.json.nix-managed"
        manage_mutable_json \
          antigravity-keybindings \
          "${dotfilesDir}/gemini/.gemini/antigravity-cli/keybindings.json" \
          "$HOME/.gemini/antigravity-cli/keybindings.json" \
          "$HOME/.gemini/antigravity-cli/.keybindings.json.nix-managed"
      '';
    };
}
