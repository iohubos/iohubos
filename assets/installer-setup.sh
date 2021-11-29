#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

cat <<'EOT' >> /root/.bashrc
alias ll='ls $LS_OPTIONS -la'
alias cd='cd -P'
export EDITOR=vi
EOT

# disable vi syntax coloring
cat <<EOT >/root/.vimrc
syntax off
EOT

# change hostname
echo "IOhubOSSetup" > /etc/hostname

DEBIAN_FRONTEND=noninteractive apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv

# install base software
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends procps ca-certificates vim
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends grub2-common dosfstools grub-pc-bin grub-efi-amd64-bin
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends efibootmgr parted fdisk
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl wget iputils-ping bc rsync mawk sed cron lshw
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends isc-dhcp-client

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends net-tools bridge-utils ifupdown

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssl

# copy setup only commands
cp /usr/src/iohubos/assets/iohub-installer /usr/bin/iohub-installer
chmod 755 /usr/bin/iohub-installer

# create autologin
mkdir /etc/systemd/system/getty@.service.d
cat <<EOT >/etc/systemd/system/getty@.service.d/override.conf
[Service]
ExecStart=
ExecStart=-/sbin/agetty --noclear --autologin root %I $TERM
EOT

# clean chroot
DEBIAN_FRONTEND=noninteractive apt-get clean -y

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*
