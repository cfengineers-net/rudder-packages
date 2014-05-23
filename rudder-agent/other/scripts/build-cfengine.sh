#!/bin/bash -e

. $PWD/vars/common

. $PWD/vars/cfengine.$OS
. $PWD/vars/exports

. $PWD/functions/common

builder

function prepare_pkg_libs_cfengine() {
	BINCOMPS="$PREFIX/bin/cf-*"
	
	mkdir -p $SPOOL_SRC

	(ldd $BINCOMPS | grep csw > /dev/null 2>&1) && (echo "FATAL: check linking manually" && exit 1)

	ldd $BINCOMPS | grep $PREFIX/lib | awk '{print $NF}' | sort -u | while read line; do
		dir=${line%/*}
		lib=${line##*/}
		lib=${lib%%.so*}
		mkdir -p $SPOOL_SRC/$dir
		$CP -a $dir/$lib.so* $SPOOL_SRC/$dir
		chmod 644 $SPOOL_SRC/$dir/*
	done
}
function prepare_pkg_bins_cfengine() {
	mkdir -p $SPOOL_SRC/$PREFIX/bin
	$CP -a $PREFIX/bin/cf-* $SPOOL_SRC/$PREFIX/bin	
	if [ -f $PREFIX/bin/tchmgr ]; then
		$CP -a $PREFIX/bin/tchmgr $SPOOL_SRC/$PREFIX/bin
	fi
}

function prepare_pkg_share_common() {
	test -d $SPOOL_SRC/$PREFIX/share && rm -rf $SPOOL_SRC/$PREFIX/share
	$CP -a $PREFIX/share $SPOOL_SRC/$PREFIX/share
}

function package_cfengine() {
	cat > $SPOOL_SRC/pkginfo << EOF
PKG="$PKGNAME"
NAME="$NAME"
ARCH="$ARCH"
VERSION="$VERSION"
CATEGORY="application"
VENDOR="$DESCRIPTION"
EMAIL="contact@cfengineers.net"
PSTAMP="www.cfengineers.net"
BASEDIR="/"
CLASSES="none"
SUNW_PKG_ALLZONES="false"
SUNW_PKG_THISZONE="true"
EOF
	$CP -a $SCRIPTDIR/../pkg/cfengine/$OS/* $SPOOL_SRC
	cat > $SPOOL_SRC/prototype << EOF
i pkginfo=./pkginfo
i postinstall=./postinstall
i preremove=./preremove
i postremove=./postremove
i preinstall=./preinstall
EOF
	cd $SPOOL_SRC
	find var | pkgproto >> $SPOOL_SRC/prototype
	find etc | pkgproto >> $SPOOL_SRC/prototype

	SPOOL_TRANS=$SPOOL/trans/cfengine/$VERSION
	mkdir -p $SPOOL_TRANS
	pkgmk -o -r $SPOOL_SRC -d $SPOOL_TRANS
	pkgtrans -s $SPOOL_TRANS $BUILDDIR/$PKGNAME-$VERSION-${CFE_NAMING}_$OS_RELEASE-$ARCH.pkg all 
	gzip -f $BUILDDIR/$PKGNAME-$VERSION-${CFE_NAMING}_$OS_RELEASE-$ARCH.pkg
}

function clean() {
	cd $SCRIPTDIR
	rm -rf $SPOOL
}

prepare_pkg_libs_cfengine
prepare_pkg_bins_cfengine
prepare_pkg_share_common

package_cfengine

clean
