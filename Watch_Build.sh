#!/bin/bash
set -e  # Exit on error

if ! command -v gum &> /dev/null; then
   echo "Gum could not be found, Please install Gum"
   exit 5
fi

CompileScript=$1
ProjectRootDir=$2

if [[ -z "$CompileScript" || -z "$ProjectRootDir" ]]; then
   echo "Usage: ./Watch_Build.sh <Path/To/CompileScript> <Path/To/Project/Root>"
   exit 1
fi

if [[ ! -d "$ProjectRootDir" ]]; then
   echo "Invalid Directory : $ProjectRootDir"
   exit 2
fi

if [ ! -f "$CompileScript" ]; then
   echo "Invalid Compile Script : $CompileScript"
   exit 3
fi

if [ ! -x "$CompileScript" ]; then
   echo "Is not Executable! : $CompileScript"
   exit 4
fi

if ! gum confirm "Start?"; then
   echo "Operation Canceled"
   exit 0
fi

# Collect existing watch directories
watch_dirs=()
for dir in src Source Resource wwwroot; do
   if [[ -d "$ProjectRootDir/$dir" ]]; then
      watch_dirs+=("$ProjectRootDir/$dir")
   fi
done

if [[ ${#watch_dirs[@]} -eq 0 ]]; then
   echo "No watchable directories found in : $ProjectRootDir (expected one of: src/ Source/ Resource/ wwwroot/)"
   exit 6
fi

# Function to calculate hash of directory contents
calculate_hash() {
   find "${watch_dirs[@]}" -type f -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -d' ' -f1
}

echo "Watching ${watch_dirs[*]} for changes (adaptive polling, max 5s)..."

# Initial hash
previous_hash=$(calculate_hash)
current_interval=2
max_interval=5

while true; do
   sleep "$current_interval"

   current_hash=$(calculate_hash)

   if [ "$current_hash" != "$previous_hash" ]; then
      clear
      echo "Found a change.. Compiling"
      "$CompileScript"
      previous_hash=$current_hash
      current_interval=2  # Reset to fast polling after change
   else
      # No change, increase interval (adaptive polling)
      if [ "$current_interval" -lt "$max_interval" ]; then
         current_interval=$((current_interval + 1))
      fi
   fi
done
