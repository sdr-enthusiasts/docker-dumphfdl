FROM ghcr.io/sdr-enthusiasts/docker-baseimage:acars-decoder

ENV DEVICE_INDEX="" \
    QUIET_LOGS="TRUE" \
    FREQUENCIES="" \
    FEED_ID="" \
    PPM="0"\
    GAIN="40" \
    SERIAL="" \
    SOAPYSDR="" \
    SERVER="acarshub" \
    SERVER_PORT="5556" \
    VDLM_FILTER_ENABLE="TRUE"

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
    KEPT_PACKAGES+=(libfftw3-bin) && \
    TEMP_PACKAGES+=(libfftw3-dev) && \
    TEMP_PACKAGES+=(libliquid-dev) && \
    KEPT_PACKAGES+=(libliquid1) && \
    TEMP_PACKAGES+=(libairspy-dev) && \
    KEPT_PACKAGES+=(libairspy0) && \
    TEMP_PACKAGES+=(libusb-1.0-0-dev) && \
    KEPT_PACKAGES+=(libusb-1.0-0) && \
    # install packages
    apt-get update && \
    apt-get install -y --no-install-recommends \
    "${KEPT_PACKAGES[@]}" \
    "${TEMP_PACKAGES[@]}"\
    && \
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
    git clone https://github.com/pothosware/SoapySDR.git /src/SoapySDR && \
    pushd /src/SoapySDR && \
    BRANCH_SOAPYSDR=$(git tag --sort="creatordate" | tail -1) && \
    git checkout "$BRANCH_SOAPYSDR" && \
    mkdir -p /src/SoapySDR/build && \
    pushd /src/SoapySDR/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make test && \
    make install && \
    popd && popd && \
    ldconfig && \
    # Deploy SoapyRTLTCP
    git clone https://github.com/pothosware/SoapyRTLTCP.git /src/SoapyRTLTCP && \
    pushd /src/SoapyRTLTCP && \
    mkdir -p /src/SoapyRTLTCP/build && \
    pushd /src/SoapyRTLTCP/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make all && \
    make install && \
    popd && popd && \
    ldconfig && \
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
    # Install dumphfdl
    git clone https://github.com/szpajder/dumphfdl.git /src/dumphfdl && \
    pushd /src/dumphfdl && \
    mkdir -p /src/dumphfdl/build && \
    pushd /src/dumphfdl/build && \
    cmake ../ -DCMAKE_BUILD_TYPE=Release && \
    make && \
    make install && \
    # git clone https://github.com/szpajder/dumpvdl2.git /src/dumpvdl2 && \
    # mkdir -p /src/dumpvdl2/build && \
    # pushd /src/dumpvdl2/build && \
    # # cmake ../ && \
    # cmake ../ -DCMAKE_BUILD_TYPE=RelWithDebInfo && \
    # make -j "$(nproc)" && \
    # make install && \
    # popd && \
    # Clean up
    apt-get remove -y "${TEMP_PACKAGES[@]}" && \
    apt-get autoremove -y && \
    rm -rf /src/* /tmp/* /var/lib/apt/lists/*


COPY rootfs/ /

# ENTRYPOINT [ "/init" ]

# Add healthcheck
HEALTHCHECK --start-period=3600s --interval=600s CMD /scripts/healthcheck.sh
