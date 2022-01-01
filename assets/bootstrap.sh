#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

# initial debootstrap
debootstrap --variant=minbase "$SUITE" $WORK/debootstrap "$MIRROR"

# prepare working directories
mkdir -p /installer

# build live firmware
mkdir -p $WORK/LIVE_BOOT
cp -rp $WORK/debootstrap $WORK/LIVE_BOOT/chroot
mkdir -p $WORK/LIVE_BOOT/chroot/usr/src && cp -rp $WORK/iohubos $WORK/LIVE_BOOT/chroot/usr/src/.
chroot $WORK/LIVE_BOOT/chroot /usr/src/iohubos/assets/live-setup.sh
# copy builtin images
mkdir -p $WORK/LIVE_BOOT/chroot/var/lib/images
[ -d "${WORK}/iohubos/${REGISTRY}" ] && cp -r ${WORK}/iohubos/${REGISTRY}/* $WORK/LIVE_BOOT/chroot/var/lib/images/.
# clean up
find $WORK/LIVE_BOOT/chroot/var/log -type f -exec cp /dev/null {} \;
rm -rf $WORK/LIVE_BOOT/chroot/var/log/journal/* $WORK/LIVE_BOOT/chroot/var/log/apt/*
rm -rf $WORK/LIVE_BOOT/chroot/usr/src/iohubos && cat /dev/null > $WORK/LIVE_BOOT/chroot/root/.bash_history

# package into squashfs
mkdir -p $WORK/LIVE_BOOT/image/live
mksquashfs $WORK/LIVE_BOOT/chroot $WORK/LIVE_BOOT/image/live/filesystem.squashfs -e boot
cp -p $WORK/LIVE_BOOT/chroot/boot/vmlinuz-*     $WORK/LIVE_BOOT/image/vmlinuz
cp -p $WORK/LIVE_BOOT/chroot/boot/initrd.img-*  $WORK/LIVE_BOOT/image/initrd
printf "${IOHUBOS_VERSION}" >  $WORK/LIVE_BOOT/image/VERSION

# create firmware image in /installer/firmware.tgz
cd $WORK/LIVE_BOOT/image && tar zcvf /installer/firmware.tgz * && cd -

# build installer
mkdir -p $WORK/LIVE_USB
cp -rp $WORK/debootstrap $WORK/LIVE_USB/chroot
mkdir -p $WORK/LIVE_USB/chroot/usr/src && cp -rp $WORK/iohubos $WORK/LIVE_USB/chroot/usr/src/.
cp /installer/firmware.tgz $WORK/LIVE_USB/chroot/.
chroot $WORK/LIVE_USB/chroot /usr/src/iohubos/assets/installer-setup.sh
# clean up
find $WORK/LIVE_USB/chroot/var/log -type f -exec cp /dev/null {} \;
rm -rf $WORK/LIVE_USB/chroot/var/log/journal/* $WORK/LIVE_USB/chroot/var/log/apt/*
rm -rf $WORK/LIVE_USB/chroot/usr/src/iohubos && cat /dev/null > $WORK/LIVE_USB/chroot/root/.bash_history

# package into squashfs
mkdir -p /installer/image/live
mksquashfs $WORK/LIVE_USB/chroot /installer/image/live/filesystem.squashfs -e boot
cp $WORK/LIVE_USB/chroot/boot/vmlinuz-*     /installer/image/vmlinuz
cp $WORK/LIVE_USB/chroot/boot/initrd.img-*  /installer/image/initrd

# move builder to /installer
cp $WORK/iohubos/assets/build.sh /installer/.
