#!/bin/bash

# Get the Physical Interface name
PHY_IFACE=""
while [ "$PHY_IFACE" = "" ]
do
    ip link
    read -p "Choose the Network Interface you use to connect to your physical network: " physical_net_iface
    ip link | grep $physical_net_iface
    if [ $? -eq 0 ]; then
        PHY_IFACE=$physical_net_iface
    else
        echo "The device does not exist, retry."
    fi
done

# Get the ZeroTier Network ID from the user and join the network
read -p "Give the ZeroTier Network ID for the Network you want to join: " zt_net_id
zerotier-cli join $zt_net_id
echo "Remember to authorize the new device and set the routes accordingly in the ZeroTier Web Interface."

# Retrieve the ZeroTier Network Interface name
ZT_IFACE="$(ls /sys/class/net | grep zt)"

# Set up the iptables rules to allow for direct IP forwarding
iptables -t nat -A POSTROUTING -o $PHY_IFACE -j MASQUERADE
iptables -A FORWARD -i $PHY_IFACE -o $ZT_IFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $ZT_IFACE -o $PHY_IFACE -j ACCEPT
bash -c iptables-save > /etc/iptables/rules.v4