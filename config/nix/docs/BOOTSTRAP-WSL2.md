# WSL2 の初回構築

会社 Windows の WSL2（Ubuntu、`x86_64`）に、既存の `homeConfigurations.wsl` を適用する。
Ubuntu の一般ユーザーで `uname -m`、`id -un`、`echo "$HOME"` を実行し、アーキテクチャと
[ホスト定義](../hosts/wsl/hostSpec.nix)のユーザー名・ホームディレクトリが一致することを確認する。

## 1. systemd を有効にする

Ubuntu で `sudoedit /etc/wsl.conf` を開き、既存の各セクションに次の設定を反映する。
このホストでは Windows 側の PATH の取り込みを止め、Windows ドライブでは Linux のメタデータを使う。

```ini
[boot]
systemd=true

[interop]
appendWindowsPath=false

[automount]
options="metadata"
```

WSL 上の作業を保存し、Windows の PowerShell で `wsl --shutdown` を実行する。
Ubuntu を開き直し、`ps -p 1 -o comm=` が `systemd` を返すことを確認する。

## 2. dotfiles を配置する

ホスト定義は Linux のホーム配下に置いたリポジトリを参照する。初回は Ubuntu の Git で配置できる。
すでに同じ場所に clone 済みなら次へ進む。

```sh
mkdir -p ~/ghq/github.com/yoshihiko555
git clone https://github.com/yoshihiko555/dotfiles.git ~/ghq/github.com/yoshihiko555/dotfiles
```

## 3. Nix を導入する

Ubuntu で Nix の公式インストーラを実行し、flakes を有効にする。[NixOS のインストーラ](https://github.com/NixOS/nix-installer)

```sh
curl -sSfL https://channels.nixos.org/nix-latest/nix-installer | sh -s -- install --enable-flakes
```

## 4. ユーザー環境を初めて適用する

Ubuntu の新しいシェルで、一般ユーザーとして実行する。初回は `nix run` で home-manager を起動する。
`-b backup` は配線先にある既存ファイルを退避するための指定。

```sh
nix --version
cd ~/ghq/github.com/yoshihiko555/dotfiles
nix run home-manager/master -- switch -b backup --flake ./config/nix#wsl
```

適用後、新しいシェルで `home-manager generations` に世代が表示され、`command -v starship` で共通パッケージを参照できることを確認する。
次回からは[チートシートの WSL2 再適用手順](CHEATSHEET.md#wsl2--linux-運用standalone-home-manager)を使う。
初回導入時の判断は [WSL2 の移行記録](PHASE-3-3-WSL2.md) にある。
