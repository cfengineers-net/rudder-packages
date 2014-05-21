#!/bin/bash -e

PREFIX="/opt/rudder"
PERL_PREFIX="$PREFIX"
PERL_VERSION="5.12.4";
BUILDDIR="$PWD/../build"
FILEDIR="$BUILDDIR/files"
FUSIONINVENTORY_FOLDER="$BUILDDIR/fusioninventory-agent"
MODULES="Digest::MD5 Net::IP XML::SAX XML::Simple UNIVERSAL::require File::Which XML::TreePP"


export LDFLAGS="-L$PREFIX/lib -R$PREFIX/lib" && export CFLAGS="-I$PREFIX/include -I$PREFIX/include/libxml2"
export LD_LIBRARY_PATH="$PREFIX/lib"
export LD_RUN_PATH="$PREFIX/lib"
export LDDLFLAGS="-G -fstack-protector -L$PREFIX/lib -R$PREFIX/lib"

PATCH_FILE=/tmp/solaris.build.tmp

build_prepare() {
	mkdir -p $BUILDDIR
}

build_libgcc () {
	mkdir -p $PREFIX/lib
	gcp -rp /opt/csw/lib/libssp.so* $PREFIX/lib
	gcp -rp /opt/csw/lib/libgcc_s.so* $PREFIX/lib
	chrpath -r $PREFIX/lib $PREFIX/lib/libssp.so.0.0.0
}

build_perl () {
	cd $BUILDDIR
	gunzip < $FILEDIR/perl-$PERL_VERSION.tar.gz | tar xf -
	cd perl-$PERL_VERSION
    
	./Configure -Dnoextensions=ODBM_File -Duserelocatableinc -Dusethreads -des -Dcc="gcc" -Dinstallprefix=$PREFIX -Dsiteprefix=$PREFIX \
		-Dprefix=$PREFIX -Dlddlflags="-G -fstack-protector -L$PREFIX/lib -R$PREFIX/lib" -Dldflags="-fstack-protector -L$PREFIX/lib -R$PREFIX/lib" \
		-Dcldflags="-L$PREFIX/lib -R$PREFIX/lib -fstack-protector"
	cat > $PATCH_FILE << EOF
--- Makefile    Mon May 19 15:46:43 2014
+++ /tmp/Makefile       Mon May 19 15:49:42 2014
@@ -7,8 +7,8 @@
 CC = gcc
 LD = gcc
 
-LDFLAGS =  -fstack-protector 
-CLDFLAGS =  -fstack-protector 
+LDFLAGS =  -L$PREFIX/lib -R$PREFIX/lib -fstack-protector
+CLDFLAGS =  -L$PREFIX/lib -R$PREFIX/lib -fstack-protector
 
 mallocsrc = 
 mallocobj = 
@@ -35,7 +35,7 @@
 
 # The following are used to build and install shared libraries for
 # dynamic loading.
-LDDLFLAGS = -G -fstack-protector
+LDDLFLAGS = -L$PREFIX/lib -R$PREFIX/lib -G -fstack-protector
 SHRPLDFLAGS = \$(LDDLFLAGS)
 CCDLFLAGS =  
 DLSUFFIX = .so
EOF
#	gpatch -p0 < $PATCH_FILE
	make
	make install 
}

# Generate a pseudo UUID
function build_ssl_eay() {
	cd $BUILDDIR
	gunzip < $FILEDIR/Crypt-SSLeay-0.57.tar.gz | tar xvf -
	cd Crypt-SSLeay-0.57
	PERL_MM_USE_DEFAULT=1 $PREFIX/bin/perl Makefile.PL --default INSTALL_BASE=$PERL_PREFIX \
		LDFLAGS="-fstack-protector -L/$PREFIX/lib -$PREFIX/lib" \
		LDDLFLAGS="-G -fstack-protector -L$PREFIX/lib -R$PREFIX/lib" \
		CCFLAGS="-D_REENTRANT -fno-strict-aliasing -pipe -fstack-protector -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64 -DPERL_USE_SAFE_PUTENV -I$PREFIX/include" \
		--lib $PREFIX/lib
	make install
}

function installMod () {
    modName=$1
    distName=$2
    args=$3

    if [ -z "$distName" ]; then
        distName=`echo $modName|sed 's,::,-,g'`
    fi
    archive=`ls $FILEDIR/$distName*.tar.gz`
    $PERL_PREFIX/bin/perl $CPANM -l $PERL_PREFIX --skip-installed $archive $args
    $PERL_PREFIX/bin/perl -I $PERL_PREFIX/lib/perl5-M$modName -e1
}

function build_modules() {

	cd $BUILDDIR
	archive=`ls $FILEDIR/App-cpanminus-*.tar.gz`
	echo $archive
	gunzip < $archive | tar xf -
	CPANM=$BUILDDIR/App-cpanminus-1.0004/bin/cpanm

	installMod "URI"
	installMod "HTML::Tagset"
	installMod "HTML::Parser"
	installMod "LWP" "libwww-perl"
	installMod "Compress::Raw::Bzip2"
	installMod "Compress::Raw::Zlib"
	installMod "Compress::Raw::Zlib" "IO-Compress"

	for modName in $MODULES; do
		installMod $modName
	done
}

function build_fusion_agent() {
	cd ${FUSIONINVENTORY_FOLDER}

	mkdir -p $PREFIX/share/fusion-utils && gcp -a share/* $PREFIX/share/fusion-utils

	PERL_MM_USE_DEFAULT=1 $PREFIX/bin/perl Makefile.PL --default PREFIX=$PERL_PREFIX
	gmake install

	gcp -a lib/FusionInventory $PREFIX/lib/perl5/
}

build_prepare
build_libgcc
build_perl
build_ssl_eay
build_modules

build_fusion_agent

