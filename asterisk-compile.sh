#!/bin/sh

#
# Script to create asterisk archive
# that can be extracted and used on another server
#


source /etc/os-release
EXIST=0
WORKDIR="/tmp"
ASTERISK_VERSION="18.6.0"
ASTERISK_FILE="asterisk-${ASTERISK_VERSION}"
ASTERISK_ARCH="asterisk-${ASTERISK_VERSION}.tar.gz"
OUTPUT_ARCH="asterisk-${ASTERISK_VERSION}_$ID-$VERSION_ID"

# Prepare OS
echo "Current OS: $ID-$VERSION_ID"
case $ID in
    centos)
    yum install -y epel-release
    ;;
esac


# Prepare sources
cd ${WORKDIR}
if [[ ! -f "${ASTERISK_ARCH}" ]]; then
    wget https://downloads.asterisk.org/pub/telephony/asterisk/${ASTERISK_ARCH} -O ${ASTERISK_ARCH} && EXIST=1
else
    EXIST=1
fi

# exit if sources archive not found
if [[ "$EXIST" == "1" ]]; then
    echo "Asterisk sources found"
else
    echo "Asterisk sources not found"
    exit
fi

# Do not extract archive if sources folder already exist
if [[ ! -d "${WORKDIR}/${ASTERISK_FILE}" ]]; then
    tar -zxvf ${ASTERISK_ARCH}
fi


# Configure and compile sources
if [[ -d "${WORKDIR}/${OUTPUT_ARCH}" ]]; then
    echo "Remove existing folder ${WORKDIR}/${OUTPUT_ARCH}?"
    rm -rI ${WORKDIR}/${OUTPUT_ARCH}
fi
if [[ -f "${WORKDIR}/${OUTPUT_ARCH}.tar.gz" ]]; then
    echo "Remove existing archive ${WORKDIR}/${OUTPUT_ARCH}.tar.gz?"
    rm -rI ${WORKDIR}/${OUTPUT_ARCH}.tar.gz
fi
cd ${WORKDIR}/${ASTERISK_FILE}
contrib/scripts/install_prereq install
./configure --with-jansson-bundled --prefix=/ --exec_prefix=/usr
menuselect/menuselect --disable-category MENUSELECT_CDR --disable-category MENUSELECT_CEL --disable-category MENUSELECT_CHANNELS \
                      --disable-category MENUSELECT_CORE_SOUNDS --disable-category MENUSELECT_MOH \
                      --enable chan_bridge_media --enable chan_pjsip --enable chan_rtp \
                      --enable CORE-SOUNDS-EN-WAV --enable MOH-OPSOUND-WAV
make install DESTDIR=${WORKDIR}/${OUTPUT_ARCH}
make samples DESTDIR=${WORKDIR}/${OUTPUT_ARCH}
make config DESTDIR=${WORKDIR}/${OUTPUT_ARCH}
make install-logrotate DESTDIR=${WORKDIR}/${OUTPUT_ARCH}
tar -C ${WORKDIR}/${OUTPUT_ARCH} -cvf ${WORKDIR}/${OUTPUT_ARCH}.tar.gz .
