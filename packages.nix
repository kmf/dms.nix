{ pkgs, ... }:

# Extra user packages, installed into kmf's home-manager profile.
# Add new packages to the list below. Imported by home.nix.
{
  home.packages = with pkgs; [
    ghostty   # terminal (bound to Mod+Return / Mod+T in home.nix)
    dsearch   # danksearch - file search backing DMS spotlight (nixpkgs 26.05)
    maestral-gui  # Dropbox client (Qt system-tray GUI + sync daemon)
    brave     # browser (Apple Music via web/PWA; cider is broken in nixpkgs 26.05)
    brightnessctl  # keyboard-backlight control (F5/F6 -> smc::kbd_backlight)
    insync    # proprietary multi-cloud sync client (unfree, prebuilt binary)
    modem-manager-gui  # GTK frontend for ModemManager (SMS, USSD, signal)
    neovim    # terminal text editor
    reaper    # digital audio workstation (unfree; free eval, licensed use)
  ];
}
