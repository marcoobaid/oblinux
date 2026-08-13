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

### 1. Default wallpaper(s) — not started

OBLinux logo over a background that's trendy/techy/appealing/inspiring —
"not too simplistic, not overly complicated." Lives in the main
`oblinux` repo (`airootfs/usr/share/backgrounds/oblinux/`), matching the
existing `gnome-backgrounds` package already shipped. Sequenced first:
low-dependency, quick win, sets the visual mood for everything after it.
Needs a style-direction discussion (mood, composition candidates) before
generating anything — not started.

### 2. GTK theme — accent color — not started

Set the OS default accent color to the closest native preset to Amber.
No new repo — this is now a single dconf/gsettings default, not a theme
package. Sequenced early since it's low-effort and immediately visible
across every app once set — good to have in place before judging how
the icon theme and shell styling look alongside it.

### 3. Fonts — desktop UI + terminal — not started

Desktop UI default: **Inter**. Terminal/monospace default: **JetBrains
Mono Nerd Font**. Browser/reading legibility via system-wide fontconfig
fallback defaults, not Firefox-specific settings. Sequenced right after
the accent-color item and *before* fastfetch/zsh prompt (items 6 and 7
below) on purpose: those two depend on a Nerd Font actually being the
default for their icon glyphs to render at all, so the font decision
needs to land first, not be guessed around. No new repo — Arch already
packages Nerd Fonts (exact package names to confirm when this item
starts, not assumed here) plus a small fontconfig default-family config.

### 4. Icon theme — not started

New repo: `oblinux-icon-theme`. Derive from an existing open-source icon
set, recolor accents/folders to Slate & Amber, publish via
`oblinux_repo`. The heaviest lift in this list — sequenced fourth so the
accent color and font choices are already in place to design against.
Open items for when this starts: which base icon set to derive from
(needs a candidate review — e.g. Papirus, Tela, Fluent, each with
different license/maintenance-status/aesthetic trade-offs) and a license
compatibility check for a derivative work.

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
