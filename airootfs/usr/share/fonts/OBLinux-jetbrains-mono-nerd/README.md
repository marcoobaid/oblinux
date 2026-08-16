# JetBrains Mono Nerd Font (Mono, vendored subset)

These 4 files are extracted directly from the official Arch Linux `extra`
package `ttf-jetbrains-mono-nerd` (version 3.5.0-1, base package
`nerd-fonts`, upstream https://github.com/ryanoasis/nerd-fonts), licensed
under OFL-1.1-no-RFN (`OFL.txt` in this directory, copied verbatim from the
package).

## Why vendored instead of installed via pacman

The full `ttf-jetbrains-mono-nerd` package ships 90 `.ttf` files (every
weight × style × NL/Mono/Propo/regular variant combination), 228 MB
installed, to provide the single style OBLinux actually uses:
`monospace-font-name='JetBrainsMono Nerd Font Mono 11'` (see the gschema
override, `50_oblinux-gdm.gschema.override`). Installing the whole package
for one style was always wasteful; it also correlated with a severe
live-session boot regression (GDM autologin session starting but never
being displayed) isolated via git bisection to the commit that added this
package — see `docs/THEMING.md` for the full investigation log. Whether the
package's size/file-count was the actual mechanism behind that regression
was not conclusively proven, but shipping only what's used removes it as a
variable either way and is the right call regardless.

## What's here

Only the 4 non-"NL" Mono files (Regular/Bold/Italic/BoldItalic) — the exact
files needed to satisfy the `JetBrainsMono Nerd Font Mono` family at every
weight/style GNOME Terminal or any app might request. ~9.7 MB total vs.
228 MB for the full package.

## Updating

To pick up a newer upstream release, download the matching
`ttf-jetbrains-mono-nerd-<ver>-1-any.pkg.tar.zst` from an Arch mirror and
replace these 4 files (path inside the package:
`usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-{Regular,Bold,Italic,BoldItalic}.ttf`)
plus `OFL.txt`.
