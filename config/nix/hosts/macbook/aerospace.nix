{ config, lib, ... }:
let
  user = lib.escapeShellArg config.system.primaryUser;

  # macOS 標準のワークスペース切替と AeroSpace のキー割り当てが衝突するため無効化する。
  # 79 / 81 は ctrl-←/→、118〜124 は ctrl-1〜7。value も宣言しておくことで、
  # 撤退時は enabled を true に戻すだけで元のキー割り当てを復元できる。
  symbolicHotkeys = [
    {
      id = "79";
      parameters = [
        65535
        123
        8650752
      ];
    }
    {
      id = "81";
      parameters = [
        65535
        124
        8650752
      ];
    }
    {
      id = "118";
      parameters = [
        65535
        18
        262144
      ];
    }
    {
      id = "119";
      parameters = [
        65535
        19
        262144
      ];
    }
    {
      id = "120";
      parameters = [
        65535
        20
        262144
      ];
    }
    {
      id = "121";
      parameters = [
        65535
        21
        262144
      ];
    }
    {
      id = "122";
      parameters = [
        53
        23
        262144
      ];
    }
    {
      id = "123";
      parameters = [
        54
        22
        262144
      ];
    }
    {
      id = "124";
      parameters = [
        65535
        26
        262144
      ];
    }
  ];

  disableSymbolicHotkey =
    { id, parameters }:
    let
      value = lib.generators.toPlist { escape = true; } {
        enabled = false;
        value = {
          inherit parameters;
          type = "standard";
        };
      };
    in
    ''
      launchctl asuser "$(id -u -- ${user})" sudo --user=${user} -- \
        defaults write com.apple.symbolichotkeys AppleSymbolicHotKeys \
          -dict-add ${lib.escapeShellArg id} ${lib.escapeShellArg value}
    '';
in
{
  # AeroSpace は native Spaces を使わない。名前と値が直感と逆で、true にすると
  # 「ディスプレイごとに個別の操作スペース」が OFF になる。反映にはログアウトが必要。
  system.defaults.spaces.spans-displays = true;

  # AeroSpace が非アクティブなウィンドウを画面外へ退避するため、Mission Control では
  # アプリ単位にまとめて散らかりを抑える。
  system.defaults.dock.expose-group-apps = true;

  # CustomUserPreferences で AppleSymbolicHotKeys を指定すると辞書全体を置換し、
  # 対象外のショートカットまで消してしまう。activation で対象 ID だけを -dict-add する。
  # system.activationScripts は root で動くため、nix-darwin の user defaults と同じ方法で
  # primaryUser の GUI セッションに書き込む。この例外は対象キーだけを保持するために必要。
  system.activationScripts.postActivation.text = lib.mkAfter ''
    echo >&2 "disabling macOS symbolic hotkeys reserved for AeroSpace..."
    ${lib.concatMapStringsSep "\n" disableSymbolicHotkey symbolicHotkeys}
  '';
}
