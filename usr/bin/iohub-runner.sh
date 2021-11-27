#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

# run global docker applications
[ -x /iohub/docker/global/start.sh ] && /iohub/docker/global/start.sh

# run all docker applications
for app in /iohub/docker/apps/*/ ; do
    [ -x "${app}start.sh" ] && "${app}start.sh"
done

sleep 120
docker system prune -a -f --volumes
