{ ... }:
{
  # Nix store の自動 GC。開発機は依存関係の入れ替わりが多く世代が溜まりやすいため、
  # hermes（常時稼働機）と同じ設定で週次の自動削除を宣言する。
  #
  # 実測（2026-08-14）: /nix/store 約 23G、nix-env の世代管理は未使用（home-manager /
  # nix-darwin の宣言的管理のため `nix-env --list-generations` は 0 件）。逼迫はして
  # おらず、hermes と揃えるための予防的な宣言である。
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
