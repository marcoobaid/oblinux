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

### 1. Default wallpaper(s) — done, VM-confirmed 2026-08-13

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

This item is closed out.

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

### 5. GNOME Shell styling — not started

Goal: make the top bar, overview, and quick-settings panel visually
appealing and on-brand. Real technical constraint to resolve before
design, not after: modern GNOME Shell doesn't natively support custom
shell themes without the "User Themes" extension (or a deeper
gresource-level override) — and the base ISO deliberately ships no
extensions (stock-GNOME decision from the package-list phase). Needs a
scoping conversation on approach (extension vs. baked-in override vs.
leaning on accent color alone) before any design work. Sequenced after
wallpaper/GTK/fonts/icon theme so it can be designed against the actual
established look rather than in isolation.

### 6. Neofetch/Fastfetch branding — not started

Fastfetch over neofetch — neofetch's upstream maintainer archived the
project in 2024; fastfetch is the actively maintained, faster successor.
(Confirm still current / available on Arch when this item starts, not
assumed here.) OBLinux logo as ASCII art or an image-protocol logo —
needs deciding once this item starts; Ptyxis's image-protocol support
should be checked before assuming a raster logo renders cleanly, ASCII
is the likely safe fallback. Benefits from the Nerd Font default already
being decided (item 3) if the info display leans on glyph icons. Lives
in the main `oblinux` repo (`airootfs/etc/fastfetch/`), no new repo.

### 7. Zsh custom prompt — not started

Custom `starship.toml` matching Slate & Amber, using JetBrains Mono
Nerd Font's glyph set for prompt icons (item 3's default). Lives in the
main `oblinux` repo (likely `airootfs/etc/skel/.config/starship.toml`),
no new repo. Sequenced last — pure terminal/CLI polish, dependent on the
font decision above but nothing else.
