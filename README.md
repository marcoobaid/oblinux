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

**First successful end-to-end Calamares install verified 2026-08-09** (VirtualBox, BIOS): a
fresh disk erase-install completes cleanly, and the resulting system boots on its own —
GRUB, Plymouth, GDM, and GNOME desktop login all confirmed working, `sudo` working for the
installed user. Reaching that point took 5 rounds of install → log → fix testing (rounds
8–12; `docs/TESTING.md`), each round's fix uncovering the next bug further into the install
sequence. A few polish items remain open (installed GRUB menu is unthemed, default shell is
bash not zsh, an intermittent installer crash on the swap option isn't yet root-caused) —
see the Calamares checklist item below.

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
      `paru` (both AUR-only) plus future custom OBLinux packages. **Verified working end to end** —
      both packages built, published, and confirmed resolving on a built/booted system. Details,
      and why Calamares' own config is deliberately *not* packaged this way, in
      [`docs/CUSTOM_REPO.md`](docs/CUSTOM_REPO.md).
- [x] **Visual branding, boot→login checklist complete** — logo mark
      (`docs/branding/oblinux-mark*.svg`), boot splash (`syslinux/splash.png`), Plymouth boot theme
      (`airootfs/usr/share/plymouth/themes/oblinux/`, the amber spark orbits the ring during boot),
      GDM login logo + solid-Ink background
      (`airootfs/usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override`), and the
      `os-release` `LOGO=oblinux-logo` icon (`airootfs/usr/share/pixmaps/oblinux-logo.{svg,png}`) —
      GNOME Settings' About panel now shows the real mark instead of a generic fallback. Palette,
      mark rationale, and asset details are documented in [`docs/BRANDING.md`](docs/BRANDING.md).
- [x] **Calamares installer — successful end-to-end install verified, repeatably (rounds 12–13,
      2026-08-09/10)**. `settings.conf`, all module configs (partitioning, users, bootloader,
      live-artifact cleanup, etc.), and OBLinux branding all written, verified against
      Calamares' own current source rather than guessed (see
      [`docs/CALAMARES.md`](docs/CALAMARES.md)). `ckbcomp` built and published to
      `oblinux_repo` alongside `calamares`/`paru`. Getting to a clean install took 5 rounds of
      testing (8–12), one new bug surfacing after each fix as the install got further:
      `shellprocess` placeholder token (`@@ROOT@@` vs. `${ROOT}`), `mount.conf`'s `options: bind`
      needing to be a YAML list, `linux.preset` pointing at a live-only mkinitcpio config,
      `packages.conf` missing the required `backend: pacman` key. Round 13 confirmed the last
      follow-up (`/etc/calamares` no longer left on the installed system). Full log with root
      causes: [`docs/TESTING.md`](docs/TESTING.md) (rounds 8–13). Closing out remaining polish
      items next (none block a basic install):
      - [x] default shell on the installed system was silently staying bash — `users.conf` used
        a made-up `userShell` key instead of the real nested `user.shell`; also added
        `/etc/skel/.zshrc` so new users don't hit zsh's first-run wizard. Fixed a second,
        adjacent bug found the same way (`passwordRequirements.nonempty` isn't a real key
        either — confirmed by a warning present in every `session.log` so far — so no minimum
        password length was actually being enforced; now `minLength: 1`). Not yet re-verified
        by an actual run.
      - [ ] installed system's GRUB menu is unthemed (the live ISO's boot menu isn't affected) —
        in progress
      - [ ] an intermittent installer crash right after choosing the swap option recurred in
        round 12's log (auto-recovers) — still not root-caused, investigating next
- [ ] Default application package list (user-controlled — TBD)

## Implementation notes

- `liveuser` has passwordless sudo (`/etc/sudoers.d/g_wheel`) for live-session convenience only.
  Calamares typically clones this live filesystem onto the install target, so **when the Calamares
  config is added, it must explicitly strip or replace that sudoers rule as a post-install step** —
  otherwise it ships on real installs too.
- Package list intentionally does *not* yet include a curated set of end-user apps — that list is
  still TBD and will be added as its own increment.
