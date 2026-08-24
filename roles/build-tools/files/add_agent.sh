#!/bin/bash

if [ -z "$1" ]; then
    echo "Use: $0 <agent_name>"
    echo "Example: $0 kharon"
    exit 1
fi

AGENT_NAME="$1"

find . -type f -name "*.axs" | while read -r file; do
    if grep -q 'register_commands_group' "$file" && grep -q '"beacon", "gopher"' "$file"; then
        if ! grep -q "$AGENT_NAME" "$file"; then
            echo "[+] Update file: $file"
            sed -i 's/\["beacon", "gopher"\([^]]*\)\]/["beacon", "gopher"\1, "'"$AGENT_NAME"'"]/g' "$file"
        else
            echo "[!] Agent $AGENT_NAME already exists in $file"
        fi
    fi
done

echo "--- Complete ---"
