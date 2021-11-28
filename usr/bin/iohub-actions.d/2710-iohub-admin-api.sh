#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_ADMIN_API_ENABLED}" != "true" ]]; then
    exit 0
fi

# start admin api
docker pull "${IOHUBOS_HOSTNAME}:5000/ezvpn/iohubos-admin-api"

docker run -d --rm --privileged \
    --name iohubos-admin-api \
    -p ${IOHUBOS_ADMIN_API_SERVER_PORT}:8080 \
    -v /iohub/docker/apps:/mnt \
    -e ROOT_DOCKER_FOLDER=/mnt \
    -e DEST_DOCKER_FOLDER=/iohub/docker/apps \
    -e API_TOKEN="${IOHUBOS_ADMIN_API_AUTH_TOKEN}" \
    "${IOHUBOS_HOSTNAME}:5000/ezvpn/iohubos-admin-api"
