#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_HOSTNAME}" == "" ]]; then
    exit 0
fi

hostnamectl set-hostname "${IOHUBOS_HOSTNAME}"

cat <<EOF >/etc/hosts
127.0.0.1	localhost
127.0.1.1	${IOHUBOS_HOSTNAME}

# The following lines are desirable for IPv6 capable hosts
::1     localhost ip6-localhost ip6-loopback
ff02::1 ip6-allnodes
ff02::2 ip6-allrouters
EOF
