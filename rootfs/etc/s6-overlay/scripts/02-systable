#!/command/with-contenv bash
# shellcheck shell=bash

# if the /opt/dumphfdl-data directory does not have a systable.cong file, grab it from github
if [ ! -f /opt/dumphfdl-data/systable.conf ]; then
    curl -o /opt/dumphfdl-data/systable.conf https://raw.githubusercontent.com/szpajder/dumphfdl/master/etc/systable.conf
fi
