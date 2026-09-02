#!/bin/bash
set -euo pipefail

DEFAULT_USER="attacker"
DEFAULT_KEY="${HOME}/.ssh/id_ed25519.pub"

usage() {
    echo "Usage: $0 -server <ip[,ip,...]> [-user <username>] [-key-path <path>]"
    echo
    echo "  -server     Target server IP or comma-separated list of IPs (required)"
    echo "  -user       Remote username to deploy the key to (default: ${DEFAULT_USER})"
    echo "  -key-path   Path to the public key to deploy (default: ${DEFAULT_KEY})"
    exit 1
}

user="${DEFAULT_USER}"
key_path="${DEFAULT_KEY}"
server=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -key-path)
            key_path="$2"
            shift 2
            ;;
        -user)
            user="$2"
            shift 2
            ;;
        -server)
            server="$2"
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

if [[ -z "$server" ]]; then
    echo "Error: -server is required"
    usage
fi

if [[ "$key_path" != *.pub ]]; then
    key_path="${key_path}.pub"
fi

if [[ ! -f "$key_path" ]]; then
    echo "Error: public key not found at ${key_path}"
    exit 1
fi

IFS=',' read -ra servers <<< "$server"

for ip in "${servers[@]}"; do
    ip="$(echo "$ip" | xargs)"
    [[ -z "$ip" ]] && continue
    echo "[*] Deploying ${key_path} to ${user}@${ip}"
    ssh_opts=(
        -o StrictHostKeyChecking=accept-new
        -o PreferredAuthentications=password,keyboard-interactive
        -o PubkeyAuthentication=no
        -o NumberOfPasswordPrompts=1
        -o ConnectTimeout=10
    )
    if [[ -n "${SSHPASS:-}" ]]; then
        sshpass -e ssh-copy-id -i "$key_path" "${ssh_opts[@]}" "${user}@${ip}"
    else
        ssh-copy-id -i "$key_path" "${ssh_opts[@]}" "${user}@${ip}"
    fi
done
