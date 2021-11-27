#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_TIMEZONE}" == "" ]]; then
    exit 0
fi

ln -fs /usr/share/zoneinfo/${IOHUBOS_TIMEZONE} /etc/localtime
dpkg-reconfigure --frontend noninteractive tzdata
