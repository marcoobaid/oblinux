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

`mkarchiso` (not `build.sh`) is the current, correct entry point — `build.sh` was a deprecated shim
upstream removed years ago; see [OBLinux-OLD](https://github.com/marcoobaid/OBLinux-OLD) for why
that mattered.

## Status

Phase 1, in progress — see issues/project board for tracking. Built so far:

- [x] Base profile scaffolded from archiso's current `releng` example (BIOS/syslinux +
      UEFI/systemd-boot, current package set)
- [x] GNOME desktop (GDM + gnome-shell + core apps), autologin as `liveuser` on the live medium
- [x] NetworkManager (replaces releng's default iwd/systemd-networkd, since that's what GNOME
      Settings' network panel expects)
- [x] Text/identity branding: ISO name & label, hostname, `/etc/os-release`, `/etc/issue`, MOTD,
      boot menu titles (BIOS + UEFI)
- [x] AUR support via a first-login bootstrap that builds `paru` (see
      `airootfs/usr/local/bin/oblinux-aur-bootstrap`)
- [x] **Visual branding** — logo mark (`docs/branding/oblinux-mark*.svg`), boot splash
      (`syslinux/splash.png`), Plymouth boot theme (`airootfs/usr/share/plymouth/themes/oblinux/`,
      the amber spark orbits the ring during boot), and the GDM login logo + solid-Ink background
      (`airootfs/usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override`). Palette, mark
      rationale, and asset details are documented in [`docs/BRANDING.md`](docs/BRANDING.md).
- [ ] App icon — export the mark into a proper hicolor icon set for `os-release`'s
      `LOGO=oblinux-logo` (still a generic fallback icon until this is done — last item on the
      boot→login checklist)
- [ ] Calamares installer + OBLinux branding module (next increment)
- [ ] Default application package list (user-controlled — TBD)

## Notes for future me

- `liveuser` has passwordless sudo (`/etc/sudoers.d/g_wheel`) for live-session convenience only.
  Calamares typically clones this live filesystem onto the install target, so **when the Calamares
  config is added, it must explicitly strip or replace that sudoers rule as a post-install step** —
  otherwise it ships on real installs too.
- `/etc/os-release` sets `LOGO=oblinux-logo`, but no icon asset with that name exists yet — GNOME's
  About panel will fall back to a generic icon until one is added.
- Package list intentionally does *not* yet include a curated set of end-user apps — that list is
  still TBD and will be added as its own increment.
