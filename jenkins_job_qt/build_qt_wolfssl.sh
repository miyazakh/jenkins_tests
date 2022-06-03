#!/bin/bash

###############################################################################
# This script allows for building Qt versions that wolfSSL supports.
# A patch for Qt 5.15.2 will be applied to allow for a wolfSSL config.
# An OpenSSL build option was added to demonstrate that both options work.
#
# Instructions:
#   It is reccomended to do each unique build in a seperate directory.
#   Run the script "./build-qt-wolfssl.sh"
#   Follow the prompts for Qt and SSL versions.
#
# For any questions or problems, please contact:
# Original Author:  Aaron Jense
# Updated by : HM
# Contact: hide@wolfssl.com
###############################################################################

###############################################################################
# Environment
###############################################################################
HOME=$(eval "pwd")
THREADS=8
WOLFINSTDIR=/wolfssl-install

QT_BUILDDIR=qt5_build
QT_TEST_DIR=$QT_BUILDDIR/qtbase/tests/auto/network/ssl
#PATCH_DIR=/home/miyazakh/workspace/jenkins
PATCH_DIR=$HOME
PATCH_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/wolfssl-qt-515.patch
UPATCH_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/wolfssl-qt-515-unit-test.patch

# Certs URL
CERT1_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/certs/ca-cert.pem
CERT2_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/certs/client-cert.pem
CERT3_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/certs/client-key.pem
CERT4_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/certs/server-cert.pem
CERT5_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/certs/server-key.pem
# Unit Test Program URL
UT1_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/qssl_wolf.pro
UT2_WGETPATH=https://raw.githubusercontent.com/wolfSSL/osp/master/qt/qssl_wolf/tst_wolfssl.cpp

export LD_LIBRARY_PATH="${HOME}/${WOLFINSTDIR}/lib:$LD_LIBRARY_PATH"
###############################################################################
# wolfSSL Setup
###############################################################################
WOLFSSL_QT_CONFIG="-wolfssl-linked -developer-build -opensource -confirm-license -no-opengl -nomake examples"
WOLFSSL_CONFIG=(--enable-qt --enable-qt-test --enable-alpn --enable-rc2 --prefix=${HOME}/${WOLFINSTDIR} CFLAGS="-DWOLFSSL_ERROR_CODE_OPENSSL -DWOLFSSL_LOAD_VERIFY_DEFAULT_FLAGS=0x1b")
#WOLFSSL_INCLUDE="-I${HOME}/${WOLFINSTDIR}/include/wolfssl -I$HOME/$WOLFINSTDIR/include"
WOLFSSL_INCLUDE="-I${HOME}/${WOLFINSTDIR}/include/wolfssl -I${HOME}/${WOLFINSTDIR}/include"
export WOLFSSL_LIBS="-L${HOME}/${WOLFINSTDIR}/lib -lwolfssl"
###############################################################################
# OpenSSL Setup
###############################################################################
OPENSSL_QT_CONFIG="-openssl-linked -developer-build -opensource -confirm-license"
OPENSSL_CONFIG="--prefix=$HOME/openssl-install --openssldir=$HOME/openssl-install"
OPENSSL_INCLUDE="-I$WORKSPACE/openssl-install/include/openssl -I$WORKSPACE/openssl-install/include"
export OPENSSL_LIBS="-L$WORKSPACE/openssl-install/lib -lcrypto -lssl"
export OPENSSL_VERSION_NUMBER=0x1000100fL

###############################################################################
# Default Set up
###############################################################################
QT_VERSION="5.15.2"
QT_PATCH="${PATCH_DIR}/wolfssl-qt-515.patch"
QT_UNITTEST_PATCH="${PATCH_DIR}/wolfssl-qt-515-unit-test.patch"
SSL_VERSION="wolfSSL"
QT_WOLF_UNIT_TEST="qssl_wolf"
QT_WOLF_UNIT_TEST_PRG="tst_wolfssl.cpp"
QT_WOLF_UNIT_TEST_PRG_PATCH="$HOME/unitprg.patch"
################################################################################
## Retreive Path files and Test files
################################################################################
GetPatch_Test () {

    # Retreive path files from URL
    if [ -f "$QT_PATCH" ]; then
        rm -f "$QT_PATCH"
    fi

    if [ -f "$QT_UNITTEST_PATCH" ]; then
        rm -f "${QT_UNITTEST_PATCH}"
    fi

    wget $PATCH_WGETPATH  --no-check-certificate
    wget $UPATCH_WGETPATH --no-check-certificate

    # Retreive unit test program from URL
    if [ -d "$QT_WOLF_UNIT_TEST" ]; then
        rm -rf "$QT_WOLF_UNIT_TEST"
    fi

    mkdir "$QT_WOLF_UNIT_TEST"
    
    cd "$QT_WOLF_UNIT_TEST"
    mkdir "certs"
    
    cd "certs"

    wget $CERT1_WGETPATH  --no-check-certificate
    wget $CERT2_WGETPATH  --no-check-certificate
    wget $CERT3_WGETPATH  --no-check-certificate
    wget $CERT4_WGETPATH  --no-check-certificate
    wget $CERT5_WGETPATH  --no-check-certificate

    cd "$HOME/$QT_WOLF_UNIT_TEST"
    wget $UT1_WGETPATH  --no-check-certificate
    wget $UT2_WGETPATH  --no-check-certificate

    # apply patch for unit test program to be ran as jenkins job
    patch ./$QT_WOLF_UNIT_TEST_PRG $QT_WOLF_UNIT_TEST_PRG_PATCH

    cd "$HOME"


}
################################################################################
## User Setup
################################################################################
User_Setup () {
 echo "Choose Qt Version to build."
 
 options=("5.12.4" "5.13" "5.15" "Quit")
 
 select opt in "${options[@]}"
 do
     case $opt in
         "5.12.4")
             echo "Building Qt 5.12.4"
             QT_VERSION="5.12.4"
             QT_PATCH="wolfssl-qt-512.patch"
             QT_UNITTEST_PATCH=""
             break
             ;;
         "5.13")
             echo "Building Qt 5.13"
             QT_VERSION="5.13"
             QT_PATCH="wolfssl-qt-513.patch"
             QT_UNITTEST_PATCH=""
             break
             ;;
         "5.15")
             echo "Building Qt 5.15"
             QT_VERSION="5.15.2"
             QT_PATCH="wolfssl-qt-515.patch"
             QT_UNITTEST_PATCH="wolfssl-qt-515-unit-test.patch"
             break
             ;;
         "Quit")
             exit 0
             ;;
         *) echo "Unknown Option: $REPLY";;
     esac
 done

 echo "Choose SSL Version to build."
 options=("wolfSSL" "OpenSSL" "Quit")
 select opt in "${options[@]}"
 do
     case $opt in
         "wolfSSL")
             SSL_VERSION="wolfSSL"
             break
             ;;
         "OpenSSL")
             SSL_VERSION="OpenSSL"
             break
             ;;
         "Quit")
             exit 0
             ;;
         *) echo "Unknown Option: $REPLY";;
     esac
 done

 echo "Building Qt $QT_VERSION with $SSL_VERSION"

}

################################################################################
## Build SSL Library (wolfSSL or OpenSSL)
################################################################################
build_SSLLib () {

 if [ $SSL_VERSION = "wolfSSL" ]; then
     # Configure and install wolfSSL
     if [ ! -d "wolfssl" ]; then
         git clone https://github.com/wolfssl/wolfssl
     else
         cd "$HOME"/wolfssl
         git clean -dfx
         git pull
     fi
 
     cd "$HOME"/wolfssl

     ./autogen.sh
     ./configure "${WOLFSSL_CONFIG[@]}"
     make check
     if [ $? -ne 0 ]; then
         echo "wolfSSL Unit Test Failure"
         exit -1
     else
         make install
     fi

     QT_CONFIG=${WOLFSSL_QT_CONFIG}
     QT_INCLUDE=${WOLFSSL_INCLUDE}
     echo "qt config $QT_CONFIG"
     echo "qt include $QT_INCLUDE"
 elif [ $SSL_VERSION = "OpenSSL" ]; then
     # Configure and install wolfSSL
     if [ ! -d "openssl" ]; then
         git clone git://git.openssl.org/openssl.git
     fi

     cd "$HOME"/openssl
     ./config "$OPENSSL_CONFIG"
     make -j$THREADS

     QT_CONFIG=${OPENSSL_QT_CONFIG}
     QT_INCLUDE=${OPENSSL_INCLUDE}
 else
     echo "Error Building $SSL_VERSION"
 fi
}

###############################################################################
# Configure and build Qt
###############################################################################
build_Qt () {
 cd "$HOME"
 if [ ! -d "qt5" ]; then
#    git clone git://code.qt.io/qt/qt5.git
     git clone https://github.com/qt/qt5.git
 else
     cd "$HOME"/qt5/qtbase
#     git restore .
     git checkout .
 fi

 cd "$HOME"/qt5
 git checkout $QT_VERSION
 perl ./init-repository --module-subset=qtbase
 cd "$HOME"/qt5/qtbase
 printf "\nApplying Patch on Qt for wolfSSL configuration.\n"
 printf "This shouldn't break OpenSSL configurations.\n\n"
 printf "$QT_PATCH and $QT_UNITTEST_PATCH\n"

 if [ ! -f "$QT_PATCH" ]; then
    echo "Can't locate patch file ${QT_PATCH}, please check the file path and try again"
    exit 1
 fi
 echo "${QT_PATCH}"
 git apply -v "${QT_PATCH}"
 if [ $? -ne 0 ]; then
     echo "FAILED: Applying Patch"
     exit -1
 fi
 
 if [ ! -f "$QT_UNITTEST_PATCH" ]; then
    echo "Can't locate patch file ${QT_UNITTEST_PATCH}, please check the file path and try again"
    exit 1
 fi
 if [ $QT_UNITTEST_PATCH != "" ]; then
     git apply -v "${QT_UNITTEST_PATCH}"
     if [ $? -ne 0 ]; then
         echo "FAILED: Applying unit test Patch"
         exit -1
     fi
     cp -r "$PATCH_DIR"/qssl_wolf "$HOME"/qt5/qtbase/tests/auto/network/ssl
     
     cp "$HOME"/qt5/qtbase/tests/auto/network/ssl/qsslsocket/certs/* "$HOME"/qt5/qtbase/tests/auto/network/ssl/qssl_wolf/certs/* 
     
 fi
 
 if [ -d "${HOME}/${QT_BUILDDIR}" ]; then
    rm -rf "${HOME}/${QT_BUILDDIR}"
 fi
 mkdir "${HOME}/${QT_BUILDDIR}"
 
 cd "${HOME}/${QT_BUILDDIR}"
 echo "../qt5/configure ${QT_CONFIG} ${QT_INCLUDE}"
 ../qt5/configure $QT_CONFIG $QT_INCLUDE

 make -j$THREADS
 if [ $? -ne 0 ]; then
     echo "FAILED : Qt build"
     exit -1
 fi

}

###############################################################################
# Run Qt unit test 
###############################################################################
run_test () {
 no_pid=-1
 openssl_pid=$no_pid

 echo cp "$PATCH_DIR"/run_unit_test.sh "${HOME}/${QT_TEST_DIR}"
 cp "$PATCH_DIR"/run_unit_test.sh "${HOME}/${QT_TEST_DIR}"
 cd "${HOME}/${QT_TEST_DIR}"
 
 ./run_unit_test.sh

 if [ $? -ne 0 ]; then
     echo "FAILED : Qt unit test"
     exit -1
 fi

 diff "${HOME}/${QT_TEST_DIR}"/qt_unittest.log "$PATCH_DIR"/unitlog.gold
 
 if [ $? -ne 0 ]; then
     echo "Qt test log has differences to gold file"
     exit -1
 fi
}

run_test_opnessl () {
 no_pid=-1
 openssl_pid=$no_pid

 cp "$HOME"/run_unit_test.sh "${HOME}/${QT_TEST_DIR}"
 cd "${HOME}/${QT_TEST_DIR}"
 
 if type openssl >/dev/null 2>&1; then
    
    openssl s_server -accept 11111 -key "$HOME"/wolfssl/certs/server-key.pem -cert "$HOME"/wolfssl/certs/server-cert.pem  -WWW &
    openssl_pid=$!
    echo openssl pid $openssl_pid

    ./run_unit_test.sh

    if [ $openssl_pid != $no_pid ]; then

        echo kill openssl pid $openssl_pid
        kill -9 $openssl_pid
        openssl_pid=$no_pid
    fi
 fi

 if [ $? -ne 0 ]; then
     echo "FAILED : Qt unit test"
     exit -1
 else
     echo "SUCCEED: Qt unit test!"
     exit 1
 fi
}

###############################################################################
# main 
###############################################################################
#User_Setup
echo "Get patch file from" "${PATCH_WGETPATH}"
GetPatch_Test

echo "Build SSL library"
build_SSLLib
cd "$HOME"

echo "Build Qt"
build_Qt
cd "$HOME"

echo "LD_LIBRARY_PATH" "${LD_LIBRARY_PATH}"
echo "Run Qt Unit test" 
run_test
cd "$HOME"

echo "END OF TEST"
