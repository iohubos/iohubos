
#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_DOCKER_ENABLED}" != "true" ]]; then
    exit 0
fi

# cleanup containers
docker container prune -f

# cleanup networks
docker network prune -f

# cleanup volumes
volumes="$(docker volume ls -q)"
if [ "${volumes}" != "" ]; then
    docker volume rm ${volumes}
fi
