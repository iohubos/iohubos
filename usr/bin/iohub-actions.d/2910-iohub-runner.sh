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

# start docker applications
(
    [ -x /iohub/docker/global/start.sh ] && /iohub/docker/global/start.sh

    # run all docker applications
    for app in /iohub/docker/apps/*/ ; do
        [ -x "${app}start.sh" ] && "${app}start.sh"
    done

    sleep 120
    docker system prune -a -f --volumes
) & >/dev/null 2>&1
