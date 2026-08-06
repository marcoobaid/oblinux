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

### Observed, not yet investigated (non-blocking)

- **zsh prompt**: terminal shows the plain default-looking `liveuser@oblinux ~ %`
  rather than the custom colored prompt set in
  `airootfs/home/liveuser/.zshrc` (`PS1='%F{cyan}oblinux%f:%~%# '`). Likely
  `grml-zsh-config` (inherited from upstream `releng`'s package list, ships
  its own zsh setup for the live session) taking precedence, or the dotfile
  not being sourced. Cosmetic only — everything else about the liveuser
  session works.
- **Boot menu splash scale/position**: the "OBLinux" wordmark appears large
  and separated from the menu box in the boot menu screenshot, suggesting
  `syslinux/splash.png` (designed at 640×480) may be getting scaled up by
  vesamenu at the VM's actual boot resolution, shifting the composition
  relative to the menu box. Not broken — branding is clearly visible and
  legible — just not pixel-tight at this resolution. Worth a look before
  calling boot-menu branding fully polished, but not blocking further work.

### Not yet tested

- UEFI boot mode (only BIOS confirmed so far)
- NetworkManager / actual network connectivity
- `sudo` (passwordless, for `liveuser`)
- AUR bootstrap (`paru` install on first graphical login) — check
  `~/.cache/oblinux/aur-bootstrap.log` if not confirmed
- Accessibility/speech boot entry
