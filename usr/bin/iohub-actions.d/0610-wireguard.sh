#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions
. /usr/lib/iohub/network-functions

load_vars

if [[ "${IOHUBOS_VPN_ENABLED}" != "true" ]]; then
    exit 0
fi

mkdir -p /iohub/vpn
[ -f /iohub/vpn/private.key ] || wg genkey | tee /iohub/vpn/private.key
[ -f /iohub/vpn/public.key ] || cat /iohub/vpn/private.key | wg pubkey | tee /iohub/vpn/public.key

PRIVATE_KEY=$(cat /iohub/vpn/private.key)
NETWORK=$(network_part "${IOHUBOS_VPN_NETWORK}")
CIDR=$(cidr_part "${IOHUBOS_VPN_NETWORK}")

ADDRESS=$(add_to_ip_address ${NETWORK} ${IOHUBOS_VPN_BOX_NUMBER})

cat <<EOF >/etc/wireguard/wg0.conf
[Interface]
PrivateKey = ${PRIVATE_KEY}
Address = ${ADDRESS}/${CIDR}
SaveConfig = false

PostUp = iptables -t nat -I POSTROUTING -o ${IOHUBOS_ETH0_DEVICE} -j MASQUERADE
PostDown = iptables -t nat -D POSTROUTING -o ${IOHUBOS_ETH0_DEVICE} -j MASQUERADE

[Peer]
PublicKey = ${IOHUBOS_VPN_SERVER_PUBLIC_KEY}
EOF

if [ "${IOHUBOS_VPN_EXPOSE}" == "auto" ]; then
    if [ "${IOHUBOS_NETWORK_MODE}" == "standalone" ]; then
        ALLOWED_IPS=$(ip addr show dev ${IOHUBOS_ETH0_DEVICE} | grep "inet " | tr -s ' ' | cut -d " " -f 3)
    else
        ALLOWED_IPS="$(network_by_ip_and_mask ${IOHUBOS_ETH1_IP} ${IOHUBOS_ETH1_NETMASK})/$(cidr_by_netmask ${IOHUBOS_ETH1_NETMASK})"
    fi
else
    ALLOWED_IPS="${IOHUBOS_VPN_EXPOSE}"
fi
cat <<EOF >>/etc/wireguard/wg0.conf
AllowedIPs = ${ALLOWED_IPS}
Endpoint = ${IOHUBOS_VPN_SERVER_IP_ADDRESS}:${IOHUBOS_VPN_SERVER_IP_PORT}
PersistentKeepalive = 25
EOF

docker run --rm -d --name wg-client -v /etc/wireguard:/work --cap-add=NET_ADMIN --cap-add=SYS_MODULE iohubos/wg-client