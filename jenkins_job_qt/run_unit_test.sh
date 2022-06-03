#!/bin/bash

TESTDIR="./*"
GRPKEY="-e Totals: -e FAIL"
QSSLSOCKET="qsslsocket"
LOGFILE="qt_unittest.log"

if [ -f $LOGFILE ]; then
    rm $LOGFILE
fi

# test dirs
dirs=`find $TESTDIR -maxdepth 0 -type d`

# iterate dirs
for dir in $dirs;
do
    if [[ $dir == *$QSSLSOCKET* ]];
    then
        echo Skip : $dir
    else
        echo Test : $dir
        make check -C $dir | grep $GRPKEY | sed -e "s/blacklisted.*/blacklisted/" >> $LOGFILE
    fi
done
