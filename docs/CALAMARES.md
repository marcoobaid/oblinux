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
   - `users.conf`'s shell setting is `user.shell` (nested under a `user:`
     block), not a flat `userShell` key — again valid YAML either way, so
     it silently fell back to `useradd`'s own default (`/bin/bash`)
     instead of erroring. Caught only by diffing the actual `useradd`
     invocation in `session.log` against what `users.conf` intended.
     `passwordRequirements.nonempty` is the same story: not a real key
     (`minLength`/`maxLength`/`libpwquality` are), and Calamares actually
     logs a warning about it every single run —
     `WARNING: nonempty check is ignored; use minLength: 1` — visible in
     every `session.log` produced by this project so far, unnoticed until
     cross-checking this file against source for the shell bug. Both
     fixed; see round 14 in `docs/TESTING.md` once verified.
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
reached ~90% before failing on the `@@ROOT@@` bug described above (fixed).
A separate, unexplained installer crash on selecting the "Swap (no
Hibernate)" partitioning option was also observed once; `partition.conf`'s
`userSwapChoices` values (`none`/`small`) are valid against Calamares' own
schema, so this isn't a config error as far as source review can tell —
still open, needs reproducing with `~/.cache/calamares/session.log`
captured (see below for the real log location; an earlier answer here
about `/var/log/Calamares.log` was wrong).

Second attempt (round 9): got further, then failed on `mkinitcpio` with
`/dev must be mounted!`. Root cause was in `mount.conf`, not the
`shellprocess` steps — `options: bind` on the `/dev` and `/run/udev`
extraMounts entries needs to be a YAML list (`options: [ bind ]`).
Calamares' mount module does `",".join(partition["options"])`; given a
bare string it iterated the string's characters instead, turning `bind`
into the mount options `b,i,n,d` and silently failing both bind mounts.
Fixed.

Third attempt (round 10): the round 9 fix confirmed working (bind mounts
succeeded in `session.log`), got one step further, then failed on
`mkinitcpio` again — this time `Invalid option -c -- '...archiso.conf'
must be readable`. `airootfs/etc/mkinitcpio.d/linux.preset` (the standard
archiso-profile preset, not OBLinux-authored) still pointed at the
archiso-only mkinitcpio config that `shellprocess-before.conf` correctly
deletes — that step never replaced `linux.preset` itself. Fixed by adding
a step that overwrites it with the standard `default`+`fallback` preset.

Fourth attempt (round 11): the round 10 fix confirmed working —
`mkinitcpio` completed cleanly this time. Swap selected on the
Partitions page with no repeat of the round 8 crash either (not
confirmed fixed, just not reproduced). New failure at the `packages`
job: "Bad backend" / `backend="None"`. `packages.conf` never set the
required top-level `backend` key (verified against
`src/modules/packages/main.py` — `backend =
configuration.get("backend")`, no default, fails exactly this way if
unset or unrecognized). Fixed: added `backend: pacman`.

**Fifth attempt (round 12): first successful end-to-end install.**
`session.log` confirms `completion: succeeded` across all 35 jobs.
Rebooted into the installed system — GRUB, Plymouth, GDM, desktop login
all confirmed working. `packages.conf`'s missing `backend` key was
therefore the last blocking bug in the install sequence itself. Two
small follow-ups came out of this round: `/etc/calamares` was left
behind on the installed system (fixed, added to
`shellprocess-final.conf`), and `session.log` evidence suggests the
round 8 swap-dropdown crash recurred (auto-recovered, still not
root-caused).

**Round 13** confirmed the `/etc/calamares` fix — no longer present on
the installed system. Phase 2's core goal (a basic OBLinux system
installable via Calamares, that boots on its own afterward) is now
verified working end-to-end, repeatably. Full log analysis in
`docs/TESTING.md`, rounds 9-13.

**Polish pass after round 13** (closing out remaining open items rather
than starting phase 3/4): `users.conf` had two more of these
valid-YAML-but-wrong-key bugs — `userShell` isn't real (`user.shell`,
nested, is) and `passwordRequirements.nonempty` isn't real either
(`minLength: 1` is), the second one independently confirmed by a warning
Calamares has been logging on every single run so far, unnoticed until
now. Also found and fixed: `grubcfg.conf` was forcing
`GRUB_TERMINAL_OUTPUT: "console"`, which is why the installed system's
GRUB menu stayed unthemed through every round — full writeup in
`docs/BRANDING.md`'s new GRUB section, since it's fundamentally a
branding asset, not a Calamares-specific one.

**Correction**: that `GRUB_TERMINAL_OUTPUT` fix alone wasn't sufficient
— round 14's test still failed to render the theme. Real cause, found
only by reading the actual installed target's `/etc/default/grub` and
`grub.cfg` rather than re-reading `theme.txt` again: `grubcfg.conf`'s
entire `defaults:` block (all 8 keys, not just the theme-related ones)
was being silently skipped by the `grubcfg` module every round —
requires `always_use_defaults: true` to actually apply, which this
project's config never set. This is also a correction to this doc's own
earlier claim ("verified... checked `src/modules/grubcfg/main.py`
directly") — that check read the file but missed this exact gating
condition; pulling the file fully verbatim the second time (rather than
a summarized read) is what actually caught it. Full details in
`docs/BRANDING.md`'s GRUB section.

**Round 15 confirmed the fix** — GRUB theme renders correctly on the
installed system.

**Round 16, first real-hardware attempt**: failed immediately at
`unpackfs` — `unpackfs.conf`'s hardcoded source path only stays valid
if archiso's `copytoram` boot feature is off, and it auto-enables under
conditions a real USB stick on a well-specced laptop meets but a
VirtualBox VM (attached ISO mounts as virtual optical media) structurally
cannot. All 15 prior rounds were VM-only, so this was never reachable
until now. Fixed at the boot-parameter level (`copytoram=n` on every
live-boot entry) rather than in `unpackfs.conf` itself — full reasoning
in `unpackfs.conf`'s own header comment and `docs/TESTING.md` round 16.
Not yet re-verified.

**Swap-dropdown crash investigation** (round 8's open item): compared
the crashed and successful runs in round 12's `session.log` line by
line. Selecting "Erase disk" alone always logs a clean 3-job queue
(table, root partition, flags); the crash happens specifically in
whatever handles the swap dropdown's selection changing afterward — the
crashed run's log stops mid-partitioning-setup, before a single log line
from that recompute path (`swapSuggestion()`, the second `CreatePartitionJob`
for swap) ever printed. Checked for a known cause rather than guess:
[PR #2392](https://github.com/calamares/calamares/pull/2392) fixed a
real swap+"Erase disk" crash
([issue #2367](https://github.com/calamares/calamares/issues/2367)),
but it's GPT-specific (partition boundary math for `lastSectorForRoot`);
OBLinux uses `msdos`/MBR tables on BIOS, a different code path, and the
fix is already in Calamares 3.4.2 (the version we use) regardless of
partition table type. Not our bug. A raw `SIGSEGV` kills the process
before Qt/Calamares logs anything about it, so `session.log` can't show
the crash itself — only the last thing that happened before it. Further
root-causing needs a `coredumpctl`-captured backtrace from an actual
reproduction (`systemd-coredump` should already be active, no extra
setup — part of `systemd`/`base`). **Deprioritized, not chased further
for now** (user's call) — it auto-recovers and doesn't block an install.

Calamares' own session log is `~/.cache/calamares/session.log` (Qt cache
location, falling back to `$HOME` then `/tmp`) — verified against
`libcalamares/utils/Dirs.cpp`/`Logger.cpp`, not assumed. Since Calamares
runs via `pkexec`, `HOME` is normally reset to the elevated user, so on
the live session this is `/root/.cache/calamares/session.log`, readable
via `sudo`. This log — not a screenshot — is what actually diagnosed both
round 8 and round 9's failures.
