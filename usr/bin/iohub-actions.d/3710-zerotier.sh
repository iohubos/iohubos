#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions
. /usr/lib/iohub/network-functions

load_vars

if [[ "${IOHUBOS_ZEROTIER_ENABLED}" != "true" ]]; then
    exit 0
fi

. /usr/lib/iohub/init-functions
. /usr/lib/iohub/network-functions

load_vars

mkdir -p /iohub/runtime/zerotier

docker pull "iohubos/iohubos-zerotier"

docker run --rm -d --name zerotier \
  --cap-add NET_ADMIN --device /dev/net/tun \
  -e CLEAN_PID=Y -e ROUTE_HOST=Y \
  -v /iohub/runtime/zerotier:/var/lib/zerotier-one \
  iohubos/iohubos-zerotier:latest ${IOHUBOS_ZEROTIER_NETWORK}