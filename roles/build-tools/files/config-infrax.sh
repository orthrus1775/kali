#!/bin/bash
set -euo pipefail

DEFAULT_USER="attacker"
DEFAULT_KEY="${HOME}/.ssh/id_ed25519"

usage() {
    echo "Usage: $0 -name <host-alias> -server <ip[,ip,...]> [-user <username>] [-key-path <path>]"
    echo
    echo "Wrapper that runs deploy-keys then config-ssh:"
    echo "  1. deploy-keys  - copies the local SSH public key to the target(s) via ssh-copy-id"
    echo "  2. config-ssh   - adds a matching Host entry to ~/.ssh/config"
    echo
    echo "  -name       Host alias to add to ~/.ssh/config (required)"
    echo "  -server     Target IP or comma-separated list of IPs (required)"
    echo "  -user       Remote username (default: ${DEFAULT_USER})"
    echo "  -key-path   Path to the private key to use (default: ${DEFAULT_KEY})"
    exit 1
}

service_name=""
server=""
remote_user="${DEFAULT_USER}"
key_path="${DEFAULT_KEY}"

while [[ $# -gt 0 ]]; do
    case "$1" in
        -name)
            service_name="$2"
            shift 2
            ;;
        -server)
            server="$2"
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

if [[ -z "$service_name" || -z "$server" ]]; then
    echo "Error: -name and -server are required"
    usage
fi

echo "[*] Deploying SSH key to ${server}"
deploy-keys -server "$server" -user "$remote_user" -key-path "$key_path"

echo "[*] Adding SSH config entry '${service_name}'"
config-ssh -name "$service_name" -server "$server" -user "$remote_user" -key-path "$key_path"
