#!/command/with-contenv bash
#shellcheck shell=bash

#shellcheck disable=SC1091
source /scripts/common

#shellcheck disable=SC2154
"${s6wrap[@]}" /usr/bin/sdrplay_apiService
