#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_ENGINE_ENABLED}" != "true" ]]; then
    exit 0
fi

systemctl stop docker.service

[ -d /iohub/docker ] || mkdir -p /iohub/docker

# create permanent docker lib if missing
[ -d /iohub/docker/lib ] || mkdir -p /iohub/docker/lib

# link to permanent docker lib
rm -rf /var/lib/docker && ln -s /iohub/docker/lib /var/lib/docker

# start docker
systemctl start docker.service

# cleanup containers
docker container prune -f

# cleanup networks
docker network prune -f

# cleanup volumes
volumes="$(docker volume ls -q)"
if [ "${volumes}" != "" ]; then
    docker volume rm ${volumes}
fi
