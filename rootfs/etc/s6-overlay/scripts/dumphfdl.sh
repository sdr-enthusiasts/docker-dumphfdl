#!/command/with-contenv bash
#shellcheck shell=bash

# Credit goes to wiedehopf
# https://raw.githubusercontent.com/wiedehopf/hfdlscript/main/hfdl.sh
# just to make shellcheck shut up
freq=()
fname=()
# shellcheck disable=SC1091
source /scripts/common

if [[ -f /opt/scanner/scanner_freqs.sh ]]; then
  # shellcheck disable=SC1091
  source /opt/scanner/scanner_freqs.sh
else
  # shellcheck disable=SC1091
  source /opt/hfdl/scanner_freqs.sh
fi

touch /run/hfdl_test_mode

if [[ -z "$TIMEOUT" ]]; then
  TIMEOUT=90
fi

#shellcheck disable=SC2154
"${s6wrap[@]}" echo "Running through test to determine best frequencies."
"${s6wrap[@]}" echo "Each test will run for $TIMEOUT seconds"

trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

##############################################################

#finds the most-active frequencies currently in use by aircraft then runs dumphfdl using them. dumphfdl version 1.2.1 or higher is required

#this script is written for use with an sdrplay sdr on a computer with a fast #multicore processor running linux. At least a Raspberry Pi 4 or a mini PC recommended. Modify the script as needed for use with an airspy hf+ discovery sdr (consult your sdr's documentation for sampling rate, gain and other settings information.)

#you must specify the testing duration for each array of frequencies from the command line when you run the script, for example ./hfdl.sh 2m or ./hfdl.sh 90s. Choose the lowest duration that still gives you a good representative sample of current activity on the frequencies.

#the script may be automatically run at intervals as a cron job if you wish. Example: run crontab -e and at the end of the file add 0 * * * * /home/pi/dumphfdl/hfdl.sh 2m  > /home/pi/hflog/cron.log 2>&1 (which will also log the output of the script plus any error messages)

#to close dumphfdl after running the script, run pkill dumphfdl in another terminal window

###############################################################

# build the command line for dumphfdl
dumpcmd=(/usr/local/bin/dumphfdl)

# edit the soapysdr driver as required
dumpcmd+=(--soapysdr "${SOAPYSDRDRIVER}")
dumpcmd+=(--station-id "$FEED_ID")

dumpcmd+=(--output "decoded:json:udp:address=127.0.0.1,port=5556")
# dumpcmd+=(--output "decoded:json:tcp:address=feed.airframes.io,port=5556")

# if EXTRA_OUTPUT is configured, append it to the dumphfdl command
if [[ -n "$DUMP_HFDL_COMMAND_EXTRA" ]]; then
  # I don't know if this is necessary, but it doesn't hurt I don't think.
  # split the string into an array
  IFS=' ' read -r -a extra_output <<<"$DUMP_HFDL_COMMAND_EXTRA"
  dumpcmd+=("${extra_output[@]}")

fi

if chk_enabled "${ENABLE_SYSTABLE}"; then
  # the systable file
  dumpcmd+=(--system-table "/opt/dumphfdl-data/systable.conf" --system-table-save "/opt/dumphfdl-data/systable.conf")
fi

if chk_enabled "${ENABLE_BASESTATION}"; then
  # base station database
  dumpcmd+=(--bs-db "/usr/local/share/basestation/BaseStation.sqb" --freq-as-squawk)

  if chk_enabled "${BASESTATION_VERBOSE}"; then
    dumpcmd+=(--ac-details "verbose")
  fi
fi

if [[ -n "$ZMQ_MODE" ]]; then
  if [[ -n "$ZMQ_ENDPOINT" ]]; then
    dumpcmd+=("--output" "decoded:json:zmq:mode=${ZMQ_MODE,,},endpoint=${ZMQ_ENDPOINT}")
  fi
fi

# only run scan if FREQUENCIES is not set
if [[ -n "${FREQUENCIES}" ]]; then
  rm -rf /run/hfdl_test_mode
  # shellcheck disable=SC2206
  longcmd=("${dumpcmd[@]}" "$GAIN_TYPE" "$GAIN" --sample-rate "$SOAPYSAMPLERATE" $FREQUENCIES)

  "${s6wrap[@]}" echo "Frequencies were supplied, skipping test."
  "${s6wrap[@]}" echo "------"
  "${s6wrap[@]}" echo "Running: ${longcmd[*]}"
  "${s6wrap[@]}" "${longcmd[@]}"
  "${s6wrap[@]}" echo "------"
# we must be in scan mode, lets see if the scanner was previously run and we have a valid state
elif [[ -f /opt/scanner/current_state ]]; then
  #shellcheck disable=SC1091
  source /opt/scanner/current_state
  "${s6wrap[@]}" echo "Found previous state, running with previous state of frequencies."
  "${s6wrap[@]}" echo "run docker exec -it dumphfdl /reset-dumphfdl.sh to rerun the scanner"
  "${s6wrap[@]}" echo "Using ${freq[0]}"
  rm -rf /run/hfdl_test_mode
  # shellcheck disable=SC2206
  longcmd=("${dumpcmd[@]}" "$GAIN_TYPE" "$GAIN" --sample-rate "$SOAPYSAMPLERATE" ${freq[0]})

  "${s6wrap[@]}" echo "------"
  "${s6wrap[@]}" echo "Running: ${longcmd[*]}"
  "${s6wrap[@]}" "${longcmd[@]}"
  "${s6wrap[@]}" echo "------"
else

  # adjust scoring weights
  WEIGHT_POSITIONS=40
  WEIGHT_AIRCRAFT=10
  WEIGHT_GROUNDSTATION=1

  # nothing beyond this point should need user changes

  trap 'echo "[ERROR] Error in line $LINENO when executing: $BASH_COMMAND"' ERR

  #this kills any currently-running dumphfdl and tail tasks. (If you tail or multitail the hfdl.log, not killing tail tasks will leave several zombie tail processes running which could impact your computer's performance.)
  pkill dumphfdl || true
  pkill tail || true
  sleep 5

  # this shouldn't need changing
  TMPLOG="/tmp/hfdl.sh.log.tmp"
  rm -f "$TMPLOG"

  aircraftMessages=()
  positions=()
  stationMessages=()
  score=()

  "${s6wrap[@]}" echo --------
  i=0
  for _ in "${freq[@]}"; do
    aircraftMessages+=(0)
    stationMessages+=(0)
    positions+=(0)
    score+=(0)
    rm -f "$TMPLOG"
    # shellcheck disable=SC2206
    timeoutcmd=(timeout "$TIMEOUT" "${dumpcmd[@]}" "$GAIN_TYPE" "$GAIN" --sample-rate "$SOAPYSAMPLERATE" ${freq[$i]} --output "decoded:text:file:path=$TMPLOG")
    "${s6wrap[@]}" echo "running: ${timeoutcmd[*]}"
    "${s6wrap[@]}" "${timeoutcmd[@]}" || true
    if [[ -f "$TMPLOG" ]]; then
      stationMessages[i]=$(grep -c "Src GS" "$TMPLOG" || true)
      aircraftMessages[i]=$(grep -c "Src AC" "$TMPLOG" || true)
      positions[i]=$(grep -c "Lat:" "$TMPLOG" || true)
      score[i]=$((WEIGHT_POSITIONS * positions[i] + WEIGHT_AIRCRAFT * aircraftMessages[i] + WEIGHT_GROUNDSTATION * stationMessages[i]))
    fi
    "${s6wrap[@]}" echo --------
    "${s6wrap[@]}" printf "%-20s%-15s%-25s%-26s%-18s\n" "${fname[$i]}" "score: ${score[$i]}" "stationMessages: ${stationMessages[$i]}" "aircraftMessages: ${aircraftMessages[$i]}" "positions: ${positions[$i]}"
    "${s6wrap[@]}" echo --------
    ((i += 1))
    sleep 10
  done

  rm -f "$TMPLOG"

  "${s6wrap[@]}" echo --------
  "${s6wrap[@]}" echo Summary:
  "${s6wrap[@]}" echo --------
  i=0
  k=0
  for _ in "${freq[@]}"; do
    "${s6wrap[@]}" printf "%-20s%-15s%-25s%-26s%-18s\n" "${fname[$i]}" "score: ${score[$i]}" "stationMessages: ${stationMessages[$i]}" "aircraftMessages: ${aircraftMessages[$i]}" "positions: ${positions[$i]}"
    if ((${score[$i]} > ${score[$k]})); then
      k=$i
    fi
    ((i += 1))
  done
  "${s6wrap[@]}" echo --------
  "${s6wrap[@]}" echo "${fname[$k]} wins"
  "${s6wrap[@]}" printf "%-20s%-15s%-25s%-26s%-18s\n" "${fname[$k]}" "score: ${score[$k]}" "stationMessages: ${stationMessages[$k]}" "aircraftMessages: ${aircraftMessages[$k]}" "positions: ${positions[$k]}"
  "${s6wrap[@]}" echo --------

  #Display the friendly name, gain elements, sample rate and active frequencies chosen by the script when running it manually in a terminal
  "${s6wrap[@]}" echo "Using ${fname[$k]}: frequencies ${freq[$k]}"

  #this ends the script and runs dumphfdl using the above parameters and the most-acive frequency array using its gain reduction settings and sampling rate

  #NOTE: if something is wrong with your script or if no messages were received it will always default to using the first frequency array

  rm -rf /run/hfdl_test_mode

  echo "freq=(\"${freq[$k]}\")" >/opt/scanner/current_state
  # shellcheck disable=SC2206
  longcmd=("${dumpcmd[@]}" "$GAIN_TYPE" "$GAIN" --sample-rate "$SOAPYSAMPLERATE" ${freq[$k]})

  "${s6wrap[@]}" echo "------"
  "${s6wrap[@]}" echo "Running: ${longcmd[*]}"
  "${s6wrap[@]}" "${longcmd[@]}"
  "${s6wrap[@]}" echo "------"
fi
