#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

dd if=/dev/zero of=/installer/installer.img bs=100M count=10
losetup -fP /installer/installer.img

disk=$(losetup -a | grep "/installer/installer.img" | tail -n 1 | cut -d ' ' -f1  | sed 's/.$//')

mkfs.vfat -F32 ${disk}

mkdir -p /mnt/destination
mount -o loop ${disk} /mnt/destination

# copy image
cp -rp /installer/image/* /mnt/destination/

# add grub config
mkdir -p /mnt/destination/boot/grub
cat <<EOF >/mnt/destination/boot/grub/grub.cfg

insmod all_video

set default="0"
set timeout=5
set timeout_style=menu

menuentry "IOhubOS Installer" {
    linux /vmlinuz boot=live bootfrom=removable-usb quiet nomodeset ip=frommedia
    initrd /initrd
}
EOF

# install grub
grub-install \
    --target=x86_64-efi \
    --efi-directory=/mnt/destination \
    --boot-directory=/mnt/destination/boot \
    --removable \
    --recheck

# issues with some systems
[[ -f /mnt/destination/EFI/BOOT/fbx64.efi ]] && rm /mnt/destination/EFI/BOOT/fbx64.efi

umount /mnt/destination
rmdir /mnt/destination

losetup -d ${disk}

# move to shared folder
mv /installer/firmware.tgz /dist/.
mv /installer/installer.img /dist/.
