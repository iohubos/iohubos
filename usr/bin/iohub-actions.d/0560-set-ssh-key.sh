#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_SSH_PUBLIC_KEY}" == "" ]]; then
    exit 0
fi

mkdir -p /root/.ssh
chmod 700 /root/.ssh
echo "${IOHUBOS_SSH_PUBLIC_KEY}" >> /root/.ssh/authorized_keys
chmod 644 /root/.ssh/authorized_keys
