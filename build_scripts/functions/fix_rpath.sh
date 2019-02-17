#!/bin/bash -x

DIR=$1; shift
RESDIR=$1; shift
SUFFIX=$1; shift

# possibly remove trailing slash
RESDIR=${RESDIR%/}
echo $RESDIR;

if [ -d $DIR ]; then
	cd $DIR;

	for f in *${SUFFIX}; do
		echo $f;
		if [ -f $f  -a ! -h $f ]; then
			if file $f | grep -m1 Mach; then
				chmod u+w $f
				if [ -x $f ]; then
					g=`otool -l $f | grep -c "path $RESDIR"`;
					while [ $g -gt 0 ]; do
						install_name_tool -rpath "$RESDIR" ""@loader_path/../lib"" $f || true;
						g=`otool -l $f | grep -c "path $RESDIR"`;
					done;
				else
					install_name_tool -rpath "$RESDIR" ""../Resources/lib"" $f || true;
				fi;
				chmod u-w $f;
			fi;
		fi;
	done;
fi;
