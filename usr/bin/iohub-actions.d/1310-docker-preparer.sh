#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_DOCKER_ENABLED}" != "true" ]]; then
    exit 0
fi

systemctl stop docker.service

[ -d /iohub/docker ] || mkdir -p /iohub/docker

# create permanent docker lib if missing
[ -d /iohub/docker/lib ] || mkdir -p /iohub/docker/lib

# link to permanent docker lib
rm -rf /var/lib/docker && ln -s /iohub/docker/lib /var/lib/docker
