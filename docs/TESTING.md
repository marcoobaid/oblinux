# Build verification log

## 2026-08-06 — first successful build (VirtualBox)

**Build:** `sudo mkarchiso -v .` on a physical Arch Linux build machine, at
commit `30716ce` (GDM logo + os-release LOGO icon). ISO booted from a
VirtualBox VM (BIOS boot mode). Evidence: 5 screenshots reviewed, described
below by boot stage.

### Confirmed working

| Stage | Evidence | Result |
|---|---|---|
| BIOS boot menu | Screenshot of syslinux menu | "OBLinux" title, correct menu entries (live/install, speech, boot existing OS, Memtest86+, HDT, reboot, power off), our ring mark visible in the background |
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

Marco checked items 1–4 and 6 from the previous round's "not yet tested"
list, with screenshots + `aur-bootstrap.log` output.

### Confirmed working

| Stage | Evidence | Result |
|---|---|---|
| NetworkManager | Settings → Network screenshot | "Wired — Connected — 1000 Mb/s" |
| Passwordless sudo | Terminal screenshot | `sudo pacman -Syyu` ran straight to syncing, no password prompt |
| `~/.zshrc` deployed | `cat ~/.zshrc` output | File present with exactly the content we wrote |

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
  before every prompt render, silently overriding our static `PS1=` line
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

After the round-2 fixes, Marco rebuilt and immediately hit `write error: no
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

**My first theory was wrong and worth recording as a correction**: I
initially assumed this meant the VM had too little RAM (archiso's cowspace
is tmpfs-backed, and I assumed a RAM-percentage default). Marco correctly
pushed back — the VM's RAM was 4096MB, unchanged from the first successful
round. Checking archiso's actual source (`mkinitcpio-archiso`'s `hooks/archiso`)
rather than continuing to guess turned up the real cause:
```bash
cow_spacesize="$(getarg 'cow_spacesize' '256M')"
```
`cow_spacesize` is a **hardcoded 256M default**, completely unrelated to
RAM, unless a distro's own boot config explicitly overrides it with
`cow_spacesize=` on the kernel command line. We never did — a real gap in
our own `syslinux`/`efiboot` configs, not a VM setting.

**Fix**: added `cow_spacesize=75%` (adapts to whatever RAM is actually
available) to all four live-boot kernel command lines — BIOS main + speech
(`syslinux/archiso_sys-linux.cfg`), UEFI main + speech
(`efiboot/loader/entries/0{1,2}-archiso-*.conf`). PXE entries left alone
(not something we're testing). This should also resolve the `paru` build
failure, which was almost certainly the same disk-space exhaustion, not a
logic bug in the bootstrap script itself.

Not yet re-verified with a fresh build.
