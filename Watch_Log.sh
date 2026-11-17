#!/bin/bash
set -e  # Exit on error

if ! command -v bat &> /dev/null; then
    echo "This script uses bat, Install it first | or edit it to make whatever u want."
    exit 1
fi

if [[ $# -eq 0 ]]; then
    echo "Usage : ./Watch_Log.sh <Path/To/Log/File> [Path/To/Log/File...]"
    exit 2
fi

# Collect existing log files
log_files=()
for path in "$@"; do
    if [[ -f "$path" ]]; then
        log_files+=("$path")
    fi
done

if [[ ${#log_files[@]} -eq 0 ]]; then
    echo "No valid log files found!"
    exit 3
fi

Hash() {
   for f in "${log_files[@]}"; do
      sha256sum "$f"
   done | sort | sha256sum | cut -d' ' -f1
}

ChangedFiles() {
   for f in "${log_files[@]}"; do
      sha256sum "$f"
   done | sort
}

echo "Watching ${log_files[*]}.."

# Initial hash
previous_hash=$(Hash)
previous_hashes=$(ChangedFiles)
current_interval=2
max_interval=5

while true; do
    sleep "$current_interval"

    current_hash=$(Hash)
    if [ "$current_hash" != "$previous_hash" ]; then
        clear
        echo "Log file changed"

        # Show which files changed
        diff <(echo "$previous_hashes") <(ChangedFiles) | grep '^[<>]' | awk '{print $3}' | sort -u | while read -r f; do
            bat --pager=none "$f"
        done

        previous_hash=$current_hash
        previous_hashes=$(ChangedFiles)
        current_interval=2  # Reset to fast polling after change
    else
        # No change, increase interval (adaptive polling)
        if [ "$current_interval" -lt "$max_interval" ]; then
            current_interval=$((current_interval + 1))
        fi
    fi
done
