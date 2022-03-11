#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_ADMIN_API_ENABLED}" != "true" ]]; then
    exit 0
fi

# start admin api
docker pull "${IOHUBOS_HOSTNAME}:${IOHUBOS_DOCKER_REGISTRY_PORT}/iohubos/iohubos-admin-api"

docker run -d --rm --privileged \
    --name iohubos-admin-api \
    -p ${IOHUBOS_ADMIN_API_SERVER_PORT}:8080 \
    -v /iohub/docker/apps:/mnt \
    -e ROOT_DOCKER_FOLDER=/mnt \
    -e DEST_DOCKER_FOLDER=/iohub/docker/apps \
    -e API_TOKEN="${IOHUBOS_ADMIN_API_AUTH_TOKEN}" \
    "${IOHUBOS_HOSTNAME}:${IOHUBOS_DOCKER_REGISTRY_PORT}/iohubos/iohubos-admin-api"
