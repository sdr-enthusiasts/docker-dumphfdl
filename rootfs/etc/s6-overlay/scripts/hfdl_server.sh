#!/command/with-contenv bash
#shellcheck shell=bash

set -o pipefail
set -e

# Listens for the output of dumphfdl (UDP), and makes it available for multiple processes at TCP port 15555
# shellcheck disable=SC2016
socat -u udp-listen:5556,fork stdout | ncat -4 --keep-open --listen 0.0.0.0 15556

sleep 5
