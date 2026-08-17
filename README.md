<div align="center">

<img src="docs/branding/oblinux-lockup.svg" alt="OBLinux" width="440">

### An Arch-based GNOME desktop built for a polished, practical experience

[![License: MIT](https://img.shields.io/badge/License-MIT-d68a3c.svg)](LICENSE)
[![Base: Arch Linux](https://img.shields.io/badge/Base-Arch%20Linux-1793d1.svg)](https://archlinux.org/)
[![Desktop: GNOME](https://img.shields.io/badge/Desktop-GNOME-4a86cf.svg)](https://www.gnome.org/)

</div>

OBLinux is an independent Linux distribution proof of concept built from the
current Arch Linux [`archiso`](https://gitlab.archlinux.org/archlinux/archiso)
profile. It provides a branded GNOME live environment and a graphical
Calamares installer for deploying the system to a VM or physical computer.

> [!IMPORTANT]
> OBLinux is under active development. It is suitable for evaluation and
> testing, but it is not yet intended to replace a production operating
> system.

## Highlights

- Arch Linux base with standard `pacman` package management
- GNOME desktop with OBLinux wallpapers, icons, fonts, and Slate & Amber branding
- BIOS and UEFI boot support
- Branded Syslinux, GRUB, Plymouth, GDM, and Calamares experience
- Automatic `liveuser` login on the live medium
- Graphical installation through Calamares
- Firefox, Ptyxis, Flatpak, Flathub, GNOME applications, codecs, and modern CLI tools
- NetworkManager, Bluetooth, printing, firmware update, and firewall tooling
- Signed OBLinux package repository and optional Chaotic-AUR access
- Zsh, Starship, `paru`, and a curated terminal toolset

## Current status

The proof of concept currently supports the full workflow:

```text
ISO build → BIOS/UEFI boot → GNOME live desktop → Calamares install → installed system boot
```

Validated results include:

- Live GNOME desktop and `liveuser` autologin
- 10/10 consecutive boots from an independently built ISO in VirtualBox
- Successful BIOS installation in VirtualBox
- Successful UEFI installation and boot on physical hardware
- Successful installed-system boot through Plymouth and GDM
- Working installed-system root console authentication
- Signed package resolution from `oblinux_repo`

The GDM, Plymouth, and live-autologin VT race found during development is
resolved and documented in
[`docs/GDM_PLYMOUTH_AUTOLOGIN_FIX.md`](docs/GDM_PLYMOUTH_AUTOLOGIN_FIX.md).

## Building the ISO

Build on an up-to-date Arch Linux system:

```bash
sudo pacman -S --needed archiso
sudo mkarchiso -v .
```

The completed ISO is written to `out/`.

### Package repository prerequisite

OBLinux obtains `calamares`, `paru`, `ckbcomp`, and its custom icon theme
from the signed
[`oblinux_repo`](https://github.com/marcoobaid/oblinux_repo). These packages
must be published there before building, or `mkarchiso` will be unable to
resolve them.

See [`docs/CUSTOM_REPO.md`](docs/CUSTOM_REPO.md) for the repository workflow
and [`docs/PACKAGE_SIGNING.md`](docs/PACKAGE_SIGNING.md) for signing and
build-machine trust requirements.

## Project layout

```text
airootfs/          Files copied into the live and installed systems
docs/              Design, implementation, and testing documentation
efiboot/           UEFI systemd-boot configuration
grub/              GRUB configuration and loopback support
syslinux/          BIOS boot configuration and artwork
packages.x86_64    Packages included in the ISO
pacman.conf        Package configuration used while building
profiledef.sh      Archiso profile definition
```

## Documentation

| Topic | Document |
|---|---|
| Build and verification history | [`docs/TESTING.md`](docs/TESTING.md) |
| Calamares configuration | [`docs/CALAMARES.md`](docs/CALAMARES.md) |
| GDM/Plymouth autologin fix | [`docs/GDM_PLYMOUTH_AUTOLOGIN_FIX.md`](docs/GDM_PLYMOUTH_AUTOLOGIN_FIX.md) |
| Brand system and boot artwork | [`docs/BRANDING.md`](docs/BRANDING.md) |
| Desktop theming | [`docs/THEMING.md`](docs/THEMING.md) |
| Default applications | [`docs/DEFAULT_APPS.md`](docs/DEFAULT_APPS.md) |
| Custom package repository | [`docs/CUSTOM_REPO.md`](docs/CUSTOM_REPO.md) |
| Package signing and Chaotic-AUR | [`docs/PACKAGE_SIGNING.md`](docs/PACKAGE_SIGNING.md) |

## Known limitations

- OBLinux remains a proof of concept and does not yet have a formal release process.
- Hardware coverage is limited; additional devices and graphics configurations need testing.
- A rare, non-blocking Calamares crash was previously observed after changing the
  automatic-partitioning swap option. It auto-recovered and has not prevented a
  successful installation. The investigation is recorded in
  [`docs/CALAMARES.md`](docs/CALAMARES.md).
- Some optional desktop decisions, printer-driver coverage, and later customization
  work remain open.

## Origins

This repository replaces
[`oblinux-old`](https://github.com/marcoobaid/oblinux-old). The current
project was rebuilt from a modern Archiso `releng` baseline instead of
continuing to patch a profile that had been dormant for several years.

## License

The OBLinux project files are available under the [MIT License](LICENSE).
Bundled and derived third-party assets retain their respective licenses and
attributions.
