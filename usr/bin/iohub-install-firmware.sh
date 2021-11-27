#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

if [ $# -ne 2 ]
then
    echo "usage: $0 <firmware file> <disk device>"
    exit 1
fi
firmware=$1
disk=$2

if [[ ! -f "${firmware}" ]]; then
    echo "firmware '${firmware}' not found"
    exit 1
fi

if [[ ! -b "${disk}" ]]; then
    echo "'${disk}' is not a valid disk device"
    exit 1
fi

devicePostfix=""
if [[ $disk =~ .[0-9]$ ]]; then
    devicePostfix="p"
fi

# select new partition
partnum=$(iohub-next-partition.sh)
realpartnum=$(( partnum + 1 ))

echo "installing new firmware on '${disk}${devicePostfix}${realpartnum}'"

# format partition
sync && mkfs.vfat -F32 ${disk}${devicePostfix}${realpartnum}
if [[ $? -ne 0 ]]; then
    echo "format of '${disk}${devicePostfix}${realpartnum}' failed"
    exit 1
fi

sleep 1

# update partition

echo "setting '${disk}${devicePostfix}${realpartnum}' as default boot partition"

# mount disk
rm -rf /mnt/newfw
mkdir -p /mnt/newfw
mount ${disk}${devicePostfix}${realpartnum} /mnt/newfw

sleep 1

# extract new firmware
tar zxf ${firmware} -C /mnt/newfw

sleep 1

mkdir -p /mnt/efi
mount ${disk}${devicePostfix}1 /mnt/efi

sleep 1

sed -i -e "s/^set default=\"iohub-live.*$/set default=\"iohub-live${partnum}\"/" /mnt/efi/boot/grub/grub.cfg
umount /mnt/efi
rmdir /mnt/efi

# umount disk
umount /mnt/newfw
rmdir /mnt/newfw
