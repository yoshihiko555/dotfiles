{ ... }:
{
  # Nix store の自動 GC。常時稼働の hermes は放置すると世代が溜まり続けるため、
  # 週次で古い世代を削除する。
  #
  # 実測（2026-08-02）: system プロファイル 2 世代 / store 約 7G / ディスク空き 119Gi。
  # 逼迫はしておらず緊急性は低い。コストがほぼ無いための予防的な宣言である。
  #
  # 経緯: 移行前（Determinate Nix 運用時）は `nix.enable = false` が必須で、
  # nix.gc.automatic は `assertion = cfg.automatic -> config.nix.enable` に弾かれ、
  # launchd.daemons の自前宣言で代替していた。2026-08-02 の素の Nix 移行により
  # 標準オプションが使えるようになったため、そちらへ寄せた（ADR-20260802-0005）。
  nix.gc = {
    automatic = true;
    # nix-darwin の既定値と同じ日曜 3:15。
    interval = [
      {
        Weekday = 7;
        Hour = 3;
        Minute = 15;
      }
    ];
    # rollback 可能な期間を十分に残すための保守的な設定。
    options = "--delete-older-than 30d";
  };
}
