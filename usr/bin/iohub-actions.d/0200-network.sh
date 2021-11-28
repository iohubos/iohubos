#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

[ -f /iohub/envvars ] && . /iohub/envvars

if [[ "${IOHUBOS_NETWORK_CONFIG}" != "true" ]]; then
    exit 0
fi

# wait for a wifi interface ready
if [[ "${IOHUBOS_WIFI_MODE}" == "client" || "${IOHUBOS_WIFI_MODE}" == "ap" ]]; then
    WIFI_ATTEMPTS=0
    while :
    do
        FOUND_WIFI_DEVICE=$(iw dev | awk '$1=="Interface" {print $2}' | head -n 1)
        if [[ "${FOUND_WIFI_DEVICE}" != "" ]]; then
            # wifi interface found
            break
        fi

        sleep 1
        WIFI_ATTEMPTS=$((WIFI_ATTEMPTS + 1))
        if [ "${WIFI_ATTEMPTS}" -gt 30 ] ; then
            # wifi interface not found
            break
        fi
    done

    if [[ "${FOUND_WIFI_DEVICE}" == "" ]]; then
        # wifi interface not found
        exit 0
    fi

    # check if wifi autodiscovery is needed
    if [[ "${IOHUBOS_WIFI_DEVICE}" == "auto" ]]; then
        IOHUBOS_WIFI_DEVICE=${FOUND_WIFI_DEVICE}
    fi
fi

# first interface
if [[ "${IOHUBOS_WIFI_MODE}" != "client" ]]; then
    if [[ "${IOHUBOS_ETH0_MODE}" == "dhcp" ]]; then
        # wifi client enabled, do not use eth0
        cat <<EOF >/etc/network/interfaces.d/${IOHUBOS_ETH0_DEVICE}
auto ${IOHUBOS_ETH0_DEVICE}
iface ${IOHUBOS_ETH0_DEVICE} inet dhcp
EOF
    else
        # cable connection
        cat <<EOF >/etc/network/interfaces.d/${IOHUBOS_ETH0_DEVICE}
auto ${IOHUBOS_ETH0_DEVICE}
iface ${IOHUBOS_ETH0_DEVICE} inet static
    address ${IOHUBOS_ETH0_IP}
    netmask ${IOHUBOS_ETH0_NETMASK}
    gateway ${IOHUBOS_ETH0_GATEWAY}
    dns-nameservers ${IOHUBOS_ETH0_DNS}
EOF

        # configure dns resolvers
        printf "" >/etc/resolv.conf
        dnsarr=($(echo ${IOHUBOS_ETH0_DNS} | tr -s ' ' "\n"))
        for dns in "${dnsarr[@]}"; do
            if [[ "${dns}" != "" ]]; then
                echo "nameserver ${dns}" >>/etc/resolv.conf
            fi
        done
    fi
fi

# second interface (br1)
if [[ "${IOHUBOS_NETWORK_MODE}" == "router" ]]; then
    if [[ "${IOHUBOS_WIFI_MODE}" == "ap" ]]; then
        cat <<EOF >/etc/network/interfaces.d/br1
auto br1
iface br1 inet static
    bridge_ports ${IOHUBOS_ETH1_DEVICE} ${IOHUBOS_WIFI_DEVICE}
    address ${IOHUBOS_ETH1_IP}
    netmask ${IOHUBOS_ETH1_NETMASK}
iface ${IOHUBOS_ETH1_DEVICE} inet manual
iface ${IOHUBOS_WIFI_DEVICE} inet manual
EOF
    else
        cat <<EOF >/etc/network/interfaces.d/br1
auto br1
iface br1 inet static
    bridge_ports ${IOHUBOS_ETH1_DEVICE}
    address ${IOHUBOS_ETH1_IP}
    netmask ${IOHUBOS_ETH1_NETMASK}
iface ${IOHUBOS_ETH1_DEVICE} inet manual
EOF
    fi
fi

systemctl restart networking
ip link set dev ${IOHUBOS_ETH1_DEVICE} up

if [[ "${IOHUBOS_WIFI_MODE}" == "client" ]]; then
    # wifi client mode
    wpa_passphrase "${IOHUBOS_WIFI_CLIENT_SSID}" "${IOHUBOS_WIFI_CLIENT_PASS}" >/etc/wpa_supplicant.conf
    wpa_supplicant -B -D wext -i ${IOHUBOS_WIFI_DEVICE} -c /etc/wpa_supplicant.conf
    dhclient ${IOHUBOS_WIFI_DEVICE}
elif [[ "${IOHUBOS_WIFI_MODE}" == "ap" ]]; then
    # wifi ap mode
    cat <<EOT >/etc/default/hostapd
DAEMON_CONF="/etc/hostapd/hostapd.conf"
EOT

    cat <<EOT >/etc/hostapd/hostapd.conf
interface=${IOHUBOS_WIFI_DEVICE}
bridge=br1
ssid=${IOHUBOS_WIFI_AP_SSID}
wpa=2
wpa_passphrase=${IOHUBOS_WIFI_AP_PASS}
wpa_key_mgmt=WPA-PSK
wpa_pairwise=TKIP
rsn_pairwise=CCMP
auth_algs=1
macaddr_acl=0
hw_mode=g
ieee80211n=1
channel=0
EOT

    systemctl start hostapd
fi

# change console message
if [[ "${IOHUBOS_WIFI_MODE}" == "client" ]]; then
    echo "IOhubOS ${IOHUBOS_VERSION} - WiFi:\4{${IOHUBOS_WIFI_DEVICE}}" > /etc/issue
else
    echo "IOhubOS ${IOHUBOS_VERSION} - eth0:\4{${IOHUBOS_ETH0_DEVICE}}" > /etc/issue
fi
systemctl restart getty@tty1
