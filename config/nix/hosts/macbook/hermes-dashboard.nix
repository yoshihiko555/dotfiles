{ config, ... }:
let
  username = config.hostSpec.username;
in
{
  home-manager.users.${username} =
    { pkgs, ... }:
    let
      tunnel = pkgs.writeShellScript "hermes-dashboard-tunnel" (
        builtins.readFile ./hermes-dashboard-tunnel.sh
      );
    in
    {
      launchd.agents."com.hermes.dashboard-tunnel" = {
        enable = true;
        config = {
          Label = "com.hermes.dashboard-tunnel";
          ProgramArguments = [ "${tunnel}" ];
          RunAtLoad = true;
          KeepAlive = true;
          # 外出中・ネットワーク切断中に再試行を連発しない。
          ThrottleInterval = 60;
          StandardOutPath = "/dev/null";
          StandardErrorPath = "/dev/null";
        };
      };
    };
}
