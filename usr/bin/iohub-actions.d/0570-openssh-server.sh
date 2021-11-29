#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_OPENSSH_ENABLED}" != "true" ]]; then
    exit 0
fi

systemctl start ssh.service
