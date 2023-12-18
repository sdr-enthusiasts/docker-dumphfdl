#!/command/with-contenv bash
#shellcheck shell=bash

#shellcheck disable=SC2154
SCRIPT_NAME="$(basename "$0")"
SCRIPT_NAME="${SCRIPT_NAME%.*}"

# shellcheck disable=SC2034
s6wrap=(s6wrap --quiet --timestamps --prepend="$SCRIPT_NAME" --args)

set -o pipefail

was_testing_mode=false

# Require that hfdl_server is running
if ! netstat -an | grep -P '^\s*tcp\s+\d+\s+\d+\s+0\.0\.0\.0:15556\s+(?>\d{1,3}\.{0,1}){4}:\*\s+LISTEN\s*$' >/dev/null; then
  sleep 1
  if [[ ! ${QUIET_LOGS,,} =~ true ]]; then
    "${s6wrap[@]}" echo "[hfdl_stats] hfdl_server not running, exiting"
  fi
  exit
fi

# Start our stats loop
while true; do
  # capture 5 mins of flows
  timeout --foreground 300s socat -u TCP:127.0.0.1:15556 CREATE:/run/hfdl/hfdl.past5min.json

  # if the port isn't reachable, this file isn't created, either container is shutting down or hfdl_server isn't reachable
  # in both cases let's exit, if this should still be running it will be restarted
  if ! [[ -f /run/hfdl/hfdl.past5min.json ]]; then
    exit
  fi

  # if /run/hfdl_test_mode exists we're in test mode, so don't do any of the following
  if [[ -f /run/hfdl_test_mode ]]; then
    rm -rf /run/hfdl/hfdl.*.json
    was_testing_mode=true
    continue
  fi

  # we don't want to accidentally count a low volume of messages in the average_message_count
  # if we were previously in test mode. So we'll skip this check if we were in test mode but no longer are
  if [[ $was_testing_mode == true ]]; then
    "${s6wrap[@]}" echo "Exiting test mode. Will start to count messages again."
    was_testing_mode=false
    rm -rf /run/hfdl/hfdl.*.json
    continue
  fi

  # shellcheck disable=SC2016
  "${s6wrap[@]}" echo "$(sed 's/}{/}\n{/g' /run/hfdl/hfdl.past5min.json | wc -l) hfdl messages received in last 5 mins"

  # rotate files keeping last 2 hours
  for i in {24..1}; do
    mv "/run/hfdl/hfdl.$((i - 1)).json" "/run/hfdl/hfdl.$i.json" >/dev/null 2>&1 || true
  done
  mv "/run/hfdl/hfdl.past5min.json" "/run/hfdl/hfdl.0.json" >/dev/null 2>&1 || true

  # now check and see if the last 30 minutes of data has any messages. If not, pkill dumphfdl
  # if FREQUENCIES is set, we're not using dumphfdl scan, so skip this check
  if [[ -z "${FREQUENCIES}" ]]; then
    # first, verify we have 30 minutes of data by verifying there are at least 6 files
    if [[ $(find /run/hfdl -type f -name 'hfdl.*.json' | wc -l) -gt 6 ]]; then
      # now check the last 6 files for messages
      average_message_count=$(sed 's/}{/}\n{/g' /run/hfdl/hfdl.{0..5}.json | wc -l)
      average_message_count=$((average_message_count / 6))
      if [[ $average_message_count -lt $MIN_MESSAGE_THRESHOLD ]]; then
        "${s6wrap[@]}" echo "Average messages/5 minutes (${average_message_count}) received in last 30 minutes is less then the threshold (${MIN_MESSAGE_THRESHOLD})"
        "${s6wrap[@]}" echo "Restarting dumphfdl to rerun the frequency optimizer"
        rm -f /opt/scanner/current_state
        s6-svc -r /run/service/dumphfdl
        rm -f /run/hfdl/hfdl.*.json
        exit
      else
        "${s6wrap[@]}" echo "Average messages/5 minutes (${average_message_count}) received in last 30 minutes is greater then the threshold (${MIN_MESSAGE_THRESHOLD})"
        "${s6wrap[@]}" echo "Will check again in 5 minutes"
      fi
    fi
  fi

done

sleep 5
