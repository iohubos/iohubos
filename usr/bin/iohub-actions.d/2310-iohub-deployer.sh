#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_DEPLOYER_ENABLED}" != "true" ]]; then
    exit 0
fi

for app in /iohub/deploy/*.zip ; do
    if [ -f "${app}" ]; then
        unzip -o ${app} -d /iohub
        find /iohub/docker/apps -name start.sh -exec chmod 755 {} \;

        rm -f ${app}
    fi
done
