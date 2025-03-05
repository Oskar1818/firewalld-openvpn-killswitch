#!/bin/bash

# Path to your OpenVPN configuration file
CONFIG_FILE="claude.ovpn"

# Extract all unique IP addresses from the config file
echo "Extracting unique IP addresses from $CONFIG_FILE..."
IP_ADDRESSES=$(grep -E "^remote [0-9]+" "$CONFIG_FILE" | awk '{print $2}' | sort -u)

# Count unique IPs
IP_COUNT=$(echo "$IP_ADDRESSES" | wc -l)
echo "Found $IP_COUNT unique IP addresses."

echo ""
echo "Creating firewalld rules:"
echo "========================="
echo ""

# Print commands to create the zone and policy
echo "# Create VPN-Only zone"
echo "firewall-cmd --permanent --new-zone VPN-Only"
echo "firewall-cmd --permanent --zone VPN-Only --set-target DROP"
echo ""

echo "# Create VPN-Killswitch policy"
echo "firewall-cmd --permanent --new-policy VPN-Killswitch"
echo "firewall-cmd --permanent --policy VPN-Killswitch --set-target DROP"
echo ""

echo "# Reload to apply the changes:"
echo "firewall-cmd --reload"

echo "# Policy Rule for each unique IP:"
# For each unique IP, create a rich rule
for ip in $IP_ADDRESSES; do
    echo "sudo firewall-cmd --policy VPN-Killswitch --add-rich-rule='rule family=\"ipv4\" destination address=\"$ip\" service name=\"openvpn\" accept'"
done

echo ""
echo "# Set the ingress and egress zones"
echo "firewall-cmd --policy VPN-Killswitch --add-ingress-zone HOST"
echo "firewall-cmd --policy VPN-Killswitch --add-egress-zone VPN-Only"
echo ""

echo "# Test the killswitch:"
echo " activate the vpn and make sure its active"
echo "./toggle_killswitch on"
echo " now see if it works with the vpn on"
echo " then deactivate the vpn (should not have any connections)"   
echo ""

echo "# Make changes permanent after testing"
echo "firewall-cmd --runtime-to-permanent"
echo ""

echo "# usefull commands:"
echo "sudo firewall-cmd --list-all-policies"
echo "sudo firewall-cmd --policy VPN-Killswitch --remove-rich-rule='rule family="ipv4" destination address="1.2.3.4" service name="openvpn" accept'"
echo ""