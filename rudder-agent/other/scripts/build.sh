#!/bin/bash -e

RUDDERDIR=/opt/rudder
RUDDERVARDIR=/var/rudder
RUDDERLOGDIR=/var/log/rudder
PREFIX=$RUDDERDIR
BUILD_DIR="$PWD/../build"


export LDFLAGS="-R${RUDDERDIR}/lib -L${RUDDERDIR}/lib"
export CFLAGS="-I${RUDDERDIR}/include"
export LD_LIBRARY_PATH="$RUDDERDIR/lib"
export LD_RUN_PATH="$RUDDERDIR/lib"

export AR=/opt/csw/bin/gar

OS=`uname -s`
ARCH=`uname -p`


for build in prepare zlib bzip2 pcre openssl cfengine perlprepare perl mod_ssleay mods; do
	if [ -f functions/$build.$OS.$ARCH ]; then
		source functions/$build.$OS.$ARCH
	elif [ -f functions/$build.$OS ]; then
		source functions/$build.$OS
	elif [ -f functions/$build.common ]; then
		source functions/$build.common
	else
		echo "ERROR: Unable to locate source file for function build_$build"
		exit 1
	fi
	
	build_$build
	
done
