#!/bin/bash

# Basic IPTABLES Template Script
# Author: Joe Vest, Andrew Chiles

# Description:
#       Template script to protect ATRTO C2 infrastructure.
#
# Note: Run this script on both your teamservers AND redirectors!
#
# Parameter Reference:
#    ALLOWED_PORTS - port allowed from the anywhere
#    TEAM_RANGE    - IP range allowed to connect to all ports
#    INTERFACE     - Interface name
#
# Usage
#   1) Modify the parameters to fit your needs
#   2) run script

# TODO: ensure your listener ports are contained in the list below!!!
ALLOWED_PORTS="80,443,8000,8080,8443"

STUDENT_IP_ENDS=['101','102','103','104']

IP_END=$(ip addr show | grep "inet 10" | awk '{print $2}' | awk -F"." '{print $4}' | awk -F "/" '{print $1}')

TEAM=$(ip addr show | grep "inet 10" | awk '{print $2}' | awk -F"." '{print $2}')
TEAM_RANGE="10.${TEAM}.100.0/24"

if [[ ${STUDENT_IP_ENDS[*]} =~ $IP_END ]]
then
  echo "Script can not be run from on student VM, only on teamservers and redirectors!"
  exit 1
fi

# System Settings
INTERFACE="ens3"
IPTABLES="/sbin/iptables"

IFACE_STATE=$(cat /sys/class/net/$INTERFACE/operstate 2>/dev/null)

if [[ ${IFACE_STATE} != "up" ]]
then
  echo "Interface does not exist.  Please check before running."
  exit 1
fi

# Start of script
echo "Basic iptables Configuration Script"
echo "Using the following variables..."
echo " TEAM_RANGE: $TEAM_RANGE"
echo " Allowed Ports: $ALLOWED_PORTS"
echo " Primary Interface: $INTERFACE"

# Flush all existing rules
echo " Clearing Existing Rules..."
$IPTABLES -F INPUT
$IPTABLES -F FORWARD
$IPTABLES -F OUTPUT
$IPTABLES -F -t nat
$IPTABLES -F LOGGING

# Set default policies on each chain
echo " Setting Default Policies..."
$IPTABLES -P INPUT DROP
$IPTABLES -P FORWARD DROP
$IPTABLES -P OUTPUT ACCEPT

echo " Setting New Rules..."
# Open up C2 ports for access from anywhere
$IPTABLES -A INPUT -i $INTERFACE -m multiport -p tcp --dports $ALLOWED_PORTS -j ACCEPT
# Allow all access from the student range
$IPTABLES -A INPUT -i $INTERFACE -s $TEAM_RANGE -p tcp -j ACCEPT
# Anti-lockout: Allow access from the admin systems so instructors can help
$IPTABLES -A INPUT -i $INTERFACE -s 10.0.0.250/32 -p tcp -j ACCEPT
$IPTABLES -A INPUT -i $INTERFACE -s 10.0.0.30/32 -p tcp -j ACCEPT
$IPTABLES -A INPUT -i $INTERFACE -s 10.254.0.254/32 -p tcp -j ACCEPT
# Enable stateful firewall
$IPTABLES -A INPUT -i $INTERFACE -m state --state RELATED,ESTABLISHED -j ACCEPT
# Enable all outbound traffic
$IPTABLES -A OUTPUT -o $INTERFACE -j ACCEPT
# Ensure loopback traffic is allowed
$IPTABLES -A INPUT -i lo -j ACCEPT
$IPTABLES -A OUTPUT -o lo -j ACCEPT

# Create logging for dropped packets
echo " Setting Logging..."
$IPTABLES -N LOGGING
$IPTABLES -A INPUT -j LOGGING
$IPTABLES -A LOGGING -m limit --limit 4/min -j LOG --log-prefix "IPTABLES-DROPPED "
$IPTABLES -A LOGGING -j DROP

echo "Done"
echo "Use iptables -L to view the rules"
echo "NOTE: These rules are not persistent !!!"