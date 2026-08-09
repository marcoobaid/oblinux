# Calamares installer

`airootfs/etc/calamares/` — `settings.conf`, per-module configs under
`modules/`, and branding under `branding/oblinux/`. Everything here is
plain files, not a package — see `docs/CUSTOM_REPO.md` for why.

## How this was built

Not written from scratch or from memory. Two sources, cross-checked
against each other:

1. **Calamares' own current source** (`github.com/calamares/calamares`,
   `calamares` branch) — the authoritative schema for every module config
   key used here. Several settings in the most obvious reference material
   turned out to be wrong or outdated against this:
   - `bootloader.conf`'s `kernel`/`img`/`fallback`/`timeout` keys don't
     exist in the current schema at all (an older Calamares version had
     them).
   - `grubcfg.conf`'s distributor-name key is `keep_distributor`
     (snake_case), not `keepDistributor`.
   - `branding.desc`'s style keys are `SidebarBackground`/`SidebarText`/
     `SidebarTextCurrent`/`SidebarBackgroundCurrent`, not
     `sidebarBackground`/`sidebarText`/`sidebarTextSelect`/
     `sidebarTextHighlight`.
   - `GRUB_DISTRIBUTOR` isn't a manual `grubcfg.conf` default at all —
     it's calculated from `branding.desc`'s `bootloaderEntryName`.
   - the `shellprocess` module's placeholder token is `${ROOT}`, not
     `@@ROOT@@` — the latter is what the reference project's older
     Calamares version used. This one wasn't caught in review (it's valid
     YAML either way, so nothing failed to parse) and only surfaced in the
     first real install test as a literal, unsubstituted path handed to
     `sed`/`rm`. See "Round 8" in `docs/TESTING.md`.
2. **uarchiso's `archiso-calamares-config`**
   (`gitlab.com/uaiso/labs/uarchiso/archiso-calamares-config`, found via
   the AUR package of the same name) — a real, working Calamares config
   for an archiso-based distro. Useful for structure and for things
   Calamares' own generic docs don't spell out, most importantly:
   - `unpackfs` has to separately copy the kernel image — the squashfs
     doesn't include `/boot`'s bootable kernel at all.
   - the general shape of a live-artifact cleanup pass
     (`shellprocess@final`).
   Adapted rather than copied wholesale — it's KDE/SDDM/btrfs-oriented,
   OBLinux is GNOME/GDM/ext4, and several of its settings (see below) were
   corrected against Calamares' own current schema before use.

## Why `initcpiocfg` isn't in the module sequence

`initcpiocfg` edits `/etc/mkinitcpio.conf`'s `HOOKS=` line via
prepend/append/remove on the existing list. That can't express "insert
the `plymouth` hook right after `base`/`udev`" precisely — `prepend` would
put it before `base` entirely, which breaks the initramfs build. Used a
`shellprocess@before` step with `sed` instead, setting the target's
`HOOKS=` line directly and completely, for exact control over ordering.
The line used is OBLinux's own live-boot HOOKS
(`airootfs/etc/mkinitcpio.conf.d/archiso.conf`) with only the archiso/PXE/
memdisk hooks removed and `fsck` added — same relative order already
proven working by this project's own boot testing, not a fresh guess.

That drop-in file itself also has to be deleted on the target (same
shellprocess step) — it's where OBLinux's *live-only* HOOKS actually live;
the base `/etc/mkinitcpio.conf` (shipped untouched by the `mkinitcpio`
package) has no OBLinux-specific configuration of its own at all.

## AUR-only packages this depends on

Same situation as `calamares`/`paru` (see `docs/CUSTOM_REPO.md`) —
`ckbcomp` (for the `keyboard` module's layout live-preview) is also
AUR-only. Added to `packages.x86_64`; needs building and publishing to
`oblinux_repo` the same way. Optional in the sense that the installer
still works without it — keyboard selection just loses the live preview.

## Partitioning / filesystem / LVM — scope for this phase

- ext4 only: no `availableFileSystemTypes` list at all (confirmed via
  Calamares' own docs: omitting it means no filesystem-choice UI is shown,
  cleanest match for "basic")
- `allowManualPartitioning: false` — hides the manual partition editor
  only; Erase/Replace/Alongside (the automated modes) stay available,
  Calamares doesn't support hiding those individually
- LVM disabled (`lvm.enable: false`)
- No disk encryption (LUKS) support — `luksbootkeyfile`/
  `luksopenswaphookcfg` dropped from the sequence entirely

## Live-artifact cleanup — what and why

`unpackfs` clones the live filesystem as-is, so anything live-session-only
persists onto the install unless explicitly stripped. Went through
everything this project has actually shipped (not just copied a reference
list) — full reasoning is in `modules/services-systemd.conf` and
`modules/shellprocess-final.conf`'s own comments. Short version:

| What | Where | How |
|---|---|---|
| Passwordless sudo | `/etc/sudoers.d/g_wheel` | removed |
| GDM autologin as liveuser | `/etc/gdm/custom.conf` | disabled, not deleted (keeps the file's section scaffolding) |
| `liveuser` account | — | dedicated `removeuser` module |
| Root tty1 rescue-script mechanism | `/root/.automated_script.sh`, `/root/.zlogin` | removed |
| Passwordless root autologin on tty1 | `getty@tty1.service.d/` | removed |
| Ephemeral pacman keyring mount | `etc-pacman.d-gnupg.mount` | removed (would break signature verification after every reboot otherwise) |
| Live-only first-boot services | `pacman-init.service`, `choose-mirror.service` | masked (`choose-mirror` is interactive — left enabled it could hang an unattended boot) |
| Mirror ranking | `reflector.service` | disabled, not masked (stays available to run manually/periodically) |
| Live-session MOTD | `/etc/motd` | removed |
| The installer itself | `calamares` package | removed via `packages.conf` |

**Not** cleaned up, deliberately: `/etc/issue` (branded console banner,
fine on an installed system too), the GDM background/logo GSettings
override (intentionally becomes the installed system's default too, per
`docs/BRANDING.md`), the accessibility/speech live services (condition on
a kernel cmdline flag that won't be present on a normal boot — harmless
no-ops, not worth the cleanup).

## Branding — status

Real OBLinux assets (mark, Slate & Amber palette) are already wired in —
this wasn't left as generic Calamares placeholder branding, since the
"minimal branded single panel" scope was already decided and the assets
already existed. Slideshow is a single static image
(`slideshow: [ "logo.png" ]`), not QML — matches that same decision, no
feature-showcase content exists yet to justify a multi-slide walkthrough.

## Build/install testing

First real install attempt: see "Round 8" in `docs/TESTING.md`. Summary —
reached ~90% before failing on the `@@ROOT@@` bug described above (now
fixed, not yet re-verified by an actual run). A separate, unexplained
installer crash on selecting the "Swap (no Hibernate)" partitioning option
was also observed once; `partition.conf`'s `userSwapChoices` values
(`none`/`small`) are valid against Calamares' own schema, so this isn't a
config error as far as source review can tell — needs reproducing with a
log captured (Calamares writes to `/var/log/Calamares.log` during install)
before it can be root-caused.
