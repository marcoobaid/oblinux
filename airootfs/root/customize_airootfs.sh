#!/bin/bash

set -e -u

sed -i 's/#\(en_US\.UTF-8\)/\1/' /etc/locale.gen
locale-gen

usermod -s /usr/bin/zsh root
cp -aT /etc/skel/ /root/
chmod 700 /root
# unset the root password
passwd -d root

sed -i 's/#\(PermitRootLogin \).\+/\1yes/' /etc/ssh/sshd_config
sed -i "s/#Server/Server/g" /etc/pacman.d/mirrorlist

#oblinux
systemctl enable pacman-init.service choose-mirror.service
systemctl set-default graphical.target
systemctl enable sddm.service

groupsoblinux="adm,audio,disk,floppy,log,network,optical,rfkill,storage,video,wheel,sys"
useradd -m -g users -G $groupsoblinux -s /bin/bash liveuser
passwd -d liveuser