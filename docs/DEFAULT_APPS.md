# Default application package list (2026-08-13)

Phase 3/4 item 1 of Marco's bucket list (see `README.md`'s Status section
for the full list and sequencing). Previously `packages.x86_64` had no
curated end-user apps at all — just the archiso `releng` boot/rescue
toolset and a minimal GNOME core (`gdm`, `gnome-shell`,
`gnome-control-center`, `nautilus`, portals). This fills that in.

Goal, per Marco's direction: GNOME should be **functional and appealing**
out of the box, with a **solid terminal**, and the user should have "all
they need to have a functional system" without hitting a wall on day one.

## Decisions

- **Flatpak + Flathub: yes.** `xdg-desktop-portal`/`xdg-desktop-portal-gnome`
  were already shipped (added for Calamares/GNOME sandboxing), so the
  portal prerequisite was free. `flatpak` + `gnome-software` added;
  keeps the curated base list lean while still giving users a GUI app
  store for anything not shipped by default.
- **Browser: Firefox**, shipped in the base ISO. Marco also wants a
  **Calamares installer option to choose the default browser at install
  time** — not yet designed, folded into the "enrich Calamares options"
  bucket-list item (item 2), tackled after this one.
- **Office suite: none.** Available via Flatpak/AUR instead of bloating
  every ISO.
- **Terminal: Ptyxis**, replacing `gnome-terminal`. Modern,
  GPU-accelerated, actively developed (what Fedora Workstation switched
  its own default to) — `gnome-terminal` is feature-frozen upstream.
- **Desktop feel: stock vanilla GNOME shell** — no `gnome-tweaks` or
  extensions baked in. That customization surface is deliberately left
  for the future Customization App (bucket-list item 7) to offer as
  opt-in rather than shipped-by-default.
- **GNOME core apps**: calendar, calculator, characters, clocks,
  contacts, disk-utility, firmware (+ `fwupd`), online-accounts,
  software, system-monitor, text-editor, weather, plus `baobab`, `eog`,
  `evince`, `file-roller`, `sushi`, `totem`. `gnome-maps` deliberately
  left out (heavier, needs `geoclue`, least-used of the set) — easy to
  add later if wanted.
- **Shell experience**: `starship` + `zsh-autosuggestions` +
  `zsh-syntax-highlighting` on top of the already-default zsh — a modern
  out-of-the-box feel without the overhead of a full framework like
  oh-my-zsh.
- **Modern CLI tools**: `bat`, `btop`, `eza`, `fd`, `fzf`, `ripgrep`,
  `zoxide` — plus filling a real gap, `unzip`/`zip`/`p7zip`/`wget` (only
  `squashfs-tools` existed before, no general-purpose archive/download
  tools at all).
- **Codecs**: full `gst-plugins-base/good/bad/ugly` + `gst-libav`, not
  Fedora's conservative patent-conscious subset — matches the "just
  works" positioning over a cautious one.
- **Fonts**: `noto-fonts` + `noto-fonts-emoji` + `ttf-liberation`. Base
  ISO shipped zero desktop fonts before this. `noto-fonts-cjk`
  deliberately left out (large; can be added via Flatpak/AUR by users
  who need it).
- **Printing**: `cups` + `cups-pdf` + `avahi` + `nss-mdns` for
  driverless network-printer discovery. GNOME Settings' printer panel
  handles configuration once `cups` is running.
- **Bluetooth**: `bluez` + `bluez-utils`.
- **Firewall**: `ufw` + `gufw` over `firewalld` — simpler mental model,
  friendlier to users switching from macOS/Windows. Base packages only;
  actual ruleset/hardening is bucket-list item 5's job, not this one.

## Implemented since the initial draft

- **Flathub remote add** — wired into `shellprocess-final.conf` as a
  best-effort post-install step, same pattern as the pacman-keyring
  refresh. Verified the exact command against Flathub's own setup docs
  (`flathub.org/setup/Fedora`) rather than assumed —
  `flathub.org/setup/Arch` doesn't show a remote-add step at all (Arch's
  `flatpak` package doesn't appear to pre-configure it, unlike Fedora's),
  so this runs unconditionally with `--if-not-exists` to be safe either
  way:
  `flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo`

## Not yet implemented — needed before this is actually "done"

- **`gnome-software`'s Flatpak backend** — needs its exact
  package/plugin requirement on Arch confirmed at build time, not
  assumed here.
- **`eog`/`evince` vs newer replacements** — GNOME has floated newer
  image/PDF viewers (Loupe, Papers) in recent releases; defaulted to the
  established `eog`/`evince` as the safe, known-available choice rather
  than assume the newer ones are stable/available on Arch. Worth a
  quick check next time this list is revisited.
- **Printer drivers** — `cups`/`avahi` cover discovery and GNOME
  Settings covers configuration UI, but specific driver packages
  (`gutenprint`, etc.) are hard to right-size without test hardware;
  deferred rather than guessed.
- **Not yet build/boot tested.** Like every other phase in this project,
  this list isn't "done" until a real `mkarchiso` build boots clean with
  it — a large jump in package count (and first-ever pull of packages
  like `ptyxis`, `starship`, `gnome-online-accounts`, the `gst-plugins-*`
  set) makes an actual build/boot round especially worth doing before
  calling this closed, same as every other phase in this project.
