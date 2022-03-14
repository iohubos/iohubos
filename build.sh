#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

ARG0="$0"
pushd `dirname $ARG0` > /dev/null
DIRNAME=`pwd -P`
popd > /dev/null

cd "$DIRNAME"

registry="${DIRNAME}/assets/registry"

# registry folder
mkdir -p "${DIRNAME}/registry"

# download registry
docker pull registry:2
docker save registry:2 | gzip > "${DIRNAME}/registry/registry.tar.gz"
chmod 644 "${DIRNAME}/registry/registry.tar.gz"

# additional images
IMGNUM=1
[ -f "${registry}" ] && cat "${registry}" |
while read -r image
do
    docker pull ${image}
    docker save ${image} | gzip > "${DIRNAME}/registry/image-${IMGNUM}.tar.gz"
    chmod 644 "${DIRNAME}/registry/image-${IMGNUM}.tar.gz"

    IMGNUM=$((IMGNUM + 1))
done

# create builder image
docker build --no-cache \
    --build-arg MIRROR="${DEB_MIRROR:-http://deb.debian.org/debian}" \
    --progress="${PROGRESS:-auto}" \
    -t iohubos/iohubos-builder .
rm -rf "${DIRNAME}/registry"

# create installer image and firmware
mkdir -p "${DIRNAME}/dist"
docker run -it --privileged --rm -v ${PWD}/dist:/dist iohubos/iohubos-builder

# clean up
docker image rm iohubos/iohubos-builder

echo -e "\n===== Installer built in ${DIRNAME}/dist =====\n"
