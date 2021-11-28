#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

kernelparams=$(cat /proc/cmdline)

IFS=' '
read -ra KPS <<< "$kernelparams"
for kernelparam in "${KPS[@]}"; do
    if [[ "$kernelparam" == "iohub-boot1" ]]; then
        printf "2"
        exit 0
    elif [[ "$kernelparam" == "iohub-boot2" ]]; then
        printf "1"
        exit 0
    fi
done

printf "1"
exit 0
