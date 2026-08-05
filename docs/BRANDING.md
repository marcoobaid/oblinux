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

## Asset checklist (boot → login, phase 1 scope)

| Asset | Path in repo | Format | Status |
|---|---|---|---|
| Logo / wordmark | `docs/branding/` (source), exported per-use below | SVG source | Not started |
| BIOS boot menu background | `syslinux/splash.png` | PNG, 640×480 (matches current upstream default) | Stock Arch art — needs replacing |
| UEFI boot menu | uses same visual language via `efiboot/loader/entries/*.conf` titles (text only, systemd-boot has no background image) | — | Text branding done already |
| Plymouth boot theme | new: `airootfs/usr/share/plymouth/themes/oblinux/` + `plymouth` package | `.plymouth` + script + images | Not started |
| GDM login background | `airootfs/etc/dconf/db/gdm.d/` override | PNG or solid color via dconf | Not started |
| OS logo (About panel, `LOGO=oblinux-logo` in os-release) | `airootfs/usr/share/icons/hicolor/.../oblinux-logo.svg` | SVG icon, symbolic + full-color variants | Not started — `os-release` already references this name |

## Next steps

1. **Logo/wordmark** — I'll mock up 2–3 SVG options using Primary/Ink/Amber. This
   unblocks everything else, since the boot splash, Plymouth theme, and GDM
   background all reuse it.
2. **Boot splash** (`syslinux/splash.png`) — apply the logo to a 640×480 Ink/Slate
   background.
3. **Plymouth theme** — a themed spinner/logo on the same background, shown during
   kernel boot before GDM starts.
4. **GDM background** — same visual language for the login screen.
5. **App icon / `LOGO` asset** — export the mark as a proper hicolor icon set.

Want me to go ahead and mock up logo/wordmark options now?
