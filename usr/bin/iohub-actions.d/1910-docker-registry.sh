#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

importImage () {
    local image="$1"
    local IMAGES=$(docker load < ${image})

    echo "$IMAGES" | grep "^Loaded image: " |
    while read -r line
    do
        local tag=$(echo $line | awk '{print $NF}')

        if [[ "registry:2" == "$tag" ]]; then
            # do not store the registry in registry
            continue
        fi

        local localtag="${IOHUBOS_HOSTNAME}:${IOHUBOS_DOCKER_REGISTRY_PORT}/${tag}"
        docker tag ${tag} ${localtag}
        docker push ${localtag}
        docker image rm ${tag}
        docker image rm ${localtag}
    done
}

waitForRegistry() {
    # wait for registry fully up and running

    local ATTEMPTS=0
    while : ; do
        local httpcode=$(curl -s -o /dev/null -w "%{http_code}" "http://127.0.0.1:${IOHUBOS_DOCKER_REGISTRY_PORT}/v2/_catalog")
        if [[ "${httpcode}" == "200" ]]; then
            break
        fi
        if [ "${ATTEMPTS}" -gt 15 ] ; then
            # registry not starting, giving up
            break
        fi

        ATTEMPTS=$((ATTEMPTS + 1))
        sleep 1
    done
}

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_DOCKER_ENABLED}" != "true" || "${IOHUBOS_DOCKER_REGISTRY_ENABLED}" != "true" ]]; then
    exit 0
fi

if [[ ! -f "/var/lib/images/registry.tar.gz" ]]; then
    exit 0
fi

# always loaded from firmware, not relying on cache
docker load < /var/lib/images/registry.tar.gz
mkdir -p /iohub/docker/registry

# start registry network
if [[ -z $(docker network ls --filter name=^iohubos-registry-net$ --format="{{ .Name }}") ]]; then
     docker network create -d bridge iohubos-registry-net
fi

# start registry
docker run \
    --rm -d \
    -p ${IOHUBOS_DOCKER_REGISTRY_PORT}:5000 \
    -v /iohub/docker/registry:/var/lib/registry \
    --network=iohubos-registry-net \
    --name=iohubos-registry registry:2

if [[ ! -f "/iohub/docker/registry.done" ]]; then
    waitForRegistry

    # add found images to registry
    for image in /var/lib/images/*.tar.gz ; do
        if [[ -f "${image}" ]]; then
            importImage "${image}"
        fi
    done

    touch "/iohub/docker/registry.done"
fi

if [[ -d /iohub/runtime/iohub-registry && ${IOHUBOS_DOCKER_REGISTRY_RESCAN} == "true" ]]; then
    waitForRegistry

    # add found images to registry
    for image in /iohub/runtime/iohub-registry/*.tar.gz ; do
        if [[ -f "${image}" ]]; then
            importImage "${image}"
            if [[ ${IOHUBOS_DOCKER_REGISTRY_RESCAN_DELETE} == "true" ]]; then
                rm -f "${image}"
            fi
        fi
    done

    touch "/iohub/docker/registry.done"
fi

waitForRegistry
