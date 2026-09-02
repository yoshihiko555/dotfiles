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
        "aerospace".source = mkLink "config/aerospace";
        "gh/config.yml".source = mkLink "config/gh/config.yml";
        "ghostty".source = mkLink "config/ghostty";
        "karabiner".source = mkLink "config/karabiner";
        "lazygit".source = mkLink "config/lazygit";
        "nix".source = mkLink "config/nix";
        "opencode/opencode.json".source = mkLink "config/opencode/opencode.json";
        "sheldon".source = mkLink "config/sheldon";
        "wezterm".source = mkLink "config/wezterm";
        "zed/keymap.json".source = mkLink "config/zed/keymap.json";
        "zed/settings.json".source = mkLink "config/zed/settings.json";
      };

      # CLI が生成する履歴・認証情報・キャッシュは各ディレクトリに残し、
      # リポジトリで管理するエントリだけを個別に配線する。
      home.file = {
        ".editorconfig".source = mkLink "home/editorconfig";

        # 中身は IP・ホスト名のみで秘匿情報ではないため平文配線。sops-nix の
        # 仕組み自体は導入済み（flake.nix / .sops.yaml）なので、将来 GitHub
        # Packages トークンのような本物の秘密が必要になれば sops.secrets へ
        # 切り替えられる（Phase 4-5, 2026-08-14 の方針転換。詳細は ROADMAP 参照）
        ".ssh/config".source = mkLink "ssh/config";

        ".claude/.mcp.json".source = mkLink "claude/.mcp.json";
        ".claude/CLAUDE.md".source = mkLink "claude/CLAUDE.md";
        ".claude/agents".source = mkLink "claude/agents";
        ".claude/claude_message.sh".source = mkLink "claude/claude_message.sh";
        ".claude/docs".source = mkLink "claude/docs";
        ".claude/hooks".source = mkLink "claude/hooks";
        ".claude/rules".source = mkLink "claude/rules";
        ".claude/skills".source = mkLink "claude/skills";
        ".claude/statusline.py".source = mkLink "claude/statusline.py";
        ".claude/templates".source = mkLink "claude/templates";

        # 会社アカウント用（ccw / CLAUDE_CONFIG_DIR=~/.claude-work）。
        # statusline.py と claude_message.sh は ~/.claude 非依存のため実体を共有する。
        # skills は task sync-claude-work-skills が管理するのでここでは触らない。
        ".claude-work/CLAUDE.md".source = mkLink "claude-work/CLAUDE.md";
        ".claude-work/rules".source = mkLink "claude-work/rules";
        ".claude-work/claude_message.sh".source = mkLink "claude/claude_message.sh";
        ".claude-work/hooks".source = mkLink "claude/hooks";
        ".claude-work/statusline.py".source = mkLink "claude/statusline.py";

        ".codex/AGENTS.md".source = mkLink "codex/AGENTS.md";
        ".codex/codex_message.sh".source = mkLink "codex/codex_message.sh";
        ".codex/config.toml".source = mkLink "codex/config.toml";
        ".codex/rules".source = mkLink "codex/rules";
        ".codex/skills".source = mkLink "codex/skills";

        ".gemini/AGENTS.md".source = mkLink "gemini/AGENTS.md";
        ".gemini/antigravity/mcp_config.json".source = mkLink "gemini/antigravity/mcp_config.json";
        ".gemini/config/skills".source = mkLink "gemini/config/skills";
        ".gemini/settings.json".source = mkLink "gemini/settings.json";

        ".takt/config.yaml".source = mkLink "takt/config.yaml";

        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.C9692AD7-2800-42B7-8F97-8F8CCD1CC88E".source =
          mkLink "alfred/Open-VS-or-IT";
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.D644F268-263B-4B05-929D-7E80AEA91BC0".source =
          mkLink "alfred/audio-output";
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.455DAC0F-6957-4573-9A95-565C76C88D28".source =
          mkLink "alfred/post";
        # Notion トークンは info.plist ではなく Alfred の Workflow Configuration
        # （workflow ディレクトリ内の prefs.plist）に置く。public リポジトリなので
        # 当該ファイルは .gitignore で除外している
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.CC5F7378-77EC-4037-B0BD-499DBF07983D".source =
          mkLink "alfred/fast-notion";
        "Dropbox/02_Private/08_Settings/02_Alfred/Alfred.alfredpreferences/workflows/user.workflow.5B4C6E9B-E7D8-4A26-BDE6-653EFD05231D".source =
          mkLink "alfred/github-repo";
      };

      # Claude Code / Antigravity CLI は JSON を rename で置換するため、symlink では
      # 管理できない。repo を正として実ファイルを生成し、前回 switch 時の参照コピーと
      # 差がある間は上書きを拒否する。repo へ回収後は target == source になるため再開できる。
      home.activation.mutableDotfiles = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        json_equal() {
          left="$1"
          right="$2"
          # 第3引数: 比較前に適用する jq フィルタ（省略時は全体を比較）
          filter="''${3:-.}"
          left_normalized="$(${pkgs.coreutils}/bin/mktemp)"
          right_normalized="$(${pkgs.coreutils}/bin/mktemp)"

          if ${pkgs.jq}/bin/jq -S "$filter" "$left" > "$left_normalized" 2>/dev/null \
            && ${pkgs.jq}/bin/jq -S "$filter" "$right" > "$right_normalized" 2>/dev/null; then
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
          # 第5引数: repo では管理せず実ファイル側の値を引き継ぐトップレベルキー。
          # 空白区切りで複数指定できる。Claude Code が自動生成する autoMode や
          # modelSettings のように、public リポジトリへ載せたくない・端末側で
          # 書き換わる内容を drift 比較からも除外する用途で使う。
          preserve="''${5:-}"

          compare_filter="."
          preserve_keys_json="[]"
          if [ -n "$preserve" ]; then
            del_args=""
            for key in $preserve; do
              if [ -n "$del_args" ]; then
                del_args="$del_args,"
              fi
              del_args="$del_args.$key"
            done
            compare_filter="del($del_args)"
            preserve_keys_json="$(printf '%s\n' $preserve \
              | ${pkgs.jq}/bin/jq -R . | ${pkgs.jq}/bin/jq -s -c .)"
          fi

          if ! ${pkgs.jq}/bin/jq -e . "$source" >/dev/null 2>&1; then
            echo "warning: $label: repo 側が不正な JSON のため更新を拒否しました: $source" >&2
            return 0
          fi

          ${pkgs.coreutils}/bin/mkdir -p "''${target%/*}"

          if [ -e "$target" ] && [ ! -f "$target" ]; then
            echo "warning: $label: 通常ファイルではないため更新を拒否しました: $target" >&2
            return 0
          fi

          if [ -f "$target" ] && [ -f "$reference" ] \
            && ! json_equal "$target" "$reference" "$compare_filter"; then
            if ! json_equal "$target" "$source" "$compare_filter"; then
              echo "warning: $label の drift を検出。上書きしません。" >&2
              echo "warning: task adopt-settings TARGET=$label で repo へ回収してから再度 switch してください。" >&2
              return 0
            fi
          elif [ -f "$target" ] && [ ! -f "$reference" ] \
            && ! json_equal "$target" "$source" "$compare_filter"; then
            echo "warning: $label: 初回管理時の既存内容が repo と異なるため上書きしません。" >&2
            echo "warning: 内容を確認し、task adopt-settings TARGET=$label で回収してください。" >&2
            return 0
          fi

          # 引き継ぎは target を消す前に済ませる
          generated="$source"
          if [ -n "$preserve" ] && [ -f "$target" ]; then
            generated="$(${pkgs.coreutils}/bin/mktemp)"
            ${pkgs.jq}/bin/jq -s --argjson keys "$preserve_keys_json" \
              '.[0] + (.[1] | with_entries(select(.key as $k | $keys | index($k) != null)))' \
              "$source" "$target" > "$generated"
          fi

          if [ -L "$target" ]; then
            ${pkgs.coreutils}/bin/rm -f "$target"
          fi

          ${pkgs.coreutils}/bin/install -m 0644 "$generated" "$target"
          ${pkgs.coreutils}/bin/install -m 0644 "$generated" "$reference"
          if [ "$generated" != "$source" ]; then
            ${pkgs.coreutils}/bin/rm -f "$generated"
          fi
        }

        manage_mutable_json \
          claude \
          "${dotfilesDir}/claude/settings.json" \
          "$HOME/.claude/settings.json" \
          "$HOME/.claude/.settings.json.nix-managed"
        manage_mutable_json \
          claude-work \
          "${dotfilesDir}/claude-work/settings.json" \
          "$HOME/.claude-work/settings.json" \
          "$HOME/.claude-work/.settings.json.nix-managed" \
          "autoMode modelSettings"
        manage_mutable_json \
          antigravity-settings \
          "${dotfilesDir}/gemini/antigravity-cli/settings.json" \
          "$HOME/.gemini/antigravity-cli/settings.json" \
          "$HOME/.gemini/antigravity-cli/.settings.json.nix-managed"
        manage_mutable_json \
          antigravity-keybindings \
          "${dotfilesDir}/gemini/antigravity-cli/keybindings.json" \
          "$HOME/.gemini/antigravity-cli/keybindings.json" \
          "$HOME/.gemini/antigravity-cli/.keybindings.json.nix-managed"
      '';

      # BetterTouchTool の設定実体は SQLite（ファイル名にバージョン番号が入る）
      # なので symlink でも実ファイル生成でも管理できない。AppleScript API 経由で
      # repo の JSON を流し込む。判定ロジックは task btt-apply と共有したいので
      # ここではスクリプトを呼ぶだけに留める。
      #
      # BTT 未起動・未インストール時はスクリプト側が警告して抜けるため switch は
      # 止まらない。新規マシンでは初回に Automation の許可ダイアログが出る。
      home.activation.bttSync = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        JQ=${pkgs.jq}/bin/jq \
          ${pkgs.bash}/bin/bash "${dotfilesDir}/scripts/btt-sync.sh" apply || true
      '';
    };
}
