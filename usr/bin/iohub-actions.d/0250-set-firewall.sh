#!/bin/bash
# Copyright 2021 EZ VPN Inc.
# Author: paolo.denti@gmail.com (Paolo Denti)
#
# SPDX-License-Identifier: AGPL-3.0-only

. /usr/lib/iohub/init-functions

load_vars

if [[ "${IOHUBOS_FIREWALL_CONFIG}" != "true" ]]; then
    exit 0
fi

# check if wifi autodiscovery is needed
if [[ ( "${IOHUBOS_WIFI_MODE}" == "client" || "${IOHUBOS_WIFI_MODE}" == "ap" ) && "${IOHUBOS_WIFI_DEVICE}" == "auto" ]]; then
    IOHUBOS_WIFI_DEVICE=$(iw dev | awk '$1=="Interface" {print $2}' | head -n 1)
fi

# find out eth0
if [[ "${IOHUBOS_WIFI_MODE}" == "client" ]]; then
    IOHUBOS_INBOUND_DEVICE=${IOHUBOS_WIFI_DEVICE}
else
    IOHUBOS_INBOUND_DEVICE=${IOHUBOS_ETH0_DEVICE}
fi

iptables -F
iptables -X
iptables -t nat -F
iptables -t nat -X
iptables -t mangle -F
iptables -t mangle -X
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT ACCEPT

# local interface
iptables -A INPUT -i lo -j ACCEPT

# established
iptables -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

## input rules

# ping
iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT

# dhcp server
if [[ "${IOHUBOS_NETWORK_MODE}" == "router" ]] && [[ "${IOHUBOS_DHCP_SERVER_ENABLED}" == "true" ]]; then
    iptables -A INPUT -i br1 -p udp --dport 67 -j ACCEPT
fi

# ssh
if [[ "${IOHUBOS_OPENSSH_ENABLED}" == "true" ]]; then
    iptables -A INPUT -p tcp --dport 22 --syn -m conntrack --ctstate NEW -j ACCEPT
fi

# docker registry
if [[ "${IOHUBOS_DOCKER_REGISTRY_EXPOSE_ETH0}" != "true" ]]; then
    iptables -I FORWARD -i ${IOHUBOS_INBOUND_DEVICE} -p tcp --dport 5000 -j DROP
fi
if [[ "${IOHUBOS_NETWORK_MODE}" == "router" ]] && [[ "${IOHUBOS_DOCKER_REGISTRY_EXPOSE_ETH1}" != "true" ]]; then
    iptables -I INPUT -i br1 -p tcp --dport 5000 -j DROP
fi

## output rules

# output from router to internet
if [[ "${IOHUBOS_FIREWALL_ROUTER_TO_INTERNET}" == "true" ]]; then
    iptables -A FORWARD -i br1 -j ACCEPT
fi

# port forwards
[[ -f /iohub/forwards-tcp ]] && IOHUBOS_FIREWALL_PORT_FORWARDS_TCP=$(cat /iohub/forwards-tcp)
while IFS= read -r pf ;do
    if [[ "$pf" =~ ^\# ]] || [[ "$pf" =~ ^[[:space:]]*$ ]]; then
        continue
    fi

    mapfile -td \= fields < <(printf "%s\0" "${pf}")
    fields=("${fields[@]%$'\n'}")
    if [[ ${#fields[@]} -ne 2 ]]; then
        continue
    fi

    mapfile -td \: destination < <(printf "%s\0" "${fields[1]}")
    destination=("${destination[@]%$'\n'}")
    if [[ ${#destination[@]} -ne 2 ]]; then
        continue
    fi

    if [[ "${fields[0]}" == "22" ]] && [[ "${IOHUBOS_OPENSSH_ENABLED}" == "true" ]]; then
        continue
    fi
    if [[ "${fields[0]}" == "${IOHUBOS_ADMIN_API_SERVER_PORT}" ]] && [[ "${IOHUBOS_ADMIN_API_ENABLED}" == "true" ]]; then
        continue
    fi
    iptables -A PREROUTING -t nat -i ${IOHUBOS_INBOUND_DEVICE} -p tcp --dport ${fields[0]} -j DNAT --to ${destination[0]}:${destination[1]}
    iptables -A FORWARD -i ${IOHUBOS_INBOUND_DEVICE} -o br1 -p tcp -d ${destination[0]} --dport ${destination[1]} --syn -m conntrack --ctstate NEW -j ACCEPT
done <<< "${IOHUBOS_FIREWALL_PORT_FORWARDS_TCP}"

[[ -f /iohub/forwards-udp ]] && IOHUBOS_FIREWALL_PORT_FORWARDS_UDP=$(cat /iohub/forwards-udp)
while IFS= read -r pf ;do
    if [[ "$pf" =~ ^\# ]] || [[ "$pf" =~ ^[[:space:]]*$ ]]; then
        continue
    fi

    mapfile -td \= fields < <(printf "%s\0" "${pf}")
    fields=("${fields[@]%$'\n'}")
    if [[ ${#fields[@]} -ne 2 ]]; then
        continue
    fi

    mapfile -td \: destination < <(printf "%s\0" "${fields[1]}")
    destination=("${destination[@]%$'\n'}")
    if [[ ${#destination[@]} -ne 2 ]]; then
        continue
    fi

    iptables -A PREROUTING -t nat -i ${IOHUBOS_INBOUND_DEVICE} -p tcp --dport ${fields[0]} -j DNAT --to ${destination[0]}:${destination[1]}
    iptables -A FORWARD -i ${IOHUBOS_INBOUND_DEVICE} -o br1 -p tcp -d ${destination[0]} --dport ${destination[1]} -m conntrack --ctstate NEW -j ACCEPT
done <<< "${IOHUBOS_FIREWALL_PORT_FORWARDS_UDP}"

# masquerade
iptables -t nat -A POSTROUTING -o ${IOHUBOS_INBOUND_DEVICE} -j MASQUERADE
if [[ "${IOHUBOS_NETWORK_MODE}" == "router" ]]; then
    iptables -t nat -A POSTROUTING -o br1 -j MASQUERADE
fi
