#!/bin/bash -e

. $PWD/vars/common

. $PWD/vars/cfengine.$OS
. $PWD/vars/exports

test -d $PREFIX && mv $PREFIX $PREFIX.bak

gunzip -f $BUILDDIR/$PKGNAME-$VERSION-${CFE_NAMING}_$OS_RELEASE-$ARCH.pkg.gz

cat > /tmp/admin << EOF
mail=
instance=overwrite
partial=nocheck
runlevel=nocheck
idepend=nocheck
rdepend=nocheck
space=nocheck
setuid=nocheck
conflict=nocheck
action=nocheck
networktimeout=60
networkretries=3
authentication=quit
keystore=/var/sadm/security
proxy=
basedir=default
EOF

pkgadd -n -a /tmp/admin -d $BUILDDIR/$PKGNAME-$VERSION-${CFE_NAMING}_$OS_RELEASE-$ARCH.pkg all

gpatch -N -d $BUILDDIR/cfengine-source/tests/acceptance -p0 < $SCRIPTDIR/patches/SunOS/testall/0001-correct-erroneous-use-of-date-on-solaris.patch

cd $BUILDDIR/cfengine-source/tests/acceptance

./testall --no-network --agent=$PREFIX/bin/cf-agent

pkgrm -n -a /tmp/admin $PKGNAME

gzip -f $BUILDDIR/$PKGNAME-$VERSION-${CFE_NAMING}_$OS_RELEASE-$ARCH.pkg
rm -rf $PREFIX
