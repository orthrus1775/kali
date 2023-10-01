#!/bin/bash

# Check if the user is running as root
if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root."
    exit 1
fi

# Check for the correct number of arguments
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 <start|stop>"
    exit 1
fi

action="$1"
container_name="covenant"

if [ "$action" == "start" ]; then
    sudo docker start "$container_name" 1>/dev/null
    if [ $? -eq 0 ]; then
        echo "Covenant has started! Navigate to https://127.0.0.1:7443 in a browser"
    else
        echo "Failed to start Covenant."
    fi
elif [ "$action" == "stop" ]; then
    sudo docker stop "$container_name" 1>/dev/null
    if [ $? -eq 0 ]; then
        echo "Covenant stopped successfully."
    else
        echo "Failed to stop the Covenant."
    fi
else
    echo "Invalid action. Use 'start' or 'stop'."
    echo "Usage: $0 <start|stop>"
    exit 1
fi