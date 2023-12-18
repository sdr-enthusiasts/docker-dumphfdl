#!/bin/bash

#shellcheck disable=SC1091
source /scripts/common

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

#shellcheck disable=SC2154
"${s6wrap[@]}" echo "This container uses SDRPlay API V3. If you are using a device that will use SDRPlay please be sure"
"${s6wrap[@]}" echo "you are conforming to the license agreement."
"${s6wrap[@]}" echo "docker exec -it <container name> cat /sdrplay_license.txt"
"${s6wrap[@]}" echo "to view the license"
