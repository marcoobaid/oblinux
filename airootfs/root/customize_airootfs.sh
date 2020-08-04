#!/usr/bin/env bash
#
# SPDX-License-Identifier: GPL-3.0-or-later

set -e -u

echo 'Warning: customize_airootfs.sh is deprecated! Support for it will be removed in a future archiso version.'

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root
# unset the root password
passwd -d root

#oblinux
systemctl enable pacman-init.service choose-mirror.service
systemctl set-default graphical.target
systemctl enable sddm.service

groupsoblinux="adm,audio,disk,floppy,log,network,optical,rfkill,storage,video,wheel,sys"
useradd -m -g users -G $groupsoblinux -s /bin/bash liveuser
passwd -d liveuser
