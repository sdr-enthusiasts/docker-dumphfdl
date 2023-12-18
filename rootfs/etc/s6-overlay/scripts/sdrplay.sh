#!/command/with-contenv bash
#shellcheck shell=bash

#shellcheck disable=SC1091
source /scripts/common

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

#shellcheck disable=SC2154
"${s6wrap[@]}" /usr/bin/sdrplay_apiService
