{ ... }:
{
  # --- 単位 A: Touch ID sudo（不採用、2026-08-14）------------------------
  # `security.pam.services.sudo_local.touchIdAuth` は**意図的に宣言しない**。
  #
  # 2026-08-14 に導入を試み、宣言・生成物ともに正常であることを確認した:
  #   - /etc/pam.d/sudo_local に pam_tid.so が生成される
  #   - /etc/pam.d/sudo は auth include sudo_local を先頭に持つ（macOS 14+ の既定）
  #   - Touch ID は登録済み・有効（bioutil -r で確認）
  #   - 本体を開いた状態（クラムシェルではない）で検証
  #
  # にもかかわらず **macOS 26.5.2 では sudo が指紋を要求しない**。代わりに
  # Authorization Services の認可ダイアログ（パスワード入力欄のみ、Touch ID
  # センサーに触れても無反応）が出る。pam_reattach の有無は無関係であることを
  # 実機で切り分け済み（外しても同じ挙動）。
  #
  # Apple は macOS 15.4 で sudo を Rust 実装へ置き換えており、その過程で PAM の
  # 扱いが変わった可能性があるが、/usr/bin/sudo は setuid で読めず未確認。
  #
  # 指紋が使えない以上、GUI ダイアログはマウス操作を強いるぶん CLI での
  # パスワード入力より不便なだけなので、宣言を外して従来の挙動に戻す
  # （pam_opendirectory によるターミナル内の Password: 入力）。
  # 将来 OS 側で挙動が変わったら再検討する。

  # --- 単位 C: loginwindow / screensaver ---------------------------------
  # hermes（hosts/hermes/security.nix, 単位 B）で検証済みの値を移植。
  # GuestEnabled は現状 (無効) と一致し無変化。screensaver のパスワード要求は
  # 明示的に宣言していなかった状態から確定値を持たせる（Phase 4-8 セキュリティ強化）。
  system.defaults.loginwindow.GuestEnabled = false;

  system.defaults.screensaver = {
    askForPassword = true;
    askForPasswordDelay = 0;
  };

  # Application Firewall は今回のスコープ外。MBP は現在無効であり、有効化は実挙動の
  # 変化を伴うため、常用ネットワークサービスの洗い出しを先に行う（別 Phase で対応）。
}
