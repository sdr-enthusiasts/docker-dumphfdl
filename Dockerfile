FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

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

# hadolint ignore=DL3008,SC2086,SC2039
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
    KEPT_PACKAGES+=(libglib2.0-0) && \
    TEMP_PACKAGES+=(libzmq3-dev) && \
    KEPT_PACKAGES+=(libzmq5) && \
    TEMP_PACKAGES+=(libconfig++-dev) && \
    KEPT_PACKAGES+=(libconfig++9v5) && \
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

    git clone https://github.com/ericek111/libmirisdr-5.git /src/libmirisdr-5 && \
    pushd /src/libmirisdr-5 && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make && \
    make install && \
    popd && popd && \

    # install sdrplay
    curl --location --output /tmp/install_sdrplay.sh https://raw.githubusercontent.com/sdr-enthusiasts/install-libsdrplay/main/install_sdrplay.sh && \
    chmod +x /tmp/install_sdrplay.sh && \
    /tmp/install_sdrplay.sh && \
    # build libairspy
    git clone https://github.com/airspy/airspyhf.git /src/airspyhf && \
    pushd /src/airspyhf && \
    mkdir -p /src/airspyhf/build && \
    pushd /src/airspyhf/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    ldconfig && \
    popd && popd && \
    # deploy airspyone host
    git clone https://github.com/airspy/airspyone_host.git /src/airspyone_host && \
    pushd /src/airspyone_host && \
    mkdir -p /src/airspyone_host/build && \
    pushd /src/airspyone_host/build && \
    cmake ../ -DINSTALL_UDEV_RULES=ON && \
    make && \
    make install && \
    ldconfig && \
    popd && popd && \
    # Deploy SoapySDR
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \

    git clone https://github.com/ericek111/SoapyMiri.git /src/SoapyMiri && \
    pushd /src/SoapyMiri && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make -j4 && \
    make install && \
    popd && popd && \

    # Deploy AirspyHF+
    git clone https://github.com/pothosware/SoapyAirspyHF.git /src/SoapyAirspyHF && \
    pushd /src/SoapyAirspyHF && \
    mkdir -p /src/SoapyAirspyHF/build && \
    pushd /src/SoapyAirspyHF/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy Airspy
    git clone https://github.com/pothosware/SoapyAirspy.git /src/SoapyAirspy && \
    pushd /src/SoapyAirspy && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make    && \
    make install   && \
    popd && \
    popd && \
    ldconfig && \
    # Deploy SoapyRTLSDR
    git clone https://github.com/pothosware/SoapyRTLSDR.git /src/SoapyRTLSDR && \
    pushd /src/SoapyRTLSDR && \
    BRANCH_SOAPYRTLSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYRTLSDR" && \
    mkdir -p /src/SoapyRTLSDR/build && \
    pushd /src/SoapyRTLSDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Debug && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
    # install sdrplay support for soapy
    git clone https://github.com/pothosware/SoapySDRPlay.git /src/SoapySDRPlay && \
    pushd /src/SoapySDRPlay && \
    mkdir build && \
    pushd build && \
    cmake .. && \
    make && \
    make install && \
    popd && \
    popd && \
    ldconfig && \
    # Install dumphfdl
    git clone https://github.com/szpajder/dumphfdl.git /src/dumphfdl && \
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
