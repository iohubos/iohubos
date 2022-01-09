#! /bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

# === generic sourcer for iohub-bootstrap/<program>
sourcefile() {
    prog="$1"

    [ -f "/iohub/runtime/iohub-bootstrap/${prog}" ] && . "/iohub/runtime/iohub-bootstrap/${prog}"
}

# === main ===

# mount writable folder
partition=$(lsblk -l | grep "/usr/lib/live/mount/medium$" | cut -d ' ' -f1 | sed 's/.$/4/')
mount /dev/${partition} /iohub

# iohub-bootstrap/postmount
sourcefile "postmount"

# iohub-bootstrap/presetup
sourcefile "presetup"

# check first setup
if [ ! -f /iohub/setup.done ]; then
    mkdir -p /iohub/deploy
    mkdir -p /iohub/firmware
    mkdir -p /iohub/live
    mkdir -p /iohub/runtime/iohub-bootstrap
    mkdir -p /iohub/runtime/iohub-registry

    cp /usr/lib/iohub/envvars /iohub/envvars

    touch /iohub/setup.done
fi

# iohub-bootstrap/postsetup
sourcefile "postsetup"

# check if service is enabled
if [ ! -f /iohub/ask.noboot ]; then
    # iohub-bootstrap/prelivesync
    sourcefile "prelivesync"

    # overwrite downloaded system files
    if [ ! -f /iohub/disable.livesync ]; then
        if [ -d /iohub/live ]; then
            rsync -rK /iohub/live/ /
        fi
    fi

    # iohub-bootstrap/postlivesync
    sourcefile "postlivesync"

    # iohub-bootstrap/preliveactions
    sourcefile "preliveactions"

    # execute actions
    if [ ! -f /iohub/disable.actions ]; then
        for action in /usr/bin/iohub-actions.d/*; do
            if [ -x "${action}" ]; then
                ${action}
            elif [ -f "${action}" ]; then
                . "${action}"
            fi
        done
    fi

    # iohub-bootstrap/postliveactions
    sourcefile "postliveactions"
fi

# iohub-bootstrap/end
sourcefile "end"

exit 0
