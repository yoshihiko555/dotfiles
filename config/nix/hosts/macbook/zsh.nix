{ ... }:
{
  # compinit は sheldon（packages.nix）が行うため、/etc/zshrc 側の初期化は止める。
  # sheldon の無い hermes では /etc/zshrc の compinit が唯一なので共通層には置かない。
  programs.zsh.enableGlobalCompInit = false;
  programs.zsh.enableBashCompletion = false;
  # 既定の prompt suse は starship が上書きするため不要
  programs.zsh.promptInit = "";
}
