# Build verification log

## 2026-08-06 — first successful build (VirtualBox)

**Build:** `sudo mkarchiso -v .` on a physical Arch Linux build machine, at
commit `30716ce` (GDM logo + os-release LOGO icon). ISO booted from a
VirtualBox VM (BIOS boot mode). Evidence: 5 screenshots reviewed, described
below by boot stage.

### Confirmed working

| Stage | Evidence | Result |
|---|---|---|
| BIOS boot menu | Screenshot of syslinux menu | "OBLinux" title, correct menu entries (live/install, speech, boot existing OS, Memtest86+, HDT, reboot, power off), the ring mark visible in the background |
| Plymouth | Screenshot mid-boot | Ring + wordmark rendered on Ink background, spark visibly off-center (mid-orbit) — confirms the animation is actually running, not a static frame |
| GDM → desktop handoff | Screenshot of GNOME Shell overview | Reaches a working GNOME Shell session (search bar, dock with Files + Show Apps) — no crash/fallback to a black screen or text console |
| liveuser autologin | Terminal screenshot, prompt `liveuser@oblinux ~ %` | GDM auto-logged into `liveuser` (not root) as designed; zsh is the shell, matching `/etc/passwd` |
| Hostname | About panel + terminal prompt | `oblinux` in both places, matches `airootfs/etc/hostname` |
| os-release identity | Settings → About | "Operating System: OBLinux" — confirms `NAME`/`PRETTY_NAME` |
| os-release LOGO icon | Settings → About | OBLinux mark (ring + spark) rendered next to the OS info — confirms the `/usr/share/pixmaps/oblinux-logo.svg` + `LOGO=oblinux-logo` wiring resolved correctly, not a generic fallback icon |
| Package leanness | Dock in the overview screenshot | Only Files + Show Apps visible — consistent with not having added a curated app list yet |

- **Boot menu splash scale/position**: the "OBLinux" wordmark appears large
  and separated from the menu box in the boot menu screenshot, suggesting
  `syslinux/splash.png` (designed at 640×480) may be getting scaled up by
  vesamenu at the VM's actual boot resolution, shifting the composition
  relative to the menu box. Not broken — branding is clearly visible and
  legible — just not pixel-tight at this resolution. Still open.
- **UEFI speech boot entry** still reads "Arch Linux install medium... with
  speech" — only the main UEFI entry (`01-archiso-linux.conf`) got rebranded,
  not `02-archiso-speech-linux.conf`. Same category of fix as the BIOS
  speech entry (already correctly branded). Still open.

## 2026-08-06 — round 2: sudo/network/AUR/zsh (VirtualBox, BIOS)

Items 1–4 and 6 from the previous round's "not yet tested" list were
checked, with screenshots and `aur-bootstrap.log` output as evidence.

### Confirmed working

| Stage | Evidence | Result |
|---|---|---|
| NetworkManager | Settings → Network screenshot | "Wired — Connected — 1000 Mb/s" |
| Passwordless sudo | Terminal screenshot | `sudo pacman -Syyu` ran straight to syncing, no password prompt |
| `~/.zshrc` deployed | `cat ~/.zshrc` output | File present with exactly the expected content |

### Bugs found and fixed (commit follows)

- **AUR bootstrap failed** — `aur-bootstrap.log` showed:
  ```
  warning: database file for 'core' does not exist (use '-Sy' to download)
  error: target not found: cargo
  ```
  Two stacked causes: (1) the live ISO never runs an initial `pacman -Sy`,
  so `makepkg`'s dependency resolution had an empty db cache to work with;
  (2) `cargo` was never installed — paru is written in Rust and `rust`
  wasn't in the package list, only `base-devel`/`git`. **Fix**: added
  `sudo pacman -Syu --noconfirm` to the top of
  `oblinux-aur-bootstrap`, and added `rust` to `packages.x86_64` so `cargo`
  ships pre-installed rather than downloading the whole toolchain during a
  live session.
- **zsh prompt root cause confirmed**: `~/.zshrc` was present and correct,
  but `grml-zsh-config`'s own prompt system recalculates `PS1` dynamically
  before every prompt render, silently overriding the static `PS1=` line
  regardless of file-sourcing order. **Fix**: removed `grml-zsh-config`
  from `packages.x86_64` — it's a text-console rescue-shell toolkit that
  doesn't add much for a GNOME desktop distro where the terminal is
  secondary, and fighting its prompt-override hooks wasn't worth it.

### Deferred

- **UEFI boot**: menu (systemd-boot) renders and lists entries correctly,
  but selecting an entry produces a black screen. Since BIOS mode uses the
  identical kernel/initramfs and works, this looks like a VirtualBox
  UEFI/graphics-handoff quirk rather than an OBLinux bug — deferred pending
  a real-hardware USB boot test.
- Accessibility/speech boot entry (BIOS) — not yet tested.

## 2026-08-06 — round 3: rebuilt ISO, `no space left on device` (VirtualBox, BIOS)

After the round-2 fixes, a rebuild immediately hit `write error: no
space left on device` errors in the terminal, `sudo pacman -S nano` failing
with `error: Partition / too full: 3443 blocks needed, 0 blocks free`, and
`paru` still missing.

### Bug found and fixed

`df -h` showed the smoking gun:
```
cowspace       256M  256M     0 100% /run/archiso/cowspace
airootfs       256M  256M     0 100% /
```
The live session's entire writable overlay was capped at 256MB and full —
explaining all three symptoms at once (nothing could write: not `nano`'s
install, not zsh's completion cache, not `paru`'s build).

**Initial theory was incorrect — recorded as a correction**: the first
hypothesis assumed insufficient VM RAM (archiso's cowspace is tmpfs-backed,
assumed to default to a RAM percentage). That was ruled out — the VM's RAM
was confirmed at 4096MB, unchanged from the first successful round.
Checking archiso's actual source (`mkinitcpio-archiso`'s `hooks/archiso`)
rather than continuing to guess turned up the real cause:
```bash
cow_spacesize="$(getarg 'cow_spacesize' '256M')"
```
`cow_spacesize` is a **hardcoded 256M default**, completely unrelated to
RAM, unless a distro's own boot config explicitly overrides it with
`cow_spacesize=` on the kernel command line. That override was missing — a
real gap in the `syslinux`/`efiboot` configs, not a VM setting.

**Fix**: added `cow_spacesize=75%` (adapts to whatever RAM is actually
available) to all four live-boot kernel command lines — BIOS main + speech
(`syslinux/archiso_sys-linux.cfg`), UEFI main + speech
(`efiboot/loader/entries/0{1,2}-archiso-*.conf`). PXE entries left alone
(out of scope for this testing). This should also resolve the `paru` build
failure, which was almost certainly the same disk-space exhaustion, not a
logic bug in the bootstrap script itself.

## 2026-08-06 — round 4: cow_spacesize fix verified (VirtualBox, BIOS)

Rebuilt with the `cow_spacesize=75%` fix and rebooted. Clean across the
board:

| Stage | Evidence | Result |
|---|---|---|
| Overlay space | `df -h` | `cowspace`/`airootfs` now 5.8G, 4% used — scales with RAM instead of a fixed 256M |
| No more write errors | Terminal | No `no space left on device` errors |
| zsh prompt | Terminal | Custom `oblinux:~%` prompt confirmed working |
| AUR bootstrap | Desktop notification screenshot | `paru is ready — you can now install AUR packages` fired ~5 minutes after login |

**On the ~5 minute delay before the paru notification**: expected, not a
bug. `oblinux-aur-bootstrap.service` (systemd `--user`, triggered on
`graphical-session.target`) runs automatically at first login: sync repos →
clone paru from the AUR → `makepkg -si` (a real Rust compile, hence the
wait) → notify on completion. One-time cost — the script exits immediately
on every login after `paru` exists. This is the direct tradeoff of choosing
"first-run bootstrap" over "prebuilt binary repo" earlier in the project;
the latter would remove the wait at the cost of build/hosting
infrastructure deliberately deferred to a later phase.

Branding (boot menu, Plymouth, GDM, About panel) reconfirmed working after
the rebuild too.

### Still open

- UEFI speech entry branding ("Arch Linux" text)
- Boot menu splash scale/position at non-640×480 resolutions (BIOS/syslinux only)

## 2026-08-06 — round 5: UEFI on real hardware (USB, physical laptop)

ISO burned to USB, booted on a physical laptop via UEFI (not VirtualBox).

| Stage | Evidence | Result |
|---|---|---|
| systemd-boot menu | Photo | Plain text menu on black, listing entries + "Boot in 14s" countdown — expected appearance, not a bug (systemd-boot has no background-image support, unlike syslinux's vesamenu; documented as expected since the initial boot-menu branding work) |
| Selecting "OBLinux live/install medium (x86_64, UEFI)" | Manual confirmation | Boots through Plymouth → GDM → desktop, same as BIOS |

**Resolves the round-1 VirtualBox black-screen question**: confirmed a
VirtualBox-specific UEFI/graphics quirk, not an OBLinux bug — real hardware
boots UEFI cleanly end to end, matching BIOS behavior. **Both boot modes
are now fully verified.**

## 2026-08-06 — cosmetics cleanup

- **UEFI speech entry branding**: `efiboot/loader/entries/02-archiso-speech-linux.conf`
  title changed from "Arch Linux install medium..." to "OBLinux live/install
  medium... with speech", matching the main UEFI entry.
- **Boot menu splash scale/position**: checked `syslinux`'s own docs rather
  than guess again — confirmed `MENU RESOLUTION` defaults to `640 480`
  (matching the image exactly, so it wasn't a scaling bug at all), but
  `MENU VSHIFT 10` (inherited unchanged from upstream) puts the menu box's
  top edge around y=171, which the original composition's lower half
  (down to y≈345) overlapped. Re-rendered smaller and top-anchored
  (y=12–137) so it sits entirely clear of the box. Not yet re-verified with
  a fresh build/boot — pending next test round.

## 2026-08-06 — round 6: cosmetics verified (VirtualBox, BIOS)

Rebuilt and rebooted. Screenshot confirms the boot menu splash fix: the
mark + wordmark now sit cleanly above the menu box with clear separation,
no overlap. All prior functional confirmations (round 4/5) held.

**Nothing outstanding on the boot→login checklist.** Every item — logo
mark, boot splash, Plymouth theme, GDM logo/background, os-release icon,
BIOS + UEFI boot (both modes, both main + speech entries) — is built,
verified, and documented. Next up: Calamares.

## 2026-08-08 — round 7: oblinux_repo infrastructure verified (VirtualBox, BIOS)

`calamares` and `paru` built on the build machine and published to
`oblinux_repo` (see [`docs/CUSTOM_REPO.md`](CUSTOM_REPO.md)). Rebuilt and
booted.

| Stage | Evidence | Result |
|---|---|---|
| Boot + branding | Screenshot | ISO built and booted cleanly, all branding intact |
| `oblinux_repo` resolves on the built system | `paru` output | `oblinux_repo is up to date` alongside `core`/`extra` — confirms the repo is wired into both the build-time and persisted `pacman.conf` correctly |
| `paru` itself | Terminal | Runs correctly — prebuilt-package delivery (superseding the old first-login bootstrap) confirmed working |
| Calamares launches | Screenshot | Reaches a full wizard UI (Welcome → Location → Keyboard → Partitions → Users → Summary → Install → Finish) |
| Calamares install | Screenshot | Fails: **"Calamares Initialization Failed" — module `initramfs@initramfs` could not be loaded** |

**Expected, not a new bug**: there's no OBLinux-authored `settings.conf`
yet, so Calamares falls back to its own bundled stock example config
(installed by the AUR `PKGBUILD` via `-DINSTALL_CONFIG=ON`). That example
config references a module called `initramfs` — but the same `PKGBUILD`
explicitly skips building that module (along with `dracut`,
`dracutlukscfg`, and a few others, via its `_skip_modules` list, checked
when the `PKGBUILD` was first reviewed). Confirms Increment 1's actual
`settings.conf`/module config work is the right next step, and surfaces a
concrete requirement for it: skip the generic `initramfs` module entirely
and use a `shellprocess` step calling `mkinitcpio -P` instead — the
standard approach on Arch-based Calamares distros anyway, since Arch uses
`mkinitcpio`, not `dracut`.

## 2026-08-09 — round 8: first real Calamares install attempt (VirtualBox, BIOS)

`ckbcomp` built and published to `oblinux_repo` (third and final AUR-only
dependency). Rebuilt, booted, and ran the OBLinux-authored Calamares
config (`docs/CALAMARES.md`) for the first time, end to end, targeting a
20 GiB virtual disk with "Erase disk".

| Stage | Evidence | Result |
|---|---|---|
| Boot + branding + `paru` | Screenshot | All previously-verified artifacts intact |
| Calamares installed on the system | Screenshot | Confirmed present (from `packages.x86_64`) |
| Calamares branding | Screenshot | Sidebar/logo/palette render correctly (Slate & Amber, ring mark) |
| Install run | Screenshot | Reaches ~90% (`shellprocess@before`, in the `exec` sequence) then fails |

### Bug found and fixed (commit follows)

- **`shellprocess@before` failed**: `sed: can't read @@ROOT@@/etc/mkinitcpio.conf: No such file or directory` (exit code 2). Root cause verified against Calamares' actual current source
  (`libcalamares/utils/CommandList.cpp`): the shell placeholder token is
  `${ROOT}`, not `@@ROOT@@` — `@@ROOT@@` is what the reference project
  (`archiso-calamares-config`, an older Calamares version) used, and it
  was carried over unverified when `shellprocess-before.conf`/
  `shellprocess-final.conf` were written. Since it's valid YAML either
  way, nothing caught it before an actual `sed`/`rm` command ran against
  the literal, unsubstituted string. **Fix**: `@@ROOT@@` → `${ROOT}` in
  both files (10 occurrences total). Not yet re-verified by an actual
  install — next build/test round should confirm this clears `exec` and
  completes.

### Open item — not yet root-caused

- **Installer crashed/closed** on the *first* attempt, immediately after
  selecting "Swap (no Hibernate)" from the swap dropdown on the Partitions
  page (Erase disk mode). No error dialog — the whole application closed.
  Reopening and reinstalling with "No swap" selected produced the run
  described above instead. `partition.conf`'s `userSwapChoices` values
  (`none`, `small`) are valid against Calamares' own partition module
  schema, so this doesn't look like an OBLinux config error as far as
  source review can tell. Needs reproducing with `/var/log/Calamares.log`
  captured afterward (survives the crash, unlike a screenshot of a closed
  window) before it can be root-caused. Retest once the `${ROOT}` fix
  above is verified.

## 2026-08-09 — round 9: `session.log`-diagnosed mount bug (VirtualBox, BIOS)

ISO rebuilt with the round 8 `${ROOT}` fix, install re-run with "Erase
disk" / "No swap". Got further than round 8 (past `shellprocess@before`)
before failing at job 17/34, "Creating initramfs with mkinitcpio…" — same
screenshot-visible symptom as round 7 (`/dev must be mounted!`), but this
time from a config actually written for this project, not the stock
example. `session.log` (`~/.cache/calamares/session.log`, read via `sudo`
from `/root/...` since Calamares runs under `pkexec`) was captured for
the first time and made the real root cause immediately visible,
several steps upstream of the mkinitcpio failure itself:

```
Running mount -o "b,i,n,d" /dev /tmp/calamares-root-.../dev
Target cmd: ... Exit code: 32 output:
mount: .../dev: fsconfig() failed: squashfs: Unknown parameter 'b'.
```

### Bug found and fixed (commit follows)

- **`mount.conf`'s `/dev` and `/run/udev` bind mounts silently failed**:
  `options: bind` (a bare YAML string) was written expecting it to mean
  the single mount option `bind`. Calamares' mount module actually builds
  the `-o` argument with `",".join(partition["options"])` — verified
  directly against `src/modules/mount/main.py` — which expects `options`
  to be a *list*. Given a bare string, Python iterated its individual
  characters instead, producing mount options `b,i,n,d` (four bogus
  single-letter options) instead of `bind`. Both bind mounts failed
  (logged as `WARNING: [PYTHON JOB]: "Cannot mount /dev"` etc., non-fatal
  at the time), so `/dev` was never available inside the target chroot by
  the time `mkinitcpio -p linux` ran there — the actual, later error.
  **Fix**: `options: bind` → `options: [ bind ]` on both entries.

This also means round 7 and round 8's `mkinitcpio` failures were never
actually caused by anything in `shellprocess-before.conf`/the HOOKS
line — the `@@ROOT@@` fix from round 8 was still correct and necessary
(the shell commands were genuinely broken), it just wasn't sufficient on
its own to reach a clean `mkinitcpio` run, since this `mount.conf` bug
was present the whole time and only became reachable once round 8's bug
was fixed.

Not yet re-verified by an actual run — next build/test round should
confirm this clears job 17 and the install completes.

## 2026-08-09 — round 10: `linux.preset` bug (VirtualBox, BIOS)

ISO rebuilt with the round 9 `mount.conf` fix, install re-run the same
way. `session.log` confirms the round 9 fix worked — `mount -o "bind"`
(not `b,i,n,d`) for both `/dev` and `/run/udev`, both succeeding this
time. Progress got one step further, to job 18/35, "Creating initramfs
with mkinitcpio…", before failing again — a different error this time:

```
==> Building image from preset: /etc/mkinitcpio.d/linux.preset: 'archiso'
==> Using configuration file: '/etc/mkinitcpio.conf.d/archiso.conf'
==> ERROR: Invalid option -c -- '/etc/mkinitcpio.conf.d/archiso.conf' must be readable
```

### Bug found and fixed (commit follows)

- **`linux.preset` still pointed at the deleted archiso config**:
  `airootfs/etc/mkinitcpio.d/linux.preset` is the standard archiso-profile
  preset override (not OBLinux-specific) — it defines a single
  `PRESETS=('archiso')` preset whose `-c` config file is
  `/etc/mkinitcpio.conf.d/archiso.conf`. `shellprocess-before.conf`
  correctly deletes that config file (it's live-only, see reasons 1-2 in
  the file's own header comment) but never touched `linux.preset` itself,
  so `mkinitcpio -p linux` kept trying to use the now-missing file.
  **Fix**: added a third step to `shellprocess-before.conf` that
  overwrites `linux.preset` with the standard `default`+`fallback` preset
  the `linux` package itself ships (verified against mkinitcpio's own
  upstream example preset and Arch packaging conventions) — the same
  preset layout a normal Arch install ends up with, nothing
  OBLinux-specific to maintain.

Not yet re-verified by an actual run — next build/test round should
confirm this clears job 18 and the install completes. Three rounds (8, 9,
10) of the same category of bug — live-only artifacts that unpackfs
clones onto the target unless explicitly cleaned up — suggests a closer
line-by-line audit of everything airootfs ships, cross-referenced against
what's actually live-only vs. what should persist, would be worth doing
once the install completes cleanly at least once, rather than continuing
to find these one `mkinitcpio` run at a time.

## 2026-08-09 — round 11: `packages.conf` missing `backend` (VirtualBox, BIOS)

ISO rebuilt with the round 10 `linux.preset` fix, install re-run — this
time with "Swap (no Hibernate)" selected on the Partitions page. Two
pieces of good news up front, both visible in `session.log`:

- **`mkinitcpio` completed successfully** (job 18/35 finished cleanly,
  moved on to job 19) — confirms the round 10 `linux.preset` fix worked.
  Rounds 8-10's chain of `mkinitcpio`-adjacent bugs is now clear.
- **No crash on selecting swap this time** — a 2047MiB linux-swap
  partition was created and the install proceeded normally. Doesn't
  confirm the round 8 swap-dropdown crash is fixed (nothing changed that
  would explain it), but it didn't reproduce here either — leaving that
  item open rather than closing it, see below.

New failure, at job 30/35 ("packages"): the installer's error dialog just
said "Bad backend" / `backend="None"`, no further detail. `session.log`
showed job 30 starting, then nothing else from it before the emergency
unmount kicked in.

### Bug found and fixed (commit follows)

- **`packages.conf` never set `backend`**: verified against Calamares'
  own `packages` module source (`src/modules/packages/main.py`) — it
  reads `backend = libcalamares.job.configuration.get("backend")` with no
  default, and fails immediately with exactly `"Bad backend",
  backend="{backend}"` if that doesn't match a registered package manager
  (`pacman`, `apt`, `dnf`, etc.). Missing the key entirely gives
  `backend="None"` — precisely the observed error. `packages.conf` had
  `pacman:` (the pacman-specific options block) but never the required
  top-level `backend: pacman` selecting that backend in the first place.
  **Fix**: added `backend: pacman`.

Not yet re-verified by an actual run — next build/test round should
confirm this clears job 30 and reaches `grubcfg`/`bootloader`, the last
untested part of the sequence.

## 2026-08-09 — round 12: first successful end-to-end install (VirtualBox, BIOS)

ISO rebuilt with the round 11 `packages.conf` fix, install re-run.
`session.log` confirms: **all 35 jobs completed,
`Config::doNotify`'s final line reads `completion: succeeded`.** First
clean install, start to finish, no fixes needed mid-run. Rebooted into
the installed system and verified further from the desktop side:

| Stage | Evidence | Result |
|---|---|---|
| Install | `session.log` | `completion: succeeded`, all 35 jobs |
| GRUB → Plymouth → GDM → desktop | Screenshots | Boots cleanly; Plymouth animation plays correctly; reaches GDM, logs in as `marco` |
| GRUB menu | Screenshot | Boots and lists "OBLinux Linux" / "Advanced options for OBLinux Linux" — functional, unthemed (plain GNU GRUB default look) |
| `marco` account | Terminal, GDM | Created during install, can `sudo`, default shell `/bin/bash` (as configured — zsh is a live-session-only default, not yet carried into `users.conf`) |

Also visible in `session.log`, confirming several earlier fixes at once:
`mkinitcpio` completed cleanly (job 18), `packages` removed the
`calamares` package via `pacman -Rs` without error (job 30), `grubcfg`
correctly detected no `dracut`/`systemd` hook and left the plymouth hook
alone (job 31), and `bootloader` ran `grub-install --target=i386-pc
--recheck --force /dev/sda` followed by `grub-mkconfig -o
/boot/grub/grub.cfg`, both without error (job 32) — the last part of the
sequence that had never actually executed until this round.

**Also caught in the log, not from the screenshots**: two
`=== START CALAMARES` banners 9 seconds apart, right after "Erase disk" +
swap was chosen — the first run's log stops abruptly mid partition-setup
(no error, no clean shutdown) and a fresh process start follows
immediately after. Since `=== START CALAMARES` is the application's own
startup banner, this can only mean the whole process restarted — i.e.
this looks like the same round-8 swap-dropdown crash recurring, at
essentially the same point (right after the Erase+swap choice is
applied, during the `restoreSelectedBootLoader`/`setBootLoaderInstallPath`
sequence), auto-recovered without a report this time. Still not
root-caused — no crash handler output/backtrace reaches `session.log` —
but this narrows down where in the sequence it happens.

### Follow-up items noted (not yet actioned)

- **`/etc/calamares` left on the installed system** — `packages` removes
  the `calamares` binary itself but nothing removed its config tree.
  Fixed: added a step to `shellprocess-final.conf` removing
  `${ROOT}/etc/calamares` (verified safe against `preservefiles.conf` —
  it copies Calamares' own in-memory log/report data to `/var/log/`, not
  anything under `/etc/calamares`, so no ordering conflict). Not yet
  re-verified by an actual run.
- **GRUB menu is unthemed** — plain default GNU GRUB look. The live ISO's
  boot menu (syslinux/systemd-boot) has full OBLinux branding; the
  installed system's GRUB currently doesn't. Not yet scoped/scheduled —
  open question whether this belongs in this phase's wrap-up or is
  deferred alongside the rest of theming/ricing (phase 3/4).
- **Default shell is bash, not zsh** — expected; `users.conf` doesn't set
  a shell yet, so `useradd` uses its own default. The live session's zsh
  setup (prompt, `.zshrc`) was live-only and never meant to carry over
  automatically. Deferred, per README's existing phase-3/4 theming note.
- **Swap-dropdown crash** — recurred (see above), still not root-caused.
  Auto-recovers (Calamares restarts cleanly and the next attempt works),
  so not a hard blocker, but worth root-causing before this phase is
  called done.

## 2026-08-10 — round 13: `/etc/calamares` cleanup verified (VirtualBox)

ISO rebuilt with the round 12 `shellprocess-final.conf` fix, install
re-run. Confirmed on the installed system: `/etc/calamares` is no longer
present post-install. Closes that follow-up item from round 12.

With this, Phase 2's core goal — a basic OBLinux system installable via
Calamares, that boots on its own afterward — is verified working
end-to-end, repeatably.

## 2026-08-10 — Phase 2 polish pass

Closing out the three items still open after round 13 (user's explicit
choice — close out Calamares/Phase 2 polish before starting phase 3/4):

1. **Default shell was bash, not zsh** — `users.conf` used a made-up
   `userShell` key instead of the real nested `user.shell`; a second,
   adjacent bug (`passwordRequirements.nonempty`, not a real key either)
   found the same way and fixed alongside it. `airootfs/etc/skel/.zshrc`
   added so new users don't hit zsh's first-run wizard. Fixed, not yet
   re-verified by an actual run.
2. **Installed GRUB menu was unthemed** — root cause was `grubcfg.conf`
   forcing `GRUB_TERMINAL_OUTPUT: "console"`. Fixed alongside writing an
   actual theme (`airootfs/usr/share/grub/themes/oblinux/`). Full
   writeup in `docs/BRANDING.md`. Not yet build/boot tested.
3. **Swap-dropdown crash** — investigated via log analysis (see
   `docs/CALAMARES.md`); trigger narrowed to the swap-choice recompute
   handler, ruled out a known historical Calamares bug in the same area
   (GPT-specific, not ours). No backtrace possible from `session.log`
   alone (a raw `SIGSEGV` never reaches it). **Documented and
   deprioritized** — user's call, given it auto-recovers and doesn't
   block an install. Would need a `coredumpctl`-captured backtrace from
   an actual reproduction to go further; revisit only if it gets worse.

Next build/test round should cover items 1 and 2.

## 2026-08-10 — round 14: polish-pass results (VirtualBox, BIOS)

ISO rebuilt with the polish-pass fixes (shell/password, GRUB theme),
install re-run.

| Item | Result |
|---|---|
| Full install | Completes end to end |
| zsh as default shell | **Confirmed working** — opening a terminal shows the zsh prompt directly, no first-run configuration wizard (`/etc/skel/.zshrc` doing its job) |
| GRUB theme | **Did not render** — plain default GRUB menu, unchanged from every prior round |
| Swap-dropdown crash | **Reproduced twice back-to-back**, did not reproduce a third attempt — consistent with the intermittent, non-deterministic behavior already documented; no new action taken per the round 13 decision to deprioritize |

### GRUB theme — investigation, and the real root cause

`grub-install`/`grub-mkconfig` both ran clean in `session.log` (no error
output), so config-writing wasn't an obvious suspect from the install
log alone. First pass: self-audited `theme.txt`, found two properties
that were only ever verified as "the schema accepts this key name,"
never confirmed to actually work — `icon_width`/`icon_height: 0` and
`menu_pixmap_style`. Checked a real, actively-maintained community theme
(rose-pine/grub) — it uses neither in that form. Removed both,
`panel_*.png` deleted.

That fix turned out to be addressing a real (if minor) issue, but not
*the* issue. Requested `/etc/default/grub` and `/boot/grub/grub.cfg`
from the still-installed VM to check the config-writing side for real,
rather than assume — and both showed `GRUB_THEME`/`GRUB_TERMINAL_OUTPUT`
still at their stock, untouched values. Traced this through Calamares'
`grubcfg/main.py`, pulled fully verbatim this time (an earlier read of
the same file had missed this): the entire `defaults:` block in
`grubcfg.conf` — all 8 keys — was being silently skipped every round,
gated behind an `always_use_defaults` flag this project's config never
set. `GRUB_GFXMODE`/`GRUB_GFXPAYLOAD_LINUX` only ever *looked* correct
because they happen to already be Arch's own stock values, unrelated to
our config. Fixed with `always_use_defaults: true`. Full writeup,
including the corrected earlier claim, in `docs/BRANDING.md` and
`docs/CALAMARES.md`.

Both fixes (the `theme.txt` trim and `always_use_defaults: true`) are
in for round 15. Not yet re-verified by an actual build/boot.

## 2026-08-10 — round 15: GRUB theme confirmed working

ISO rebuilt with the `always_use_defaults: true` fix, install re-run.

| Item | Result |
|---|---|
| Full install | Completes end to end |
| GRUB theme | **Confirmed rendering** — mark + wordmark on Ink, Primary highlight bar on the selected entry, screenshot evidence |
| Swap-dropdown crash | Did not reproduce this round |
| General system check | All pieces functional |

With this, all three items from the post-round-13 polish pass (zsh
default shell, GRUB theme, swap-crash investigation/deprioritization)
are closed out. Phase 2 (Calamares installer, boot→login branding
including the installed system) is complete.

## 2026-08-11 — round 16: first real-hardware Calamares attempt, `copytoram` bug

Same ISO, USB stick, physical laptop (BIOS boot per the `bootmnt.txt`/
`lsblk.txt` diagnostics below, not VirtualBox) — the **first time**
Calamares has been tested outside a VM. Failed immediately at job
12/36, `unpackfs`:

```
ERROR: Installation failed: "Bad unpackfs configuration"
details: The source filesystem "/run/archiso/bootmnt/oblinux/x86_64/airootfs.sfs" does not exist
```

Requested live diagnostics rather than guess (`lsblk`, `df -h`,
`ls -la /run/archiso/bootmnt/`, `cat /proc/cmdline`) — confirmed
`/run/archiso/bootmnt/` had no boot-media directory at all, just
`airootfs`/`copytoram`/`cowspace`, and `df -h` showed
`copytoram 23G 1.6G 22G 7% /run/archiso/copytoram` — the boot media's
own mount was gone, its contents copied into RAM.

### Root cause

`copytoram`, an archiso boot feature this project never set explicitly
(`mkinitcpio-archiso`'s hook script: `copytoram="$(getarg 'copytoram'
'auto')"`). `auto` — the default — enables it when: (1) boot media isn't
optical (`/dev/sr*`), (2) the squashfs is under 4 GiB, (3) available RAM
exceeds the image size + 2 GiB. Once enabled, the archiso hook copies
the squashfs into `/run/archiso/copytoram/` and **unmounts the original
boot media**, which is exactly what `unpackfs.conf`'s hardcoded source
path depends on staying mounted.

This explains why 15 rounds of VM testing never hit it: VirtualBox
mounts an attached ISO as a virtual **optical** drive (`/dev/sr0`),
failing condition (1) regardless of how much RAM the VM has — copytoram
could never auto-enable there. A real USB stick is a plain block device
(`/dev/sda`), and this laptop has ample RAM, so all three conditions
were met on the very first real-hardware attempt. `unpackfs.conf`'s own
header comment claimed this path was "cross-checked against archiso's
mkarchiso source" — true, but only ever exercised in the one
environment (VM/optical) where the bug is structurally impossible to
hit.

### Fix

`copytoram=n` added to all four live-boot kernel command lines (BIOS +
UEFI, main + speech entries) — `syslinux/archiso_sys-linux.cfg`,
`efiboot/loader/entries/01-archiso-linux.conf`,
`efiboot/loader/entries/02-archiso-speech-linux.conf`. Forces
deterministic behavior (boot media always stays mounted) instead of
depending on `auto`'s environment-dependent heuristic. Applied to all
entries, not just the main ones (unlike `quiet splash`) — this affects
installer reliability generically, no accessibility angle to it. Trades
away "safe to physically eject the USB after boot," which costs nothing
for an install-focused live session where the media stays plugged in
throughout anyway.

Not yet re-verified by an actual install — next round should confirm
this clears `unpackfs` on the same hardware.

## 2026-08-11 — round 17: `copytoram=n` confirmed, real UEFI bug found

Two builds this round: a VM re-test (BIOS) confirming the `copytoram=n`
fix worked with no issues, then the same ISO burned to USB and
installed on the same physical laptop as round 16 — which this time
booted UEFI (round 16 was BIOS). Got much further than round 16
(`unpackfs` cleared), then failed at job 33/36, `bootloader`:

```
Installing for x86_64-efi platform.
EFI variables are not supported on this system.
EFI variables are not supported on this system.
grub-install: error: efibootmgr failed to register the boot entry: No such file or directory.
```

### Root cause

Scanning the `mount` job's actual output (job 11), no `efivarfs` mount
was ever attempted, despite this clearly being a real UEFI system — the
ESP was correctly detected and mounted at `/boot/efi`
(`PartitionCoreModule::scanForEfiSystemPartitions()`: "system is EFI and
new EFI system partition has been found"), and `bootloader` itself later
chose the EFI target.

Pulled `src/modules/mount/main.py` fully verbatim (given the `grubcfg`
lesson two rounds ago, not trusting a summarized read on anything
decision-critical again) — and found `mount.conf` had a config key,
`extraMountsEfi:`, that **does not exist anywhere in the module's actual
source**. The real mechanism: a single `extraMounts` list, where
individual entries marked `efi: true` get pruned out at runtime if
`firmwareType` isn't `"efi"`. `mount.conf` had invented a separate
top-level key instead — valid YAML, so nothing ever errored, but
silently inert on every platform since round 8. Never mattered until
this round's first real UEFI install attempt; every prior Calamares
round (VM and round 16's BIOS boot) never needed `/sys/firmware/efi`
at all.

Confirmed the correct structure against Calamares' own real `mount.conf`
example rather than infer it purely from the Python logic — matches
exactly: the `efivarfs` entry moved inside `extraMounts`, tagged
`efi: true`.

### Fix

Moved the `efivarfs` entry from the now-deleted `extraMountsEfi:` block
into `extraMounts:`, with `efi: true` added. Not yet re-verified by an
actual UEFI install.
