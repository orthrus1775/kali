#!/bin/bash

# Set colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display a header
function print_header {
    echo "======================================="
    echo "       SSH TUNNEL SERVICES STATUS      "
    echo "======================================="
    printf "%-30s %s\n" "TUNNEL NAME" "STATUS"
    echo "---------------------------------------"
}

# Check if systemctl is available
if ! command -v systemctl &> /dev/null; then
    echo "Error: systemctl not found. This script requires systemd."
    exit 1
fi

# Find all tunnel services
tunnel_services=$(systemctl list-units --type=service --all | grep -o "[a-zA-Z0-9_-]*-tunnel.service" || true)

if [ -z "$tunnel_services" ]; then
    echo "No tunnel services found."
    exit 0
fi

print_header

# Check status of each tunnel service
for service in $tunnel_services; do
    # Extract tunnel name (remove .service)
    tunnel_name=${service%.service}

    # Check if service is active
    if systemctl is-active --quiet "$service"; then
        status="${GREEN}✓${NC}"  # Check mark
    else
        status="${RED}✗${NC}"    # X mark
    fi

    # Print status
    printf "%-30s %s\n" "$tunnel_name" "$status"

    # Optional: Get more details if you want
    # active_state=$(systemctl show -p ActiveState --value "$service")
    # sub_state=$(systemctl show -p SubState --value "$service")
    # echo "  Details: $active_state ($sub_state)"
done

echo "---------------------------------------"
echo "Legend: ${GREEN}✓${NC} = Active, ${RED}✗${NC} = Inactive/Failed"
echo ""

# Offer to view detailed status for any service
read -p "View detailed status for a specific tunnel? (tunnel name/n): " tunnel_choice

if [[ ! "$tunnel_choice" =~ ^[Nn]$ ]] && [ ! -z "$tunnel_choice" ]; then
    # If user didn't add the .service extension, add it
    if [[ ! "$tunnel_choice" == *".service" ]]; then
        tunnel_choice="${tunnel_choice}.service"
    fi

    echo ""
    echo "Detailed status for $tunnel_choice:"
    echo "---------------------------------------"
    systemctl status "$tunnel_choice"
fi
