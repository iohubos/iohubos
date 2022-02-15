#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions
. /usr/lib/iohub/network-functions

load_vars

if [[ "${IOHUBOS_WIREGUARD_ENABLED}" != "true" ]]; then
    exit 0
fi

# upgrade to the new 1.1.1 location and keep backward compatibility
if [[ -d /iohub/vpn ]] && [[ ! -d /iohub/runtime/wireguard ]]; then
    mkdir -p /iohub/runtime
    mv /iohub/vpn /iohub/runtime/wireguard
    ln -s /iohub/runtime/wireguard /iohub/vpn
fi

mkdir -p /iohub/runtime/wireguard
[ -f /iohub/runtime/wireguard/private.key ] || wg genkey | tee /iohub/runtime/wireguard/private.key
[ -f /iohub/runtime/wireguard/public.key ] || cat /iohub/runtime/wireguard/private.key | wg pubkey | tee /iohub/runtime/wireguard/public.key

PRIVATE_KEY=$(cat /iohub/runtime/wireguard/private.key)
NETWORK=$(network_part "${IOHUBOS_WIREGUARD_NETWORK}")
CIDR=$(cidr_part "${IOHUBOS_WIREGUARD_NETWORK}")

ADDRESS=$(add_to_ip_address ${NETWORK} ${IOHUBOS_WIREGUARD_BOX_NUMBER})

cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${ADDRESS}/${CIDR}
SaveConfig = false

PostUp = iptables -t nat -I POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = ${IOHUBOS_WIREGUARD_SERVER_PUBLIC_KEY}
EOF

if [ "${IOHUBOS_WIREGUARD_EXPOSE}" == "auto" ]; then
    ALLOWED_IPS="${NETWORK}/${CIDR}"
else
    ALLOWED_IPS="${IOHUBOS_WIREGUARD_EXPOSE}"
fi
cat <<EOF >>/etc/wireguard/wg0.conf
AllowedIPs = ${ALLOWED_IPS}
Endpoint = ${IOHUBOS_WIREGUARD_SERVER_IP_ADDRESS}:${IOHUBOS_WIREGUARD_SERVER_IP_PORT}
PersistentKeepalive = 25
EOF

docker pull "iohubos/wg-client"

docker run --rm -d --name wg-client -v /etc/wireguard:/work --privileged iohubos/wg-client
