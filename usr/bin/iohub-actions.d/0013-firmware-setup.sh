#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

mkdir -p /iohub/envvars.d

# install default firmware specific versions up to current version
currentVersion=$(getVersion ${IOHUBOS_VERSION})
for version in $(ls /usr/lib/iohub/envvars.d/*.*.*-envvars | sort -V); do
    if [[ -f "$version" ]]; then
        envvar=$(basename "$version")
        normalizedVersion=$(getVersion ${envvar})
        if [ ${normalizedVersion} -le ${currentVersion} ]; then
            if [[ ! -f /iohub/envvars.d/${envvar} ]]; then
                cp "$version" /iohub/envvars.d/.
            fi
        fi
    fi
done
