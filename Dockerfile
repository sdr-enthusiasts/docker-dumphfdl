FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder-soapy

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN_TYPE="" \
    GAIN="" \
    SERIAL="" \
    SOAPYSDR="" \
    SERVER_PORT="5556" \
    MIN_MESSAGE_THRESHOLD="5" \
    ENABLE_SYSTABLE="TRUE" \
    ENABLE_BASESTATION="TRUE" \
    BASESTATION_VERBOSE="TRUE" \
    STATSD_SERVER=""

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# hadolint ignore=DL3008,SC2086,SC2039,SC1091
RUN set -x && \
    TEMP_PACKAGES=() && \
    KEPT_PACKAGES=() && \
    # Required for building multiple packages.
    TEMP_PACKAGES+=(build-essential) && \
    TEMP_PACKAGES+=(pkg-config) && \
    TEMP_PACKAGES+=(cmake) && \
    TEMP_PACKAGES+=(git) && \
    TEMP_PACKAGES+=(automake) && \
    TEMP_PACKAGES+=(autoconf) && \
    TEMP_PACKAGES+=(wget) && \
    # packages for dumpvdl2
    TEMP_PACKAGES+=(libglib2.0-dev) && \
    # if we are on trixie, we want libglib2.0-0t64, otherwise we want libglib2.0-0
    . /etc/os-release && \
    # distro="$ID" && \
    # version="$VERSION_ID" && \
    codename="$VERSION_CODENAME" && \
    if [[ "$codename" == "trixie" ]]; then \
    KEPT_PACKAGES+=(libglib2.0-0t64) && \
    KEPT_PACKAGES+=(libconfig++11) && \
    branch="devel"; \
    else \
    KEPT_PACKAGES+=(libglib2.0-0) && \
    KEPT_PACKAGES+=(libconfig++9v5) && \
    branch="master"; \
    fi && \
    TEMP_PACKAGES+=(libzmq3-dev) && \
    KEPT_PACKAGES+=(libzmq5) && \
    TEMP_PACKAGES+=(libconfig++-dev) && \
    KEPT_PACKAGES+=(libfftw3-bin) && \
    TEMP_PACKAGES+=(libfftw3-dev) && \
    TEMP_PACKAGES+=(libliquid-dev) && \
    KEPT_PACKAGES+=(libliquid1) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    TEMP_PACKAGES+=(libsqlite3-dev) && \
    KEPT_PACKAGES+=(libsqlite3-0) && \
    TEMP_PACKAGES+=(unzip) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
    # Install statsd-c-client library
    git clone https://github.com/romanbsd/statsd-c-client.git /src/statsd-client && \
    pushd /src/statsd-client && \
    make -j "$(nproc)" && \
    make install && \
    ldconfig && \
    popd && \
    # Install dumphfdl
    git clone -b "$branch" https://github.com/szpajder/dumphfdl.git /src/dumphfdl && \
    pushd /src/dumphfdl && \
    mkdir -p /src/dumphfdl/build && \
    pushd /src/dumphfdl/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    # grab the basestation database
    curl --location --output /tmp/BaseStation.zip https://github.com/rikgale/VRSData/raw/main/BaseStation.zip && \
    mkdir -p /usr/local/share/basestation/ && \
    unzip /tmp/BaseStation.zip -d /usr/local/share/basestation/ && \
    # grab the /etc/systable.conf file from the dumphfdl source tree
    mkdir -p /opt/dumphfdl-data && \
    cp /src/dumphfdl/etc/systable.conf /opt/dumphfdl-data && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*


COPY rootfs/ /
