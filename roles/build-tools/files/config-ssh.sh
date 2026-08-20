#!/bin/bash
set -euo pipefail

DEFAULT_USER="attacker"
DEFAULT_KEY="${HOME}/.ssh/id_ed25519"
ssh_config="${HOME}/.ssh/config"

usage() {
    echo "Usage: $0 -name <host-alias> -server <ip_address> [-user <username>] [-key-path <path>]"
    echo
    echo "  -name       Host alias to add to ${ssh_config} (required)"
    echo "  -server     IP address / hostname of the target (required)"
    echo "  -user       Remote username (default: ${DEFAULT_USER})"
    echo "  -key-path   Path to the private key to use (default: ${DEFAULT_KEY})"
    exit 1
}

service_name=""
ip_address=""
remote_user="${DEFAULT_USER}"
key_path="${DEFAULT_KEY}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -name)
            service_name="$2"
            shift 2
            ;;
        -server)
            ip_address="$2"
            shift 2
            ;;
        -user)
            remote_user="$2"
            shift 2
            ;;
        -key-path)
            key_path="$2"
            shift 2
            ;;
        -h|--help)
            usage
            ;;
        *)
            echo "Unknown argument: $1"
            usage
            ;;
    esac
done

if [[ -z "$service_name" || -z "$ip_address" ]]; then
    echo "Error: -name and -server are required"
    usage
fi

if [ -f "$ssh_config" ]; then
    cp "$ssh_config" "${ssh_config}.bak"
    echo "Backup of SSH config created at ${ssh_config}.bak"

    # Drop any existing block for this host alias so re-running updates it in place
    # instead of leaving a stale duplicate entry.
    awk -v RS="" -v ORS="\n\n" -v target="Host $service_name" '
        { n = split($0, lines, "\n"); if (lines[1] != target) print }
    ' "$ssh_config" > "${ssh_config}.tmp"
    mv "${ssh_config}.tmp" "$ssh_config"
fi

# Append new host configuration
cat << EOF >> "$ssh_config"

Host $service_name
     HostName $ip_address
     User $remote_user
     IdentityFile $key_path
     ServerAliveInterval 30
     ServerAliveCountMax 3
     PubkeyAuthentication yes
EOF

echo "[*] Added Host '${service_name}' (${ip_address}) to ${ssh_config}"
