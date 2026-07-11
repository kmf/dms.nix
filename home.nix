{ config, pkgs, inputs, ... }:

{
  home.username = "kmf";
  home.homeDirectory = "/home/kmf";
  home.stateVersion = "26.05";

  imports = [
    # NOTE: do NOT import inputs.niri.homeModules.niri here - niri-flake's
    # NixOS module already injects niri's home-manager config via
    # home-manager.sharedModules. Importing it again double-declares
    # programs.niri.finalConfig and breaks the build.
    inputs.dms.homeModules.dank-material-shell
    inputs.dms.homeModules.niri
    inputs.dankcalendar.homeModules.dank-calendar
  ];

  # dankcalendar (dcal) - standalone calendar daemon (tray + reminders),
  # backing DMS's calendar. Runs as a user systemd service.
  programs.dank-calendar = {
    enable = true;
    systemd.enable = true;
  };

  programs.dank-material-shell = {
    enable = true;

    # niri integration
    niri = {
      enableKeybinds = true;    # DMS's own action shortcuts (launcher/notifications/audio/...)
      enableSpawn = true;       # auto-start DMS with niri
    };

    # Feature toggles - trim to what the 11" Air's modest hardware can afford
    enableSystemMonitoring = true;
    enableDynamicTheming = true;   # wallpaper-based theming via matugen
    enableAudioWavelength = true;  # cava audio visualizer
    enableVPN = false;
    # DMS's built-in calendar widget is khal-backed (enableCalendarEvents pulls
    # in pkgs.khal, needing vdirsyncer + CalDAV setup). We use the standalone
    # dankcalendar (dcal) app instead, so leave this off.
    enableCalendarEvents = false;

    # NOTE: no `settings`/`session` blocks on purpose. Declaring them makes
    # home-manager write read-only nix-store files that (a) collide with DMS's
    # own runtime state - `session.json` already exists and would be clobbered
    # - and (b) stop DMS persisting wallpaper/theme changes (the read-only
    # settings.json that `dms doctor` flags). Keybinds below are declarative;
    # DMS owns its mutable theme/session state. Theme defaults to dark.
  };

  # Do not enable both systemd auto-start and niri.enableSpawn -
  # this repo intentionally only uses niri.enableSpawn above.

  # Window-management keymap, declaratively in nix (preferred over DMS's
  # runtime `dms keybinds`/dms-binds.kdl). DMS's `enableKeybinds` only adds
  # its own action shortcuts; declaring ANY binds section makes niri drop its
  # built-in default keymap, so these provide terminal/focus/move/workspace/
  # quit. They mkMerge with the DMS binds - avoid keys DMS already uses
  # (Mod+Space/N/M/P/V/X/Comma, Mod+Alt+N, Super+Alt+L, XF86*).
  programs.niri.settings.binds = with config.lib.niri.actions; {
    "Mod+Return".action = spawn "ghostty";
    "Mod+T".action = spawn "ghostty";
    "Mod+Q".action = close-window;

    "Mod+Left".action  = focus-column-left;
    "Mod+Right".action = focus-column-right;
    "Mod+Up".action    = focus-window-up;
    "Mod+Down".action  = focus-window-down;
    "Mod+H".action = focus-column-left;
    "Mod+J".action = focus-window-down;
    "Mod+K".action = focus-window-up;
    "Mod+L".action = focus-column-right;

    "Mod+Shift+Left".action  = move-column-left;
    "Mod+Shift+Right".action = move-column-right;
    "Mod+Shift+Up".action    = move-window-up;
    "Mod+Shift+Down".action  = move-window-down;
    "Mod+Shift+H".action = move-column-left;
    "Mod+Shift+J".action = move-window-down;
    "Mod+Shift+K".action = move-window-up;
    "Mod+Shift+L".action = move-column-right;

    "Mod+1".action = focus-workspace 1;
    "Mod+2".action = focus-workspace 2;
    "Mod+3".action = focus-workspace 3;
    "Mod+4".action = focus-workspace 4;
    "Mod+5".action = focus-workspace 5;
    "Mod+6".action = focus-workspace 6;
    "Mod+7".action = focus-workspace 7;
    "Mod+8".action = focus-workspace 8;
    "Mod+9".action = focus-workspace 9;
    # move-column-to-workspace takes an index arg, so it is not exposed as a
    # bare action in config.lib.niri.actions - use niri-flake's raw form.
    "Mod+Shift+1".action.move-column-to-workspace = 1;
    "Mod+Shift+2".action.move-column-to-workspace = 2;
    "Mod+Shift+3".action.move-column-to-workspace = 3;
    "Mod+Shift+4".action.move-column-to-workspace = 4;
    "Mod+Shift+5".action.move-column-to-workspace = 5;
    "Mod+Shift+6".action.move-column-to-workspace = 6;
    "Mod+Shift+7".action.move-column-to-workspace = 7;
    "Mod+Shift+8".action.move-column-to-workspace = 8;
    "Mod+Shift+9".action.move-column-to-workspace = 9;
    "Mod+Page_Down".action = focus-workspace-down;
    "Mod+Page_Up".action   = focus-workspace-up;

    "Mod+R".action = switch-preset-column-width;
    "Mod+F".action = maximize-column;
    "Mod+Shift+F".action = fullscreen-window;
    "Mod+C".action = center-column;
    "Mod+Minus".action = set-column-width "-10%";
    "Mod+Equal".action = set-column-width "+10%";

    "Mod+O".action = toggle-overview;
    # screenshot (interactive) also takes args, so use the raw form.
    "Print".action.screenshot = { show-pointer = true; };

    "Mod+Shift+E".action = quit;
    "Mod+Shift+Slash".action = show-hotkey-overlay;
  };

  home.packages = with pkgs; [
    ghostty
    dsearch   # danksearch - file search backing DMS spotlight (nixpkgs 26.05)
  ];

  programs.fish.enable = true;
}
