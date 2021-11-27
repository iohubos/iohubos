#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_ENGINE_ENABLED}" != "true" ]]; then
    exit 0
fi

# start docker applications
/usr/bin/iohub-runner.sh & >/dev/null 2>&1
