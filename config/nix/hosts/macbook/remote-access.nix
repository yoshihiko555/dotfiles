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
      # Tailscale の IPv4 / IPv6 からのみ公開鍵ログインを許可する。
      # 端末の所属・到達可否は Tailscale 側のアクセス制御が担う。
      AllowUsers ${config.hostSpec.username}@100.64.0.0/10 ${config.hostSpec.username}@fd7a:115c:a1e0::/48

      # launchd が待ち受けるため ListenAddress では制限できない。
      # LAN / localhost 宛ての接続は、接続元にかかわらずログインを拒否する。
      Match LocalAddress *,!100.64.0.0/10,!fd7a:115c:a1e0::/48
        DenyUsers *
      Match all
    '';
  };
}
