#!/bin/bash
set -e  # Exit on error

CompileScript=$1
ProjectRootDir=$2

if [[ -z "$CompileScript" || -z "$ProjectRootDir" ]]; then
   echo "Usage: ./Watch_Build.sh <Path/To/CompileScript> <Path/To/Project/Root>"
   exit 1
fi

if [[ ! -d "$ProjectRootDir" || ! -d "$ProjectRootDir"/src || ! -d "$ProjectRootDir"/Resources ]]; then
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

# Function to calculate hash of directory contents
calculate_hash() {
   find "$ProjectRootDir/src" "$ProjectRootDir/Source" "$ProjectRootDir/Resources" -type f -exec sha256sum {} + 2>/dev/null | sort | sha256sum | cut -d' ' -f1
}

echo "Watching $ProjectRootDir/src and $ProjectRootDir/Resources for changes (adaptive polling, max 5s)..."

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
