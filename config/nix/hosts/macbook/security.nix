{ ... }:
{
  # --- 単位 A: Touch ID sudo（MBP 専用） ---------------------------------
  # MBP はビルトインの Touch ID を持つが hermes はヘッドレスで生体認証デバイスが
  # 無いため、共通層（darwin/）へは昇格せずホスト固有層に留める（ADR-20260801-0004）。
  #
  # 適用後は sudo 実行時に Touch ID プロンプトが出るようになる。パスワード入力は
  # 引き続きフォールバックとして機能する。Phase 4-1（remote builders）で発生する
  # 多数の sudo 作業が楽になるため最優先で導入する。
  #
  # reattach（pam_reattach）を有効化し、tmux / screen のセッション内でも Touch ID が
  # 効くようにする。無効のままだと、バックグラウンドプロセスが bootstrap セッション
  # から切り離されているため Touch ID 認証が反応しない。
  security.pam.services.sudo_local = {
    touchIdAuth = true;
    reattach = true;
  };

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
