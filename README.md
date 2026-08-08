# OBLinux

A GNOME desktop distro built on Arch Linux, using [archiso](https://gitlab.archlinux.org/archlinux/archiso).
Successor to [OBLinux-OLD](https://github.com/marcoobaid/OBLinux-OLD), rebuilt from a current
archiso `releng` baseline instead of patching forward a 5-year-old profile.

## Building

On the build machine:

```bash
sudo pacman -S --needed archiso
sudo mkarchiso -v .
```

The finished ISO is written to `out/`. `work/` and `out/` are gitignored — safe to delete between
builds (`sudo rm -rf work out`).

**Before building**: `calamares` and `paru` come from
[`oblinux_repo`](https://github.com/marcoobaid/oblinux_repo) (both are AUR-only, not in the
official repos) — if they aren't built and published there yet, `pacstrap` will fail to resolve
them and the build will fail. See [`docs/CUSTOM_REPO.md`](docs/CUSTOM_REPO.md).

`mkarchiso` (not `build.sh`) is the current, correct entry point — `build.sh` was a deprecated shim
upstream removed years ago; see [OBLinux-OLD](https://github.com/marcoobaid/OBLinux-OLD) for why
that mattered.

## Status

Phase 1, in progress — see issues/project board for tracking.

**Boot→login checklist fully verified as of 2026-08-06**, across 6 rounds of build → boot →
fix testing (5 in VirtualBox, 1 on real hardware via USB): boot menu (BIOS + UEFI, main +
speech entries), Plymouth, GDM, GNOME desktop, `liveuser` autologin, NetworkManager,
passwordless sudo, the zsh prompt, and the AUR bootstrap (`paru` builds successfully on
first login) are all confirmed working. Three real bugs and two cosmetic issues were found
and fixed along the way — full log with root causes: [`docs/TESTING.md`](docs/TESTING.md).
Nothing outstanding on this checklist; next up is Calamares.

Built so far:

- [x] Base profile scaffolded from archiso's current `releng` example (BIOS/syslinux +
      UEFI/systemd-boot, current package set)
- [x] GNOME desktop (GDM + gnome-shell + core apps), autologin as `liveuser` on the live medium
- [x] NetworkManager (replaces releng's default iwd/systemd-networkd, since that's what GNOME
      Settings' network panel expects)
- [x] Text/identity branding: ISO name & label, hostname, `/etc/os-release`, `/etc/issue`, MOTD,
      boot menu titles (BIOS + UEFI)
- [x] AUR support via `paru`, prebuilt and installed like any other package (see below) —
      replaces an earlier first-login-bootstrap approach that built it from source on first login
- [x] Custom package repo (`oblinux_repo`, GitHub Pages) wired into `pacman.conf` (build-time)
      and `airootfs/etc/pacman.conf` (persists to the live/installed system), for `calamares` and
      `paru` (both AUR-only) plus future custom OBLinux packages. Details, and why Calamares'
      own config is deliberately *not* packaged this way, in
      [`docs/CUSTOM_REPO.md`](docs/CUSTOM_REPO.md).
- [x] **Visual branding, boot→login checklist complete** — logo mark
      (`docs/branding/oblinux-mark*.svg`), boot splash (`syslinux/splash.png`), Plymouth boot theme
      (`airootfs/usr/share/plymouth/themes/oblinux/`, the amber spark orbits the ring during boot),
      GDM login logo + solid-Ink background
      (`airootfs/usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override`), and the
      `os-release` `LOGO=oblinux-logo` icon (`airootfs/usr/share/pixmaps/oblinux-logo.{svg,png}`) —
      GNOME Settings' About panel now shows the real mark instead of a generic fallback. Palette,
      mark rationale, and asset details are documented in [`docs/BRANDING.md`](docs/BRANDING.md).
- [ ] Calamares installer (package + repo infrastructure in place; `settings.conf`, module
      config, and cleanup-of-live-artifacts still to build) + OBLinux branding module
- [ ] Default application package list (user-controlled — TBD)

## Implementation notes

- `liveuser` has passwordless sudo (`/etc/sudoers.d/g_wheel`) for live-session convenience only.
  Calamares typically clones this live filesystem onto the install target, so **when the Calamares
  config is added, it must explicitly strip or replace that sudoers rule as a post-install step** —
  otherwise it ships on real installs too.
- Package list intentionally does *not* yet include a curated set of end-user apps — that list is
  still TBD and will be added as its own increment.
