#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

# basic bash config
cat <<'EOT' >/root/.bashrc
alias ll='ls $LS_OPTIONS -la'
alias cd='cd -P'
export EDITOR=vi
EOT

# enable contrib non-free
cat <<EOT >/etc/apt/sources.list
deb http://ftp.us.debian.org/debian ${SUITE} main contrib non-free
EOT

DEBIAN_FRONTEND=noninteractive apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    linux-image-amd64 \
    live-boot \
    systemd-sysv

# install base software
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends apt-utils
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends procps ca-certificates vim nano
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends grub2-common dosfstools grub-pc-bin grub-efi-amd64-bin
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends efibootmgr parted fdisk
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends curl wget iputils-ping bc rsync mawk sed cron lshw
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends isc-dhcp-client
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends isc-dhcp-server
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends ebtables iptables
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends net-tools bridge-utils ifupdown2
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends libconfig9 libjson-c5 zlib1g libssl1.1 libmbedtls12
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends zip unzip
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends wireguard
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends acpi-support-base acpid bc
DEBIAN_FRONTEND=noninteractive apt-get install -y wireless-tools iw hostapd wpasupplicant
DEBIAN_FRONTEND=noninteractive apt-get install -y firmware-iwlwifi firmware-realtek firmware-ralink firmware-misc-nonfree
DEBIAN_FRONTEND=noninteractive apt-get install -y intel-microcode

systemctl disable isc-dhcp-server.service
systemctl disable hostapd.service
systemctl mask wpa_supplicant.service

# time synchronization
systemctl enable systemd-timesyncd

# ssh access
DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends openssh-client openssh-server
systemctl disable ssh.service

sed -i -e 's/^#PermitRootLogin .*$/PermitRootLogin yes/' /etc/ssh/sshd_config
sed -i -e 's/^#PubkeyAuthentication .*$/PubkeyAuthentication yes/' /etc/ssh/sshd_config
sed -i -e 's/^#PasswordAuthentication .*$/PasswordAuthentication yes/' /etc/ssh/sshd_config

# dhcp client
touch /usr/local/etc/oui.txt
cp /usr/src/iohubos/etc/dhcp/dhclient.conf /etc/dhcp/dhclient.conf

# network interfaces
cp /usr/src/iohubos/etc/network/interfaces /etc/network/interfaces
mkdir -p /etc/network/interfaces.d

# docker engine
DEBIAN_FRONTEND=noninteractive apt-get install -y apt-transport-https ca-certificates curl gnupg lsb-release software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
    $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
DEBIAN_FRONTEND=noninteractive apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y docker-ce docker-ce-cli containerd.io aufs-dkms-
systemctl disable docker.service

# docker compose
curl -L "https://github.com/docker/compose/releases/download/1.29.2/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# configure network
sed -i -e 's/^#net.ipv4.ip_forward=1$/net.ipv4.ip_forward=1/' /etc/sysctl.conf

# configure console messages
sed -i -e 's/^#kernel.printk =.*$/kernel.printk = 3 4 1 3/' /etc/sysctl.conf

# iohub commands
cp /usr/src/iohubos/usr/bin/iohub-next-partition.sh      /usr/bin/iohub-next-partition.sh
cp /usr/src/iohubos/usr/bin/iohub-install-firmware.sh    /usr/bin/iohub-install-firmware.sh
cp /usr/src/iohubos/usr/bin/iohub-runner.sh    /usr/bin/iohub-runner.sh
chmod 755 \
    /usr/bin/iohub-next-partition.sh \
    /usr/bin/iohub-install-firmware.sh \
    /usr/bin/iohub-runner.sh

cp -rp /usr/src/iohubos/usr/bin/iohub-actions.d /usr/bin
find /usr/bin/iohub-actions.d -type f -exec chmod 644 {} \;
find /usr/bin/iohub-actions.d -type f -name '*.sh' -exec chmod 755 {} \;

# bootstrap service
cp /usr/src/iohubos/usr/bin/iohub-bootstrap.sh                 /usr/bin/iohub-bootstrap.sh
cp /usr/src/iohubos/etc/systemd/system/iohub-bootstrap.service /etc/systemd/system/iohub-bootstrap.service

chmod 644 /etc/systemd/system/iohub-bootstrap.service
chmod 755 /usr/bin/iohub-bootstrap.sh

systemctl enable iohub-bootstrap.service

# set default hostname
cat <<EOF >/etc/hostname
iohub
EOF

cat <<EOF >/etc/hosts
127.0.0.1	localhost
127.0.1.1	iohub

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF

# set console default message
cp /usr/src/iohubos/etc/issue /etc/issue

# create ext4 mount point
mkdir /iohub

# custom setup
. /usr/src/iohubos/assets/live-setup-custom.include

# clean chroot
DEBIAN_FRONTEND=noninteractive apt-get clean -y

rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/*
rm -rf /usr/share/doc/*
rm -rf /usr/share/locale/*
