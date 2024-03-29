#!/command/with-contenv bash
# shellcheck shell=bash

# shellcheck disable=SC1091
source /scripts/common

SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

if [[ -z "$SOAPYSAMPLERATE" ]]; then
	# shellcheck disable=SC2154
	"${s6wrap[@]}" echo "SOAPYSAMPLERATE is not set, exiting"
	exit 1
fi

if [[ -n "$GAIN" ]]; then
	if [[ -z "$GAIN_TYPE" ]]; then
		"${s6wrap[@]}" echo "GAIN_TYPE is not set with GAIN being set. Please see documentation. Exiting"
		exit 1
	fi
fi



if [[ -z "$SOAPYSDRDRIVER" ]]; then
	"${s6wrap[@]}" echo "SOAPYSDRDRIVER is not set, exiting"
	exit 1
fi

if [[ -n "${SERVER}" && -z "${SERVER_PORT}" ]]; then
	"${s6wrap[@]}" echo "SERVER is set but SERVER_PORT is not set, exiting"
	exit 1
fi

if [[ -n "$ZMQ_MODE" ]]; then
  if [[ -z "$ZMQ_ENDPOINT" ]]; then
	"${s6wrap[@]}" echo "ZMQ_MODE mode set to '${ZMQ_MODE}, but ZMQ_ENDPOINT is not set, exiting"
	exit 1
  fi
fi

if [[ -n "$ZMQ_ENDPOINT" ]]; then
  if [[ -z "$ZMQ_MODE" ]]; then
    "${s6wrap[@]}" echo "ZMQ_ENDPOINT mode set to '${ZMQ_ENDPOINT}, but ZMQ_MODE is not set, exiting"
	exit 1
  fi
fi

if [[ -z "$FEED_ID" ]]; then
	"${s6wrap[@]}" echo "FEED_ID is not set, exiting"
	exit 1
fi

mkdir -p /run/hfdl
touch /run/hfdl/hfdl.past5min.json


# Everything is good to go. Exit with 0

exit 0
