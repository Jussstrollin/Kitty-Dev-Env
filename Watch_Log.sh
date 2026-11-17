#!/bin/bash
set -e  # Exit on error

LogPath=$1

if ! command -v bat &> /dev/null; then
    echo "This script uses bat, Install it first | or edit it to make whatever u want."
    exit 1
fi

if [[ -z "$LogPath" ]]; then
    echo "Usage : ./Watch_Log.sh <Path/To/Log/File>"
    exit 2
fi

if [[ ! -f "$LogPath" ]]; then
    echo "Invalid Log file!"
    exit 3
fi

Hash() {
   sha256sum "$LogPath" | cut -d' ' -f1
}

echo "Watching $LogPath.."

# Initial hash
previous_hash=$(Hash)
current_interval=2
max_interval=5

while true; do
    sleep "$current_interval"

    current_hash=$(Hash)
    if [ "$current_hash" != "$previous_hash" ]; then
        clear
        echo "Log file changed"
        bat --pager=none "$LogPath"

        previous_hash=$current_hash
        current_interval=2  # Reset to fast polling after change
    else
        # No change, increase interval (adaptive polling)
        if [ "$current_interval" -lt "$max_interval" ]; then
            current_interval=$((current_interval + 1))
        fi
    fi
done
