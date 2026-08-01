{ config, ... }:
let
  dotfilesDir = config.hostSpec.dotfilesDir;
in
{
  # Hermes Agent の基盤一式（Phase 3-1b で brew から移行、2026-08-01）。
  # gateway 本体（ai.hermes.gateway）は hermes-agent 側の管理に残しており、
  # ここでは LLM / News 配信のデーモンと gateway が必要とする CLI の橋渡しを宣言する。

  home-manager.users.agent =
    { config, pkgs, ... }:
    let
      mkLink = path: config.lib.file.mkOutOfStoreSymlink "${dotfilesDir}/${path}";
    in
    {
      # CLI としても叩けるように per-user profile へ導入
      home.packages = with pkgs; [
        llama-cpp
        llama-swap
        miniserve
      ];

      # llama-swap の設定。cmd の llama-server は裸のコマンド名で書き、
      # 実体は下記 launchd サービスの PATH（Nix ストアの llama-cpp）から解決する。
      # これによりストアパス補間が不要になり、mkOutOfStoreSymlink 原則
      # （編集即反映）を維持できる。
      xdg.configFile."llama-swap/config.yaml".source =
        mkLink "config/.config/nix/hosts/hermes/llama-swap-config.yaml";

      # ai.hermes.gateway（Hermes Agent 本体、hermes-agent 側管理の launchd）の
      # PATH は ~/.local/bin を含むが Nix の per-user profile を含まない。
      # gateway が gh を発見できるよう、安定パス（/etc/profiles/per-user）への
      # symlink を ~/.local/bin に置く。plist が再生成されても壊れない。
      home.file.".local/bin/gh".source =
        config.lib.file.mkOutOfStoreSymlink "/etc/profiles/per-user/agent/bin/gh";

      # 旧 ~/Library/LaunchAgents/com.user.llama-swap.plist（手書き）を置き換える宣言。
      # Label / ログパス / KeepAlive は旧 plist と同一に保つ。
      launchd.agents."com.user.llama-swap" = {
        enable = true;
        config = {
          Label = "com.user.llama-swap";
          ProgramArguments = [
            "${pkgs.llama-swap}/bin/llama-swap"
            "--config"
            "/Users/agent/.config/llama-swap/config.yaml"
            "--listen"
            "127.0.0.1:8080"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          StandardOutPath = "/Users/agent/Library/Logs/llama-swap.log";
          StandardErrorPath = "/Users/agent/Library/Logs/llama-swap.err";
          EnvironmentVariables = {
            # config.yaml の cmd（裸の llama-server）はこの PATH で解決される
            PATH = "${pkgs.llama-cpp}/bin:/usr/bin:/bin:/usr/sbin:/sbin";
          };
        };
      };

      # 旧 ~/Library/LaunchAgents/com.hermes.miniserve.plist（手書き）を置き換える宣言。
      launchd.agents."com.hermes.miniserve" = {
        enable = true;
        config = {
          Label = "com.hermes.miniserve";
          ProgramArguments = [
            "${pkgs.miniserve}/bin/miniserve"
            "--port"
            "18080"
            "--interfaces"
            "0.0.0.0"
            "--hidden"
            "--title"
            "Hermes News"
            "/Users/agent/.hermes/data/news-pipeline/reviews"
          ];
          RunAtLoad = true;
          KeepAlive = true;
          StandardOutPath = "/tmp/com.hermes.miniserve.log";
          StandardErrorPath = "/tmp/com.hermes.miniserve.err";
        };
      };
    };
}
