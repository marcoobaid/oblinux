# Custom package repo (oblinux_repo)

`calamares` and `paru` are both **AUR-only** — not in the official Arch
repos — so they can't just be added to `packages.x86_64` and picked up by
`pacstrap` like everything else in this profile. Instead they're built once
and published to
[`oblinux_repo`](https://github.com/marcoobaid/oblinux_repo), a small pacman
repo hosted via GitHub Pages at `https://marcoobaid.github.io/oblinux_repo/x86_64`.

Checked before assuming: `calamares`'s own dependencies (`kcoreaddons`,
`kpmcore`, `qt6-declarative`, etc.) are all in official repos — it's a
single AUR package to build, not a deep transitive AUR chain.

## Wired in

- `pacman.conf` (repo root) — build-time only, lets `mkarchiso`'s `pacstrap`
  install `calamares`/`paru` from `oblinux_repo` during the ISO build.
- `airootfs/etc/pacman.conf` — the same `[oblinux_repo]` section, but
  persisted onto the live session and installed systems, so the repo stays
  usable after boot too (this is the actual point of hosting it durably
  rather than building locally on the build machine only — future custom
  OBLinux packages can be pushed here and pulled by already-installed
  systems).
- `packages.x86_64` — `calamares` and `paru` added directly, same as any
  other package, now that they resolve via `oblinux_repo`.

## Build/publish workflow

See `oblinux_repo`'s own README for the exact steps (`makepkg`, then
`x86_64/update_repo.sh` to regenerate the repo database, then commit/push).
Short version: **packages must be built and published to `oblinux_repo`
before running `mkarchiso`** — if `calamares`/`paru` aren't there yet,
`pacstrap` will fail to resolve them and the ISO build will fail.

## Why not a `oblinux-calamares-config` package

Calamares' own config/branding (`settings.conf`, module configs,
`branding.desc`) is **not** packaged — it ships as plain files under
`airootfs/etc/calamares/`, the same way every other config in this project
does (GDM's schema override, the Plymouth theme, sudoers, etc.). It's
static YAML/desc content with no build step, and during active iteration on
it, packaging would mean every tweak needs a full build → `repo-add` →
publish cycle before it even reaches a test ISO build, instead of just
editing the file and rebuilding directly. `oblinux_repo` is for things that
actually need compiling.

## Signing — deferred, not skipped

Packages are currently unsigned (`SigLevel = Optional TrustedOnly`).
Confirmed this doesn't create rework later: signing is a layer added on top
(generate a key, `repo-add -s`, seed trust on the consuming side) — it
doesn't require redoing the repo structure or any package already built.
Deferred for now since it adds real setup ceremony (key generation, secure
private-key backup, trust-seeding) that isn't needed to get Calamares
working. TODO before shipping this more broadly.
