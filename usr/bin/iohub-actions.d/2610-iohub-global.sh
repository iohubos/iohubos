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

# create global volume if missing
[ -d /iohub/docker/global/volumes/global-vol ] || mkdir -p /iohub/docker/global/volumes/global-vol

# manage global broker
if [[ "${IOHUBOS_GLOBAL_MQTT}" == "true" ]]; then
    cat <<EOT >/iohub/docker/global/start.sh
if [ -z \$(docker network ls --filter name=^${IOHUBOS_GLOBAL_MQTT_NET}\$ --format="{{ .Name }}") ] ; then
     docker network create -d bridge ${IOHUBOS_GLOBAL_MQTT_NET}
fi

docker pull ${IOHUBOS_GLOBAL_MQTT_IMG}
docker run --network=${IOHUBOS_GLOBAL_MQTT_NET} --rm -d --name=${IOHUBOS_GLOBAL_MQTT_NAME} ${IOHUBOS_GLOBAL_MQTT_IMG}
EOT
    chmod 755 /iohub/docker/global/start.sh
else
    [ -f /iohub/docker/global/start.sh ] && rm -f /iohub/docker/global/start.sh
fi
