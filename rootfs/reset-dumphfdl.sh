#!/command/with-contenv bash
#shellcheck shell=bash

s6-svc -r /run/service/dumphfdl || exit 1
rm -f /run/hfdl/hfdl.*.json || exit 1
