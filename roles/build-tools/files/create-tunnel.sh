#!/bin/bash

# Script to create system service for SSH tunnels

# Set colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display usage
function show_usage {
    echo "Usage: sudo $0 -i <ip_address> -n <name> [-k <key_path>] [-u <remote_user>] [-a] [-f <service_file>]"
    echo "  -i: IP address of the remote server"
    echo "  -n: Name of the tunnel (will append -tunnel automatically)"
    echo "  -k: Path to SSH key (default: ~/.ssh/id_ed25519 of the user who ran sudo)"
    echo "  -u: Username for SSH connection (default: the user who ran sudo)"
    echo "  -a: Automatically activate the service (no prompt)"
    echo "  -f: Path to an existing service file to activate (skips creation steps)"
    echo
    echo "Always intended to be run with sudo. SSH config, default key, and"
    echo "systemd User= still belong to the calling user (not root) unless you"
    echo "override them with -k or -u."
    exit 1
}

# sudo create-tunnel is the normal path. Ignore root's HOME/USER; use the
# account that invoked sudo. -k and -u are the only overrides for key/user.
function resolve_invoking_user {
    if [ -n "${SUDO_USER:-}" ] && [ "$SUDO_USER" != "root" ]; then
        real_user="$SUDO_USER"
    elif [ -n "${SUDO_UID:-}" ] && [ "$SUDO_UID" != "0" ]; then
        real_user=$(getent passwd "$SUDO_UID" | cut -d: -f1)
    elif [ "$(id -u)" -ne 0 ]; then
        real_user=$(id -un)
    else
        real_user=$(logname 2>/dev/null || true)
    fi

    if [ -z "$real_user" ] || [ "$real_user" = "root" ]; then
        echo -e "${RED}Error: could not determine the calling user. Run: sudo create-tunnel ...${NC}"
        exit 1
    fi

    real_home=$(getent passwd "$real_user" | cut -d: -f6)
    if [ -z "$real_home" ] || [ ! -d "$real_home" ]; then
        echo -e "${RED}Error: could not resolve home directory for $real_user${NC}"
        exit 1
    fi
}

function own_as_invoker {
    if [ "$EUID" -eq 0 ]; then
        chown "$real_user:$real_user" "$@"
    fi
}

# Function to activate a service
function activate_service {
    local service_path="$1"
    local service_name=$(basename "$service_path")

    echo -e "${BLUE}Activating service $service_name...${NC}"

    # Check if autossh is installed
    if ! command -v autossh &> /dev/null; then
        echo "autossh not found. Installing autossh..."
        # sudo apt-get update && sudo apt-get install -y autossh
    fi

    # Move service file to system directory
    sudo cp "$service_path" "/etc/systemd/system/"

    # Enable and start the service
    sudo systemctl daemon-reload
    sudo systemctl enable "$service_name" --now

    # Check status
    echo -e "${BLUE}Service status:${NC}"
    sudo systemctl status "$service_name"

    echo -e "${GREEN}Service activated successfully!${NC}"
}

# Parse command line arguments
auto_activate=false
service_file_path=""

while getopts "i:n:k:u:af:h" opt; do
    case $opt in
        i) ip_address="$OPTARG" ;;
        n) tunnel_name="${OPTARG}" ;;
        k) key_path="$OPTARG" ;;
        u) remote_user="$OPTARG" ;;
        a) auto_activate=true ;;
        f) service_file_path="$OPTARG" ;;
        h) show_usage ;;
        *) show_usage ;;
    esac
done

# If a service file is provided, just activate it and exit
if [ -n "$service_file_path" ]; then
    if [ ! -f "$service_file_path" ]; then
        echo -e "${RED}Error: Service file not found at $service_file_path${NC}"
        exit 1
    fi

    activate_service "$service_file_path"
    exit 0
fi

# Check required parameters
if [ -z "$ip_address" ] || [ -z "$tunnel_name" ]; then
    echo -e "${RED}Error: IP address (-i) and tunnel name (-n) are required.${NC}"
    show_usage
fi

resolve_invoking_user

# Set defaults from the invoking user (not root's HOME/USER)
if [ -z "$key_path" ]; then
    key_path="$real_home/.ssh/id_ed25519"
fi

if [ -z "$remote_user" ]; then
    remote_user="$real_user"
fi

echo -e "${BLUE}Using $real_user ($real_home) — override key with -k, remote user with -u${NC}"

# Add -tunnel suffix
service_name="${tunnel_name}-tunnel"

# Verify the SSH key exists
if [ ! -f "$key_path" ]; then
    echo -e "${RED}Error: SSH key not found at $key_path${NC}"
    exit 1
fi

# Update SSH config
echo -e "${BLUE}Updating SSH config...${NC}"
ssh_config="$real_home/.ssh/config"

# Ensure SSH config directory exists
mkdir -p "$real_home/.ssh"
chmod 700 "$real_home/.ssh"
own_as_invoker "$real_home/.ssh"

# Create backup of current SSH config if it exists
if [ -f "$ssh_config" ]; then
    cp "$ssh_config" "${ssh_config}.bak"
    own_as_invoker "${ssh_config}.bak"
    echo "Backup of SSH config created at ${ssh_config}.bak"
fi

# Append new host configuration
cat << EOF >> "$ssh_config"

Host $service_name
     HostName $ip_address
     User $remote_user
     IdentityFile $key_path
     RemoteForward 8443 localhost:443
     ServerAliveInterval 30
     ServerAliveCountMax 3
     PubkeyAuthentication yes
EOF

chmod 600 "$ssh_config"
own_as_invoker "$ssh_config"

echo -e "${GREEN}SSH config updated (${ssh_config}).${NC}"

# Create systemd service file
echo -e "${BLUE}Creating systemd service file...${NC}"
service_file="$real_home/${service_name}.service"

cat << EOF > "$service_file"
[Unit]
Description=$service_name
After=network.target
StartLimitIntervalSec=0

[Service]
Type=simple
Restart=on-failure
RestartSec=3
User=$real_user
ExecStart=/usr/bin/autossh -M 0 -N $service_name

[Install]
WantedBy=multi-user.target
EOF

own_as_invoker "$service_file"

echo -e "${GREEN}Service file created at $service_file${NC}"

# Handle activation based on flag or prompt
if $auto_activate; then
    activate_service "$service_file"
else
    read -p "Do you want to activate the service now? (y/n): " activate_response

    if [[ "$activate_response" =~ ^[Yy]$ ]]; then
        activate_service "$service_file"
    else
        echo -e "${BLUE}Service not activated. To activate later, run:${NC}"
        echo "  $0 -f $service_file"
        echo "  OR"
        echo "  sudo mv $service_file /etc/systemd/system/"
        echo "  sudo systemctl daemon-reload"
        echo "  sudo systemctl enable ${service_name}.service --now"
        echo "  sudo systemctl status ${service_name}.service"
    fi
fi

echo -e "${GREEN}Setup complete!${NC}"
