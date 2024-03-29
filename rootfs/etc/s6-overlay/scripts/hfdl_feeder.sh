#!/command/with-contenv bash
# shellcheck shell=bash

#shellcheck disable=SC1091
source /scripts/common

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

set -o pipefail

if [[ -n ${SERVER} ]]; then
  # Require that vdlm_server is running
  if ! netstat -an | grep -P '^\s*tcp\s+\d+\s+\d+\s+0\.0\.0\.0:15556\s+(?>\d{1,3}\.{0,1}){4}:\*\s+LISTEN\s*$' >/dev/null; then
    sleep 1
    if [[ ! ${QUIET_LOGS,,} =~ true ]]; then
      # shellcheck disable=SC2154
      "${s6wrap[@]}" echo "vdlm_server not running, exiting"
    fi
    exit
  fi

  set -e

  SERVER_ADDR="UDP:${SERVER}:${SERVER_PORT}"
  # shellcheck disable=SC2016
  "${s6wrap[@]}" socat -d TCP:127.0.0.1:15556 "$SERVER_ADDR"

  sleep 5
else
  sleep 86400
fi
