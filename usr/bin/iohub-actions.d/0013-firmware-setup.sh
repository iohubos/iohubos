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

# prepare base config if missing
if [[ ! -f /iohub/forwards-tcp ]]; then
    cat <<EOF >/iohub/forwards-tcp
    # SRC_PORT=DST_IP:DST_PORT
EOF
    chmod 644 /iohub/forwards-tcp
fi

if [[ ! -f /iohub/forwards-udp ]]; then
    cat <<EOF >/iohub/forwards-udp
    # SRC_PORT=DST_IP:DST_PORT
EOF
    chmod 644 /iohub/forwards-udp
fi

if [[ ! -f /iohub/routes ]]; then
    cat <<EOF >/iohub/routes
    # DESTINATION/NETMASK:GATEWAY
    # e.g. 192.168.152.0/24:10.11.12.100
EOF
    chmod 644 /iohub/routes
fi
