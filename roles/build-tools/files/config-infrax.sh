#!/bin/bash
set -euo pipefail

DEFAULT_USER="attacker"
DEFAULT_KEY="${HOME}/.ssh/id_ed25519"

usage() {
    echo "Usage:"
    echo "  $0 --opfor-infrax"
    echo "      Generate a fresh ed25519 key, prompt for password once,"
    echo "      then deploy-keys + config-ssh for each OPFOR host."
    echo
    echo "  $0 -name <host-alias> -server <ip[,ip,...]> [-user <username>] [-key-path <path>]"
    echo "      Run deploy-keys then config-ssh for a single host."
    echo
    echo "  1. deploy-keys  - copies the local SSH public key via ssh-copy-id"
    echo "  2. config-ssh   - adds a matching Host entry to ~/.ssh/config"
    echo
    echo "If SSHPASS is already set, the password prompt is skipped."
    echo
    echo "  -name       Host alias to add to ~/.ssh/config"
    echo "  -server     Target IP or comma-separated list of IPs"
    echo "  -user       Remote username (default: ${DEFAULT_USER})"
    echo "  -key-path   Path to the private key (default: ${DEFAULT_KEY})"
    exit 1
}

setup_host() {
    local name="$1"
    local target="$2"
    local user="$3"
    local key="$4"

    echo "[*] Adding SSH config entry '${name}'"
    config-ssh -name "$name" -server "$target" -user "$user" -key-path "$key"
    echo "[*] Deploying SSH key to ${target} (${name})"
    deploy-keys -server "$target" -user "$user" -key-path "$key"
}

bootstrap_opfor() {
    local key_path="${DEFAULT_KEY}"

    mkdir -p "${HOME}/.ssh"
    chmod 700 "${HOME}/.ssh"

    echo "[*] Generating fresh ${key_path}"
    rm -f "$key_path" "${key_path}.pub"
    ssh-keygen -t ed25519 -f "$key_path" -N "" -q
    chmod 600 "$key_path"
    chmod 644 "${key_path}.pub"

    if [[ -z "${SSHPASS:-}" ]]; then
        read -r -s -p "Password for attacker on OPFOR hosts: " SSHPASS
        echo
        export SSHPASS
    fi

    setup_host redirector01 30.30.30.30 attacker "$key_path"
    setup_host redirector02 30.30.30.31 attacker "$key_path"
    setup_host redirector03 30.30.30.31 attacker "$key_path"
    setup_host payload 30.30.30.31 attacker "$key_path"
    setup_host exfil 30.30.30.31 attacker "$key_path"

    unset SSHPASS
    echo "[*] Done"
}

if [[ $# -eq 0 ]]; then
    usage
fi

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
        --opfor-infrax)
            bootstrap_opfor
            exit 0
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
    echo "Error: -name and -server are required (or use --opfor-infrax to bootstrap all hosts)"
    usage
fi

prompted_password=0
if [[ -z "${SSHPASS:-}" ]]; then
    read -r -s -p "Password for ${remote_user}@${service_name}: " ssh_password
    echo
    export SSHPASS="$ssh_password"
    prompted_password=1
    unset ssh_password
fi

setup_host "$service_name" "$server" "$remote_user" "$key_path"

if [[ "$prompted_password" -eq 1 ]]; then
    unset SSHPASS
fi
