# Network Connectivity Monitoring Script

## Overview
This bash script provides automated network connection monitoring and recovery for Linux systems. It continuously checks network interfaces (eth0 and wlan0) for connectivity issues and implements a multi-phase recovery process to restore network access without manual intervention.

## Purpose
The script addresses a common problem in embedded systems, IoT devices, or servers where network connections can become unstable or drop unexpectedly. Instead of requiring manual intervention, this script:
1. Detects network connectivity issues
2. Attempts to restore connectivity automatically
3. Reboots the system as a last resort if recovery fails
4. Maintains detailed logs of all actions

## How It Works

### Monitoring Process
The script follows a structured approach to network monitoring:

#### Phase 1: Initial Connectivity Check
- Checks if either eth0 or wlan0 is connected
- Verifies each connected interface can ping its gateway
- Makes 10 attempts with 10-second intervals
- Exits if a working connection is found

#### Phase 2: Connection Recovery
- Executes if Phase 1 fails to find a working connection
- Cycles the NetworkManager service (off/on) up to 15 times
- Waits 5 seconds between cycling operations
- Checks connectivity after each cycle
- Exits if connection is restored

#### Final Action: System Reboot
- Triggers only if all recovery attempts in Phases 1 and 2 fail
- Forces system reboot as a last resort to clear any hardware/driver issues

### Detailed Workflow
1. Confirms required tools (nmcli and ping) are installed
2. Defines a log file to track all actions
3. Uses a dedicated function to check interface connectivity
4. Tests both eth0 and wlan0 interfaces
5. Validates both connection state and gateway ping success
6. Implements progressive recovery strategies

## Installation

### Prerequisites
- Linux system with NetworkManager installed
- Root access or sudo privileges
- `nmcli` and `ping` utilities installed

### Setup
1. Save the script to a location like `/usr/local/bin/network-monitor.sh`
2. Make the script executable:
   ```
   chmod +x /usr/local/bin/network-monitor.sh
   ```
3. Create the log directory if it doesn't exist:
   ```
   sudo mkdir -p /var/log
   ```

### Crontab Configuration
To run the script automatically every 5 minutes:

1. Edit the root crontab:
   ```
   sudo crontab -e
   ```

2. Add the following line:
   ```
   */5 * * * * /usr/local/bin/network-monitor.sh
   ```

3. Save and exit the editor

## Caveats and Considerations

### System Impact
- Running this script via crontab creates recurring system activity
- The reboot function can disrupt running services and processes
- Consider enabling filesystem journaling to prevent data corruption during forced reboots

### Network Configuration
- The script assumes eth0 and wlan0 as standard interface names
- Systems using predictable network interface naming (e.g., enp0s3) will need modifications
- VPN or complex network setups may require additional logic

### Security Considerations
- The script requires root privileges to control networking and reboot
- Log files should be monitored as they may contain gateway IP information
- Consider implementing log rotation for `/var/log/network-monitor.log`

### Customization Options
- Adjust the number of retry attempts based on your environment's stability
- Modify the sleep durations for faster or more patient recovery
- Add notification mechanisms (email, SMS) before reboot occurs
- Extend interface checks to include other network devices (e.g., wwan0)

## Troubleshooting
If the script is not working as expected:

1. Check the log file: `cat /var/log/network-monitor.log`
2. Verify script permissions and ownership
3. Confirm crontab is properly configured with `sudo crontab -l`
4. Test the script manually with `sudo /usr/local/bin/network-monitor.sh`
