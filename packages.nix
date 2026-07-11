{ pkgs, ... }:

# Extra user packages, installed into kmf's home-manager profile.
# Add new packages to the list below. Imported by home.nix.
{
  home.packages = with pkgs; [
    ghostty   # terminal (bound to Mod+Return / Mod+T in home.nix)
    dsearch   # danksearch - file search backing DMS spotlight (nixpkgs 26.05)
    maestral  # Dropbox client
    brave     # browser (Apple Music via web/PWA; cider is broken in nixpkgs 26.05)
  ];
}
