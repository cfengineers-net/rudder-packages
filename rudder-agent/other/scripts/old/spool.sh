
function spool_cfengine {
	BINCOMPS="$PREFIX/bin/cf-*"
	
	SPOOL=$PREFIX.spool	
	mkdir -p $SPOOL

	(ldd $BINCOMPS | grep csw > /dev/null 2>&1) && (echo "FATAL: check linking manually" && exit 1)

	ldd $BINCOMPS | grep $PREFIX/lib | awk '{print $NF}' | sort -u | while read line; do
		dir=${line%/*}
		lib=${line##*/}
		lib=${lib%%.so*}
		mkdir -p $SPOOL/$dir
		$CP -a $dir/$lib.so* $SPOOL/$dir
		chmod 644 $SPOOL/$dir/*
	done
	test -d $SPOOL/$PREFIX/share && rm -rf $SPOOL/$PREFIX/share
	$CP -a $PREFIX/share $SPOOL/$PREFIX/share
	mkdir -p $SPOOL/$PREFIX/bin
	$CP -a $PREFIX/bin/cf-* $SPOOL/$PREFIX/bin	
	if [ -f $PREFIX/bin/tchmgr ]; then
		$CP -a $PREFIX/bin/tchmgr $SPOOL/$PREFIX/bin
	fi  
}

function spool_perl {
	
	#find $PREFIX/lib/perl5 -name "*.so" -exec ldd {} \;	
	find $PREFIX/lib/perl5 -name "*.so" -exec ldd {} \; | grep lib | awk '{print $NF}' | sort -u | while read line; do
		echo $line	
	done
}
