#!/bin/bash
#
# 2019.03.15 HM Initial created
# 2019.09.01 HW Update for the latest ESP-IDF
#

function usage() {
    cat <<_EOT_
    Usage:
     $0 [-r] [-t]
     
     Description:
      test esp-idf port

     Options:
        -r : fetch the latest from upstream and merge it to the master
	-t : target esp version
        -w : working folder
_EOT_
exit 1
}

HOME=$(eval "pwd")
WRSDIR="${HOME}/esp/"
ESP_TARGET_VERSION="v4.4"

while getopts rt:w:h OPT
do
 case $OPT in
    r)
        FETCH_FLG="on"
        ;;
    t)
        ESP_TARGET_VERION=$OPTARG
        ;;
    w)
	WRSDIR=$OPTARG
        ;;
    h)
        usage
        ;;
   \?)
        usage
        ;;
    esac
done

RMDCMD='/bin/rm -rf'
MKDCMD='/bin/mkdir'
CPDCMD='/bin/cp'
GITCMD='/usr/bin/git'
GITCLEAN=' clean -dfx'

SCRIPTDIR=`dirname $0`
SCRIPTDIR=`cd $SCRIPTDIR && pwd -P`

ESPDIR="esp-idf"
WFDIR="wolfssl_test"
EXAMPLEDIR="${ESPDIR}/examples/protocols"
SCDIR="${WFDIR}/IDE/Espressif/ESP-IDF"
BRANCH="master"
COMMITHASH="master"

# check directory
echo "checking... ${WRSDIR}"
[ ! -d "${WRSDIR}" ] && mkdir -p "${WRSDIR}"

# clone wolfssl
GITPATH="https://github.com/wolfSSL/wolfssl.git"

echo "cloning... $GITPATH"
if [ -d ${WRSDIR}${WFDIR} ]; then
    echo "exist.: $WFDIR. will be removed."    
    ${RMDCMD} ${WRSDIR}${WFDIR}
fi

pushd ${WRSDIR} > /dev/null

${GITCMD} clone ${GITPATH} wolfssl_test

# clone esp-idf
if [ ! -z "$IDF_PATH" ]; then
    KEEP_IDE_PATH=$IDF_PATH
fi

IDF_PATH=${WRSDIR}${ESPDIR}
echo "target esp-idf : $IDF_PATH"

if [ -d ${IDF_PATH} ]; then
    #echo "exist : $IDF_PATH. will be cleaning up files."
    #
    #pushd ${IDF_PATH} > /dev/null
    #pwd
    #
    #${GITCMD} ${GITCLEAN}
    #${GITCMD} submodule update --init --recursive
    #${GITCMD} pull
    
    rm -rf ${IDF_PATH}
fi

${GITCMD} clone -b ${ESP_TARGET_VERSION} --recursive https://github.com/espressif/esp-idf.git

# move to ESP Directory
pushd ${IDF_PATH} > /dev/null
./install.sh
. ./export.sh
popd > /dev/null # ${SCRIPTDIR}

# deploying files into esp-idf
pushd ${WRSDIR}${SCDIR} > /dev/null
pwd
./setup.sh
popd > /dev/null # ${SCRIPTDIR} 

# Uncomment WOLFSSL_ESPIDF
pushd ${IDF_PATH} > /dev/null    # /path/to/esp-idf
# uncomment out macro definition for ESP32-WROOM-32
TRGFILE="./components/wolfssl/wolfssl/wolfcrypt/settings.h"

sed -i -e "s/\/\* #define WOLFSSL_ESPIDF \*\//#define WOLFSSL_ESPIDF /" ${TRGFILE} 
sed -i -e "s/\/\* #define WOLFSSL_ESPWROOM32 \*\//#define WOLFSSL_ESPWROOM32/" ${TRGFILE} 

popd > /dev/null # ${SCRIPTDIR}
pwd

# make examples
# benchmark
pushd ${WRSDIR}${EXAMPLEDIR}/wolfssl_benchmark > /dev/null
pwd

idf.py build
ret=$?
echo $ret
if [ $ret -ne 0 ]; then
    echo "Failed to build Benchmark program"
    exit 1
else
    echo "Succeed to build Benchmark program"
fi

popd > /dev/null # ${SCRIPTDIR}
pwd

# test
pushd ${WRSDIR}${EXAMPLEDIR}/wolfssl_test > /dev/null

idf.py build
ret=$?
if [ $ret -ne 0 ]; then
    echo "Failed to build Crypt test program"
    exit 1
else
    echo "Succeed to build Crypt test program"
fi
popd > /dev/null # ${SCRIPTDIR}
pwd

# server
pushd ${WRSDIR}${EXAMPLEDIR}/wolfssl_server > /dev/null

idf.py build
ret=$?
if [ $ret -ne 0 ]; then
    echo "Failed to build Server example program"
    exit 1
else
    echo "Succeed to build Server example program"
fi

popd > /dev/null # ${SCRIPTDIR}
pwd

# client
pushd ${WRSDIR}${EXAMPLEDIR}/wolfssl_client > /dev/null

idf.py build
ret=$?
if [ $ret -ne 0 ]; then
    echo "Failed to build Client example program"
    exit 1
else
    echo "Succeed to build Client example program"
fi

popd > /dev/null # ${SCRIPTDIR}
pwd

exit 0
