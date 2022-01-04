#!/bin/bash
# Copyright 2022 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_NETWORK_MODE}" != "router" ]]; then
    exit 0
fi
if [[ "${IOHUBOS_DHCP_SERVER_ENABLED}" != "true" ]]; then
    exit 0
fi

# get network from ip and netmask
IFS=. read -r i1 i2 i3 i4 <<< ${IOHUBOS_ETH1_IP}
IFS=. read -r m1 m2 m3 m4 <<< ${IOHUBOS_ETH1_NETMASK}
IOHUBOS_ETH1_NETWORK=$(printf "%d.%d.%d.%d\n" "$((i1 & m1))" "$((i2 & m2))" "$((i3 & m3))" "$((i4 & m4))")

cat <<EOT >/etc/dhcp/dhcpd.conf
default-lease-time 600;
max-lease-time 7200;

ddns-update-style none;

authoritative;

subnet ${IOHUBOS_ETH1_NETWORK} netmask ${IOHUBOS_ETH1_NETMASK} {
    option routers ${IOHUBOS_ETH1_IP};
    option subnet-mask ${IOHUBOS_ETH1_NETMASK};
    range dynamic-bootp ${IOHUBOS_DHCP_SERVER_FROM} ${IOHUBOS_DHCP_SERVER_TO};
EOT
if [[ "${IOHUBOS_DHCP_SERVER_DNS}" != "" ]]; then
    echo "    option domain-name-servers ${IOHUBOS_DHCP_SERVER_DNS};" >>/etc/dhcp/dhcpd.conf
fi
echo "}" >>/etc/dhcp/dhcpd.conf

cat <<EOT >/etc/default/isc-dhcp-server
INTERFACESv4="br1"
EOT

systemctl start isc-dhcp-server.service
