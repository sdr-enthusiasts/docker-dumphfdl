#!/command/with-contenv bash
# shellcheck shell=bash

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

SOURCE_PORT=5556
ACARS_BRIDGE_BIN="/opt/acars-bridge"
ACARS_BRIDGE_CMD=(--source-port "$SOURCE_PORT")
ACARS_BRIDGE_CMD+=(--source-protocol "zmq")
ACARS_BRIDGE_CMD+=(--source-host "127.0.0.1")

"${s6wrap[@]}" echo "[INFO] Starting acars-bridge with command: $ACARS_BRIDGE_BIN ${ACARS_BRIDGE_CMD[*]}"
"${s6wrap[@]}" "$ACARS_BRIDGE_BIN" "${ACARS_BRIDGE_CMD[@]}"
