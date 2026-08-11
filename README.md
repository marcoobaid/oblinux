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

**Phase 2 (Calamares installer) complete and verified as of 2026-08-10** (VirtualBox, BIOS):
a fresh disk erase-install completes cleanly, and the resulting system boots on its own —
GRUB (themed), Plymouth, GDM, GNOME desktop login, `sudo`, and zsh as the default shell all
confirmed working. Reaching that point took 8 rounds of install → log → fix testing (rounds
8–15; `docs/TESTING.md`), each round's fix uncovering the next issue further into the
sequence. One known issue remains, deliberately deprioritized (an intermittent, non-blocking
installer crash) — see the Calamares checklist item below.

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
- [x] **Calamares installer — Phase 2 complete, verified end to end (rounds 8–15,
      2026-08-09/10)**. `settings.conf`, all module configs (partitioning, users, bootloader,
      live-artifact cleanup, etc.), and OBLinux branding (including the installed system's
      themed GRUB menu) all written and confirmed working by real install/boot testing, not
      just config review. `ckbcomp` built and published to `oblinux_repo` alongside
      `calamares`/`paru`. A fresh erase-disk install completes cleanly and the resulting system
      boots on its own — GRUB (themed), Plymouth, GDM, GNOME desktop login, `sudo`, and zsh as
      the default shell all confirmed working.
      - Getting to a clean install took 8 rounds of testing (8–15), each fix uncovering the next
        issue further into the sequence: a `shellprocess` placeholder token, `mount.conf`'s
        `options: bind` needing to be a YAML list, a live-only `linux.preset` left in place,
        `packages.conf` missing `backend: pacman`, two wrong keys in `users.conf`
        (`userShell`/`passwordRequirements.nonempty`), and `grubcfg.conf`'s entire `defaults:`
        block silently never being applied (needs `always_use_defaults: true`, not obvious from
        the schema alone).
      - Full round-by-round log with root causes: [`docs/TESTING.md`](docs/TESTING.md).
        Calamares-specific reasoning: [`docs/CALAMARES.md`](docs/CALAMARES.md). GRUB theme
        writeup: [`docs/BRANDING.md`](docs/BRANDING.md).
      - [~] **One known issue, deprioritized rather than blocking**: an intermittent installer
        crash right after choosing the swap option (rounds 8, 12, 14 — non-deterministic,
        auto-recovers, hasn't recurred since). Log analysis narrowed the trigger and ruled out a
        known historical Calamares bug in the same area
        ([PR #2392](https://github.com/calamares/calamares/pull/2392)/
        [issue #2367](https://github.com/calamares/calamares/issues/2367) — GPT-specific, not
        ours). A raw `SIGSEGV` doesn't reach `session.log`, so a real fix needs a
        `coredumpctl`-captured backtrace from an actual reproduction — not chased since it
        doesn't block an install. Revisit if it gets worse.
- [ ] Default application package list (user-controlled — TBD)

## Implementation notes

- `liveuser` has passwordless sudo (`/etc/sudoers.d/g_wheel`) for live-session convenience only.
  Calamares typically clones this live filesystem onto the install target, so **when the Calamares
  config is added, it must explicitly strip or replace that sudoers rule as a post-install step** —
  otherwise it ships on real installs too.
- Package list intentionally does *not* yet include a curated set of end-user apps — that list is
  still TBD and will be added as its own increment.
