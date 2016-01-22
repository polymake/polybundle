#!/bin/bash -ex

DIR=$1; shift
RESDIR=$1; shift
SUFFIX=$1; shift

# possibly remove trailing slash
RESDIR=${RESDIR%/}
echo $RESDIR;

if [ -d $DIR ]; then
	cd $DIR;

	for f in *$SUFFIX; do
		if [ -f $f  -a ! -h $f ]; then
			if file $f | grep -m1 Mach; then
				if otool -L $f | grep -o "/Users.*dylib" ; then
					dl=`otool -L $f | grep -o "/Users.*dylib"`;
					for d in $dl; do
						echo "found lib:" $d;
						if [[ "$d" =~ ^$RESDIR ]]; then
  							lib=${d##*/};    # get the libname
							echo $lib;
							path=${d%/*};    # and the path to it
							path=${path#$RESDIR/}
							echo $path;
#							if [ $lib != $f ]; then
								chmod u+w $f;
								if [[ $path =~ "lib" ]]; then
									install_name_tool -change "$d" "@rpath/$lib" $f;
								else
									install_name_tool -change "$d" "@rpath/../$path/$lib" $f;
								fi;
								chmod u-w $f;
#							fi;
						fi;
					done;
				fi;
			fi;
		fi;
	done;
fi;
