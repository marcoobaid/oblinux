# OBLinux GNOME Shell theme — source

Design source for `airootfs/usr/share/themes/OBLinux/gnome-shell/` (see
`docs/THEMING.md` item 5). Not shipped on the image itself — same
separation as `docs/branding/wallpapers/`: SVG/SCSS sources live here for
future edits, only the compiled output ships.

## What this is

A fork of the `gnome-shell` module from
[vinceliuice/Graphite-gtk-theme](https://github.com/vinceliuice/Graphite-gtk-theme)
(GPL-3.0), recolored to OBLinux's Slate & Amber palette. Chosen over
Nordic, Orchis, and WhiteSur after comparing real GitHub activity, license,
and shell-specific (not just overall repo) commit currency — see
`docs/THEMING.md` item 5 for the full comparison. Only the `gnome-shell`
module was taken — OBLinux relies on GNOME's native accent-color system
for GTK app theming (item 2's decision), not a custom GTK theme, so
Graphite's `gtk-3.0`/`gtk-4.0` modules were never pulled in.

## What was actually changed

`sass/_colors.scss` gained a new `$color_type: 'oblinux'` branch —
following the exact same pattern as the upstream `'nord'` branch already
there, not a hack bolted on top:

| Role | Upstream Graphite (`default`, dark) | OBLinux |
|---|---|---|
| Top bar / OSD / system (`background(e)`) | `#212121` | `#151a22` (Ink — same hex as the GDM background/wallpaper) |
| Scrim / base-alt (`background(f)`) | `#242424` | `#1e2733` (interpolated) |
| Background / base / login / titlebar (`background(g)`) | `#2C2C2C` | `#2c3a4e` (Slate — same hex as the GDM background/wallpaper) |
| Surface — popovers/menus (`background(h)`) | `#3C3C3C` | `#3a4d68` (interpolated, deliberately short of Slate's lighter primary `#3f6690` — that tone stays reserved for the mark/accent gradient) |
| Accent (`$theme_default_color` → `$primary`) | `$grey-300` | `#d68a3c` (Amber, exact — same hex as the spark, `accent-color='orange'`, the GDM logo) |
| Link | `$blue-500` (Material) | `#3f6690` (Slate primary — same hex as the mark's ring gradient) |

Also recolored: the two accent-dependent asset SVGs
(`toggle-on(-dark).svg`, `checkbox-dark.svg`, sourced from Graphite's own
built-in `orange` variant as the closest starting point) from Material
orange (`#F57C00`/`#FB8C00`) to exact Amber (`#d68a3c`).

Removed entirely: the `#lockDialogGroup` background image
(`background.png`, bundled by upstream) — OBLinux's lock/login screen
already gets its own gradient via GDM's dconf profile (item 1), a
bundled generic background image would only conflict with it. See
`sass/gnome-shell/common/_login-dialog.scss`.

## Version scope

Built against Graphite's most current shell styling — the
`widgets-48-0`/`extensions-46-0` import chain (`sass/gnome-shell/
_common-temp.scss`), matching upstream's own default when no running
`gnome-shell` is detected at build time (true here — built on macOS).
OBLinux ships `gnome-shell` 50.4; Graphite's own shell-specific commits
top out around Shell 48 (verified against real commit history, not
assumed — see `docs/THEMING.md` item 5). A real, disclosed gap, shared by
every strong candidate theme evaluated except Nordic (which was worse:
stalled at Shell 40–42). Needs visual build/boot verification, not just
"it compiled."

## Rebuilding

```bash
pip install libsass  # or: sassc, if installed
python3 -c "
import sass
css = sass.compile(filename='main/gnome-shell/oblinux-gnome-shell.scss', output_style='expanded')
open('gnome-shell.css', 'w').write(css)
"
```

Then copy `gnome-shell.css` plus the 8 files actually referenced by its
`url(...)` rules (`calendar-today.svg`, `checkbox-dark.svg`,
`checkbox-off.svg`, `dash-placeholder.svg`, `toggle-off(-dark).svg`,
`toggle-on(-dark).svg` — grep the compiled CSS for `url("assets/` to
reconfirm the exact list if this gets rebuilt after further edits) plus
`pad-osd.css` into
`airootfs/usr/share/themes/OBLinux/gnome-shell/`.

## License and attribution

GPL-3.0, same as Graphite — this is a derivative work and stays under
its upstream license. See `airootfs/usr/share/themes/OBLinux/AUTHORS`
and `LICENSE`.
