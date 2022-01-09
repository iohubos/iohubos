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

partnum=${@:$OPTIND:1}

# check usage
if [ "${partnum}" == "" ]; then
    echo "usage: $0 [-b <boot disk device>] [-m <boot menu description>] <default boot partion: 1 or 2>"
    echo "eg: $0 -b /dev/sda -m 'My custom firmware' 1"
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

if [[ "${partnum}" != "1" && "${partnum}" != "2" ]]; then
    echo "partition must be either 1 or 2"
    exit 1
fi

devicePostfix=""
if [[ $disk =~ .[0-9]$ ]]; then
    devicePostfix="p"
fi

mkdir -p /mnt/efi
mount ${disk}${devicePostfix}1 /mnt/efi

sed -i -e "s/^set default=\"iohub-live.*$/set default=\"iohub-live${partnum}\"/" /mnt/efi/boot/grub/grub.cfg
if [[ "${bootdesc}" != "" ]]; then
    sed -i -e "s/^menuentry \".*\" --id iohub-live${partnum}\(.*\)$/menuentry \"${bootdesc}\" --id iohub-live${partnum}\1/" /mnt/efi/boot/grub/grub.cfg
fi

umount /mnt/efi
rmdir /mnt/efi
