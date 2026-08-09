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
