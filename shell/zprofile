# ============================================
# Zsh Profile (loaded for login shells only)
# ============================================
# Note: brew shellenv is set in .zshenv

# Ensure Nix is available in login shells as well as interactive shells.
if [[ -e /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh ]]; then
  . /nix/var/nix/profiles/default/etc/profile.d/nix-daemon.sh
fi

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
