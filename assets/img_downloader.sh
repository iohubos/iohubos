#!/bin/sh
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

docker pull registry:2
docker save registry:2 | gzip > /dist/registry.tar.gz
chmod 644 /dist/registry.tar.gz

# additional images

IMGNUM=1
[ -f /registry ] && cat /registry |
while read -r image
do
    docker pull ${image}
    docker save ${image} | gzip > /dist/image-${IMGNUM}.tar.gz
    chmod 644 /dist/image-${IMGNUM}.tar.gz

    IMGNUM=$((IMGNUM + 1))
done
