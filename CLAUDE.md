# CLAUDE.md

Guidance for working on this repo. It's the NixOS flake for host **bilbo**
— a MacBook Air 11" A1465 (2013–2015, **4 GB RAM, no T2**) running niri +
DankMaterialShell (DMS). See `README.md` for hardware notes and setup.

## Deploy

- The deployed config lives in **`/etc/nixos`** on bilbo. Sync `flake.nix`,
  `configuration.nix`, and `home.nix` there, then:
  ```sh
  sudo nixos-rebuild switch --flake .#bilbo
  ```
- `hardware-configuration.nix` is machine-specific and intentionally **not**
  in this repo — generate it on the box with `nixos-generate-config`.
- Remote access is `root@<ip>` over SSH; the box's IP is **DHCP and
  changes**, so confirm the current one rather than assuming.

## Config gotchas

Hard-won, non-obvious things that will bite you. Most cost a rebuild each to
rediscover.

- **niri home-module double-import.** Do **not** add
  `inputs.niri.homeModules.niri` to `home.nix`. niri-flake's *NixOS* module
  already injects it via `home-manager.sharedModules`; importing it again
  double-declares `programs.niri.finalConfig` and breaks the build. Only
  import the DMS home modules (+ dankcalendar).

- **niri source build OOMs on 4 GB.** niri-flake compiles niri from source
  and `rustc` gets OOM-killed here. Its Cachix only covers
  nixos-unstable/25.05, not our nixpkgs 26.05, so the source build is
  uncached. Fix: `programs.niri.package = pkgs.niri` (Hydra-cached). Don't
  revert this.

- **`programs.light` was removed in nixpkgs 26.05.** Use
  `hardware.acpilight.enable` for **screen** backlight control.

- **Internal wifi needs `broadcom_sta` (`wl`), not brcmfmac/b43.** The card
  is a BCM4360 (PCI `14e4:43a0`). `b43` finds it but rejects the 802.11ac PHY
  (probe `-95`); `brcmfmac` has no PCIe binding for `43a0` (only `43602`
  firmware ships) so it never claims it. Only the proprietary
  `broadcom_sta`/`wl` works (verified associating, sees 5 GHz, on kernel
  6.18). Config: `boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ]`,
  `boot.kernelModules = [ "wl" ]`, blacklist `b43 bcma ssb brcmsmac brcmfmac`.
  It's flagged **insecure** — allow by name via
  `nixpkgs.config.allowInsecurePredicate` (the version-pinned
  `permittedInsecurePackages` string breaks on every kernel bump). Taints the
  kernel / disables some CPU mitigations — fine here. USB dongles
  (rtl8xxxu etc.) are the fallback and how SSH stays reachable regardless.

- **Keyboard backlight = `smc::kbd_backlight` LED + `brightnessctl`.** The
  `applesmc` LED works out of the box but sits at 0 with no control wired up.
  Add `pkgs.brightnessctl`, `services.udev.packages = [ pkgs.brightnessctl ]`
  (its rule `chgrp input` the `leds` nodes), and put kmf in the **`input`**
  group (not `video` — that's for the `backlight` subsystem). F5/F6 emit
  `XF86KbdBrightness{Down,Up}` (hid_apple `fnmode=3`); bind them in
  `home.nix` to `brightnessctl --device=smc::kbd_backlight set …`. DMS ships
  no kbd-brightness bind so the nix base binds stand.

- **Keep `services.openssh.enable = true`.** The flake didn't originally
  declare it; enabling then removing it drops the sshd the installer
  provided → remote lockout.

- **Keybinds = nix base + DMS runtime overrides** (see `README.md`
  → Keybinds for the full model). Key points for editing:
  - The nix `binds` block in `home.nix` is the **base keymap** and can't be
    dropped — **DMS ships no default keymap** (`dms keybinds show niri`
    reports every bind as `source: "config"`, read back from `hm.kdl`).
  - Leave `includes` at its default so `dms/binds.kdl` stays included (it's
    pulled in *after* `hm.kdl`, so `dms keybinds set` overrides win at
    runtime). Do **not** exclude `"binds"` from `filesToInclude` (kills
    runtime overrides) and do **not** disable `includes` wholesale (also
    kills DMS dynamic theming via `dms/colors.kdl`).
  - Index/arg actions (`move-column-to-workspace`, `screenshot`) need
    niri-flake's **raw** form `.action.<name> = <arg>;`, not the bare
    `config.lib.niri.actions` function.
  - The `not recommended to use both enableKeybinds and includes.enable`
    warning is **benign and unavoidable** in this model — don't "fix" it.

- **Never set `programs.dank-material-shell.settings` / `session`.** They
  become read-only nix-store files that (a) `dms doctor` flags and that
  block DMS persisting wallpaper/theme, and (b) clobber DMS's runtime
  `~/.local/state/DankMaterialShell/session.json` → home-manager activation
  fails ("would be clobbered", exit 4). Let DMS own its mutable state;
  theme defaults to dark.

- **`dms restart` kills the shell.** It SIGUSR1s DMS, but `niri.enableSpawn`
  only runs at login, so DMS doesn't come back within the session. Relaunch
  with `dms run` detached (needs `WAYLAND_DISPLAY` + `XDG_RUNTIME_DIR`), or
  just re-login.

- **DMS calendar ≠ dankcalendar.**
  `programs.dank-material-shell.enableCalendarEvents` wires `pkgs.khal`
  (CalDAV, needs vdirsyncer + account setup) as the DMS calendar-widget
  backend. dankcalendar (`dcal`, home module `programs.dank-calendar`,
  systemd user service) is a **separate** standalone app and does not feed
  the DMS widget. This config uses `dcal` standalone with
  `enableCalendarEvents = false`. (danksearch = `pkgs.dsearch`.)

- **Run `dms doctor` in-session.** From outside the niri session it
  false-reports Wayland/Quickshell/terminal/matugen/dgop as missing —
  import a running niri/quickshell process's `/proc/<pid>/environ` first.
