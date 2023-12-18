#!/bin/bash

#shellcheck disable=SC1091
source /scripts/common

#shellcheck disable=SC2154
"${s6wrap[@]}" echo "This container uses SDRPlay API V3. If you are using a device that will use SDRPlay please be sure"
"${s6wrap[@]}" echo "you are conforming to the license agreement."
"${s6wrap[@]}" echo "docker exec -it <container name> cat /sdrplay_license.txt"
"${s6wrap[@]}" echo "to view the license"
