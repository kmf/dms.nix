# bilbo

NixOS flake config for a MacBook Air 11" (A1465, 2013-2015) running
[niri](https://github.com/YaLTeR/niri) + [DankMaterialShell](https://github.com/AvengeMedia/DankMaterialShell).

## Hardware notes

- **Model:** MacBook Air 11" A1465 (Mid 2013 / Early 2014 / Early 2015)
- **No T2 chip** - this generation predates T2, so no t2linux patches
  needed. Standard NixOS kernel/firmware works.
- **Wifi:** Broadcom BCM4360 (module BCM94360CS2). Handled by the
  in-kernel `brcmfmac` driver + `hardware.enableRedistributableFirmware`.
  If it doesn't come up after first boot, `configuration.nix` has a
  commented-out fallback to the proprietary `wl` driver
  (`broadcom_sta`).
- **Display:** 1366x768 panel - you may want to bump DMS's UI scale
  once you're in, since its defaults assume 1080p+.
- **RAM:** 4GB - niri is pinned to nixpkgs' prebuilt `pkgs.niri`
  rather than niri-flake's source build, which is uncached against
  nixpkgs 26.05 and OOM-kills `rustc` on this machine.
- Fan control via `mbpfan` and battery tuning via `tlp` are enabled -
  the 11" Air runs hot under sustained load.

## Files

| File | Purpose |
|---|---|
| `flake.nix` | Pins nixpkgs (26.05), pulls in `niri-flake`, DankMaterialShell (`stable`), `dankcalendar`, and home-manager |
| `configuration.nix` | System config: hostname `bilbo`, networking, wifi, greetd + DMS greeter, niri, audio, power management, `fish` shell |
| `home.nix` | home-manager config for user `kmf`: DMS + niri integration, declarative niri keybinds, package list (`ghostty`, `dsearch`) |
| `hardware-configuration.nix` | **Not included** - generate this yourself (see below), it's machine-specific |

## Setup

This config lives in `/etc/nixos` (NixOS's default location), rather
than a separate `~/nixos-config` repo. `/etc/nixos` is root-owned by
default - either `sudo` your edits, or `sudo chown -R $USER /etc/nixos`
once for convenience (no functional downside).

1. Generate the hardware config (machine-specific, don't reuse from
   another host) - this drops `hardware-configuration.nix` straight
   into `/etc/nixos/`:
   ```sh
   sudo nixos-generate-config --root /mnt   # during install
   # or, on an already-installed system:
   sudo nixos-generate-config
   ```

2. Copy `flake.nix`, `configuration.nix`, and `home.nix` into
   `/etc/nixos/`. Overwrite the placeholder `configuration.nix` that
   `nixos-generate-config` also generates - you only need one.

   Directory should look like:
   ```
   /etc/nixos/
   ├── flake.nix
   ├── configuration.nix
   ├── home.nix
   └── hardware-configuration.nix
   ```

3. Build and switch:
   ```sh
   cd /etc/nixos
   sudo nixos-rebuild switch --flake .#bilbo
   ```

   The `#bilbo` target matches the `nixosConfigurations.bilbo`
   name in `flake.nix`. NixOS also checks `/etc/nixos` by default even
   from other directories, but being explicit with `--flake .` is
   safer.

4. (Optional) Version control - since the config now lives in
   `/etc/nixos`, you can `git init` right there rather than keeping a
   separate repo elsewhere.

## Troubleshooting

- **Wifi not detected:** check `dmesg | grep -i brcm` after boot. If
  `brcmfmac` isn't binding the card, switch to the commented-out
  `broadcom_sta` (`wl`) driver block in `configuration.nix`.
- **Two polkit prompts / double auth dialogs:** `niri-flake`'s default
  polkit agent is disabled in `configuration.nix` since DMS ships its
  own. If you see double prompts, check that setting wasn't re-enabled
  elsewhere.
- **DMS UI too small/large:** check DMS's scale settings under its
  settings panel - the 1366x768 panel often needs a manual scale
  adjustment.

## References

- [DankMaterialShell NixOS flake docs](https://danklinux.com/docs/dankmaterialshell/nixos-flake)
- [niri-flake](https://github.com/sodiboo/niri-flake)
- [DankMaterialShell repo](https://github.com/AvengeMedia/DankMaterialShell)
- [t2linux wiki](https://wiki.t2linux.org/) (not needed for A1465, but useful reference for T2-era Macs)
- [NixOS wiki - Broadcom wifi](https://wiki.nixos.org/wiki/Broadcom)
