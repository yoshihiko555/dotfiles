{ ... }:
{
  # --- 単位 B: hermes のセキュリティ宣言 ----------------------------------

  # 現状 (無効) を宣言で固定化する。無変化の確認用。
  system.defaults.loginwindow.GuestEnabled = false;

  # スクリーンセーバーのパスワード要求。現状は未設定（明示的な宣言なし）だったため、
  # ここで確定値として宣言する（Phase 4-8 セキュリティ強化）。
  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0;
  };

  # Application Firewall: 実機の現在値（有効 / stealth mode ON）をそのまま宣言で
  # 再現する。allowSigned（built-in software の着信許可）= true、allowSignedApp
  # （ダウンロードした署名済みソフトの着信許可）= false は実機の現在値どおり。
  #
  # blockAllIncoming は絶対に宣言しない。nix-darwin
  # modules/networking/applicationFirewall.nix（pin: nix-darwin rev
  # 15abb8c98f336cd8bd840d71059adebabe60bf04）を読むと、
  # 全オプションの型は `nullOr bool` で既定値は null。activation script 側は
  # `lib.optionalString (cfg.blockAllIncoming != null) (socketfilterfw "setblockall" ...)`
  # でガードされているため、未宣言（= null）であれば `setblockall` は一切呼ばれず、
  # miniserve の per-app 許可を含む既存の運用に触れない。
  # 誤って true を書くと per-app 許可を無視して受信を全遮断し、SSH ごとリモートから
  # ロックアウトされるため、このオプションはコード上でも意図的に書かない。
  networking.applicationFirewall = {
    enable = true;
    enableStealthMode = true;
    allowSigned = true;
    allowSignedApp = false;
  };
}
