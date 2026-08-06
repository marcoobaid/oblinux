# OBLinux Branding — Slate & Amber

## Palette

| Name        | Hex       | Role |
|-------------|-----------|------|
| Ink         | `#151a22` | Darkest background / near-black surfaces (terminal body, deepest shadows) |
| Slate       | `#2c3a4e` | Secondary background / chrome (window titlebars, panels, sidebars) |
| Primary     | `#3f6690` | Leading brand color — logo, links, selection, focus states |
| Slate Light | `#a9b8c8` | Muted foreground — secondary text, inactive icons, borders |
| Amber       | `#d68a3c` | Accent — reserved for actions and alerts only, never decorative |
| Cloud       | `#f2f3f5` | Lightest foreground / light-mode background |

**Usage principle** (per the design system this came from): it's a cool blue-grey
system with a warm amber accent. **Blue (Primary) leads** — it's the brand color
everywhere. **Amber is reserved** for things that need to grab attention: primary
action buttons, alerts, progress/active states. Don't use amber decoratively (e.g.
as a general highlight color) or it stops meaning anything.

## Semantic mapping (proposed)

| Semantic role       | Color         | Where it shows up |
|----------------------|---------------|--------------------|
| Background (dark)     | Ink `#151a22`         | Boot splash, Plymouth, terminal background |
| Surface / chrome       | Slate `#2c3a4e`       | GDM panel, boot menu box, window titlebars |
| Brand / accent (leading) | Primary `#3f6690`  | Logo, boot menu selection, links, focus rings |
| Muted text/borders     | Slate Light `#a9b8c8` | Secondary text, dividers, inactive UI |
| Action / alert         | Amber `#d68a3c`       | Install button, warnings, active progress indicator |
| Light background/text  | Cloud `#f2f3f5`       | Light-mode surfaces, text on dark backgrounds |

Open question for you: do we want a **dark boot-to-login experience** (Ink/Slate
dominant, matches the terminal mockup) or something lighter? I'd default to dark —
it's the more common choice for boot splashes/login screens and suits this palette,
but flag if you want it flipped.

## Logo mark — locked

The OBLinux mark: a ring left deliberately open, with an amber spark escaping
the gap. Primary blue ring, amber spark, no wordmark baked in (typography for
a "OBLinux"/"Linux" lockup is a separate decision, needed for the boot splash).

Source files:
- [`oblinux-mark.svg`](branding/oblinux-mark.svg) — full color (Primary ring,
  Amber spark), for dark surfaces (Ink/Slate)
- [`oblinux-mark-symbolic.svg`](branding/oblinux-mark-symbolic.svg) —
  single-color (`currentColor`), for GNOME symbolic icon contexts (top bar,
  notifications) where the shell recolors the icon itself

Both are 200×200 viewBox, ring centered with even margins, so they scale
cleanly from favicon size up to a boot-splash centerpiece.

## Asset checklist (boot → login, phase 1 scope)

| Asset | Path in repo | Format | Status |
|---|---|---|---|
| Logo mark | `docs/branding/oblinux-mark*.svg` | SVG source | **Done** — see above |
| BIOS boot menu background | `syslinux/splash.png` | PNG, 640×480 | **Done** — mark + wordmark, Space Grotesk |
| UEFI boot menu | uses same visual language via `efiboot/loader/entries/*.conf` titles (text only, systemd-boot has no background image) | — | Text branding done already |
| Plymouth boot theme | `airootfs/usr/share/plymouth/themes/oblinux/` + `plymouth` package | `.plymouth` + `.script` + 3 PNGs | **Done** — see below |
| GDM logo + background | `airootfs/usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override` | GSettings override + SVG | **Done** — see below |
| OS logo (About panel, `LOGO=oblinux-logo` in os-release) | `airootfs/usr/share/pixmaps/oblinux-logo.{svg,png}` | SVG + PNG, plain mark | **Done** — see below |

## GDM login screen

Not what I originally assumed (a blurred desktop-background image) — Marco's
Ubuntu screenshot pointed at the right mechanism: GDM's `org.gnome.login-screen`
schema has a dedicated `logo` key ("small image ... to display branding"),
rendered crisp (not blurred) in its own slot, separate from the desktop
background. Verified against Arch's own `gdm` PKGBUILD, which sets this same
key for the default Arch logo via a GSettings **schema override** file at
`/usr/share/glib-2.0/schemas/30_org.archlinux.gdm.gschema.override` — not a
dconf database at all. `glib2` already ships the pacman hook
(`glib-compile-schemas.hook`) that recompiles the schema cache whenever any
`*.gschema.override` file changes, so no custom build hook is needed; ours
just has to sort after Arch's (`50_` vs `30_`) to win.

Assets/wiring:
- [`oblinux-lockup.svg`](branding/oblinux-lockup.svg) — the ring (vector) +
  "OBLinux" wordmark (embedded as the same `oblinux-wordmark.png` used by the
  boot splash/Plymouth, as a base64 raster `<image>`) side by side. The
  wordmark had to be raster, not SVG `<text>`: this file is rendered live by
  GDM on the built system, and Space Grotesk isn't installed there (not in
  official Arch repos) — unlike the boot splash/Plymouth PNGs, which are
  pre-rasterized during this design session and ship as plain pixels with no
  font dependency at all.
- Copied to `airootfs/usr/share/pixmaps/oblinux-logo-text-dark.svg` — named
  to match Arch's own `archlinux-logo-text-dark.svg` (see the os-release
  section below for why this couldn't just be `oblinux-logo.svg`).
- `airootfs/usr/share/glib-2.0/schemas/50_oblinux-gdm.gschema.override` sets
  `org.gnome.login-screen`'s `logo` to that path, and separately sets
  `org.gnome.desktop.background` to solid Ink (`primary-color='#151a22'`,
  `picture-options='none'`) so the login (and default post-install desktop)
  background matches Plymouth/the boot splash instead of GNOME's default
  wallpaper. Note this changes the *system-wide* default background, not
  just GDM's — real user accounts default to solid Ink until they set their
  own wallpaper, same as how most distros ship a default wallpaper.

## os-release LOGO (About panel)

`airootfs/etc/os-release` has set `LOGO=oblinux-logo` since the very first
scaffold commit, but no file with that name existed until now — GNOME
Settings' About panel (and anything else reading `LOGO=`, which the
os-release spec defines as a freedesktop icon-theme name) fell back to a
generic icon.

Checked how Arch itself ships this (`filesystem` package's PKGBUILD) rather
than assume: it installs plain, wordmark-free logo files straight into
`/usr/share/pixmaps/` — **not** the hicolor icon-theme directory tree I'd
originally planned — as `archlinux-logo.{svg,png}`, and its own `os-release`
sets `LOGO=archlinux-logo` to match. `/usr/share/pixmaps/` is itself part of
the freedesktop icon lookup spec (an unthemed fallback location every
icon-consuming app checks), so this needs no icon-cache rebuild at all,
unlike the hicolor route. Arch keeps this plain-mark file separate from its
GDM lockup (`archlinux-logo-text-dark.svg`, mark+wordmark) — same split we
now follow:

- `airootfs/usr/share/pixmaps/oblinux-logo.svg` / `.png` (256×256) — plain
  mark only, copied straight from `docs/branding/oblinux-mark.svg`, matching
  `LOGO=oblinux-logo` exactly.
- `airootfs/usr/share/pixmaps/oblinux-logo-text-dark.svg` — the mark+wordmark
  lockup, used only by GDM's `logo` key (see above).

This is why the GDM lockup file got renamed instead of staying at
`oblinux-logo.svg` — that name was needed for the plain mark once the real
`os-release`/Arch convention was checked, so the two assets couldn't share
it.

## Plymouth theme

`airootfs/usr/share/plymouth/themes/oblinux/` — same composition as the boot
splash (ring + wordmark on Ink), but animated: the amber spark orbits the
ring continuously as a boot-activity indicator, instead of a generic
throbber. Three transparent PNGs (`oblinux-ring.png`, `oblinux-spark.png`,
`oblinux-wordmark.png`, all sourced with the same canvas pipeline as the
boot splash) plus `oblinux.script` (Plymouth's scripting language —
verified against upstream's own `themes/script` example rather than
guessed, since the API isn't something we control) drive the animation.

Wiring: `plymouth` package added; `/etc/plymouth/plymouthd.conf` sets
`Theme=oblinux` (equivalent to running `plymouth-set-default-theme`, done as
a static file since there's no build-time command-execution step anymore);
`plymouth` hook added to `mkinitcpio.conf.d/archiso.conf` (placed after
`kms`, per upstream's placement guidance); `quiet splash` added to the two
main boot entries (BIOS + UEFI) — deliberately **not** added to the
accessibility/speech boot entry, so screen-reader users still get console
text.

## Boot splash typography

`syslinux/splash.png` uses **Space Grotesk** (700 weight for "OB", 500 for
"Linux") — a geometric sans common in current tech/dev-tool branding, chosen
to match the "modern, trendy" brief. Since the wordmark is baked into a
static PNG at build-design time (not rendered on the built system), the font
doesn't need to be installed on the ISO — only the pixels ship. Same font
choice should carry over to the Plymouth theme and GDM background for
consistency.

Rendering method (for reuse on the next assets): an HTML page draws the mark
+ wordmark, served locally, then an in-page `<canvas>` (fixed pixel
dimensions, unaffected by browser zoom/DPR) rasterizes it and POSTs the PNG
bytes to a small local save endpoint — gives pixel-exact output without
needing ImageMagick/cairosvg/etc. installed on this machine.

## Next steps

1. ~~Logo/wordmark~~ — done, see above.
2. ~~Boot splash~~ (`syslinux/splash.png`) — done, see above.
3. ~~Plymouth theme~~ — done, see above.
4. ~~GDM logo + background~~ — done, see above.
5. ~~os-release `LOGO` asset~~ — done, see above.

That's the full boot→login checklist. Phase 1 moves on to Calamares next.
