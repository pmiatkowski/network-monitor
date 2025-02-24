#!/bin/bash

# ----------------------------------------------------------------------
# Purpose: This script ensures network connectivity on eth0 or wlan0.
# It checks if either interface is connected and can ping its gateway.
# If connectivity is lost, it cycles the network manager to restore it.
# If all attempts fail, it reboots the system.
# Usage: Run manually or schedule via crontab (e.g., every 5 minutes: */5 * * * * /path/to/script)
# Dependencies: Requires nmcli and ping to be installed.
# ----------------------------------------------------------------------

# Check for required tools (nmcli and ping); exit if missing
if ! command -v nmcli >/dev/null || ! command -v ping >/dev/null; then
    echo "Error: nmcli or ping not found. Please install them."
    exit 1
fi

# Define log file for tracking script actions
LOG_FILE="/var/log/network-monitor.log"

# Function to log messages with timestamps for debugging and tracking
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
}

# ----------------------------------------------------------------------
# Function: check_interfaces
# Purpose: Checks if eth0 or wlan0 is connected and can ping its gateway.
# Returns 1 (success) if at least one interface is operational, 0 (failure) otherwise.
# ----------------------------------------------------------------------
check_interfaces() {
    for dev in eth0 wlan0; do
        if nmcli device show "$dev" | grep -q "STATE.*\(connected\)"; then
            if nmcli device show "$dev" | grep -q "IP4.GATEWAY:"; then
                ip=$(nmcli device show "$dev" | grep -Po 'IP4\.GATEWAY:\s+\K\d{1,3}(?:\.\d{1,3}){3}')
                if ping -c 4 "$ip" | grep -q "0% packet loss"; then
                    return 1  # At least one interface works
                fi
            else
                log "No gateway IP on $dev"
            fi
        else
            log "Interface $dev not connected"
        fi
    done
    return 0  # No operational interface found
}

# ----------------------------------------------------------------------
# Phase 1: Initial Connectivity Check
# Tries 10 times, waiting 10 seconds between attempts, to detect a working connection.
# Exits if successful; proceeds to Phase 2 if all attempts fail.
# ----------------------------------------------------------------------
log "Phase 1: Checking connection..."
for ((i=1; i<=10; i++)); do
    check_interfaces
    if [ $? -eq 1 ]; then
        log "CONNECTED! At least one interface is operational."
        exit 0
    fi
    log "No connection. Waiting 10 seconds..."
    sleep 10
done

# ----------------------------------------------------------------------
# Phase 2: Restore Connectivity
# Cycles network manager (nmcli off/on) up to 15 times to restore connectivity.
# Exits if successful; reboots system if all attempts fail.
# ----------------------------------------------------------------------
log "Phase 2: Cycling network manager..."
for ((i=1; i<=15; i++)); do
    log "Network cycle attempt $i of 15"
    nmcli networking off
    sleep 5
    nmcli networking on
    sleep 5
    check_interfaces
    if [ $? -eq 1 ]; then
        log "Network connection established!"
        exit 0
    fi
done

# ----------------------------------------------------------------------
# Final Action: Reboot System
# If all attempts in Phases 1 and 2 fail, reboots the system as a last resort.
# ----------------------------------------------------------------------
log "All connection attempts failed. Rebooting system..."
/sbin/reboot
