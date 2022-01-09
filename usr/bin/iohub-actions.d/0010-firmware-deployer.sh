#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_UPGRADER_ENABLED}" != "true" ]]; then
    exit 0
fi

if [ -f "/iohub/firmware/firmware.tgz" ]; then
    # run prerequisites
    if [ -f "/iohub/firmware/firmware-pre" ]; then
        . "/iohub/firmware/firmware-pre"
        rm -f "/iohub/firmware/firmware-pre"
    fi

    # deploy firmwaretel
    iohub-install-firmware.sh "/iohub/firmware/firmware.tgz" ${IOHUBOS_DEVICE}
    rm -f "/iohub/firmware/firmware.tgz"

    # run postrequisites
    if [ -f "/iohub/firmware/firmware-post" ]; then
        . "/iohub/firmware/firmware-post"
        rm -f "/iohub/firmware/firmware-post"
    fi

    reboot
fi
