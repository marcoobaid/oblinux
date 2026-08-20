# OBLinux Theming (Phase 3/4, item 2 — Visual Theming)

Visual-theming sub-scope of the "GNOME theming + general tweaks"
bucket-list item, agreed 2026-08-13. Worked as a shared, sequenced
checklist — decide the full list and order first, then implement one
item at a time. Nothing below is implemented yet; this doc tracks status
per item as that work starts.

## Decisions locked in for this sub-phase

- **Zsh prompt: keep starship** (already shipped in `packages.x86_64`
  alongside `zsh-autosuggestions`/`zsh-syntax-highlighting`) — build a
  custom `starship.toml` matching Slate & Amber rather than switching to
  oh-my-zsh. Reaffirms the package-list phase's reasoning: lighter
  weight, faster shell startup, no framework to maintain.
- **GTK theme: native accent color only**, not a custom GTK theme
  package. Modern GNOME's built-in accent-color system (Settings >
  Appearance) set to the closest preset to Amber (`#d68a3c`) gets a
  branded look with zero custom theme CSS to build or maintain across
  GNOME version bumps. Exact mechanism/available presets to be confirmed
  against the actual shipped GNOME version when this item starts, not
  assumed now.
- **Icon theme: derive from an existing open-source base**, recolored to
  Slate & Amber, rather than fully original artwork — realistic scope
  for full app-icon coverage.
- **Repo layout**: only large, independently-versionable artifacts get
  their own `oblinux-` repo. Confirmed so far: `oblinux-icon-theme`
  (published via `oblinux_repo`, same packaging pattern as
  `calamares`/`paru`/`ckbcomp`). Everything else below stays inside the
  main `oblinux` repo, matching how the Plymouth and GRUB themes already
  live there.
- **Fonts**: desktop UI default is **Inter** (a deliberate, distinctive
  pick over GNOME's own native default), terminal/monospace default is
  **JetBrains Mono Nerd Font** (Nerd Font patching is what gives
  `starship` and `eza` their icon glyphs instead of broken boxes — real
  functional dependency, not just cosmetic). One curated default each,
  not a multi-font set shipped for switching — matches the package-list
  philosophy of a deliberate opinionated default over overwhelming
  choice; a font picker is a natural fit for the future Customization
  App instead. Browser/reading legibility handled via system-wide
  fontconfig fallback defaults (serif/sans-serif/monospace generics),
  not separate Firefox-specific font policy — one mechanism, covers the
  whole desktop.

## Sequenced item list

Order chosen for dependency reasons (noted per item), not just the order
first listed.

### 1. Default wallpaper(s) — done; separate live-boot regression (see below) — root cause found and fixed, validated 11/11

Three-round design process (all SVG, built on the real
`docs/branding/oblinux-mark.svg` mark, amber kept confined to the mark's
own spark per the brand rule):

- Round 1 (Orbit / Circuit Bloom / Aurora Grid) and round 2 (Facet /
  Soft Waves / Blueprint) explored direction. Facet rejected ("too
  busy, hurts the eyes"). Soft Waves, Circuit Bloom, and Blueprint
  approved.
- Refinement round: the mark's ring got a linear gradient (Primary
  warming toward the amber spark, `#3f6690` → `#a97f55`, tying the
  color shift to the "spark escaping the ring" concept rather than
  being purely decorative) and a small corner wordmark ("OBLINUX",
  Inter, low-opacity Slate Light, bottom-right).

**Final desktop set** (`airootfs/usr/share/backgrounds/oblinux/`):
`oblinux-soft-waves.svg` (default), `oblinux-circuit-bloom.svg`,
`oblinux-blueprint.svg`. Registered with GNOME Settings' background
picker via `airootfs/usr/share/gnome-background-properties/oblinux.xml`
— schema verified verbatim against gnome-backgrounds' own upstream
source and its real install path on Arch, not assumed. Default set via
the existing GDM/desktop gschema override
(`usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override`).

**GDM login screen**: does *not* use any of the three wallpapers above.
Real constraint found and verified against the ArchWiki GDM page: a
background *image* on GDM's login screen requires patching
`gnome-shell-theme.gresource` directly, which "will be overwritten on
subsequent updates of gnome-shell" — i.e. the very next `pacman -Syu`
on an installed system would silently revert it, unless OBLinux also
ships a pacman hook to re-patch it after every gnome-shell upgrade
(real ongoing infrastructure, not a one-time asset). Decided against
that for now. Instead GDM gets a durable **Ink → Slate vertical
gradient** via its own dconf profile/database
(`airootfs/etc/dconf/profile/gdm` + `airootfs/etc/dconf/db/gdm.d/`,
mechanism verified verbatim against ArchWiki) — this takes priority
over the gschema default for the `gdm` user specifically, splitting
GDM's look from the desktop session's without touching the fragile
gresource path. Two GDM-specific artwork concepts (Beacon, Circuit
Field) were designed and approved in principle but are **not** shipped
— set aside once the gresource constraint surfaced; worth revisiting if
the pacman-hook approach ever becomes worth the maintenance cost.

The mark+wordmark lockup already shown at GDM login (`org.gnome.
login-screen logo`, `oblinux-logo-text-dark.svg`) is unrelated to this
item — it predates this round and wasn't touched. Its exact on-screen
position (bottom-center, like Ubuntu's greeter) was the one thing left
unverified for vanilla GNOME — **confirmed 2026-08-13 via VM
screenshot**: it does land bottom-center, same as Ubuntu.

**VM-confirmed 2026-08-13**: built, installed, booted with no issues.
Full verification of both mechanisms, not just visual inspection:
- `gsettings get org.gnome.desktop.background picture-uri` on the
  desktop session correctly returns
  `/usr/share/backgrounds/oblinux/oblinux-soft-waves.svg`.
- `DCONF_PROFILE=gdm gsettings get org.gnome.desktop.background
  {primary-color,secondary-color,color-shading-type}` returns exactly
  `#151a22` / `#2c3a4e` / `vertical` — the GDM-specific dconf
  profile/database split is compiling and taking effect correctly.
- `gschemas.compiled` and `/etc/dconf/db/gdm` are both freshly
  timestamped from the build, confirming schema/dconf recompilation
  happens automatically during `mkarchiso` with no extra
  `customize_airootfs.sh` build hook needed — resolves what had been an
  open assumption.
- The GDM gradient reads as visually subtle in a screenshot (Ink and
  Slate are close in value by design) — checked and confirmed this is
  the gradient working as configured, not a defect. Kept as designed
  rather than increasing contrast.

**Regression found and fixed 2026-08-14** (round 21): after items 2–4
landed, the live session showed GDM falling back to a manual login
(instead of the established seamless autologin) and instability after
login. Root-caused via `journalctl`/`coredumpctl`, not guessed: the
three desktop wallpapers each had a `<text font-family="Inter, ...">`
element (the small corner wordmark). Rendering that inside GNOME's
*sandboxed* SVG loader (`glycin-svg`) triggers a fontconfig cache
build, which calls `symlink()` — a syscall the sandbox's seccomp
policy blocks, crashing the loader with `SIGSYS` and leaving the
background unloaded (`gnome-shell: Failed to load background ... i/o
error`), which was destabilizing the session around it.

**First fix (partial)**: the wordmark text was converted to real vector
path outlines extracted directly from Inter Medium (`fontTools`, the
actual `inter-font` upstream release), positioned to exactly match the
original text's metrics. This genuinely fixed *that* crash — rebuilt
and confirmed via `coredumpctl`/`journalctl`: zero `glycin`/`SIGSYS`/
`ANOM_ABEND` entries on the next boot, where every prior boot had them.
But the underlying symptom (GDM never handing off to the successful
autologin session) persisted regardless.

**Full bisection (round 21, 2026-08-14)**, using `git checkout <sha>` +
fresh `mkarchiso` builds as controls, each tested by booting the live
ISO 2–3 times and checking whether it lands on the desktop with zero
clicks:
- `4e2b993` (before any of items 1–4) — **clean every time**. Confirms
  the regression is something in items 1–4, not pre-existing/
  environmental.
- `3cc5c11` (items 1+2+3: wallpaper+accent+fonts, before icon theme
  existed) — **broken 3/3**. Clears item 4 entirely.
- `894a2d3` (item 1 alone) — **broken**. Clears items 2 and 3.
- Item 1 with the new GDM dconf profile/database
  (`etc/dconf/profile/gdm` + `etc/dconf/db/gdm.d/`) removed, wallpaper
  otherwise untouched — **still broken**. Clears the dconf profile
  mechanism itself.

That isolates the cause to the wallpaper *image* being the default
background — specifically, an SVG background. `loginctl session-status`
confirmed the actual autologin session (`gdm-autologin`, session 1) was
starting successfully and running the whole time, sitting idle on its
own VT — GDM was simply never switching the visible console over to
it, leaving the greeter (and then whatever session a manual login
creates) visible instead. Rendering the SVG background pulls in the
same `librsvg`/`cairo`/`pango`/`fontconfig` pipeline implicated in the
first crash, and this VM has no hardware-accelerated rendering
(`Failed to initialize accelerated iGPU/dGPU framebuffer sharing: Not
hardware accelerated` — pure software rendering) — plausible enough
that rendering it during the critical early-boot window interferes
with GDM's session-ready/VT-switch handshake, even without the text
element.

**Real fix**: stopped shipping SVG as the default background format
entirely. All three wallpapers are now pre-rendered to 1920×1080 PNG
(via `resvg`, matching the already-approved designs pixel-for-pixel —
verified by direct visual inspection of the rendered output) and
*that* is what `picture-uri`/`gnome-background-properties` point at.
SVG sources moved to `docs/branding/wallpapers/` for future edits —
not shipped in the image, so nothing renders SVG as part of the live
boot path at all anymore. Not a workaround for the crash specifically;
it removes the whole rendering pipeline that crash lived in.

**Round 21's fix was real but did not resolve the regression.** The PNG
conversion above is a genuine improvement (removes SVG rendering from the
live boot path entirely) and stays regardless of the rest of this story,
but rebuilding and re-testing showed the live-session hang still occurred.
This was the first hard lesson of this investigation: fixing a real,
confirmed bug found while chasing a symptom does not guarantee it's *the*
bug causing that symptom — the fix needed independent re-verification
against the original reported issue, not just against its own crash
signature.

**Continued bisection (round 22+, 2026-08-15/16)**, this time by rebuilding
`packages.x86_64` from scratch starting at the last-known-good commit and
re-adding packages a few at a time, each tested with a much larger reboot
sample (8–10+, not 2–3) after an earlier small-sample result was itself
contradicted on retest — the second hard lesson: intermittent/probabilistic
failures need real sample sizes, not 2–3 boots, to trust a "clean" result.
This isolated the regression to one specific package: **`ttf-jetbrains-
mono-nerd`**. Confirmed with a clean single-variable `diff`/Meld comparison
of two otherwise-identical `packages.x86_64` trees — commenting out just
that one line reliably fixes the hang, every time; leaving it in reliably
reproduces it, every time.

Process-level investigation of a hung boot (via SSH, to avoid contaminating
the very VT-switch state being diagnosed):
- `top` showed **0.3–3.2% CPU for 30 minutes straight** — ruled out "slow
  fontconfig cache build" (the package is legitimately huge for what it
  is: 90 `.ttf` files, 228 MB installed, confirmed via archlinux.org, vs.
  a typical font's few hundred KB — but nothing was ever busy processing
  them).
- `coredumpctl list` — empty. Ruled out a repeat of round 21's sandboxed-
  renderer crash mechanism; nothing is dying.
- `ps -eo pid,ppid,stat,wchan,cmd` — every relevant process (`gdm`,
  `gdm-session-worker`, both `gnome-shell --mode=gdm` *and*
  `--mode=user`, and all `gsd-*` daemons for both sessions) sitting in
  normal idle wait states (`Ss`/`Ssl`, `poll_schedule_timeout`). Both the
  greeter and the real liveuser desktop are fully started and healthy —
  the failure is not inside either session, it's in the hand-off between
  them.
- `journalctl -b -u gdm` — GDM's own daemon logs nothing at all about
  switching sessions, before or after the hang; total silence for the
  ~3 minutes between last activity and the point of giving up. Consistent
  with the hand-off never being attempted, not attempted-and-failing.
- Two red herrings, each ruled out by comparing directly against a
  **working** boot's same output (the actual key move that broke the
  stall in reasoning — comparing against a working-boot baseline instead
  of analyzing the broken boot in isolation):
  - `gnome-shell-calendar-server` fails to start (`error while loading
    shared libraries: libecal-2.0.so.3: cannot open shared object file`)
    — a real, separate `evolution-data-server` packaging gap, but
    present identically on the working boot too. Not the cause.
  - `loginctl show-session 1 --all` reports `Active=no` on the stuck
    session — looked damning, but also present identically on the
    working boot. Turned out not to mean what it looked like it meant
    for a Wayland seat session; `loginctl seat-status seat0`'s `Sessions:
    *N` marker is the metric that actually reflects seat-level display
    state (confirmed `*1` — session 1 correctly marked active — on a
    working boot). Not yet captured cleanly on a broken boot (requires
    checking before ever touching a TTY, which needs SSH with a
    pre-existing root password — the live ISO's root account has none by
    default, so this remains an open follow-up if the fix below doesn't
    hold).

**Font vendoring (2026-08-16)**: stopped installing the full
`ttf-jetbrains-mono-nerd` package (90 files / 228 MB) and instead vendored
just the 4 files OBLinux actually uses — see
`airootfs/usr/share/fonts/OBLinux-jetbrains-mono-nerd/README.md` for the
full rationale and provenance. This was tried as a candidate fix for the
regression and **did not resolve it** (10/10 boots still failed once
properly sampled) — the font package was never the actual mechanism, only
one of several things that happened to shift the odds of hitting the real
race below. Kept anyway: 228 MB → 9.7 MB for the one style actually
referenced by `monospace-font-name` is a sensible change on its own merits,
independent of this investigation.

**Root cause, confirmed (2026-08-17)**: an upstream GDM + Plymouth +
autologin VT race, unrelated to any application/package/branding choice
made in this project. A close match was found in a public GDM/NixOS bug
report describing the same trigger combination (autologin + Plymouth +
systemd-based initramfs) at "at least 50%" failure — OBLinux's own
measured rate at this point was ~50% too, though OBLinux's initramfs
turned out to be the traditional `udev`-based kind, not the systemd-based
kind that report described as required, so it's a related but not
identical manifestation of the same underlying class of bug.

GDM debug logging nailed the exact mechanism: the autologin session starts
correctly and completely on `tty2`. Around 20 seconds later, Plymouth
finishes its own independent, delayed shutdown and switches the active VT
*back* to `tty1` — where GDM then (re)creates and displays its greeter,
making the perfectly healthy, already-running desktop session on `tty2`
invisible. This matches every piece of prior process-level evidence
exactly: no crash, no busy process, both sessions fully healthy — because
nothing was ever broken, the visible VT was just switched away from the
working session by Plymouth itself, well after the fact.

**Fix**, three parts, all live in the actual boot path rather than
patching GDM or Plymouth:
1. `airootfs/etc/systemd/system/gdm.service.d/10-plymouth.conf` —
   `ExecStartPre=-/usr/bin/plymouth quit --retain-splash`. Makes GDM tell
   Plymouth to quit *synchronously, before GDM's own startup proceeds*,
   instead of leaving Plymouth to shut itself down independently, later,
   racing against a session that's by then already on screen.
   `--retain-splash` keeps the last rendered frame up (no flash-to-black)
   until GDM's own compositor draws over it — the branded boot splash is
   visually unaffected.
2. `getty@tty1.service` and `autovt@tty1.service` masked (symlinked to
   `/dev/null`) on both the live ISO and the installed system — nothing
   else competes for tty1 while GDM/Plymouth own it. This replaces the
   previous `getty@tty1.service.d/autologin.conf` passwordless-root-on-tty1
   convenience (see `docs/CALAMARES.md`); tty2–tty6 remain available as
   normal consoles. The live environment accepts its blank root password,
   while an installed system requires the root password configured by
   Calamares.
3. No changes needed to `packages.x86_64`, mkinitcpio hooks, or kernel
   params — Plymouth, its custom OBLinux theme, and every other branding
   decision in this document stay exactly as designed.

**Validated 11/11 consecutive VirtualBox boots.** Confirms definitively:
none of items 1–4 (wallpaper, accent color, fonts, icon theme), the
package-list addition, or `liveuser`/branding work was ever the cause.

**Independently reconfirmed 2026-08-17**: a fresh ISO built from the
pushed `main` (not the pre-push local test build) passed **10/10 boots**
and a full Calamares install completed successfully. Closed.

**Wordmark crop fix (2026-08-17)**: on a real physical laptop install, the
"OBLINUX" corner wordmark was cropped (missing its final letter) — a
separate, unrelated cosmetic bug from the VT race above. Root cause:
`picture-options='zoom'` crops the wallpaper to fill the screen, cropping
proportionally to how far the screen's aspect ratio departs from the
1920×1080 (16:9) source the wallpapers were rendered at — a 16:10 laptop
panel alone crops ~5.6% off each side, more for 3:2. The wordmark's
original margins (3.6% right, 5.5% bottom) were narrower than that. Fixed
by repositioning the wordmark (same scale/kerning, shifted as a rigid
block) to a 13%/14% margin in all three `docs/branding/wallpapers/*.svg`
sources, then re-rendering to the shipped PNGs via `resvg` (same pipeline
as the original SVG→PNG fix). **Confirmed 2026-08-17**: rebuilt, wordmark
displays fully and correctly on both VirtualBox and the physical laptop
that originally showed the crop. Closed.

### 2. GTK theme — accent color — done, VM-confirmed 2026-08-13

`org.gnome.desktop.interface accent-color='orange'`, added to the
gschema override. Enum verified verbatim against
`gsettings-desktop-schemas` upstream source (`org.gnome.desktop.
interface`'s `accent-color` key) — valid values are
blue/teal/green/yellow/orange/red/pink/purple/slate; `orange` is the
closest preset to Amber (`#d68a3c`). No new repo, no theme package —
confirms the plan's assumption that this would just be a dconf default.
Not scoped to the desktop session only: since GDM's dconf profile only
overrides background keys (item 1), this falls through to the same
compiled default for the GDM greeter too — a deliberate, cohesive
choice, unlike the wallpaper split. **Confirmed**: orange shown
selected under Settings → Appearance on the built VM.

### 3. Fonts — desktop UI + terminal — done, VM-confirmed 2026-08-13

Desktop UI default: **Inter** (`inter-font` package — confirmed on
Arch, ships the static `Inter` family plus a separate `Inter Variable`
instance; used the static one). Terminal/monospace default:
**JetBrains Mono Nerd Font**, specifically the **Mono** build variant
(`ttf-jetbrains-mono-nerd` package — confirmed on Arch) rather than the
plain or "Propo" variant, so icon glyphs (starship, eza) occupy a fixed
single-column width instead of breaking terminal alignment. Both added
to `packages.x86_64`. Wired via `org.gnome.desktop.interface`
(`font-name`, `document-font-name`, `monospace-font-name` — same
gschema override as item 2) and `/etc/fonts/local.conf` (system-wide
fontconfig `sans-serif`/`monospace` aliases, `binding="strong"` per
ArchWiki's own guidance — fontconfig 2.18+'s `48-guessfamily.conf`
preset silently overrides a plain/weak alias otherwise).

**Confirmed on the built VM**, not just visually:
- `gsettings get org.gnome.desktop.interface font-name` → `'Inter 11'`
- `fc-match sans-serif` → `Inter.ttc: "Inter" "Regular"` — the
  system-wide fontconfig default genuinely resolves to Inter, not a
  fallback.
- `fc-list | grep -i jetbrains` confirmed the registered family is
  exactly `JetBrainsMono Nerd Font Mono` — matches what was configured,
  no correction needed (the one open item from implementation).
- `eza --icons` in Ptyxis rendered real icon glyphs, not boxes —
  confirms both the font and Ptyxis's own font handling end to end
  (couldn't verify Ptyxis's system-font inheritance from source, since
  its GitLab repo is bot-gated for browsing and search needs a login —
  settled empirically instead).

**Update 2026-08-16**: the `ttf-jetbrains-mono-nerd` package described
above is no longer installed via pacman — it was isolated via git bisection
as the trigger of the live-boot regression documented under item 1, and
replaced with 4 vendored files providing the same `JetBrainsMono Nerd Font
Mono` family. See item 1's investigation log and
`airootfs/usr/share/fonts/OBLinux-jetbrains-mono-nerd/README.md`. Family
name and fontconfig wiring are unchanged — only how the files get onto the
image changed.

### 4. Icon theme — implemented, not yet build/boot tested

**Base**: [Papirus](https://github.com/PapirusDevelopmentTeam/papirus-icon-theme)
(GPL-3.0), chosen over Tela/Fluent after checking all three verbatim
against real sources (license, latest release date, contributor count,
color-customization mechanism) — Papirus has the broadest app-icon
coverage and releases every few weeks. `papirus-icon-theme` is in
Arch's official `extra` repo.

**Architecture**: new repo
[`oblinux-icon-theme`](https://github.com/marcoobaid/oblinux-icon-theme)
ships a small *inheriting* theme (`Inherits=Papirus,hicolor` in
`index.theme`) rather than vendoring Papirus's entire multi-thousand-file
icon set — only the `places` context (folders + home/user icon) is
overridden; every other icon (apps, mimetypes, devices, actions,
status...) falls through to the real `papirus-icon-theme` package,
declared as a hard dependency in the PKGBUILD. Repo is ~1.6MB, not a
multi-hundred-MB fork.

**Color match**: forked for the exact Amber hex rather than using
Papirus's existing "orange" preset as-is. Derived
from Papirus's `orange` folder-color preset (release `20260801`) — all
81 places-icon files it ships (base folder/folder-open, ~70 named
kinds — Documents, Downloads, Git, Steam, etc. — plus
user-home/user-desktop), across every size Papirus itself provides
color variants for (22/24/32/48/64px, matching the sizes its own
`papirus-folders` companion tool touches — 16px folder icons have no
color variants upstream). 405 files total. Each source SVG's two
folder-shape fill colors (`#ee923a` front, `#dd772f` back — confirmed
via direct inspection that unrelated badge-glyph colors, e.g. the git
icon's dark brown, are untouched by this and don't collide) were
replaced with `#d68a3c` (OBLinux's exact Amber) and `#b87027` (derived
via HLS: same hue/saturation as Amber, ~10 points darker lightness,
matching Papirus's own front/back ratio) — verified zero leftover
orange hex and full amber coverage across all 405 output files after
the fact, not assumed.

One real snag caught and fixed: GitHub serves a symlinked file's raw
content as the *target path string*, not the resolved file — 20 of the
405 fetches (4 kinds × 5 sizes: `videos`→`video`, `downloads`→
`download`, `desktop`→`user-desktop`, `public`→`image-people`, all
real Papirus symlinks) initially wrote that string as bogus SVG
content. Caught by verifying amber-hex presence across every output
file after the run rather than trusting file count alone, then fixed
by resolving each symlink to its already-correctly-colored target.

License: GPL-3.0 (required — this is a derivative of Papirus's GPL-3.0
work), `AUTHORS` credits Papirus/Paper Icon Set. `PKGBUILD` written
(new to this project — the first genuinely custom, non-AUR-sourced
OBLinux package, unlike calamares/paru/ckbcomp), published via
`oblinux_repo` (`oblinux-icon-theme-1.0.0-1-any.pkg.tar.zst`, signed).
`oblinux-icon-theme` added to `packages.x86_64` now that it's actually
resolvable — `papirus-icon-theme` comes along automatically as its
declared dependency, no separate `packages.x86_64` entry needed for
that. Not yet build/boot tested.

### 5. GNOME Shell styling — done, VM-confirmed 2026-08-19

Goal: make the top bar, overview, and quick-settings panel visually
appealing and on-brand. Real technical constraint resolved before design,
not after: modern GNOME Shell doesn't natively support custom shell
themes without the "User Themes" extension (or a deeper gresource-level
override) — and the base ISO deliberately ships no extensions
(stock-GNOME decision from the package-list phase). Sequenced after
wallpaper/GTK/fonts/icon theme so it can be designed against the actual
established look rather than in isolation.

**Scoping decision (2026-08-17)**: three real approaches, verified against
primary sources rather than assumed —
1. **User Themes extension** — verified compatible (v50.3) with the
   shipped `gnome-shell` (50.4). Ships in `gnome-shell-extensions`, an
   official GNOME-maintained package (not third-party) — its own author
   is a GNOME core developer. Loads CSS from a stable runtime location
   (verified against the extension's own `util.js`: checks `~/.themes`,
   then `$XDG_DATA_HOME/themes`, then every system data dir's `themes/`
   subdirectory — `/usr/share/themes` included), so unlike the GDM
   background's gresource-patch (item 1), it survives `gnome-shell`
   updates without needing an ongoing pacman hook.
2. **Direct `gnome-shell-theme.gresource` patch** — same fragile pattern
   already rejected for the GDM background in item 1, same reason
   (silently reverted by every `gnome-shell` update). Ruled out again
   here, same precedent.
3. **Accent color alone, no new dependency** — verified against GNOME's
   own 47 release notes: accent color reaches "throughout the system and
   apps," but that's GTK/libadwaita widgets and a few native Shell
   touches (quick-settings toggle color); the top bar background and
   overview chrome stay the same dark neutral regardless. Already shipped
   (item 2) — doesn't give item 5 much new on its own.

**Decision: option 1**, as a deliberate, one-time exception to the
package-list phase's "stock GNOME, no extensions" rule — judged safe
specifically because this is an official GNOME package, not a
third-party extension, and only the User Themes component of the bundle
gets enabled.

**Plumbing implemented**:
- `gnome-shell-extensions` added to `packages.x86_64`.
- `org.gnome.shell enabled-extensions` set to the User Themes UUID
  (`user-theme@gnome-shell-extensions.gcampax.github.com`, confirmed
  against the package's real file list) in the gschema override.
- `org.gnome.shell.extensions.user-theme name='OBLinux'` — looks for
  `/usr/share/themes/OBLinux/gnome-shell/gnome-shell.css`, system-wide
  (applies to `liveuser` and any Calamares-created account, same pattern
  as the icon theme).

**Design (2026-08-19)**: base chosen after comparing real GitHub activity
across candidates — not just overall repo activity, but commits actually
touching each theme's `gnome-shell` module specifically (a distinction
that mattered: Nordic's overall repo looked active, but its shell styling
was stalled at Shell v40–42):

| Theme | Stars | License | Last **shell-specific** work | Verdict |
|---|---|---|---|---|
| Nordic | 2,721 | GPL-3.0 | Stalled at Shell v40–42 | Ruled out — real compat risk |
| Orchis | 4,058 | GPL-3.0 | Shell 48 config (Mar 2025), fix (Sep 2025) | Material Design — bigger stylistic gap from Slate & Amber |
| **Graphite** | 1,509 | GPL-3.0 | "Fixed gnome-shell 48 issues" (Apr 2025), quick-settings/message-list updates (Jul 2025) | **Chosen** — neutral graphite grey needs least transformation to reach Slate |
| WhiteSur | 9,186 | MIT | (macOS-mimicking aesthetic — wrong direction, OBLinux wants its own identity) | Ruled out on aesthetic grounds |

Forked [vinceliuice/Graphite-gtk-theme](https://github.com/vinceliuice/Graphite-gtk-theme)'s
`gnome-shell` module only (not `gtk-3.0`/`gtk-4.0` — item 2's "native
accent-color, no custom GTK theme" decision stays intact). Full source,
recolor mapping table, and rebuild instructions in
`docs/branding/gnome-shell-theme-src/README.md`. Summary:
- New `$color_type: 'oblinux'` branch in `_colors.scss`, following the
  exact same pattern as upstream's own `'nord'` branch — a 4-step dark
  background ramp reusing the two already-shipped brand hexes (Ink
  `#151a22` for the top bar/OSD, Slate `#2c3a4e` for the main
  background/base/login, two interpolated steps for scrim/surface),
  Amber `#d68a3c` for the accent (buttons, focus rings, selection,
  toggles — verified present in the compiled CSS across all of those),
  Slate `#3f6690` for links.
- The two accent-dependent asset SVGs (toggle/checkbox) recolored from
  Graphite's stock Material orange to exact Amber.
- Upstream's bundled `#lockDialogGroup` background image removed — would
  conflict with the GDM dconf gradient item 1 already ships.
- GPL-3.0 (same as the icon theme's Papirus fork) — `LICENSE`/`AUTHORS`
  added under `airootfs/usr/share/themes/OBLinux/`.

**Known gap, disclosed not hidden**: Graphite's own shell-specific work
tops out around Shell 48; OBLinux ships 50.4. Built against the most
current chain Graphite has (`widgets-48-0`/`extensions-46-0`) — turned
out not to matter in practice; see verification below.

**VM-confirmed 2026-08-19**: `scripts/verify-shell-theme.sh` (extension
listed in `enabled-extensions`, theme name correct, CSS file present)
plus direct visual inspection — top bar and Quick Settings panel
correctly Ink/Slate, toggled tiles (Wired, Dark Style) and the volume
slider solid Amber, untoggled tiles (Power Mode, Do Not Disturb)
correctly staying neutral Slate rather than all going accent-colored.
The Shell 48-vs-50.4 gap flagged above didn't cause any visible breakage.

One real debugging detour worth recording: `gnome-extensions info`
initially reported `State: INACTIVE` despite `Enabled: Yes`, with no
error logged anywhere (`journalctl`, `GetExtensionInfo`'s `error` field,
`GetExtensionErrors` all empty) and `sessionModes`/`shell-version` both
correct. Traced through GNOME Shell's actual `extensionSystem.js`
source (not guessed) to understand the state machine; confirmed calling
`EnableExtension` on an already-enabled UUID is a no-op by design (it
only writes `enabled-extensions` if the UUID isn't already in it, so no
gsettings change-signal fires, so the real activation path never runs)
— a real, source-verified explanation for the *reporting*, but not for
why activation hadn't already happened at login. Resolved once
confirmed the CSS had, in fact, visually applied the whole time; a
follow-up **clean reboot with zero manual commands first** showed
`State: ACTIVE` immediately — settling that the earlier `INACTIVE`
reading was a one-off artifact of the disable/enable/reload probing
during diagnosis, not a real first-boot activation bug.

### 6. Neofetch/Fastfetch branding — implemented, not yet build/boot tested

Both open questions from the original scoping resolved with real evidence
before building anything:

- **Fastfetch over neofetch** — confirmed, not assumed: neofetch really is
  archived (github.com/dylanaraps/neofetch, "archived by the owner on Apr
  26, 2024. It is now read-only"); fastfetch is current in Arch's `extra`
  (2.67.1-1, updated within the same week this item was built).
- **ASCII logo, not an image protocol** — confirmed Ptyxis genuinely can't
  render one, not assumed. Traced this precisely: VTE (Ptyxis's underlying
  terminal widget) has real Sixel support implemented (`sixel-context.cc`,
  not a stub), but it's gated behind a meson build option that defaults to
  `false` — and Arch's actual `vte4` PKGBUILD doesn't override it
  (`arch-meson vte build -D docs=true`, no `-D sixel=true`). No Kitty
  graphics protocol support either. So Ptyxis, built against this exact
  package, cannot display a raster logo regardless of what OBLinux ships.

**Logo design**: the ring+spark mark (not the wordmark), block-character
ASCII (Unicode `█`, not plain `#` — bolder, matches the brand's clean
geometric style), colored via fastfetch's real `$1`/`$2`/`#RRGGBB`
placeholder mechanism (verified against fastfetch's own wiki —
Color-Format-Specification page confirms `#RRGGBB` hex support since
v2.42.0, well before the shipped 2.67.1) — Slate `#3f6690` for the ring,
Amber `#d68a3c` for the spark, exact brand hexes, not an approximated
named ANSI color. Iterated twice on a live color preview before landing
on the final version (spark enlarged from a single character to a 2×2
block — more proportionate to the ring and more visible).

**Module list**: short and curated, matching the package-list phase's
"deliberate defaults, not an overwhelming dump" philosophy — title, os,
kernel, uptime, packages, shell, terminal, cpu, gpu, memory, colors.
Dropped vs. the traditional neofetch-style full set: resolution, DE, WM,
GTK/icon theme, terminal font — all either GNOME-specific and unchanging
on OBLinux (always the same desktop, so "DE: GNOME" adds nothing fetch to
fetch) or genuinely niche.

**Implementation**:
- `fastfetch` added to `packages.x86_64`.
- `airootfs/etc/xdg/fastfetch/config.jsonc` + `oblinux-mark.txt` — system
  data dir, not `/etc/fastfetch/` as originally assumed in this doc's
  first draft. Verified the real search path directly in fastfetch's own
  source (`src/common/impl/FFPlatform_unix.c`'s `getConfigDirs()`):
  `$XDG_CONFIG_HOME` → `$XDG_CONFIG_DIRS` → `/etc/xdg/` → `/etc/` →
  install sysconfdir. `/etc/xdg/fastfetch/` applies to `liveuser` and any
  Calamares-created account automatically, same pattern as the icon theme
  and Shell theme — no per-user seeding into `/etc/skel/` needed.
- Runs automatically on new interactive shells — added to both
  `airootfs/home/liveuser/.zshrc` and `airootfs/etc/skel/.zshrc`
  (`[[ $- == *i* ]] && command -v fastfetch &>/dev/null && fastfetch`),
  guarded against non-interactive invocations.

**Next**: build/boot verification — confirm the logo renders correctly
(color placeholders resolve, block characters don't come out as `?`/mojibake)
and the module list looks right on the actual shipped `fastfetch` version.

### 7. Zsh custom prompt — implemented, not yet build/boot tested

Real gap found before building anything: `starship` was already in
`packages.x86_64` (added during the package-list phase) but never
actually wired up — no `starship init` line in either `.zshrc`, no
config, still a plain hardcoded `PS1` in `liveuser`'s. Fixed as part of
this item.

**Config location**: `airootfs/etc/xdg/starship.toml`, one shared file,
pointed at via `$STARSHIP_CONFIG` (exported in both `.zshrc`s) rather
than a per-user `~/.config/starship.toml` copy in each of
`airootfs/home/liveuser/` and `airootfs/etc/skel/` (this doc's original
assumption). Checked Starship's real config resolution in its own source
(`src/context/mod.rs`'s `get_config_path_os()`): only `$STARSHIP_CONFIG`
or `~/.config/starship.toml` — no XDG system-config fallback like
fastfetch has. A single shared file avoids two copies drifting out of
sync.

**Design**: Slate & Amber, no powerline blocks — colored text/glyphs
directly on the terminal background, matching the minimal geometric look
already established (wallpaper, icon theme, Shell theme). Directory in
Slate Light, git branch/status and language-version modules (Python,
Node, Rust, Go — invisible unless the directory's actually relevant) in
Slate/Amber, command duration on slow commands in muted Slate Light,
prompt character Amber on success. Deliberately kept **red** for the
error state rather than forcing it onto the brand palette — errors need
instant, unambiguous recognition, worth more there than strict on-brand
consistency. Iterated on a live two-state preview (clean repo, and a
slow/failed command) before finalizing.

No hand-specified Nerd Font glyph codepoints anywhere in the config —
relies entirely on Starship's own built-in default symbol per module,
avoiding the mojibake risk of guessing Unicode values from memory (same
caution as the fastfetch logo's block characters).

**Implementation**:
- `airootfs/etc/xdg/starship.toml` — validated as syntactically correct
  TOML before shipping.
- Both `.zshrc`s: `export STARSHIP_CONFIG=/etc/xdg/starship.toml` +
  `eval "$(starship init zsh)"`. `liveuser`'s old hardcoded `PS1` line
  removed — Starship now owns prompt rendering entirely.

**Next**: build/boot verification — confirm the prompt actually renders
(not just that `starship init` doesn't error), glyphs show correctly
rather than as boxes/`?`, and colors look right against Ptyxis's Ink
background.
