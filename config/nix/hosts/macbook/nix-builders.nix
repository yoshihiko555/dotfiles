{ ... }:
{
  # Phase 4-1（Remote builders）: hermes（M4 Mac mini, 常時稼働）を
  # distributed build のビルドマシンとして登録し、MBP のビルド負荷を逃がす。
  #
  # --- 設計方針: root の SSH 設定に依存しない構成 -------------------------
  # nix-daemon は root 権限で SSH 接続するため、/var/root/.ssh/ の状態（未確認、
  # 確認には sudo が必要）に依存すると見えない前提が増える。そこで:
  #   1. builder 専用鍵を新規に用意する（個人鍵 ~/.ssh/id_ed25519_macmini を
  #      root に流用しない。漏洩時の影響範囲を鍵ごとに限定するため）
  #   2. sshKey は絶対パスを指定し、root の ~/.ssh/config（macmini-agent 等の
  #      alias）を経由しない。hostName も IP を直書きするのはそのため
  #   3. known_hosts の初回登録問題は publicHostKey（ホスト公開鍵の base64）で
  #      回避する
  #
  # 鍵の生成・配置・hermes 側 authorized_keys への登録・darwin-rebuild switch は
  # sudo とリモートへの書き込みを伴うため、このリポジトリ側の変更では行わない
  # （ユーザーが手順書に従って手で実行する）。

  nix.buildMachines = [
    {
      # macmini-agent の HostName と同一だが、root の ~/.ssh/config に依存しない
      # ため alias ではなく IP を直書きする。
      hostName = "192.168.1.100";
      sshUser = "agent";
      # nix-daemon（root）が使う builder 専用鍵。個人鍵とは別に手順書に従って
      # 生成する。nix-darwin のオプション説明どおり、ストア内ではなくローカル
      # ファイルシステム上の絶対パスでなければならない。
      sshKey = "/var/root/.ssh/id_ed25519_hermes_builder";
      system = "aarch64-darwin";
      # hermes の実コア数（sysctl -n hw.ncpu、2026-08-14 macmini-agent 経由で確認）。
      maxJobs = 10;
      # hermes（Apple M4, 2024, 10 コア）は MBP（Apple M1 Pro, 2021, 8 コア = 6P+2E）
      # より 2 世代新しく、コア数も多い。厳密なベンチマーク比較は未計測のため、
      # 「世代差による単コア性能向上」と「コア数差（10 vs 実質 P コア 6）」を
      # 合わせて控えめに 2 と見積もる。実測（後述の手順書の確認方法）後に見直すこと。
      speedFactor = 2;
      # hermes の実際の system-features（`nix store ping` / nix.conf 確認、
      # 2026-08-14 時点）とそのまま整合させる。
      supportedFeatures = [
        "apple-virt"
        "benchmark"
        "big-parallel"
        "nixos-test"
      ];
      # ssh-ng: MBP・hermes とも Nix 2.34 系で対応済みの新プロトコル。旧 ssh より
      # 並列度・再開性に優れるため優先する。接続に問題が出た場合は "ssh" に戻す。
      protocol = "ssh-ng";
      # hermes の SSH ホスト公開鍵ファイル（/etc/ssh/ssh_host_ed25519_key.pub）の
      # 内容をそのまま base64 化した値。nix-darwin のオプション説明
      # （modules/nix/default.nix, rev 15abb8c）が明示するとおり
      # `base64 -w0 /etc/ssh/ssh_host_type_key.pub` に相当する（macOS の base64 に
      # -w0 は無いため `base64 | tr -d '\n'` で代替）。ファイル全体（"ssh-ed25519 <鍵> "
      # の末尾スペースを含む）をエンコードした値であり、鍵の一部だけを切り出した
      # ものではない。2026-08-14 に macmini-agent 経由で読み取り専用取得・確認。
      publicHostKey = "c3NoLWVkMjU1MTkgQUFBQUMzTnphQzFsWkRJMU5URTVBQUFBSUpLNEROQStmcnJjMlNpdlQ3K1lqKzdLQVcrRHBMd1JOVHFzYXJaMWJ6Z2kgCg==";
    }
  ];

  # buildMachines を宣言しただけでは有効化されない。nix-darwin は distributedBuilds
  # が false のとき nix.settings.builders を明示的に null へ上書きし、/etc/nix/machines
  # が存在しても無視する（modules/nix/default.nix 945-969 行、nix-darwin rev
  # 15abb8c、2026-08-14 確認）。true にすると上書きが外れ、nix 本体の既定値
  # `builders = @/etc/nix/machines` がそのまま効く。
  nix.distributedBuilds = true;

  nix.settings = {
    # hermes がビルド成果物を取得する際、MBP を経由せず直接バイナリキャッシュ
    # （substituters）から取得させる。ROADMAP 4-1 に明記されたタスク。
    # hermes は distributed build の受け手であり、これは送り手（MBP）側の設定
    # なので darwin/ の共通層ではなく hosts/macbook/ に置く（ADR-20260801-0004
    # ルール 3: 新規はまず使うホストの hosts/<host>/ に書き、2 台以上で使い始めて
    # から共通層へ昇格する）。
    builders-use-substitutes = true;
  };
}
