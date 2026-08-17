# WSL2（会社支給 Windows の Ubuntu）の hostSpec 値。
#
# darwin ホスト（hosts/hermes, hosts/macbook）は modules/hostSpec.nix の options を
# config として宣言し、flake.nix が `config.hostSpec` を home-manager へ渡している。
# standalone home-manager にはその darwin 側 config が存在しないため（B2）、
# WSL2 では値をこのプレーンな attrset に置き、flake.nix が extraSpecialArgs へ
# 直接渡す。値の出所をホストディレクトリ内に留めるための分離である。
{
  hostName = "wsl";
  username = "stakizawa";
  homeDirectory = "/home/stakizawa";
  # macOS 2 台と同じ ghq 構造に揃える。ghq 自体は home.packages 経由で
  # 後から入るが、ghq はパス規約だけのツールで既存ディレクトリをそのまま
  # 認識するため、初回は素の `git clone` でこのパスへ置けばよい
  # （ブートストラップ順序は docs/PHASE-3-3-WSL2.md 手順 0〜1）。
  dotfilesDir = "/home/stakizawa/ghq/github.com/yoshihiko555/dotfiles";
}
