#!/command/with-contenv bash
#shellcheck shell=bash

#shellcheck disable=SC2154,SC1091
source /scripts/common


"${s6wrap[@]}" echo "============================================="
"${s6wrap[@]}" echo "Resetting dumphfdl"
"${s6wrap[@]}" echo "============================================="
s6-svc -r /run/service/dumphfdl || exit 1
rm -f /run/hfdl/hfdl.*.json || exit 1
