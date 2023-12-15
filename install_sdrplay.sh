#!/bin/bash

#shellcheck disable=SC2164,SC2086,SC2006
ARCH=`uname -m`
OSDIST="Unknown"

VERS="3.07"
MAJVERS="3"

if [ -f "/etc/os-release" ]; then
    OSDIST=`sed '1q;d' /etc/os-release`
    echo "DISTRIBUTION ${OSDIST}"
    case "$OSDIST" in
        *Alpine*)
            ARCH="Alpine64"
        ;;
    esac
fi

echo "Architecture: ${ARCH}"
echo "API Version: ${VERS}"

# if arch is arm, armhf , set URL to ARM version
# if arch is x86_64, set URL to x86_64 version
# if arch is aarch64, set URL to aarch64 version

# https://www.sdrplay.com/software/SDRplay_RSP_API-ARM32-3.07.2.run
# https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run
# https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run

if [ "${ARCH}" == "armv7l" ]; then
  URL="https://www.sdrplay.com/software/SDRplay_RSP_API-ARM32-3.07.2.run"
elif [ "${ARCH}" == "x86_64" ]; then
  URL="https://www.sdrplay.com/software/SDRplay_RSP_API-Linux-3.07.1.run"
elif [ "${ARCH}" == "aarch64" ]; then
  URL="https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run"
elif [ "${ARCH}" == "arm64" ]; then
  URL="https://www.sdrplay.com/software/SDRplay_RSP_API-ARM64-3.07.1.run"
else
  echo "ERROR: Unsupported architecture!"
  exit 1
fi

# Below is an adaptation of the install script from the SDRPlay website
echo "Deploying SDRPlay version for architecture ${ARCH}"

echo "${URL}"

curl -s --location --output /tmp/sdrplay.run "${URL}" || exit 1
chmod +x /tmp/sdrplay.run
pushd /tmp
./sdrplay.run --target /tmp/sdrplay --noexec || exit 1
pushd /tmp/sdrplay

cp sdrplay_license.txt /sdrplay_license.txt

if [ -d "/etc/udev/rules.d" ]; then
	echo -n "Udev rules directory found, adding rules..."
	cp -f 66-mirics.rules /etc/udev/rules.d/66-mirics.rules || exit 1
	chmod 644 /etc/udev/rules.d/66-mirics.rules || exit 1
    echo "Done"
else
	echo " "
	echo "ERROR: udev rules directory not found, add udev support and run the"
	echo "installer again. udev support can be added by running..."
	echo "apt install libudev-dev"
	echo " "
	exit 1
fi

INSTALLLIBDIR="/usr/lib"
INSTALLINCDIR="/usr/include"
INSTALLBINDIR="/usr/bin"

mkdir -p ${INSTALLLIBDIR} || exit 1
mkdir -p ${INSTALLINCDIR} || exit 1
mkdir -p ${INSTALLBINDIR} || exit 1

echo -n "Installing ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS}..."
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS} || exit 1
cp -f ${ARCH}/libsdrplay_api.so.${VERS} ${INSTALLLIBDIR}/. || exit 1
chmod 644 ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS} || exit 1
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS} || exit 1
ln -s ${INSTALLLIBDIR}/libsdrplay_api.so.${VERS} ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS} || exit 1
rm -f ${INSTALLLIBDIR}/libsdrplay_api.so || exit 1
ln -s ${INSTALLLIBDIR}/libsdrplay_api.so.${MAJVERS} ${INSTALLLIBDIR}/libsdrplay_api.so  || exit 1
echo "Done"

echo -n "Installing header files in ${INSTALLINCDIR}..."
cp -f inc/sdrplay_api*.h ${INSTALLINCDIR}/. || exit 1
chmod 644 ${INSTALLINCDIR}/sdrplay_api*.h || exit 1
echo "Done"

echo -n "Installing API Service in ${INSTALLBINDIR}..."
cp -f ${ARCH}/sdrplay_apiService ${INSTALLBINDIR}/sdrplay_apiService  || exit 1
chmod 755 ${INSTALLBINDIR}/sdrplay_apiService || exit 1
echo "Done"

ldconfig
