{ config, ... }:
{
  # iPhone の Prompt 3 から接続するためのプライベートネットワーク。
  # CLI と tailscaled の launchd サービスを nix-darwin で管理する。
  # アカウントへの登録は反映後に sudo tailscale up で行う。
  services.tailscale.enable = true;

  # tailscaled 1.102.3 は /etc/resolver 外を指すリンクを拒否する。
  # ts.net は実ファイルとして tailscaled 自身に管理させる。
  environment.etc."resolver/ts.net".enable = false;

  # Prompt 3 から既存ユーザーの tmux へ接続する。公開鍵は端末ごとに登録する。
  services.openssh = {
    enable = true;
    extraConfig = ''
      PermitRootLogin no
      PubkeyAuthentication yes
      PasswordAuthentication no
      KbdInteractiveAuthentication no
      AllowUsers ${config.hostSpec.username}
    '';
  };
}
