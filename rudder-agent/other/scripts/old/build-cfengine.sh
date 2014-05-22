#!/bin/bash -e

RUDDERDIR=/opt/rudder
RUDDERVARDIR=/var/rudder
RUDDERLOGDIR=/var/log/rudder
BUILD_DIR="$PWD/../build"


export LDFLAGS="-R${RUDDERDIR}/lib -L${RUDDERDIR}/lib"
export CFLAGS="-I${RUDDERDIR}/include"
export LD_LIBRARY_PATH="$RUDDERDIR/lib"
export LD_RUN_PATH="$RUDDERDIR/lib"

export AR=/opt/csw/bin/gar

function build_prepare() {
	mkdir -p $RUDDERDIR/lib $RUDDERDIR/include	
	gcp -a /opt/csw/lib/libgcc_s.so* $RUDDERDIR/lib
}

function build_zlib() {
	cd $BUILD_DIR/zlib-source
	./configure --prefix=$RUDDERDIR
	make
	make install
}

function build_bzlib2() {
	cd $BUILD_DIR/bzip2-source
	make -f Makefile-libbz2_so
	ln -s libbz2.so.1.0.6 libbz2.so.1
	ln -s libbz2.so.1.0.6 libbz2.so
	gcp -a libbz2.so* $RUDDERDIR/lib
	gcp -a *.h $RUDDERDIR/include	
}

function build_openssl() {
	cd $BUILD_DIR/openssl-source
	./config shared --prefix=$RUDDERDIR	
	gpatch -p0 < $BUILD_DIR/../patches/openssl/0001-makefile-correct-ldflags.patch
	make
	make install
}

function build_pcre() {
	cd $BUILD_DIR/pcre-source
	./configure --prefix=$RUDDERDIR --enable-shared --disable-static --disable-cpp --enable-unicode-properties
	make
	make install
}

function build_tokyocabinet() {
	cd $BUILD_DIR/tokyocabinet-source
	./configure --enable-shared --prefix=$RUDDERDIR --disable-static --without-zlib --without-bzip
	make
	make install
}

function build_cfengine() {
	cd $BUILD_DIR/cfengine-source
	./configure --prefix=$RUDDERDIR --with-tokyocabinet=$RUDDERDIR --with-openssl=$RUDDERDIR \
		--with-pcre=$RUDDERDIR --with-workdir=$RUDDERVARDIR/cfengine-community --without-postgresql \
		--without-libxml2 --without-mysql --without-libxml2
		 
	make
	make install
}
build_prepare
build_zlib
build_bzlib2
build_openssl
build_pcre
build_tokyocabinet
build_cfengine
