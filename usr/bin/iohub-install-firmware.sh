#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

while getopts ":b:m:" flag; do
    case "${flag}" in
        m) bootdesc=${OPTARG};;
        b) disc=${OPTARG};;
    esac
done

firmware=${@:$OPTIND:1}

# check usage
if [ "${firmware}" == "" ]; then
    echo "usage: $0 [-m <boot menu description>] [-b <boot disk device>] <firmware file>"
    echo "e.g.: $0  -b /dev/sda -m 'My custom firmware' /tmp/firmware.tgz"
    exit 1
fi

if [[ "$disk" == "" ]]; then
    # autodetect disk
    disk="/dev/$(lsblk -l | grep "/usr/lib/live/mount/medium$" | cut -d ' ' -f1 | sed 's/.$//')"
    if [[ ! -b "${disk}" ]]; then
        if [[ "$disk" =~ .p$ ]]; then
            disk=${disk::-1}
        fi
    fi
fi
if [[ ! -b "${disk}" ]]; then
    echo -e "${red}'${disk}' is not a valid disk device${end}"
    exit 1
fi

if [[ ! -f "${firmware}" ]]; then
    echo "firmware '${firmware}' not found"
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

# update partition

echo "setting '${disk}${devicePostfix}${realpartnum}' as default boot partition"

# mount disk
rm -rf /mnt/newfw
mkdir -p /mnt/newfw
mount ${disk}${devicePostfix}${realpartnum} /mnt/newfw

# extract new firmware
tar zxf ${firmware} -C /mnt/newfw
version=$(cat /mnt/newfw/VERSION)

mkdir -p /mnt/efi
mount ${disk}${devicePostfix}1 /mnt/efi

if [ "${bootdesc}" == "" ];
then
    bootdesc="IOhubOS ${version}"
fi

sed -i -e "s/^set default=\"iohub-live.*$/set default=\"iohub-live${partnum}\"/" /mnt/efi/boot/grub/grub.cfg
if [[ "${bootdesc}" != "" ]]; then
    sed -i -e "s/^menuentry \".*\" --id iohub-live${partnum}\(.*\)$/menuentry \"${bootdesc}\" --id iohub-live${partnum}\1/" /mnt/efi/boot/grub/grub.cfg
fi

umount /mnt/efi
rmdir /mnt/efi

# umount disk
umount /mnt/newfw
rmdir /mnt/newfw
