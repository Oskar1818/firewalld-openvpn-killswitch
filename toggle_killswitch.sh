#!/bin/bash

# Script to toggle VPN killswitch by switching network interface between zones
# Usage: ./toggle_killswitch.sh [on|off]

# Your wireless interface name
INTERFACE="wlp0s20f3"

# Zone configuration
VPN_ZONE="VPN-Only"        # Zone to use when killswitch is ON
DEFAULT_ZONE="FedoraWorkstation"  # Zone to use when killswitch is OFF

# Function to check current status
check_status() {
    CURRENT_ZONE=$(firewall-cmd --get-zone-of-interface=$INTERFACE 2>/dev/null)
    if [ "$CURRENT_ZONE" == "$VPN_ZONE" ]; then
        echo "Killswitch is currently ON (interface $INTERFACE is in $VPN_ZONE zone)"
    else
        echo "Killswitch is currently OFF (interface $INTERFACE is in $CURRENT_ZONE zone)"
    fi
}

# Function to turn killswitch on
enable_killswitch() {
    echo "Enabling VPN killswitch..."
    firewall-cmd --zone=$VPN_ZONE --change-interface=$INTERFACE
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Killswitch enabled. Only VPN traffic is allowed."
        echo "To disable, run: $0 off"
    else
        echo "ERROR: Failed to enable killswitch."
        echo "Make sure the $VPN_ZONE zone exists and you have proper permissions."
    fi
}

# Function to turn killswitch off
disable_killswitch() {
    echo "Disabling VPN killswitch..."
    firewall-cmd --zone=$DEFAULT_ZONE --change-interface=$INTERFACE
    if [ $? -eq 0 ]; then
        echo "SUCCESS: Killswitch disabled. Normal network access restored."
    else
        echo "ERROR: Failed to disable killswitch."
        echo "Trying fallback to public zone..."
        firewall-cmd --zone=public --change-interface=$INTERFACE
        if [ $? -eq 0 ]; then
            echo "SUCCESS: Restored interface to public zone."
        else
            echo "CRITICAL ERROR: Failed to restore network connectivity."
            echo "Try manually running: firewall-cmd --zone=public --change-interface=$INTERFACE"
        fi
    fi
}

# Main logic
case "$1" in
    on)
        enable_killswitch
        ;;
    off)
        disable_killswitch
        ;;
    status)
        check_status
        ;;
    *)
        echo "Usage: $0 [on|off|status]"
        echo ""
        echo "  on     - Enable VPN killswitch (move interface to $VPN_ZONE zone)"
        echo "  off    - Disable VPN killswitch (move interface to $DEFAULT_ZONE zone)"
        echo "  status - Show current killswitch status"
        echo ""
        check_status
        ;;
esac

exit 0
