#!/usr/bin/env bash
# shellcheck disable=SC2034

iso_name="oblinux"
iso_label="OBL_$(date +%Y%m)"
iso_publisher="OBLinux <https://www.oblinux.com>"
iso_application="OBLinux Live/Rescue CD"
iso_version="$(date +%Y.%m.%d)"
install_dir="arch"
bootmodes=('bios.syslinux.mbr' 'bios.syslinux.eltorito' 'uefi-x64.systemd-boot.esp' 'uefi-x64.systemd-boot.eltorito')
arch="x86_64"
pacman_conf="pacman.conf"
