#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_TIMEZONE}" == "" ]]; then
    exit 0
fi

ln -fs /usr/share/zoneinfo/${IOHUBOS_TIMEZONE} /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
